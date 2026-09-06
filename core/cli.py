"""
OpenROM CLI — Universal ROM Compression Suite
M5 Dev | GPL v3 + Commons Clause

Usage examples:
  openrom --input game.iso --format CHD
  openrom --input game.iso --format CHD --compression High --verify
  openrom --input game.iso --format CHD --output /path/to/folder
  openrom --folder /roms/ --format CHD --compression Max
  openrom --input game.chd --verify-only
  openrom --list-formats
  openrom --json --detect game.iso
  openrom --json --convert game.iso --format CHD --compression Normal
"""

import sys
import os
import argparse
import threading
import json

# Allow imports from project root
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from core.detector import detect_file, detect_folder, CONVERSION_MAP, get_valid_targets
from core.converter import Converter, ConversionJob
from core.validator import verify_chd

# ── ANSI colors (disabled on Windows if no ANSI support) ─────────────────────
def _ansi(code: str) -> str:
    if sys.platform == "win32":
        try:
            import ctypes
            ctypes.windll.kernel32.SetConsoleMode(
                ctypes.windll.kernel32.GetStdHandle(-11), 7
            )
        except Exception:
            return ""
    return f"\033[{code}m"

RESET  = _ansi("0")
BOLD   = _ansi("1")
RED    = _ansi("31")
GREEN  = _ansi("32")
YELLOW = _ansi("33")
CYAN   = _ansi("36")
GRAY   = _ansi("90")

# ── Progress bar renderer ─────────────────────────────────────────────────────
_progress_lock = threading.Lock()

def _render_progress(label: str, pct: float, width: int = 28):
    filled = int(width * pct / 100)
    bar    = "█" * filled + "░" * (width - filled)
    line   = f"\r  {CYAN}{bar}{RESET} {YELLOW}{pct:5.1f}%{RESET}  {GRAY}{label}{RESET}"
    with _progress_lock:
        sys.stdout.write(line)
        sys.stdout.flush()

def _clear_progress():
    with _progress_lock:
        sys.stdout.write("\r" + " " * 80 + "\r")
        sys.stdout.flush()

def _json_print(obj: dict):
    with _progress_lock:
        print(json.dumps(obj), flush=True)

# ── Argument parser ───────────────────────────────────────────────────────────
def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="openrom",
        description=f"{BOLD}OpenROM v2.2{RESET} — Universal ROM Compression Suite",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
