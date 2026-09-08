# OpenROM — Universal ROM Compression Suite
# M5 Dev | GPL v3 + Commons Clause

import os


def detect_bin_mode(bin_path: str) -> str:
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


def generate_cue(bin_path: str, output_dir: str = None) -> str:
    """
    Generate a .cue file for a given BIN file.
    Output filename is the same as the BIN file but with a .cue extension.
    Never overwrites an existing .cue file — appends '_generated' suffix if needed.
    """
    if not os.path.exists(bin_path):
        raise FileNotFoundError(f"BIN file not found: {bin_path}")

    target_dir = output_dir or os.path.dirname(os.path.abspath(bin_path)) or "."
    os.makedirs(target_dir, exist_ok=True)

    bin_name = os.path.basename(bin_path)
    base_stem = os.path.splitext(bin_name)[0]

    cue_name = f"{base_stem}.cue"
    cue_path = os.path.join(target_dir, cue_name)

    if os.path.exists(cue_path):
        cue_name = f"{base_stem}_generated.cue"
        cue_path = os.path.join(target_dir, cue_name)

    track_mode = detect_bin_mode(bin_path)

    with open(cue_path, "w", encoding="utf-8") as f:
        f.write(f'FILE "{bin_name}" BINARY\n')
        f.write(f'  TRACK 01 {track_mode}\n')
        f.write('    INDEX 01 00:00:00\n')

    return cue_path
