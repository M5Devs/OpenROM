"""
core/dcp_patcher.py — Dreamcast DCP patch applier
M5 Dev | GPL v3

DCP format (Universal Dreamcast Patcher compatible):
  A .dcp file is a ZIP archive containing:
    - Modified/new game files in their original disc filesystem path
    - xdelta/  (optional) — binary diff patches as <filename>.xdelta3
    - bootsector/IP.BIN  (optional) — replacement boot sector
"""

import os
import zipfile
import shutil
import subprocess
import tempfile
from typing import Callable

from core.config import get_tool_path
from core.logger import log as global_log


class DcpPatcher:
    def __init__(self, on_log: Callable = None, on_progress: Callable = None):
        self.on_log = on_log or global_log
        self.on_progress = on_progress or (lambda pct: None)

    def apply(
        self,
        dcp_path: str,
        disc_dir: str,       # directory containing extracted GDI/CUE files
        output_dir: str,
        ignore_checksum: bool = False,
    ) -> dict:
        """
        Apply a DCP patch to an extracted Dreamcast disc directory.

        Args:
            dcp_path:   Path to the .dcp patch file
            disc_dir:   Path to folder containing extracted disc files
                        (track03.bin and game filesystem files)
            output_dir: Where to write the patched disc files
            ignore_checksum: Skip xdelta source checksum verification

        Returns:
            dict with keys: success (bool), files_patched (int),
                            xdelta_applied (int), ipbin_replaced (bool),
                            error (str or None)
        """
        if not os.path.isfile(dcp_path):
            return {'success': False, 'error': f'DCP file not found: {dcp_path}'}
        if not os.path.isdir(disc_dir):
            return {'success': False, 'error': f'Disc directory not found: {disc_dir}'}

        os.makedirs(output_dir, exist_ok=True)

        # Copy source disc to output first (non-destructive)
        self._log('[DCP] Copying source disc to output directory...')
        self._copy_disc(disc_dir, output_dir)
        self.on_progress(10.0)

        result = {
            'success': False,
            'files_patched': 0,
            'xdelta_applied': 0,
            'ipbin_replaced': False,
            'error': None,
        }

        try:
            if not zipfile.is_zipfile(dcp_path):
                result['error'] = 'DCP file is not a valid ZIP/DCP archive.'
                return result

            with zipfile.ZipFile(dcp_path, 'r') as dcp:
                names = dcp.namelist()
                total = len(names)
                self._log(f'[DCP] Archive contains {total} entries.')

                for i, name in enumerate(names):
                    pct = 10.0 + (i / total) * 80.0
                    self.on_progress(pct)

                    dest_path = os.path.abspath(os.path.join(output_dir, name))
                    base_path = os.path.abspath(output_dir)
                    if not dest_path.startswith(base_path + os.sep) and dest_path != base_path:
                        raise ValueError(f'Malicious archive entry detected (Path Traversal): {name}')

                    # bootsector/IP.BIN → replace IP.BIN in output
                    if name.lower() == 'bootsector/ip.bin':
                        ipbin_data = dcp.read(name)
                        ipbin_out = os.path.join(output_dir, 'IP.BIN')
                        with open(ipbin_out, 'wb') as f:
                            f.write(ipbin_data)
                        result['ipbin_replaced'] = True
                        self._log('[DCP] Replaced IP.BIN from patch.')
                        continue

                    # Skip xdelta folder itself (handled below)
                    if name.startswith('xdelta/') or name.startswith('xdelta\\'):
                        continue

                    # Skip directory entries
                    if name.endswith('/'):
                        continue

                    # Regular file replacement
                    target = dest_path
                    os.makedirs(os.path.dirname(target), exist_ok=True)
                    with dcp.open(name) as src, open(target, 'wb') as dst:
                        shutil.copyfileobj(src, dst)
                    result['files_patched'] += 1
                    self._log(f'[DCP] Replaced: {name}')

                # Apply xdelta patches
                xdelta_entries = [n for n in names
                                  if n.startswith('xdelta/') and not n.endswith('/')]
                if xdelta_entries:
                    xdelta_result = self._apply_xdelta_patches(
                        dcp, xdelta_entries, output_dir, ignore_checksum
                    )
                    result['xdelta_applied'] = xdelta_result
                    result['files_patched'] += xdelta_result

            self.on_progress(100.0)
            result['success'] = True
            self._log(f'[DCP] Done. Files patched: {result["files_patched"]}, '
                      f'xdelta: {result["xdelta_applied"]}, '
                      f'IP.BIN replaced: {result["ipbin_replaced"]}')
            return result

        except Exception as e:
            result['error'] = str(e)
            self._log(f'[DCP ERROR] {e}')
            return result

    def _apply_xdelta_patches(
        self,
        dcp: zipfile.ZipFile,
        xdelta_entries: list,
        output_dir: str,
        ignore_checksum: bool,
    ) -> int:
        """Apply all xdelta patches from the xdelta/ subfolder."""
        xdelta3 = get_tool_path('xdelta3')
        applied = 0

        with tempfile.TemporaryDirectory() as tmp:
            for entry in xdelta_entries:
                # xdelta/FILENAME.xdelta3 → target is FILENAME in output_dir
                basename = os.path.basename(entry)
                # Strip .xdelta3 / .xdelta / .vcdiff extension
                for ext in ('.xdelta3', '.xdelta', '.xd', '.vcdiff'):
                    if basename.lower().endswith(ext):
                        target_name = basename[: -len(ext)]
                        break
                else:
                    target_name = basename

                dest_path = os.path.abspath(os.path.join(output_dir, target_name))
                base_path = os.path.abspath(output_dir)
                if not dest_path.startswith(base_path + os.sep) and dest_path != base_path:
                    raise ValueError(f'Malicious archive entry detected (Path Traversal): {entry}')

                patch_tmp = os.path.join(tmp, basename)
                source_path = dest_path
                output_path = os.path.join(output_dir, target_name + '.patched')

                if not os.path.isfile(source_path):
                    self._log(f'[DCP WARN] xdelta source not found: {target_name} — skipping')
                    continue

                # Extract patch to temp
                with dcp.open(entry) as src, open(patch_tmp, 'wb') as dst:
                    shutil.copyfileobj(src, dst)

                args = [xdelta3, '-d']
                if ignore_checksum:
                    args.append('-n')
                args += ['-s', source_path, patch_tmp, output_path]

                try:
                    proc = subprocess.run(args, capture_output=True, text=True)
                    if proc.returncode == 0:
                        os.replace(output_path, source_path)
                        applied += 1
                        self._log(f'[DCP xdelta] Patched: {target_name}')
                    else:
                        err = proc.stderr.strip()
                        self._log(f'[DCP xdelta ERROR] {target_name}: {err}')
                except FileNotFoundError:
                    self._log('[DCP ERROR] xdelta3 binary not found.')
                    break

        return applied

    def _copy_disc(self, src_dir: str, dst_dir: str):
        """Copy all files from src_dir to dst_dir, preserving structure."""
        for root, dirs, files in os.walk(src_dir):
            rel = os.path.relpath(root, src_dir)
            dst_root = os.path.join(dst_dir, rel) if rel != '.' else dst_dir
            os.makedirs(dst_root, exist_ok=True)
            for f in files:
                shutil.copy2(os.path.join(root, f), os.path.join(dst_root, f))

    def _log(self, msg: str):
        global_log(msg)
        if self.on_log:
            try:
                self.on_log(msg)
            except Exception:
                pass
