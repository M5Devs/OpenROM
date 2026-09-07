"""
OpenROM M3U Generator — Playlist Creation Utility
M5 Dev | GPL v3 + Commons Clause
"""

import os
import re

SUPPORTED_DISC_EXTENSIONS = {".chd", ".bin", ".cue", ".iso", ".gdi", ".img", ".cdi"}


def _get_disc_number(filepath: str) -> int:
    filename = os.path.basename(filepath)
    match = re.search(r'(?:disc|disk|cd)[\s\-_]*(\d+)', filename, re.IGNORECASE)
    if match:
        return int(match.group(1))
    return 999


def clean_disc_name(filepath: str) -> str:
    base = os.path.splitext(os.path.basename(filepath))[0]
    cleaned = re.sub(
        r'[\s\-_]*[\(\[\{]?(?:Disc|Disk|CD)[\s\-_]*\d+[\)\]\}]?',
        '',
        base,
        flags=re.IGNORECASE
    ).strip()
    return cleaned or base


def generate_m3u(
    disc_files: list[str],
    output_path: str,
    relative: bool = True,
    auto_sort: bool = False,
) -> str:
    if not disc_files:
        raise ValueError("No disc files provided for M3U generation.")

    valid_discs = []
    for path in disc_files:
        ext = os.path.splitext(path)[1].lower()
        if ext in SUPPORTED_DISC_EXTENSIONS:
            valid_discs.append(path)

    if not valid_discs:
        raise ValueError(
            f"No valid disc files found. Supported extensions: {', '.join(sorted(SUPPORTED_DISC_EXTENSIONS))}"
        )

    # Sort automatically if auto_sort=True, otherwise preserve manual order
    if auto_sort:
        final_discs = sorted(valid_discs, key=lambda f: (_get_disc_number(f), os.path.basename(f)))
    else:
        final_discs = valid_discs

    # Determine final output file path
    if output_path.lower().endswith(".m3u"):
        final_m3u_path = output_path
    else:
        game_title = clean_disc_name(final_discs[0])
        final_m3u_path = os.path.join(output_path, f"{game_title}.m3u")

    m3u_dir = os.path.dirname(os.path.abspath(final_m3u_path))
    if m3u_dir and not os.path.exists(m3u_dir):
        os.makedirs(m3u_dir, exist_ok=True)

    lines = []
    for disc_path in final_discs:
        if relative:
            try:
                rel_p = os.path.relpath(disc_path, start=m3u_dir)
            except ValueError:
                rel_p = os.path.basename(disc_path)
            lines.append(rel_p)
        else:
            lines.append(os.path.abspath(disc_path))

    with open(final_m3u_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    return final_m3u_path
