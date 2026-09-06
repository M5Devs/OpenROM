import os
import re
import subprocess
import threading
import shutil
from typing import Callable
from core.detector import (
    get_chdman_path, get_tool_path, detect_file, get_valid_targets,
    get_extension, get_output_name
)
from core.logger import log as global_log
from core.validator import verify_chd

CHD_COMPRESSION = {
    "Normal": "cdlz",               # max compatibility (AetherSX2/NetherSX2 friendly)
    "High":   "zstd,zlib,huff",     # slower, better ratio
    "Max":    "zstd,zlib,huff,flac", # best ratio
}


class ConversionJob:
    def __init__(self, filepath: str, output_dir: str,
                 target_format: str, compression: str = "Normal", verify: bool = False):
        self.filepath      = filepath
        self.output_dir    = output_dir
        self.target_format = target_format   # "CHD","CSO","XISO","ECM","ISO","BIN","BIN/CUE","Files"
        self.compression   = compression     # "Normal","High","Max"
        self.verify        = verify
        self.status        = "Queued"        # Queued|Converting|Done|Failed
        self.progress      = 0.0
        self.log_lines     = []
        self.error         = None
        self._temp_files   = []
        self._file_info    = None            # Cached detect_file() result

    def get_file_info(self):
        """Return cached file info, detecting only once."""
        if self._file_info is None:
            from core.detector import detect_file
            self._file_info = detect_file(self.filepath)
        return self._file_info


