import os
import re
import shutil
import subprocess
import threading
from collections.abc import Callable

from core.cue_generator import detect_bin_mode as _detect_bin_mode
from core.detector import (
    get_chdman_path,
    get_extension,
    get_output_name,
    get_tool_path,
    get_valid_targets,
)
from core.logger import log as global_log
from core.validator import verify_chd

# CD-based platforms that require chdman createcd (not createdvd)
_CD_PLATFORM_KEYWORDS = (
    "PS1", "Dreamcast", "Saturn", "Sega CD", "PC-Engine CD", "Neo Geo CD"
)

# CD-based platforms: PS1, Dreamcast, Saturn, Sega CD, PC-Engine CD, Neo Geo CD
CHD_CD_COMPRESSION = {
    "Normal": "cdlz",
    "High":   "cdzs,cdlz",
    "Max":    "cdlz,cdzs,flac",
}

# DVD-based platforms: PS2, GameCube, Wii, Xbox, and Unknown
CHD_DVD_COMPRESSION = {
    "Normal": "zlib",
    "High":   "zstd,zlib,huff",
    "Max":    "zstd,zlib,huff,flac",
}


class ConversionJob:
    def __init__(self, filepath: str, output_dir: str,
                 target_format: str, compression: str = "Normal", verify: bool = False,
                 force_platform: str = None):
        self.filepath      = filepath
        self.output_dir    = output_dir
        self.target_format = target_format   # "CHD","CSO","XISO","ECM","ISO","BIN","BIN/CUE","Files"
        self.compression   = compression     # "Normal","High","Max"
        self.verify        = verify
        self.force_platform = force_platform
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
            # Override platform if user forced it
            if self.force_platform:
                self._file_info["platform"] = self.force_platform.strip()
        return self._file_info