examples:
  openrom --input game.iso --format CHD
  openrom --input game.iso --format CHD --compression High --verify
  openrom --input game.iso --format CHD --output ./converted/
  openrom --folder /roms/ --format CHD --compression Max
  openrom --input game.chd --verify-only
  openrom --list-formats
  openrom --json --detect game.iso
        """,
    )

    # ── Input source (mutually exclusive) ────────────────────────────────────
    src = parser.add_mutually_exclusive_group()
    src.add_argument(
        "--input", "-i",
        metavar="FILE",
        help="single input ROM file",
    )
    src.add_argument(
        "--folder", "-f",
        metavar="DIR",
        help="convert all supported ROMs in a folder",
    )
    src.add_argument(
        "--detect",
        metavar="FILE",
        help="detect file format and info",
    )
    src.add_argument(
        "--convert",
        metavar="FILE",
        help="single file to convert (alias for --input)",
    )

    # ── Conversion target ────────────────────────────────────────────────────
    parser.add_argument(
        "--format", "-F",
        metavar="FORMAT",
        help="output format: CHD, CSO, ECM, ISO, BIN, BIN/CUE, XISO",
    )

    # ── Options ──────────────────────────────────────────────────────────────
    parser.add_argument(
        "--json",
        action="store_true",
        help="output results/progress in JSON format",
    )
    parser.add_argument(
        "--output", "-o",
        metavar="DIR",
        help="output directory (default: same as source)",
    )
    parser.add_argument(
        "--compression", "-c",
        choices=["Normal", "High", "Max"],
        default="Normal",
        metavar="LEVEL",
        help="compression level: Normal | High | Max  (default: Normal)",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="verify CHD integrity after conversion",
    )
    parser.add_argument(
        "--verify-only",
        action="store_true",
        help="verify an existing CHD file without converting",
    )
    parser.add_argument(
        "--list-formats",
        action="store_true",
        help="print supported conversion formats and exit",
    )
    parser.add_argument(
        "--quiet", "-q",
        action="store_true",
        help="suppress per-job log output (still prints summary)",
    )
    parser.add_argument(
        "--version", "-v",
        action="version",
        version="OpenROM v2.2.0",
    )

    return parser

# ── --detect ──────────────────────────────────────────────────────────────────
def cmd_detect(filepath: str, is_json: bool) -> int:
    info = detect_file(filepath)
    info["filepath"] = filepath
    info["filename"] = os.path.basename(filepath)
    if is_json:
        print(json.dumps(info), flush=True)
    else:
        if "error" in info:
            print(f"{RED}✗ Error: {info['error']}{RESET}")
            return 2
        print(f"{BOLD}File:{RESET} {info['filename']}")
        print(f"  Format: {CYAN}{info.get('format')}{RESET}")
        print(f"  Platform: {YELLOW}{info.get('platform')}{RESET}")
        print(f"  Size: {info.get('size_str')}")
        print(f"  Valid targets: {', '.join(info.get('valid_targets', []))}")
    return 0 if "error" not in info else 2

# ── --list-formats ────────────────────────────────────────────────────────────
def cmd_list_formats():
    print(f"\n{BOLD}Supported conversions:{RESET}\n")
    for src_fmt, targets in CONVERSION_MAP.items():
        targets_str = "  →  " + f"{GRAY},{RESET} ".join(
            f"{CYAN}{t}{RESET}" for t in targets
        )
        print(f"  {BOLD}{src_fmt:<8}{RESET}{targets_str}")
    print()

# ── --verify-only ─────────────────────────────────────────────────────────────
def cmd_verify_only(filepath: str, is_json: bool) -> int:
    if not os.path.isfile(filepath):
        if is_json:
            _json_print({"type": "error", "message": f"File not found: {filepath}"})
        else:
            print(f"{RED}✗ File not found: {filepath}{RESET}")
        return 2

    info = detect_file(filepath)
    if info.get("format") != "CHD":
        if is_json:
            _json_print({"type": "error", "message": "--verify-only only works on CHD files."})
        else:
            print(f"{RED}✗ --verify-only only works on CHD files.{RESET}")
        return 2

    if not is_json:
        print(f"\n{BOLD}Verifying:{RESET} {os.path.basename(filepath)}")

    logs = []

    def on_log(m: str):
        logs.append(m)
        if is_json:
            _json_print({"type": "log", "message": m})

    ok = verify_chd(filepath, on_log=on_log)

    if not is_json:
        for line in logs:
            print(f"  {GRAY}{line}{RESET}")

    if ok:
        if is_json:
            _json_print({"type": "done", "success": True})
        else:
            print(f"\n{GREEN}✅ CHD is valid.{RESET}\n")
        return 0
    else:
        if is_json:
            _json_print({"type": "done", "success": False})
        else:
            print(f"\n{RED}❌ CHD verification failed.{RESET}\n")
        return 1

# ── Collect jobs from args ────────────────────────────────────────────────────
def collect_jobs(args) -> list[ConversionJob]:
    jobs = []
    target_fmt = args.format.upper() if args.format else None
    input_file = args.input or args.convert

    def _make_job(filepath: str) -> ConversionJob | None:
        job = ConversionJob(
            filepath=filepath,
            output_dir=args.output or os.path.dirname(os.path.abspath(filepath)),
            target_format="CHD",        # placeholder; resolved below
            compression=args.compression,
            verify=args.verify,
        )
        info = job.get_file_info()

        if "error" in info:
            if args.json:
                _json_print({"type": "error", "message": info['error']})
            else:
                print(f"{YELLOW}⚠ Skipping {os.path.basename(filepath)}: {info['error']}{RESET}")
            return None

        valid = info.get("valid_targets", [])
        if not valid:
            if args.json:
                _json_print({"type": "error", "message": f"No valid targets for {os.path.basename(filepath)}"})
            else:
                print(f"{YELLOW}⚠ Skipping {os.path.basename(filepath)}: no valid targets{RESET}")
            return None

        if target_fmt:
            if target_fmt not in valid and target_fmt != "BIN/CUE":
                src_fmt = info.get("format", "?")
                msg = f"{src_fmt} → {target_fmt} is not supported. Valid: {', '.join(valid)}"
                if args.json:
                    _json_print({"type": "error", "message": msg})
                else:
                    print(f"{YELLOW}⚠ Skipping {os.path.basename(filepath)}: {msg}{RESET}")
                return None
            job.target_format = target_fmt
        else:
            job.target_format = valid[0]

        return job

    if input_file:
        job = _make_job(input_file)
        if job:
            jobs.append(job)

    elif args.folder:
        if not os.path.isdir(args.folder):
            if args.json:
                _json_print({"type": "error", "message": f"Folder not found: {args.folder}"})
            else:
                print(f"{RED}✗ Folder not found: {args.folder}{RESET}")
            return []
        detected = detect_folder(args.folder)
        if not detected:
            if args.json:
                _json_print({"type": "error", "message": f"No supported ROM files found in: {args.folder}"})
            else:
                print(f"{YELLOW}⚠ No supported ROM files found in: {args.folder}{RESET}")
            return []
        for entry in detected:
            job = _make_job(entry["filepath"])
            if job:
                jobs.append(job)

    return jobs

# ── Run batch ─────────────────────────────────────────────────────────────────
def run_batch(jobs: list[ConversionJob], quiet: bool, is_json: bool = False) -> int:
    total   = len(jobs)
    passed  = 0
    failed  = 0

    if not is_json:
        print(f"\n{BOLD}OpenROM{RESET} — {total} job{'s' if total != 1 else ''} queued\n")

    # Track current job label for the progress renderer
    _current: dict = {"label": ""}

    def on_progress(job: ConversionJob, pct: float):
        if is_json:
            _json_print({
                "type": "progress",
                "file": os.path.basename(job.filepath),
                "percent": pct
            })
        else:
            _render_progress(_current["label"], pct)

    def on_log(msg: str):
        if is_json:
            _json_print({
                "type": "log",
                "message": msg
            })
        elif not quiet:
            _clear_progress()
            print(f"  {GRAY}{msg}{RESET}")
            # Re-render bar after log line
            if _current["label"]:
                _render_progress(_current["label"], job_ref[0].progress if job_ref else 0)

    job_ref: list = []   # mutable ref so on_log can access current job

    converter = Converter(on_log=on_log, on_progress=on_progress)

    for idx, job in enumerate(jobs):
        label        = f"{os.path.basename(job.filepath)}  →  {job.target_format}"
        _current["label"] = label
        job_ref.clear()
        job_ref.append(job)

        if not is_json:
            prefix = f"[{idx+1}/{total}]"
            print(f"{BOLD}{prefix}{RESET} {label}")

        ok = converter.convert(job)
        if not is_json:
            _clear_progress()

        if ok:
            passed += 1
            if is_json:
                _json_print({"type": "done", "success": True})
            else:
                print(f"  {GREEN}✅ Done{RESET}\n")
        else:
            failed += 1
            err = job.error or "conversion failed"
            if is_json:
                _json_print({"type": "done", "success": False, "error": err})
            else:
                print(f"  {RED}❌ Failed — {err}{RESET}\n")

    if not is_json:
        # ── Summary ───────────────────────────────────────────────────────────
        print("─" * 48)
        print(f"  {GREEN}✅ Passed: {passed}{RESET}   {RED}❌ Failed: {failed}{RESET}   Total: {total}")
        print("─" * 48 + "\n")

    # Exit codes: 0 = all good, 1 = some failed, 2 = all failed
    if failed == 0:
        return 0
    if passed == 0:
        return 2
    return 1

# ── Entry point ───────────────────────────────────────────────────────────────
def main() -> int:
    parser = build_parser()

    # Print help if no args given
    if len(sys.argv) == 1:
        parser.print_help()
        return 0

    args = parser.parse_args()

    # ── Dispatch ──────────────────────────────────────────────────────────────
    if args.detect:
        return cmd_detect(args.detect, args.json)

    if args.list_formats:
        cmd_list_formats()
        return 0

    if args.verify_only:
        input_file = args.input or args.convert
        if not input_file:
            if args.json:
                _json_print({"type": "error", "message": "--verify-only requires --input or --convert FILE"})
            else:
                print(f"{RED}✗ --verify-only requires --input FILE{RESET}")
            return 2
        return cmd_verify_only(input_file, args.json)

    input_file = args.input or args.convert
    if not input_file and not args.folder:
        if args.json:
            _json_print({"type": "error", "message": "Provide --input, --convert FILE, or --folder DIR"})
        else:
            print(f"{RED}✗ Provide --input FILE or --folder DIR{RESET}")
            parser.print_usage()
        return 2

    if not args.format and not args.verify_only and not args.json:
        print(f"{YELLOW}⚠ No --format specified — will use first valid target for each file.{RESET}\n")

    # Validate output dir exists if specified
    if args.output and not os.path.isdir(args.output):
        try:
            os.makedirs(args.output, exist_ok=True)
        except Exception as e:
            if args.json:
                _json_print({"type": "error", "message": f"Cannot create output directory: {e}"})
            else:
                print(f"{RED}✗ Cannot create output directory: {e}{RESET}")
            return 2

    jobs = collect_jobs(args)
    if not jobs:
        return 2

    return run_batch(jobs, quiet=args.quiet, is_json=args.json)


if __name__ == "__main__":
    sys.exit(main())
