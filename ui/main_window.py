import os
import threading
import tkinter as tk
import customtkinter as ctk
from tkinter import filedialog, StringVar, messagebox

from ui.drag_drop import DragDropFrame
from ui.settings import SettingsWindow
from ui.about import AboutWindow
from core.config import load_config, save_config
from core.detector import (
    detect_file, detect_folder, SUPPORTED_INPUT, get_valid_targets,
    get_command_preview, get_badge_color, get_extension
)
from core.converter import Converter, ConversionJob
from core.validator import verify_chd
from core.logger import log

# ── Color Palette (Matching Design Specifications) ───────────────────────────
BG_DARK     = "#1a1a2e"
CARD_BG     = "#16213e"
ACCENT_RED  = "#e94560"
BORDER_DARK = "#333333"
TEXT_WHITE  = "#ffffff"
TEXT_GRAY   = "#a0a0b0"
GREEN_DONE  = "#00e676"
RED_FAIL    = "#ff5252"

ctk.set_appearance_mode("dark")

class MainWindow(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("OpenROM v2.0 - Universal ROM Compression Suite")
        self.geometry("980x680")
        self.minsize(900, 600)
        self.configure(fg_color=BG_DARK)

        # State
        self._jobs_lock = threading.Lock()
        self.jobs: list[ConversionJob] = []
        self.selected_job_index: int | None = None

        self.config = load_config()
        saved_output_dir = self.config.get("output_dir", "")

        self.compression   = StringVar(value="Normal")
        self.verify_after  = ctk.BooleanVar(value=True)
        self.selected_target = StringVar(value="")
        self.output_dir    = StringVar(value=saved_output_dir)
        self.output_dir.trace_add("write", self._on_output_dir_changed)
        self.same_as_src   = ctk.BooleanVar(value=True)

        self._converting   = False

        self.converter     = Converter(
            on_log=self._on_log_msg,
            on_progress=self._on_progress,
        )

        self._build_menu()
        self._build_ui()

    # ── Menu Bar ──────────────────────────────────────────────────────────────

    def _build_menu(self):
        self.menu_bar = tk.Menu(self)
        self.config(menu=self.menu_bar)

        file_menu = tk.Menu(self.menu_bar, tearoff=0)
        file_menu.add_command(label="Open Files...", command=self._menu_open_files)
        file_menu.add_command(label="Open Folder...", command=self._menu_open_folder)
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.quit)
        self.menu_bar.add_cascade(label="File", menu=file_menu)

        self.menu_bar.add_command(label="Settings", command=self._open_settings)

        help_menu = tk.Menu(self.menu_bar, tearoff=0)
        help_menu.add_command(label="About OpenROM", command=self._open_about)
        self.menu_bar.add_cascade(label="Help", menu=help_menu)

    def _menu_open_files(self):
        filetypes = [
            ("ROM files", "*.iso *.bin *.cue *.gdi *.img *.ecm *.chd *.cso *.zso"),
            ("All files", "*.*"),
        ]
        paths = filedialog.askopenfilenames(filetypes=filetypes)
        if paths:
            self._add_files(list(paths))

    def _menu_open_folder(self):
        folder = filedialog.askdirectory()
        if folder:
            self._add_folder(folder)

    # ── Main Two-Column UI ───────────────────────────────────────────────────

    def _build_ui(self):
        # Master grid container: 2 columns
        self.grid_columnconfigure(0, weight=1, minsize=420)
        self.grid_columnconfigure(1, weight=1, minsize=440)
        self.grid_rowconfigure(0, weight=1)

        self._build_left_column()
        self._build_right_column()

    # ── Left Column ───────────────────────────────────────────────────────────

    def _build_left_column(self):
        left_frame = ctk.CTkFrame(self, fg_color="transparent")
        left_frame.grid(row=0, column=0, sticky="nsew", padx=(16, 8), pady=16)
        left_frame.grid_rowconfigure(2, weight=1)
        left_frame.grid_columnconfigure(0, weight=1)

        # 1. Header
        hdr_frame = ctk.CTkFrame(left_frame, fg_color="transparent")
        hdr_frame.grid(row=0, column=0, sticky="ew", pady=(0, 12))

        title_lbl = ctk.CTkLabel(
            hdr_frame, text="🎮 OpenROM",
            font=ctk.CTkFont(size=24, weight="bold"),
            text_color=TEXT_WHITE
        )
        title_lbl.pack(anchor="w")

        sub_lbl = ctk.CTkLabel(
            hdr_frame, text="Universal ROM Suite",
            font=ctk.CTkFont(size=13),
            text_color=TEXT_GRAY
        )
        sub_lbl.pack(anchor="w")

        # 2. DROP ZONE Card
        self.drop_frame = DragDropFrame(
            left_frame,
            on_files=self._add_files,
            on_folder=self._add_folder,
            label="Drop ROM files here\nor click to browse"
        )
        self.drop_frame.grid(row=1, column=0, sticky="ew", pady=(0, 12))

        # 3. Queue Section Card
        queue_card = ctk.CTkFrame(left_frame, fg_color=CARD_BG, corner_radius=12, border_color=BORDER_DARK, border_width=1)
        queue_card.grid(row=2, column=0, sticky="nsew")
        queue_card.grid_rowconfigure(1, weight=1)
        queue_card.grid_columnconfigure(0, weight=1)

        queue_hdr = ctk.CTkFrame(queue_card, fg_color="transparent")
        queue_hdr.grid(row=0, column=0, sticky="ew", padx=12, pady=(10, 4))

        self.queue_label = ctk.CTkLabel(
            queue_hdr, text="📋 Queue (0)",
            font=ctk.CTkFont(size=14, weight="bold"),
            text_color=TEXT_WHITE
        )
        self.queue_label.pack(side="left")

        # Scrollable list of queued files
        self.queue_list = ctk.CTkScrollableFrame(
            queue_card, fg_color="transparent", corner_radius=0
        )
        self.queue_list.grid(row=1, column=0, sticky="nsew", padx=6, pady=4)

        # Bottom Clear All Button
        btn_bar = ctk.CTkFrame(queue_card, fg_color="transparent")
        btn_bar.grid(row=2, column=0, sticky="ew", padx=12, pady=10)

        clear_btn = ctk.CTkButton(
            btn_bar, text="Clear All",
            fg_color=BORDER_DARK, hover_color="#444444",
            text_color=TEXT_WHITE, font=ctk.CTkFont(size=12, weight="bold"),
            height=32, command=self._clear_all
        )
        clear_btn.pack(side="left")

    # ── Right Column ──────────────────────────────────────────────────────────

    def _build_right_column(self):
        right_frame = ctk.CTkFrame(self, fg_color="transparent")
        right_frame.grid(row=0, column=1, sticky="nsew", padx=(8, 16), pady=16)
        right_frame.grid_rowconfigure(1, weight=1)
        right_frame.grid_columnconfigure(0, weight=1)

        # 1. Conversion Settings Header
        settings_hdr = ctk.CTkFrame(right_frame, fg_color="transparent")
        settings_hdr.grid(row=0, column=0, sticky="ew", pady=(0, 12))

        hdr_title = ctk.CTkLabel(
            settings_hdr, text="⚙️ Conversion Settings",
            font=ctk.CTkFont(size=20, weight="bold"),
            text_color=TEXT_WHITE
        )
        hdr_title.pack(side="left", anchor="w")

        about_btn = ctk.CTkButton(
            settings_hdr, text="About / Support",
            width=110, height=28,
            fg_color=BORDER_DARK, hover_color="#444444",
            text_color=TEXT_WHITE, font=ctk.CTkFont(size=11),
            command=self._open_about
        )
        about_btn.pack(side="right")

        # Main Settings Card
        self.settings_card = ctk.CTkFrame(right_frame, fg_color=CARD_BG, corner_radius=12, border_color=BORDER_DARK, border_width=1)
        self.settings_card.grid(row=1, column=0, sticky="nsew")
        self.settings_card.grid_columnconfigure(0, weight=1)

        # Selected File Info Sub-card
        self.info_card = ctk.CTkFrame(self.settings_card, fg_color=BG_DARK, corner_radius=10)
        self.info_card.pack(fill="x", padx=16, pady=(16, 12))

        self.info_icon_title = ctk.CTkLabel(
            self.info_card, text="📀 No File Selected",
            font=ctk.CTkFont(size=15, weight="bold"),
            text_color=TEXT_WHITE, anchor="w"
        )
        self.info_icon_title.pack(fill="x", padx=12, pady=(10, 2))

        self.info_meta = ctk.CTkLabel(
            self.info_card, text="Select or drop a file to configure conversion",
            font=ctk.CTkFont(size=12),
            text_color=TEXT_GRAY, anchor="w"
        )
        self.info_meta.pack(fill="x", padx=12, pady=(0, 10))

        # CONVERT TO Header
        ctk.CTkLabel(
            self.settings_card, text="CONVERT TO:",
            font=ctk.CTkFont(size=12, weight="bold"),
            text_color=TEXT_GRAY
        ).pack(anchor="w", padx=16, pady=(4, 6))

        # Output target selection buttons container
        self.target_buttons_frame = ctk.CTkFrame(self.settings_card, fg_color="transparent")
        self.target_buttons_frame.pack(fill="x", padx=16, pady=(0, 10))

        # Command Preview Box
        self.cmd_preview_box = ctk.CTkFrame(self.settings_card, fg_color=BG_DARK, corner_radius=8)
        self.cmd_preview_box.pack(fill="x", padx=16, pady=(0, 12))

        self.cmd_selected_lbl = ctk.CTkLabel(
            self.cmd_preview_box, text="➜ Select target output format",
            font=ctk.CTkFont(size=12, weight="bold"),
            text_color=ACCENT_RED, anchor="w"
        )
        self.cmd_selected_lbl.pack(fill="x", padx=10, pady=(6, 2))

        self.cmd_str_lbl = ctk.CTkLabel(
            self.cmd_preview_box, text="Command will appear here...",
            font=ctk.CTkFont(family="Consolas", size=11),
            text_color=TEXT_GRAY, anchor="w"
        )
        self.cmd_str_lbl.pack(fill="x", padx=10, pady=(0, 6))

        # Options Section
        ctk.CTkLabel(
            self.settings_card, text="[Options]",
            font=ctk.CTkFont(size=12, weight="bold"),
            text_color=TEXT_WHITE
        ).pack(anchor="w", padx=16, pady=(4, 6))

        # Save to Row
        save_to_row = ctk.CTkFrame(self.settings_card, fg_color="transparent")
        save_to_row.pack(fill="x", padx=16, pady=(0, 8))

        ctk.CTkLabel(
            save_to_row, text="Save to:",
            font=ctk.CTkFont(size=12), text_color=TEXT_GRAY
        ).pack(side="left", padx=(0, 8))

        self.output_dir_entry = ctk.CTkEntry(
            save_to_row,
            textvariable=self.output_dir,
            placeholder_text="Same folder as input file",
            fg_color=BG_DARK, border_color=BORDER_DARK,
            text_color=TEXT_WHITE, font=ctk.CTkFont(size=11),
            height=28
        )
        self.output_dir_entry.pack(side="left", fill="x", expand=True, padx=(0, 8))

        browse_btn = ctk.CTkButton(
            save_to_row, text="Browse",
            width=65, height=28,
            fg_color=BORDER_DARK, hover_color="#444444",
            text_color=TEXT_WHITE, font=ctk.CTkFont(size=11, weight="bold"),
            command=self._browse_output_dir
        )
        browse_btn.pack(side="right")

        opt_row = ctk.CTkFrame(self.settings_card, fg_color="transparent")
        opt_row.pack(fill="x", padx=16, pady=(0, 12))

        ctk.CTkLabel(
            opt_row, text="Compression:",
            font=ctk.CTkFont(size=12), text_color=TEXT_GRAY
        ).pack(side="left", padx=(0, 8))

        self.compression_menu = ctk.CTkOptionMenu(
            opt_row,
            values=["Normal", "High", "Max"],
            variable=self.compression,
            fg_color=BG_DARK, button_color=BORDER_DARK,
            dropdown_fg_color=CARD_BG, text_color=TEXT_WHITE,
            width=110, height=28, font=ctk.CTkFont(size=12),
            command=self._on_compression_changed
        )
        self.compression_menu.pack(side="left", padx=(0, 16))

        self.verify_chk = ctk.CTkCheckBox(
            opt_row, text="Verify after conversion",
            variable=self.verify_after,
            text_color=TEXT_WHITE, fg_color=ACCENT_RED,
            font=ctk.CTkFont(size=12)
        )
        self.verify_chk.pack(side="left")

        # Action Buttons Area
        act_row = ctk.CTkFrame(self.settings_card, fg_color="transparent")
        act_row.pack(fill="x", padx=16, pady=(12, 8))

        self.convert_btn = ctk.CTkButton(
            act_row, text="🚀 Convert",
            font=ctk.CTkFont(size=14, weight="bold"),
            fg_color=ACCENT_RED, hover_color="#c8344d",
            text_color=TEXT_WHITE, height=42,
            command=self._start_conversion
        )
        self.convert_btn.pack(side="left", fill="x", expand=True, padx=(0, 8))

        self.cancel_btn = ctk.CTkButton(
            act_row, text="✕ Cancel",
            font=ctk.CTkFont(size=14, weight="bold"),
            fg_color=BORDER_DARK, hover_color="#444444",
            text_color=TEXT_WHITE, width=110, height=42,
            state="disabled", command=self._stop_conversion
        )
        self.cancel_btn.pack(side="right")

        # Progress bar
        self.progress_bar = ctk.CTkProgressBar(
            self.settings_card, fg_color=BG_DARK, progress_color=ACCENT_RED, height=10
        )
        self.progress_bar.pack(fill="x", padx=16, pady=(8, 16))
        self.progress_bar.set(0)

    # ── Queue & Selection Logic ───────────────────────────────────────────────

    def _browse_output_dir(self):
        folder = filedialog.askdirectory()
        if folder:
            self.output_dir.set(folder)

    def _on_output_dir_changed(self, *args):
        val = self.output_dir.get().strip()
        self.config["output_dir"] = val
        save_config(self.config)
        with self._jobs_lock:
            for job in self.jobs:
                job.output_dir = val if val else os.path.dirname(job.filepath)

    def _add_files(self, paths: list):
        added_any = False
        custom_out = self.output_dir.get().strip()
        with self._jobs_lock:
            existing = {j.filepath for j in self.jobs}
            for p in paths:
                ext = f".{get_extension(p)}"
                if ext not in SUPPORTED_INPUT or p in existing:
                    continue
                info = detect_file(p)
                valid = info.get("valid_targets", [])
                if not valid:
                    log(f"[SKIP] {os.path.basename(p)} — no valid conversion targets")
                    continue

                default_fmt = valid[0]
                job = ConversionJob(
                    filepath=p,
                    output_dir=custom_out if custom_out else os.path.dirname(p),
                    target_format=default_fmt,
                    compression=self.compression.get(),
                    verify=self.verify_after.get()
                )
                self.jobs.append(job)
                existing.add(p)
                added_any = True

        if added_any:
            if self.selected_job_index is None:
                self.selected_job_index = len(self.jobs) - 1
            self._refresh_queue_ui()
            self._refresh_selected_info()

    def _add_folder(self, folder: str):
        files = detect_folder(folder)
        paths = [f["filepath"] for f in files]
        self._add_files(paths)

    def _clear_all(self):
        if self._converting:
            return
        with self._jobs_lock:
            self.jobs.clear()
            self.selected_job_index = None
        self._refresh_queue_ui()
        self._refresh_selected_info()

    def _remove_job(self, index: int):
        if self._converting:
            return
        with self._jobs_lock:
            if 0 <= index < len(self.jobs):
                self.jobs.pop(index)
                if not self.jobs:
                    self.selected_job_index = None
                elif self.selected_job_index is not None:
                    if self.selected_job_index >= len(self.jobs):
                        self.selected_job_index = len(self.jobs) - 1
        self._refresh_queue_ui()
        self._refresh_selected_info()

    def _select_job(self, index: int):
        self.selected_job_index = index
        self._refresh_queue_ui()
        self._refresh_selected_info()

    def _refresh_queue_ui(self):
        # Clear current rows
        for child in self.queue_list.winfo_children():
            child.destroy()

        with self._jobs_lock:
            total = len(self.jobs)
            self.queue_label.configure(text=f"📋 Queue ({total})")

            for i, job in enumerate(self.jobs):
                is_selected = (i == self.selected_job_index)
                bg_col = "#202e52" if is_selected else BG_DARK
                border_col = ACCENT_RED if is_selected else BORDER_DARK

                item_frame = ctk.CTkFrame(
                    self.queue_list,
                    fg_color=bg_col,
                    border_color=border_col,
                    border_width=1,
                    corner_radius=8,
                    height=44
                )
                item_frame.pack(fill="x", pady=3)
                item_frame.pack_propagate(False)

                info = detect_file(job.filepath)
                fmt = info.get("format", "ISO")
                badge_bg = info.get("badge_color", ACCENT_RED)

                # Icon
                icon = "📀" if fmt == "ISO" else "💿" if fmt in ("BIN", "CUE") else "📦"
                ctk.CTkLabel(
                    item_frame, text=icon, font=ctk.CTkFont(size=14)
                ).pack(side="left", padx=(10, 4))

                # Name
                filename = os.path.basename(job.filepath)
                ctk.CTkLabel(
                    item_frame, text=filename,
                    font=ctk.CTkFont(size=12, weight="bold" if is_selected else "normal"),
                    text_color=TEXT_WHITE, anchor="w", width=180
                ).pack(side="left", padx=4)

                # Badge
                badge = ctk.CTkLabel(
                    item_frame, text=f" {fmt} ",
                    font=ctk.CTkFont(size=10, weight="bold"),
                    fg_color=badge_bg, text_color=TEXT_WHITE, corner_radius=4
                )
                badge.pack(side="right", padx=(4, 10))

                # Bind click selection
                for w in (item_frame, badge):
                    w.bind("<Button-1>", lambda e, idx=i: self._select_job(idx))
                    w.configure(cursor="hand2")

    def _refresh_selected_info(self):
        # Clear target output buttons
        for child in self.target_buttons_frame.winfo_children():
            child.destroy()

        if self.selected_job_index is None or self.selected_job_index >= len(self.jobs):
            self.info_icon_title.configure(text="📀 No File Selected")
            self.info_meta.configure(text="Select or drop a file to configure conversion")
            self.cmd_selected_lbl.configure(text="➜ Select target output format")
            self.cmd_str_lbl.configure(text="Command will appear here...")
            return

        job = self.jobs[self.selected_job_index]
        info = detect_file(job.filepath)

        filename = os.path.basename(job.filepath)
        fmt      = info.get("format", "ISO")
        size_str = info.get("size_str", "Unknown size")
        platform = info.get("platform", "ROM")

        icon = "📀" if fmt == "ISO" else "💿" if fmt in ("BIN", "CUE") else "📦"
        self.info_icon_title.configure(text=f"{icon} {filename}")
        self.info_meta.configure(text=f"{size_str} • {fmt} • {platform}")

        valid_targets = info.get("valid_targets", [])
        if not valid_targets:
            valid_targets = ["CHD"]

        if job.target_format not in valid_targets:
            job.target_format = valid_targets[0]

        self.selected_target.set(job.target_format)

        # Build output format buttons (clickable buttons with active border matching accent)
        for target in valid_targets:
            is_active = (target == job.target_format)
            btn = ctk.CTkButton(
                self.target_buttons_frame,
                text=target,
                width=72, height=36,
                fg_color=CARD_BG,
                hover_color="#202e52",
                border_color=ACCENT_RED if is_active else BORDER_DARK,
                border_width=2 if is_active else 1,
                text_color=TEXT_WHITE,
                font=ctk.CTkFont(size=12, weight="bold"),
                command=lambda t=target: self._set_target_format(t)
            )
            btn.pack(side="left", padx=4, pady=4)

        self._update_command_preview(fmt, job.target_format, filename)

    def _set_target_format(self, target: str):
        if self.selected_job_index is not None and self.selected_job_index < len(self.jobs):
            self.jobs[self.selected_job_index].target_format = target
            self.selected_target.set(target)
            self._refresh_selected_info()

    def _on_compression_changed(self, val):
        if self.selected_job_index is not None and self.selected_job_index < len(self.jobs):
            self.jobs[self.selected_job_index].compression = val
            self._refresh_selected_info()

    def _update_command_preview(self, fmt: str, target: str, filename: str):
        self.cmd_selected_lbl.configure(text=f"➜ {target} selected")
        cmd_str = get_command_preview(fmt, target, filename)
        self.cmd_str_lbl.configure(text=cmd_str)

    # ── Conversion Execution ─────────────────────────────────────────────────

    def _start_conversion(self):
        if not self.jobs or self._converting:
            return

        self._converting = True
        self.convert_btn.configure(state="disabled")
        self.cancel_btn.configure(state="normal")
        self.progress_bar.set(0)

        def run():
            with self._jobs_lock:
                jobs_to_run = list(self.jobs)

            for i, job in enumerate(jobs_to_run):
                if self.converter._stop_flag:
                    break

                job.verify = self.verify_after.get()
                log(f"[BATCH] Starting conversion {i+1}/{len(jobs_to_run)}: {os.path.basename(job.filepath)}")

                ok = self.converter.convert(job)

                if ok:
                    log(f"[BATCH] Completed: {os.path.basename(job.filepath)}")
                else:
                    log(f"[BATCH] Failed: {os.path.basename(job.filepath)}")

            self._converting = False
            self.after(0, self._conversion_finished)

        threading.Thread(target=run, daemon=True).start()

    def _stop_conversion(self):
        self.converter.stop()
        self._converting = False
        self._conversion_finished()

    def _conversion_finished(self):
        self.convert_btn.configure(state="normal")
        self.cancel_btn.configure(state="disabled")
        self.progress_bar.set(1.0)
        self._refresh_queue_ui()
        self._refresh_selected_info()

    def _on_log_msg(self, msg: str):
        # Callback for log updates
        pass

    def _on_progress(self, job: ConversionJob, pct: float):
        def _do():
            self.progress_bar.set(pct / 100.0)
        self.after(0, _do)

    # ── Dialogs ───────────────────────────────────────────────────────────────

    def _open_settings(self):
        SettingsWindow(self)

    def _open_about(self):
        AboutWindow(self)