class Converter:
    def __init__(self, on_log: Callable = None, on_progress: Callable = None):
        self.on_log_cb   = on_log
        self.on_progress = on_progress or (lambda job, pct: None)
        self._stop_event = threading.Event()
        self._lock       = threading.Lock()

    def stop(self):
        self._stop_event.set()

    def convert(self, job: ConversionJob) -> bool:
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
        self._stop_event.clear()
        with self._lock:
            jobs_copy = list(jobs)
        for job in jobs_copy:
            if self._stop_event.is_set():
                break
            ok = self.convert(job)
            if on_job_done:
                on_job_done(job, ok)

    # ── dispatch ──────────────────────────────────────────────────────────────

    def _dispatch(self, job: ConversionJob) -> bool:
        info = job.get_file_info()
        src  = job.filepath

        if job.force_platform:
            self._log(
                f"[INFO] Platform override: using '{job.force_platform}' "
                f"(auto-detected: {info.get('platform', 'UNKNOWN')})"
            )

        if "error" in info:
            self._log(f"[ERROR] {info['error']}")
            job.error = info['error']
            return False

        fmt = info.get("format", "UNKNOWN")
        tgt = job.target_format.upper()

        # Handle ECM input directly
        if fmt == "ECM":
            return self._from_ecm(job, src, tgt)

        valid = get_valid_targets(fmt)
        if tgt not in valid and tgt not in ("BIN/CUE", "FILES"):
            err_msg = (
                f"Cannot convert {fmt} → {tgt}. "
                f"Supported targets for {fmt}: {', '.join(valid) if valid else 'none'}"
            )
            self._log(f"[ERROR] {err_msg}")
            job.error = err_msg
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

        if fmt == "XISO" and tgt in ("ISO", "FILES"):
            return self._xiso_to_files(job, src)

        if tgt == "XISO":
            return self._to_xiso(job, src)

        if (fmt in ("WUD", "WUX", "NKIT") and tgt == "ISO") or (fmt == "ISO" and tgt == "NKIT"):
            return self._nkit_convert(job, src, tgt)

        err_msg = f"Unhandled conversion route: {fmt} → {tgt}"
        self._log(f"[ERROR] {err_msg}")
        job.error = err_msg
        return False

    # ── CHD conversion ────────────────────────────────────────────────────────

    def _to_chd(self, job: ConversionJob, src: str, fmt: str, info: dict) -> bool:
        chdman = get_chdman_path()
        out    = self._out_path(job, src, ".chd")

        if fmt in ("GDI", "CUE", "BIN", "CDI"):
            sub_cmd = "createcd"
        elif fmt in ("ISO", "IMG"):
            platform = info.get("platform", "")
            sub_cmd = "createcd" if any(kw in platform for kw in _CD_PLATFORM_KEYWORDS) else "createdvd"
        else:
            sub_cmd = "createcd"

        compression_map = CHD_CD_COMPRESSION if sub_cmd == "createcd" else CHD_DVD_COMPRESSION
        default_codec = "cdlz" if sub_cmd == "createcd" else "zlib"
        cmd = [chdman, sub_cmd, "-i", src, "-o", out,
               "--compression", compression_map.get(job.compression, default_codec)]

        if fmt == "BIN":
            cue_input = info.get("paired_cue")
            if not cue_input:
                cue_input = self._auto_cue(src)
                if cue_input:
                    job._temp_files.append(cue_input)
            if cue_input:
                idx = cmd.index(src)
                cmd[idx] = cue_input

        self._log(f"[CHD] {os.path.basename(src)} → {os.path.basename(out)}")
        return self._run(cmd, job)

    def _from_chd(self, job: ConversionJob, src: str, tgt: str, info: dict) -> bool:
        chdman   = get_chdman_path()
        chd_type = info.get("chd_type", "cd")

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
        XISO → extracted files.
        extract-xiso cannot produce a single ISO output; it always extracts to a folder.
        The target label is now honestly "Files" instead of "ISO" to avoid user confusion.
        """
        xiso    = get_tool_path("extract-xiso")
        base    = os.path.basename(src).rsplit('.', 1)[0]
        out_dir = os.path.join(job.output_dir, base + "_extracted")
        os.makedirs(out_dir, exist_ok=True)
        cmd = [xiso, "-x", src, "-d", out_dir]
        self._log(f"[XISO→FILES] Extracting {os.path.basename(src)} → {out_dir}/")
        self._log("[XISO→FILES] Output is a folder of extracted files, not a single ISO.")
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

    # ── NKit conversion ───────────────────────────────────────────

    def _nkit_convert(self, job: ConversionJob, src: str, tgt: str) -> bool:
        """WUD / WUX / NKIT -> ISO or ISO -> NKIT via nkit convert"""
        nkit = get_tool_path("nkit")
        ext  = "nkit.iso" if tgt == "NKIT" else tgt.lower()
        out  = self._out_path(job, src, ext)
        cmd  = [nkit, "convert", "-i", src, "-o", out]
        self._log(f"[NKIT] {os.path.basename(src)} → {os.path.basename(out)}")
        return self._run(cmd, job)

    # ── Core runner ───────────────────────────────────────────────────────────

    def _run(self, cmd: list, job: ConversionJob) -> bool:
        self._log(f"  cmd: {' '.join(os.path.basename(c) if i == 0 else c for i, c in enumerate(cmd))}")
        last_line = ""
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
                    last_line = line
                    self._log(f"  {line}")
                    pct = _parse_progress(line)
                    if pct is not None:
                        job.progress = pct
                        self.on_progress(job, pct)
                if self._stop_event.is_set():
                    proc.terminate()
                    job.error = "Process terminated by user"
                    return False
            proc.wait()
            if proc.returncode == 0:
                self._log("  ✅ Command executed successfully")
                job.progress = 100.0
                self.on_progress(job, 100.0)
                return True
            else:
                err_msg = f"Process failed (code {proc.returncode}): {last_line}" if last_line else f"Process failed with exit code {proc.returncode}"
                job.error = err_msg
                self._log(f"  ❌ {err_msg}")
                return False
        except FileNotFoundError:
            err_msg = f"Tool not found: {cmd[0]}"
            job.error = err_msg
            self._log(f"  ❌ {err_msg}")
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
        for f in job._temp_files:
            try:
                if os.path.isfile(f):
                    os.remove(f)
                    global_log(f"[CLEANUP] Removed temp file: {os.path.basename(f)}")
            except Exception as e:
                global_log(f"[CLEANUP WARN] Could not remove {f}: {e}")

    def _auto_cue(self, bin_path: str) -> str | None:
        base      = os.path.basename(bin_path).rsplit('.', 1)[0]
        bin_dir   = os.path.dirname(os.path.abspath(bin_path))
        cue_path  = os.path.join(bin_dir, base + "_auto.cue")
        bin_name  = os.path.basename(bin_path)
        track_mode = _detect_bin_mode(bin_path)
        self._log(f"[AUTO-CUE] Detected BIN mode: {track_mode}")
        try:
            with open(cue_path, "w", encoding="utf-8") as f:
                f.write(f'FILE "{bin_name}" BINARY\n')
                f.write(f"  TRACK 01 {track_mode}\n")
                f.write("    INDEX 01 00:00:00\n")
            self._log(f"[AUTO-CUE] Generated CUE file: {os.path.basename(cue_path)}")
            return cue_path
        except Exception as e:
            self._log(f"[WARN] Could not write auto CUE: {e}")
            return None


# ── Progress line parser ──────────────────────────────────────────────────────

def _parse_progress(line: str) -> float | None:
    """
    Parse progress percentage from conversion tool outputs while ignoring system performance warnings/stats.

    chdman  : "Compressing, 42.3% complete..." or "42.3%"
    maxcso  : "Wrote 1234567 of 9876543 bytes"
    nodtool : "Progress: 42%" or "42%"
    """
    # Ignore CPU / RAM / System statistics lines
    if re.search(r"\b(?:cpu|memory|ram|disk|swap|usage|load)\b", line, re.IGNORECASE):
        return None

    # Match conversion/progress/complete percentage patterns
    m = re.search(r"(?:progress|complete|done)?\s*(\d+(?:\.\d+)?)\s*%", line, re.IGNORECASE)
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
