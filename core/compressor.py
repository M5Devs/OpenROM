"""
OpenROM Compressor — ZIP/7Z Compression & Extraction Utility
M5 Dev | GPL v3 + Commons Clause
"""

import os
import shutil
import zipfile
from typing import Callable, Optional
import py7zr

EXCLUDED_EXTENSIONS = {".chd", ".cso", ".rvz", ".7z", ".zip", ".gz", ".zst", ".csz", ".zso"}


class CompressionJob:
    def __init__(
        self,
        filepath: str,
        output_dir: str,
        format: str = "zip",         # "zip" | "7z" | "extract"
        level: str = "normal",        # "fast" | "normal" | "ultra" (7z only)
        delete_source: bool = False,
        status: str = "Queued",       # Queued|Compressing|Extracting|Done|Failed
        progress: float = 0.0,
        error: Optional[str] = None,
    ):
        self.filepath = filepath
        self.output_dir = output_dir
        self.format = format.lower()
        self.level = level.lower()
        self.delete_source = delete_source
        self.status = status
        self.progress = progress
        self.error = error


class Compressor:
    def __init__(
        self,
        on_log: Optional[Callable[[str], None]] = None,
        on_progress: Optional[Callable[[CompressionJob, float], None]] = None,
    ):
        self.on_log = on_log
        self.on_progress = on_progress or (lambda job, pct: None)
        self._stop_flag = False

    def stop(self):
        self._stop_flag = True

    def _log(self, msg: str):
        if self.on_log:
            try:
                self.on_log(msg)
            except Exception:
                pass

    def _update_progress(self, job: CompressionJob, pct: float):
        job.progress = min(100.0, max(0.0, pct))
        try:
            self.on_progress(job, job.progress)
        except Exception:
            pass

    def is_already_compressed(self, filepath: str) -> bool:
        ext = os.path.splitext(filepath)[1].lower()
        return ext in EXCLUDED_EXTENSIONS

    def compress(self, job: CompressionJob) -> bool:
        self._stop_flag = False
        if job.format == "extract":
            return self.extract(job)

        if not os.path.exists(job.filepath):
            job.status = "Failed"
            job.error = f"File or directory not found: {job.filepath}"
            self._log(f"[ERROR] {job.error}")
            return False

        if self.is_already_compressed(job.filepath):
            job.status = "Done"
            job.progress = 100.0
            job.error = "Skipped (already compressed)"
            self._log(f"[SKIP] {os.path.basename(job.filepath)} is already compressed. Skipped.")
            self._update_progress(job, 100.0)
            return True

        job.status = "Compressing"
        self._update_progress(job, 0.0)
        os.makedirs(job.output_dir, exist_ok=True)

        try:
            if job.format == "7z":
                success = self._compress_7z(job)
            else:
                success = self._compress_zip(job)

            if success:
                job.status = "Done"
                job.progress = 100.0
                self._update_progress(job, 100.0)
                if job.delete_source:
                    self._delete_source_path(job.filepath)
                return True
            else:
                job.status = "Failed"
                return False
        except Exception as e:
            job.status = "Failed"
            job.error = str(e)
            self._log(f"[ERROR] Compression failed: {e}")
            return False

    def extract(self, job: CompressionJob) -> bool:
        self._stop_flag = False
        if not os.path.isfile(job.filepath):
            job.status = "Failed"
            job.error = f"Archive file not found: {job.filepath}"
            self._log(f"[ERROR] {job.error}")
            return False

        job.status = "Extracting"
        self._update_progress(job, 0.0)
        os.makedirs(job.output_dir, exist_ok=True)

        ext = os.path.splitext(job.filepath)[1].lower()
        try:
            if ext == ".7z" or py7zr.is_7zfile(job.filepath):
                success = self._extract_7z(job)
            elif ext == ".zip" or zipfile.is_zipfile(job.filepath):
                success = self._extract_zip(job)
            else:
                job.status = "Failed"
                job.error = f"Unsupported archive format: {ext}"
                self._log(f"[ERROR] {job.error}")
                return False

            if success:
                job.status = "Done"
                job.progress = 100.0
                self._update_progress(job, 100.0)
                if job.delete_source:
                    self._delete_source_path(job.filepath)
                return True
            else:
                job.status = "Failed"
                return False
        except Exception as e:
            job.status = "Failed"
            job.error = str(e)
            self._log(f"[ERROR] Extraction failed: {e}")
            return False

    def compress_batch(self, jobs: list[CompressionJob]) -> None:
        for job in jobs:
            if self._stop_flag:
                break
            if job.format == "extract":
                self.extract(job)
            else:
                self.compress(job)

    # ── Internal Compression Methods ──────────────────────────────────────────

    def _compress_zip(self, job: CompressionJob) -> bool:
        base_name = os.path.splitext(os.path.basename(job.filepath))[0]
        out_path = os.path.join(job.output_dir, f"{base_name}.zip")
        self._log(f"[ZIP] Compressing {os.path.basename(job.filepath)} → {os.path.basename(out_path)}")

        if os.path.isfile(job.filepath):
            file_size = os.path.getsize(job.filepath)
            written = 0
            chunk_size = 1024 * 1024  # 1MB
            with zipfile.ZipFile(out_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
                with open(job.filepath, "rb") as src_f, zf.open(os.path.basename(job.filepath), "w") as dest_f:
                    while True:
                        if self._stop_flag:
                            return False
                        chunk = src_f.read(chunk_size)
                        if not chunk:
                            break
                        dest_f.write(chunk)
                        written += len(chunk)
                        if file_size > 0:
                            pct = (written / file_size) * 100.0
                            self._update_progress(job, pct)
        elif os.path.isdir(job.filepath):
            all_files = []
            for root, _, files in os.walk(job.filepath):
                for f in files:
                    all_files.append(os.path.join(root, f))
            total_files = len(all_files) or 1
            with zipfile.ZipFile(out_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
                for idx, src_file in enumerate(all_files):
                    if self._stop_flag:
                        return False
                    rel_path = os.path.relpath(src_file, start=os.path.dirname(job.filepath))
                    zf.write(src_file, rel_path)
                    pct = ((idx + 1) / total_files) * 100.0
                    self._update_progress(job, pct)

        return True

    def _compress_7z(self, job: CompressionJob) -> bool:
        base_name = os.path.splitext(os.path.basename(job.filepath))[0]
        out_path = os.path.join(job.output_dir, f"{base_name}.7z")
        self._log(f"[7Z] Compressing ({job.level}) {os.path.basename(job.filepath)} → {os.path.basename(out_path)}")

        level_map = {
            "fast": 1,
            "normal": 5,
            "ultra": 9,
        }
        preset = level_map.get(job.level, 5)
        filters = [{"id": py7zr.FILTER_LZMA2, "preset": preset}]

        self._update_progress(job, 10.0)
        with py7zr.SevenZipFile(out_path, "w", filters=filters) as archive:
            if os.path.isfile(job.filepath):
                archive.write(job.filepath, os.path.basename(job.filepath))
            elif os.path.isdir(job.filepath):
                archive.writeall(job.filepath, os.path.basename(job.filepath))

        self._update_progress(job, 90.0)
        return True

    # ── Internal Extraction Methods ───────────────────────────────────────────

    def _extract_zip(self, job: CompressionJob) -> bool:
        self._log(f"[UNZIP] Extracting {os.path.basename(job.filepath)} → {job.output_dir}")
        with zipfile.ZipFile(job.filepath, "r") as zf:
            members = zf.infolist()
            total = len(members) or 1
            for idx, member in enumerate(members):
                if self._stop_flag:
                    return False
                zf.extract(member, path=job.output_dir)
                pct = ((idx + 1) / total) * 100.0
                self._update_progress(job, pct)
        return True

    def _extract_7z(self, job: CompressionJob) -> bool:
        self._log(f"[UN7Z] Extracting {os.path.basename(job.filepath)} → {job.output_dir}")
        self._update_progress(job, 20.0)
        with py7zr.SevenZipFile(job.filepath, "r") as archive:
            archive.extractall(path=job.output_dir)
        self._update_progress(job, 90.0)
        return True

    def _delete_source_path(self, filepath: str):
        try:
            if os.path.isfile(filepath):
                os.remove(filepath)
                self._log(f"[CLEANUP] Deleted source file: {filepath}")
            elif os.path.isdir(filepath):
                shutil.rmtree(filepath)
                self._log(f"[CLEANUP] Deleted source directory: {filepath}")
        except Exception as e:
            self._log(f"[WARN] Failed to delete source {filepath}: {e}")
