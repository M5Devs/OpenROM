"""
core/gdi_reader.py — Minimal GDI disc image parser
M5 Dev | GPL v3

Parses .gdi files to locate track files and extract IP.BIN.
GDI format: text file listing tracks with LBA offsets and sector sizes.
"""

import os
import re
from dataclasses import dataclass


@dataclass
class GdiTrack:
    number: int
    lba: int
    track_type: int   # 0=audio, 4=data
    sector_size: int  # 2048 or 2352
    filename: str
    filesize: int


def parse_gdi(gdi_path: str) -> list[GdiTrack]:
    """
    Parse a .gdi file and return a list of GdiTrack objects.
    The .gdi format:
      Line 1: track count
      Line N: <track_num> <lba> <type> <sector_size> <filename> <unknown>
    """
    if not os.path.isfile(gdi_path):
        raise FileNotFoundError(f'GDI file not found: {gdi_path}')

    gdi_dir = os.path.dirname(os.path.abspath(gdi_path))
    tracks = []

    with open(gdi_path, 'r', encoding='utf-8', errors='replace') as f:
        lines = [line.strip() for line in f if line.strip()]

    # First line is track count
    for line in lines[1:]:
        parts = re.split(r'\s+', line, maxsplit=5)
        if len(parts) < 5:
            continue
        try:
            num = int(parts[0])
            lba = int(parts[1])
            ttype = int(parts[2])
            sector_size = int(parts[3])
            filename = parts[4].strip('"')
            filepath = os.path.join(gdi_dir, filename)
            filesize = os.path.getsize(filepath) if os.path.isfile(filepath) else 0
            tracks.append(GdiTrack(
                number=num, lba=lba, track_type=ttype,
                sector_size=sector_size, filename=filepath, filesize=filesize
            ))
        except (ValueError, IndexError):
            continue

    return tracks


def extract_ipbin_from_gdi(gdi_path: str) -> bytes:
    """
    Extract the 2048-byte IP.BIN from a GDI disc image.
    IP.BIN is always the first 2048 bytes of the data area in track 3.
    """
    tracks = parse_gdi(gdi_path)

    # Track 3 is always the first high-density data track on Dreamcast GDI
    data_tracks = [t for t in tracks if t.track_type == 4]
    if not data_tracks:
        raise ValueError('No data tracks found in GDI.')

    # The first data track after LBA 45000 is the main data track
    hd_tracks = [t for t in data_tracks if t.lba >= 45000]
    if not hd_tracks:
        hd_tracks = data_tracks  # fallback: use any data track

    track = hd_tracks[0]

    if not os.path.isfile(track.filename):
        raise FileNotFoundError(f'Track file not found: {track.filename}')

    with open(track.filename, 'rb') as f:
        # For 2352-byte sectors: IP.BIN starts at byte 16 of sector 0
        # For 2048-byte sectors: IP.BIN starts at byte 0
        if track.sector_size == 2352:
            # Read first sector, skip 16-byte sync header
            sector = f.read(2352)
            return sector[16: 16 + 2048]
        else:
            return f.read(2048)
