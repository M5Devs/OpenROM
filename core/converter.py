import os
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
    "Normal": "none",
    "High":   "cdlz",
    "Max":    "cdlz,zlib,flac",
}


class ConversionJob:
    def __init__(self, filepath: str, output_dir: str,
                 target_format: str, compression: str = "Normal", verify: bool = False):
        self.filepath      = filepath
        self.output_dir    = output_dir
        self.target_format = target_format   # "CHD","CSO","XISO","ECM","ISO","BIN","BIN/CUE"
        self.compression   = compression     # "Normal","High","Max"
        self.verify        = verify
        self.status        = "Queued"        # Queued|Converting|Done|Failed
        self.progress      = 0.0
        self.log_lines     = []
        self.error         = None
        self._temp_files   = []


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
        info = detect_file(job.filepath)
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
        if tgt not in valid and tgt != "BIN/CUE":
            self._log(
                f"[ERROR] Cannot convert {fmt} → {tgt}. "
                f"Supported targets for {fmt}: {', '.join(valid) if valid else 'none'}"
            )
            return False

        # Route conversion matrix
        if tgt == "CHD":
            return self._to_chd(job, src, fmt, info)

        if fmt == "CHD" and tgt in ("ISO", "BIN", "BIN/CUE"):
            return self._from_chd(job, src, tgt, info)

        if tgt == "CSO":
            return self._to_cso(job, src)

        if fmt in ("CSO", "ZSO") and tgt == "ISO":
            return self._cso_to_iso(job, src)

        if tgt == "ECM":
            return self._to_ecm(job, src)

        if fmt == "XISO" and tgt == "ISO":
            return self._xiso_to_iso(job, src)

        if tgt == "XISO":
            return self._to_xiso(job, src)

        if fmt == "BIN" and tgt == "ISO":
            return self._bin_to_iso(job, src, info)

        if fmt == "ISO" and tgt == "BIN":
            return self._iso_to_bin(job, src)

        self._log(f"[ERROR] Unhandled conversion route: {fmt} → {tgt}")
        return False

    # ── CHD conversion ────────────────────────────────────────────────────────

    def _to_chd(self, job: ConversionJob, src: str, fmt: str, info: dict) -> bool:
        chdman = get_chdman_path()
        out    = self._out_path(job, src, ".chd")

        if fmt in ("GDI", "CUE", "BIN", "CDI"):
            sub_cmd = "createcd"
        elif fmt in ("ISO", "IMG"):
            sub_cmd = "createdvd"
        else:
            sub_cmd = "createcd"

        cmd = [chdman, sub_cmd, "-i", src, "-o", out,
               "--compression", CHD_COMPRESSION.get(job.compression, "cdlz")]

        # BIN without CUE → auto-generate CUE file if missing before running chdman
        if fmt == "BIN":
            cue_input = info.get("paired_cue")
            if not cue_input:
                cue_input = self._auto_cue(src, job.output_dir)
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
        out = self._out_path(job, src, tgt)
        cmd = [unecm, src, out]
        self._log(f"[UNECM] {os.path.basename(src)} → {os.path.basename(out)}")

        ok = self._run(cmd, job)
        if ok and os.path.isfile(out):
            # Auto-detect format of extracted file and rename if requested format differs
            ext_found = get_extension(out)
            target_ext = tgt.lower()
            if target_ext in ("iso", "bin") and ext_found != target_ext:
                new_out = os.path.join(job.output_dir, get_output_name(os.path.basename(out), target_ext))
                try:
                    shutil.move(out, new_out)
                    self._log(f"[UNECM AUTO-DETECT] Renamed output to: {os.path.basename(new_out)}")
                except Exception as e:
                    self._log(f"[WARN] Failed to rename {out} to {new_out}: {e}")
        return ok

    # ── XISO conversion ───────────────────────────────────────────────────────

    def _to_xiso(self, job: ConversionJob, src: str) -> bool:
        """ISO → XISO via extract-xiso -r"""
        xiso = get_tool_path("xiso")
        cmd  = [xiso, "-r", src]
        self._log(f"[XISO] {os.path.basename(src)} — generating XISO...")
        return self._run(cmd, job)

    def _xiso_to_iso(self, job: ConversionJob, src: str) -> bool:
        """XISO → ISO via extract-xiso -x"""
        xiso = get_tool_path("xiso")
        base = os.path.basename(src).rsplit('.', 1)[0]
        out_dir = os.path.join(job.output_dir, base)
        cmd  = [xiso, "-x", src, "-d", out_dir]
        self._log(f"[XISO→ISO] Extracting XISO {os.path.basename(src)} to {out_dir}...")
        return self._run(cmd, job)

    # ── BCHUNK conversion (BIN ↔ ISO) ─────────────────────────────────────────

    def _bin_to_iso(self, job: ConversionJob, src: str, info: dict) -> bool:
        bchunk = get_tool_path("bchunk")
        cue_input = info.get("paired_cue")
        if not cue_input:
            cue_input = self._auto_cue(src, job.output_dir)
            if cue_input:
                job._temp_files.append(cue_input)

        if not cue_input:
            self._log(f"[ERROR] Could not find or generate CUE file for {src}")
            return False

        base = os.path.basename(src).rsplit('.', 1)[0]
        out_prefix = os.path.join(job.output_dir, base)
        cmd = [bchunk, "-v", src, cue_input, out_prefix]
        self._log(f"[BCHUNK] {os.path.basename(src)} → ISO ({out_prefix}*.iso)")

        ok = self._run(cmd, job)
        if ok:
            expected_iso = f"{out_prefix}01.iso"
            target_iso = os.path.join(job.output_dir, f"{base}.iso")
            if os.path.isfile(expected_iso) and expected_iso != target_iso:
                try:
                    if os.path.isfile(target_iso):
                        os.remove(target_iso)
                    shutil.move(expected_iso, target_iso)
                    self._log(f"[BCHUNK] Renamed output to: {os.path.basename(target_iso)}")
                except Exception as e:
                    self._log(f"[WARN] Failed to rename {expected_iso} to {target_iso}: {e}")
        return ok

    def _iso_to_bin(self, job: ConversionJob, src: str) -> bool:
        bchunk = get_tool_path("bchunk")
        base = os.path.basename(src).rsplit('.', 1)[0]
        cue_input = os.path.join(job.output_dir, f"{base}_temp.cue")
        try:
            with open(cue_input, "w", encoding="utf-8") as f:
                f.write(f'FILE "{os.path.basename(src)}" BINARY\n')
                f.write("  TRACK 01 MODE1/2048\n")
                f.write("    INDEX 01 00:00:00\n")
            job._temp_files.append(cue_input)
        except Exception as e:
            self._log(f"[ERROR] Could not write temporary CUE file: {e}")
            return False

        out_prefix = os.path.join(job.output_dir, base)
        cmd = [bchunk, "-v", src, cue_input, out_prefix]
        self._log(f"[BCHUNK] {os.path.basename(src)} → BIN ({out_prefix}*.bin)")

        ok = self._run(cmd, job)
        if ok:
            target_bin = os.path.join(job.output_dir, f"{base}.bin")
            # Find produced track file (e.g. out_prefix01.iso, out_prefix01.ugh, etc.)
            for fname in os.listdir(job.output_dir):
                if fname.startswith(os.path.basename(out_prefix)) and fname != os.path.basename(src) and not fname.endswith(".cue"):
                    created_file = os.path.join(job.output_dir, fname)
                    if created_file != target_bin and os.path.isfile(created_file):
                        try:
                            if os.path.isfile(target_bin):
                                os.remove(target_bin)
                            shutil.move(created_file, target_bin)
                            self._log(f"[BCHUNK] Renamed output {fname} to: {os.path.basename(target_bin)}")
                            break
                        except Exception as e:
                            self._log(f"[WARN] Failed to rename {created_file} to {target_bin}: {e}")
        return ok

    # ── helpers ───────────────────────────────────────────────────────────────

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
            except Exception:
                pass

    def _auto_cue(self, bin_path: str, output_dir: str) -> str | None:
        base = os.path.basename(bin_path).rsplit('.', 1)[0]
        cue_path = os.path.join(output_dir, base + "_auto.cue")
        bin_name = os.path.basename(bin_path)
        try:
            with open(cue_path, "w", encoding="utf-8") as f:
                f.write(f'FILE "{bin_name}" BINARY\n')
                f.write("  TRACK 01 MODE2/2352\n")
                f.write("    INDEX 01 00:00:00\n")
            self._log(f"[AUTO-CUE] Generated missing CUE file: {os.path.basename(cue_path)}")
            return cue_path
        except Exception as e:
            self._log(f"[WARN] Could not write auto CUE: {e}")
            return None


def _parse_progress(line: str) -> float | None:
    import re
    m = re.search(r"(\d+(?:\.\d+)?)\s*%", line)
    if m:
        return float(m.group(1))
    return None
