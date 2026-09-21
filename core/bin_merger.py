# OpenROM — Universal ROM Compression Suite
# M5 Dev | GPL v3

import os
import re
from typing import Callable, Tuple, List, Dict


def _sectors_to_msf(sectors: int) -> str:
    """Convert a sector count to MSF (MM:SS:FF) format (75 sectors/sec)."""
    mm = sectors // (75 * 60)
    rem = sectors % (75 * 60)
    ss = rem // 75
    ff = rem % 75
    return f"{mm:02d}:{ss:02d}:{ff:02d}"


def _msf_to_sectors(msf: str) -> int:
    """Convert MSF string (MM:SS:FF) to sector count."""
    parts = list(map(int, msf.split(":")))
    return parts[0] * 60 * 75 + parts[1] * 75 + parts[2]


def _get_sector_size(mode: str) -> int:
    """Return sector size in bytes based on track mode."""
    mode_upper = mode.upper()
    if "2048" in mode_upper:
        return 2048
    if "2336" in mode_upper:
        return 2336
    return 2352


def parse_cue(cue_path: str) -> List[Dict]:
    """
    Parse a CUE file to extract tracks, indexes, and referenced BIN files.
    Returns list of track dicts:
      [
        {
          "track_number": int,
          "mode": str,
          "file": str (absolute path),
          "rel_file": str (filename in cue),
          "indexes": [{"number": int, "msf": str}, ...]
        }, ...
      ]
    """
    cue_dir = os.path.dirname(os.path.abspath(cue_path))
    tracks = []

    current_file = None
    file_regex = re.compile(r'FILE\s+["\']?([^"\']+)["\']?\s+BINARY', re.IGNORECASE)
    track_regex = re.compile(r'TRACK\s+(\d+)\s+([^\s]+)', re.IGNORECASE)
    index_regex = re.compile(r'INDEX\s+(\d+)\s+(\d{2}:\d{2}:\d{2})', re.IGNORECASE)

    with open(cue_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line_str = line.strip()
            fm = file_regex.search(line_str)
            if fm:
                rel_file = fm.group(1)
                current_file = os.path.join(cue_dir, rel_file)
                continue

            tm = track_regex.search(line_str)
            if tm:
                num = int(tm.group(1))
                mode = tm.group(2)
                tracks.append({
                    "track_number": num,
                    "mode": mode,
                    "file": current_file,
                    "rel_file": os.path.basename(current_file) if current_file else "",
                    "indexes": [],
                })
                continue

            im = index_regex.search(line_str)
            if im and tracks:
                idx_num = int(im.group(1))
                idx_msf = im.group(2)
                tracks[-1]["indexes"].append({
                    "number": idx_num,
                    "msf": idx_msf,
                })

    return tracks


def merge_bins(
    cue_path: str,
    output_dir: str = None,
    on_progress: Callable[[float], None] = None
) -> Tuple[str, str]:
    """
    Merge multiple BIN files (from a multi-file BIN/CUE set) into a single BIN + updated CUE.

    Returns:
      (merged_bin_path, new_cue_path)
    """
    if not os.path.exists(cue_path):
        raise FileNotFoundError(f"CUE file not found: {cue_path}")

    cue_dir = os.path.dirname(os.path.abspath(cue_path))
    target_dir = output_dir or cue_dir or "."
    os.makedirs(target_dir, exist_ok=True)

    tracks = parse_cue(cue_path)
    if not tracks:
        raise ValueError(f"No tracks found in CUE file: {cue_path}")

    # Validate all referenced BIN files exist
    for t in tracks:
        bin_file = t.get("file")
        if not bin_file or not os.path.exists(bin_file):
            raise FileNotFoundError(f"Referenced BIN file not found: {bin_file}")

    base_stem = os.path.splitext(os.path.basename(cue_path))[0]
    merged_bin_name = f"{base_stem}_merged.bin"
    merged_cue_name = f"{base_stem}_merged.cue"

    merged_bin_path = os.path.join(target_dir, merged_bin_name)
    merged_cue_path = os.path.join(target_dir, merged_cue_name)

    total_bytes = sum(os.path.getsize(t["file"]) for t in tracks)
    bytes_written = 0

    accumulated_sectors = 0
    new_cue_tracks = []

    # Open merged BIN file for writing
    with open(merged_bin_path, "wb") as out_bin:
        for idx, t in enumerate(tracks):
            bin_path = t["file"]
            mode = t["mode"]
            sec_size = _get_sector_size(mode)

            file_size = os.path.getsize(bin_path)
            sectors_in_file = file_size // sec_size

            parsed_indexes = t.get("indexes", [])

            if parsed_indexes:
                # Find INDEX 01 offset within this track file
                idx01_entry = next((i for i in parsed_indexes if i["number"] == 1), None)
                idx01_offset = _msf_to_sectors(idx01_entry["msf"]) if idx01_entry else 0

                computed_indexes = []
                for idx_item in parsed_indexes:
                    idx_offset = _msf_to_sectors(idx_item["msf"])
                    # Convert track-relative index offset into merged timeline
                    idx_sectors = accumulated_sectors + (idx_offset - idx01_offset)
                    computed_indexes.append({
                        "number": idx_item["number"],
                        "msf": _sectors_to_msf(idx_sectors),
                    })
            else:
                computed_indexes = [{
                    "number": 1,
                    "msf": _sectors_to_msf(accumulated_sectors),
                }]

            new_cue_tracks.append({
                "track_number": t["track_number"],
                "mode": mode,
                "indexes": computed_indexes,
            })

            accumulated_sectors += sectors_in_file

            # Write BIN file contents in chunks
            chunk_size = 1024 * 1024  # 1MB
            with open(bin_path, "rb") as in_bin:
                while True:
                    chunk = in_bin.read(chunk_size)
                    if not chunk:
                        break
                    out_bin.write(chunk)
                    bytes_written += len(chunk)
                    if on_progress and total_bytes > 0:
                        pct = min(100.0, (bytes_written / total_bytes) * 100.0)
                        on_progress(pct)

    if on_progress:
        on_progress(100.0)

    # Write new merged CUE file
    with open(merged_cue_path, "w", encoding="utf-8") as f:
        f.write(f'FILE "{merged_bin_name}" BINARY\n')
        for ct in new_cue_tracks:
            f.write(f'  TRACK {ct["track_number"]:02d} {ct["mode"]}\n')
            for idx_item in ct["indexes"]:
                f.write(f'    INDEX {idx_item["number"]:02d} {idx_item["msf"]}\n')

    return (merged_bin_path, merged_cue_path)