class Converter:
    def __init__(self, on_log: Callable = None, on_progress: Callable = None):
        self.on_log_cb   = on_log
        self.on_progress = on_progress or (lambda job, pct: None)
        self._stop_flag  = False
        self._lock       = threading.Lock()

    def stop(self):
        self._stop_flag = True

    def convert(self, job: ConversionJob) -> bool:
        self._stop_flag = False
        job.status = "Converting"
        try:
            ok = self._dispatch(job)
            if ok and job.verify and job.target_format.upper() == "CHD":
                chd_out = self._out_path(job, job.filepath, ".chd")
                if os.path.isfile(chd_out):
                    self._log(f"[VERIFY] Verifying CHD integrity: {os.path.basename(chd_out)}")
                    ver_ok = verify_chd(chd_out, on_log=self._log)
                    if not ver_ok:
                        ok = False

            job.status = "Done" if ok else "Failed"
            return ok
        except Exception as e:
            job.error  = str(e)
            job.status = "Failed"
            self._log(f"[ERROR] {e}")
            return False
        finally:
            self._cleanup(job)

    def convert_batch(self, jobs: list, on_job_done: Callable = None):
        with self._lock:
            jobs_copy = list(jobs)
        for job in jobs_copy:
            if self._stop_flag:
                break
            ok = self.convert(job)
            if on_job_done:
                on_job_done(job, ok)

    # ── dispatch ──────────────────────────────────────────────────────────────

    def _dispatch(self, job: ConversionJob) -> bool:
        info = job.get_file_info()
        src  = job.filepath

        if "error" in info:
            self._log(f"[ERROR] {info['error']}")
            return False

        fmt = info.get("format", "UNKNOWN")
        tgt = job.target_format.upper()

        # Handle ECM input directly
        if fmt == "ECM":
            return self._from_ecm(job, src, tgt)

        valid = get_valid_targets(fmt)
        if tgt not in valid and tgt not in ("BIN/CUE", "FILES"):
            self._log(
                f"[ERROR] Cannot convert {fmt} → {tgt}. "
                f"Supported targets for {fmt}: {', '.join(valid) if valid else 'none'}"
            )
            return False

        if tgt == "CHD":
            return self._to_chd(job, src, fmt, info)

        if fmt == "CHD" and tgt in ("ISO", "BIN", "BIN/CUE"):
            return self._from_chd(job, src, tgt, info)

        if tgt == "CSO":
            return self._to_cso(job, src)

        if tgt == "RVZ":
            return self._to_rvz(job, src)

        if fmt in ("RVZ", "WIA", "WBFS", "GCZ") and tgt == "ISO":
            return self._from_nodtool(job, src, tgt)

        if fmt in ("CSO", "ZSO") and tgt == "ISO":
            return self._cso_to_iso(job, src)

        if tgt == "ECM":
            return self._to_ecm(job, src)

        # FIX #5 — XISO target is now "Files" (honest label), not "ISO"
        if fmt == "XISO" and tgt in ("ISO", "FILES"):
            return self._xiso_to_files(job, src)

        if tgt == "XISO":
            return self._to_xiso(job, src)

        self._log(f"[ERROR] Unhandled conversion route: {fmt} → {tgt}")
        return False

    # ── CHD conversion ────────────────────────────────────────────────────────

    def _to_chd(self, job: ConversionJob, src: str, fmt: str, info: dict) -> bool:
        chdman = get_chdman_path()
        out    = self._out_path(job, src, ".chd")

        if fmt in ("GDI", "CUE", "BIN", "CDI"):
            sub_cmd = "createcd"
        elif fmt in ("ISO", "IMG"):
            platform = info.get("platform", "")
            sub_cmd = "createcd" if "PS1" in platform else "createdvd"
        else:
            sub_cmd = "createcd"

        cmd = [chdman, sub_cmd, "-i", src, "-o", out,
               "--compression", CHD_COMPRESSION.get(job.compression, "cdlz")]

        # BIN without CUE → auto-generate CUE then register for cleanup
        if fmt == "BIN":
            cue_input = info.get("paired_cue")
            if not cue_input:
                cue_input = self._auto_cue(src, job.output_dir)
                if cue_input:
                    # FIX #4 — always register the generated CUE for cleanup
                    job._temp_files.append(cue_input)
            if cue_input:
                idx = cmd.index(src)
                cmd[idx] = cue_input

        self._log(f"[CHD] {os.path.basename(src)} → {os.path.basename(out)}")
        return self._run(cmd, job)

    def _from_chd(self, job: ConversionJob, src: str, tgt: str, info: dict) -> bool:
        chdman   = get_chdman_path()
        chd_type = info.get("chd_type", "cd")  # now populated from actual CHD header (FIX #2)

        if tgt in ("BIN", "BIN/CUE"):
            cue_out = self._out_path(job, src, ".cue")
            bin_out = self._out_path(job, src, ".bin")
            if chd_type == "dvd":
                self._log("[WARN] DVD-type CHD extracted as ISO (BIN/CUE is for CD images)")
                out = self._out_path(job, src, ".iso")
                cmd = [chdman, "extractdvd", "-i", src, "-o", out]
            else:
                cmd = [chdman, "extractcd", "-i", src, "-o", cue_out, "--outputbin", bin_out]
        else:  # ISO
            out = self._out_path(job, src, ".iso")
            if chd_type == "dvd":
                cmd = [chdman, "extractdvd", "-i", src, "-o", out]
            else:
                cmd = [chdman, "extractcd", "-i", src, "-o", out]

        self._log(f"[CHD EXTRACT] {os.path.basename(src)} → {tgt}")
        return self._run(cmd, job)

    # ── CSO conversion ────────────────────────────────────────────────────────

    def _to_cso(self, job: ConversionJob, src: str) -> bool:
        maxcso  = get_tool_path("maxcso")
        out     = self._out_path(job, src, ".cso")
        threads = os.cpu_count() or 2
        cmd = [maxcso, f"--threads={threads}", src, "-o", out]
        if job.compression == "Max":
            cmd.insert(1, "--use-zopfli")
        elif job.compression == "High":
            cmd.insert(1, "--use-zlib")
        self._log(f"[CSO] {os.path.basename(src)} → {os.path.basename(out)}")
        return self._run(cmd, job)

    def _cso_to_iso(self, job: ConversionJob, src: str) -> bool:
        maxcso = get_tool_path("maxcso")
        out    = self._out_path(job, src, ".iso")
        cmd    = [maxcso, "--decompress", src, "-o", out]
        self._log(f"[CSO→ISO] {os.path.basename(src)} → {os.path.basename(out)}")
        return self._run(cmd, job)

    # ── ECM conversion ────────────────────────────────────────────────────────

    def _to_ecm(self, job: ConversionJob, src: str) -> bool:
        ecm = get_tool_path("ecm")
        out = self._out_path(job, src, "ecm")
        cmd = [ecm, src, out]
        self._log(f"[ECM] {os.path.basename(src)} → {os.path.basename(out)}")
        return self._run(cmd, job)

    def _from_ecm(self, job: ConversionJob, src: str, tgt: str) -> bool:
        unecm = get_tool_path("unecm")
        out   = self._out_path(job, src, tgt)
        cmd   = [unecm, src, out]
        self._log(f"[UNECM] {os.path.basename(src)} → {os.path.basename(out)}")

        ok = self._run(cmd, job)
        if ok and os.path.isfile(out):
            ext_found  = get_extension(out)
            target_ext = tgt.lower()
            if target_ext in ("iso", "bin") and ext_found != target_ext:
                new_out = os.path.join(
                    job.output_dir,
                    get_output_name(os.path.basename(out), target_ext)
                )
                try:
                    shutil.move(out, new_out)
                    self._log(f"[UNECM AUTO-DETECT] Renamed output to: {os.path.basename(new_out)}")
                except Exception as e:
                    self._log(f"[WARN] Failed to rename {out} to {new_out}: {e}")
        return ok

    # ── XISO conversion ───────────────────────────────────────────────────────

    def _to_xiso(self, job: ConversionJob, src: str) -> bool:
        """ISO → XISO via extract-xiso -r (repack in place)"""
        xiso = get_tool_path("extract-xiso")
        cmd  = [xiso, "-r", src]
        self._log(f"[XISO] {os.path.basename(src)} — repacking to XISO...")
        return self._run(cmd, job)

    def _xiso_to_files(self, job: ConversionJob, src: str) -> bool:
        """
        FIX #5 — XISO → extracted files.
        extract-xiso cannot produce a single ISO output; it always extracts to a folder.
        The target label is now honestly "Files" instead of "ISO" to avoid user confusion.
        """
        xiso    = get_tool_path("extract-xiso")
        base    = os.path.basename(src).rsplit('.', 1)[0]
        out_dir = os.path.join(job.output_dir, base + "_extracted")
        os.makedirs(out_dir, exist_ok=True)
        cmd = [xiso, "-x", src, "-d", out_dir]
        self._log(f"[XISO→FILES] Extracting {os.path.basename(src)} → {out_dir}/")
        self._log(f"[XISO→FILES] Output is a folder of extracted files, not a single ISO.")
        return self._run(cmd, job)

    # ── RVZ / Wii / GC conversions ────────────────────────────────────────────

    def _to_rvz(self, job: ConversionJob, src: str) -> bool:
        """ISO → RVZ via nodtool convert"""
        nodtool = get_tool_path("nodtool")
        out     = get_output_name(src, "rvz")
        out     = os.path.join(job.output_dir, os.path.basename(out))
        cmd     = [nodtool, "convert", src, out]
        self._log(f"[RVZ] {os.path.basename(src)} → {os.path.basename(out)}")
        return self._run(cmd, job)

    def _from_nodtool(self, job: ConversionJob, src: str, tgt: str) -> bool:
        """RVZ / WIA / WBFS / GCZ → ISO via nodtool convert"""
        nodtool = get_tool_path("nodtool")
        out     = get_output_name(src, "iso")
        out     = os.path.join(job.output_dir, os.path.basename(out))
        fmt     = os.path.splitext(src)[1].upper().lstrip(".")
        cmd     = [nodtool, "convert", src, out]
        self._log(f"[{fmt}→ISO] {os.path.basename(src)} → {os.path.basename(out)}")
        return self._run(cmd, job)

    # ── Core runner ───────────────────────────────────────────────────────────

    def _run(self, cmd: list, job: ConversionJob) -> bool:
        self._log(f"  cmd: {' '.join(os.path.basename(c) if i == 0 else c for i, c in enumerate(cmd))}")
        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            for line in proc.stdout:
                line = line.rstrip()
                if line:
                    self._log(f"  {line}")
                    pct = _parse_progress(line)
                    if pct is not None:
                        job.progress = pct
                        self.on_progress(job, pct)
                if self._stop_flag:
                    proc.terminate()
                    return False
            proc.wait()
            if proc.returncode == 0:
                self._log("  ✅ Command executed successfully")
                job.progress = 100.0
                self.on_progress(job, 100.0)
                return True
            else:
                self._log(f"  ❌ Process returned exit code {proc.returncode}")
                return False
        except FileNotFoundError:
            self._log(f"  ❌ Tool not found: {cmd[0]}")
            return False

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _out_path(self, job: ConversionJob, src: str, ext: str) -> str:
        out_name = get_output_name(os.path.basename(src), ext)
        return os.path.join(job.output_dir, out_name)

    def _log(self, msg: str):
        global_log(msg)
        if self.on_log_cb:
            try:
                self.on_log_cb(msg)
            except Exception:
                pass

    def _cleanup(self, job: ConversionJob):
        """FIX #4 — clean up ALL temp files registered in job._temp_files (incl. auto-CUE)."""
        for f in job._temp_files:
            try:
                if os.path.isfile(f):
                    os.remove(f)
                    global_log(f"[CLEANUP] Removed temp file: {os.path.basename(f)}")
            except Exception as e:
                global_log(f"[CLEANUP WARN] Could not remove {f}: {e}")

    def _auto_cue(self, bin_path: str, output_dir: str) -> str | None:
        base      = os.path.basename(bin_path).rsplit('.', 1)[0]
        cue_path  = os.path.join(output_dir, base + "_auto.cue")
        bin_name  = os.path.basename(bin_path)
        track_mode = self._detect_bin_mode(bin_path)
        self._log(f"[AUTO-CUE] Detected BIN mode: {track_mode}")
        try:
            with open(cue_path, "w", encoding="utf-8") as f:
                f.write(f'FILE "{bin_name}" BINARY\n')
                f.write(f"  TRACK 01 {track_mode}\n")
                f.write("    INDEX 01 00:00:00\n")
            self._log(f"[AUTO-CUE] Generated CUE file: {os.path.basename(cue_path)}")
            # NOTE: caller is responsible for appending cue_path to job._temp_files
            return cue_path
        except Exception as e:
            self._log(f"[WARN] Could not write auto CUE: {e}")
            return None

    def _detect_bin_mode(self, bin_path: str) -> str:
        """
        Sniff the first sector of a BIN file to determine its track mode.
          MODE1/2048 : 2048-byte sectors (data only, no sync header)
          MODE1/2352 : 2352-byte sectors with sync header + mode byte 01
          MODE2/2352 : 2352-byte sectors with sync header + mode byte 02
          AUDIO      : 2352-byte sectors, no recognisable sync header
        Falls back to MODE2/2352 when the file is too small or unreadable.
        """
        SYNC = b'\x00' + b'\xff' * 10 + b'\x00'
        try:
            size = os.path.getsize(bin_path)
            with open(bin_path, "rb") as f:
                header = f.read(16)

            if len(header) < 16:
                return "MODE2/2352"

            if header[:12] == SYNC:
                mode_byte = header[15]
                if mode_byte == 0x01:
                    return "MODE1/2352"
                elif mode_byte == 0x02:
                    return "MODE2/2352"
                else:
                    return "AUDIO"

            if size % 2048 == 0:
                return "MODE1/2048"
            if size % 2352 == 0:
                return "AUDIO"

            return "MODE2/2352"
        except Exception:
            return "MODE2/2352"


# ── Progress line parser ──────────────────────────────────────────────────────

def _parse_progress(line: str) -> float | None:
    """
    FIX (IMPROVEMENT #1) — Parse progress from both chdman and maxcso output formats.

    chdman  : "Compressing, 42.3% complete..."  or  "42.3%"
    maxcso  : "Wrote 1234567 of 9876543 bytes"  (bytes-based → convert to %)
    nodtool : "Progress: 42%" or similar
    """
    # Generic percentage (chdman, nodtool)
    m = re.search(r"(\d+(?:\.\d+)?)\s*%", line)
    if m:
        return float(m.group(1))

    # maxcso: "Wrote X of Y bytes"
    m = re.search(r"Wrote\s+(\d+)\s+of\s+(\d+)\s+bytes", line, re.IGNORECASE)
    if m:
        written = int(m.group(1))
        total   = int(m.group(2))
        if total > 0:
            return round(written / total * 100, 1)

    return None
