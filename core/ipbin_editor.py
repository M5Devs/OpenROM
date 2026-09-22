"""
core/ipbin_editor.py — Dreamcast IP.BIN reader and editor
M5 Dev | GPL v3

IP.BIN is the Dreamcast boot sector: 2048 bytes, fixed ASCII/Shift-JIS fields.
Can be read from a standalone IP.BIN file or extracted from a GDI/CHD.
"""

import os

IPBIN_SIZE = 2048

# Field definitions: (offset, length, name)
IPBIN_FIELDS = [
    (0x00, 16, 'hardware_id'),      # "SEGA SEGADREAMCAST "
    (0x10, 16, 'maker_id'),         # "SEGA ENTERPRISES"
    (0x20, 10, 'product_number'),   # e.g. "T-0000"
    (0x2A,  6, 'product_version'),  # e.g. "V1.001"
    (0x30,  8, 'release_date'),     # "YYYYMMDD"
    (0x38,  8, 'boot_filename'),    # e.g. "1ST_READ.BIN"
    (0x40, 16, 'software_type'),    # "  GD-ROM1/1     "
    (0x50,  8, 'region_code'),      # "JUE     " (J=Japan, U=USA, E=Europe)
    (0x58,  8, 'peripherals'),      # bitfield as ASCII hex
    (0x60, 16, 'product_name'),     # game title
    (0x70, 16, 'product_name_2'),   # game title continued
]

REGION_FLAGS = {'J': 'Japan', 'U': 'USA', 'E': 'Europe'}


def read_ipbin(path: str) -> dict:
    """
    Read an IP.BIN file and return a dict of its fields.
    Raises ValueError if file is not a valid Dreamcast IP.BIN.
    """
    if not os.path.isfile(path):
        raise FileNotFoundError(f'IP.BIN not found: {path}')

    with open(path, 'rb') as f:
        data = f.read(IPBIN_SIZE)

    if len(data) < IPBIN_SIZE:
        raise ValueError(f'File too small to be IP.BIN: {len(data)} bytes (need {IPBIN_SIZE})')

    # Validate Dreamcast magic
    hardware_id = data[0x00:0x10].decode('ascii', errors='replace').strip()
    if 'SEGA' not in hardware_id:
        raise ValueError(f'Not a valid Dreamcast IP.BIN (hardware_id: {hardware_id!r})')

    result = {'_raw': data, '_path': path}
    for offset, length, name in IPBIN_FIELDS:
        raw = data[offset: offset + length]
        if name in ('product_name', 'product_name_2'):
            try:
                decoded = raw.decode('shift_jis')
            except UnicodeDecodeError:
                try:
                    decoded = raw.decode('cp932')
                except UnicodeDecodeError:
                    decoded = raw.decode('ascii', errors='replace')
        else:
            decoded = raw.decode('ascii', errors='replace')
        result[name] = decoded.rstrip()

    # Parse region flags
    region_raw = result.get('region_code', '')
    result['regions'] = [REGION_FLAGS[c] for c in 'JUE' if c in region_raw]

    return result


def write_ipbin(fields: dict, output_path: str):
    """
    Write modified IP.BIN fields back to a file.
    fields must contain '_raw' (the original 2048-byte blob).
    Only fields present in IPBIN_FIELDS are updated.
    """
    data = bytearray(fields['_raw'])

    for offset, length, name in IPBIN_FIELDS:
        if name not in fields or name.startswith('_'):
            continue
        val = fields[name]
        try:
            encoded = val.encode('ascii')
        except UnicodeEncodeError:
            try:
                encoded = val.encode('shift_jis')
            except UnicodeEncodeError:
                encoded = val.encode('ascii', errors='replace')

        # Pad with spaces to field length, truncate if too long
        padded = encoded[:length].ljust(length, b' ')
        data[offset: offset + length] = padded

    # Update region code from regions list
    if 'regions' in fields:
        region_str = ''
        for code, name in REGION_FLAGS.items():
            if name in fields['regions']:
                region_str += code
        region_encoded = region_str.encode('ascii').ljust(8, b' ')
        data[0x50:0x58] = region_encoded

    with open(output_path, 'wb') as f:
        f.write(bytes(data))


def set_region_free(fields: dict) -> dict:
    """Enable all three regions (Japan, USA, Europe)."""
    fields['regions'] = ['Japan', 'USA', 'Europe']
    return fields


def set_vga_enabled(fields: dict) -> dict:
    """
    Enable VGA output in the peripheral flags byte.
    Bit 4 of the peripherals field (offset 0x58) controls VGA.
    """
    perip = fields.get('peripherals', '00000000')
    try:
        flags = int(perip.strip(), 16)
    except ValueError:
        flags = 0
    flags |= (1 << 4)  # bit 4 = VGA box support
    fields['peripherals'] = f'{flags:08X}'
    return fields
