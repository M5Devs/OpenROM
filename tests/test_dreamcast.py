"""Tests for Dreamcast DCP patcher and IP.BIN editor."""
import os
import tempfile
import zipfile
import pytest

from core.ipbin_editor import read_ipbin, write_ipbin, set_region_free, set_vga_enabled, IPBIN_SIZE
from core.gdi_reader import parse_gdi


# ── IP.BIN editor tests ───────────────────────────────────────────────────────

def _make_ipbin(title='TEST GAME', region='JUE') -> bytes:
    """Create a minimal valid IP.BIN blob for testing."""
    data = bytearray(IPBIN_SIZE)
    data[0x00:0x10] = b'SEGA SEGADREAMCA'
    data[0x10:0x20] = b'SEGA ENTERPRISES'
    data[0x20:0x2A] = b'T-000000  '
    data[0x2A:0x30] = b'V1.000'
    data[0x30:0x38] = b'20260101'
    data[0x38:0x40] = b'1ST_READ'
    data[0x40:0x50] = b'  GD-ROM1/1     '
    region_bytes = region.encode('ascii').ljust(8)
    data[0x50:0x58] = region_bytes
    data[0x58:0x60] = b'00000000'
    title_bytes = title.encode('ascii')[:16].ljust(16)
    data[0x60:0x70] = title_bytes
    return bytes(data)


def test_read_ipbin_valid():
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as f:
        f.write(_make_ipbin('MY GAME', 'JU'))
        path = f.name
    try:
        fields = read_ipbin(path)
        assert 'SEGA' in fields['hardware_id']
        assert 'MY GAME' in fields['product_name']
        assert 'Japan' in fields['regions']
        assert 'USA' in fields['regions']
        assert 'Europe' not in fields['regions']
    finally:
        os.unlink(path)


def test_set_region_free():
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as f:
        f.write(_make_ipbin(region='J'))
        path = f.name
    try:
        fields = read_ipbin(path)
        assert fields['regions'] == ['Japan']
        fields = set_region_free(fields)
        assert set(fields['regions']) == {'Japan', 'USA', 'Europe'}
        out = path + '.out'
        write_ipbin(fields, out)
        fields2 = read_ipbin(out)
        assert set(fields2['regions']) == {'Japan', 'USA', 'Europe'}
    finally:
        os.unlink(path)
        if os.path.isfile(path + '.out'):
            os.unlink(path + '.out')


def test_set_vga_enabled():
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as f:
        f.write(_make_ipbin())
        path = f.name
    try:
        fields = read_ipbin(path)
        fields = set_vga_enabled(fields)
        perip = int(fields['peripherals'].strip(), 16)
        assert perip & (1 << 4), 'VGA bit (bit 4) should be set'
    finally:
        os.unlink(path)


def test_read_ipbin_invalid():
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as f:
        f.write(b'\x00' * IPBIN_SIZE)
        path = f.name
    try:
        with pytest.raises(ValueError, match='Not a valid Dreamcast IP.BIN'):
            read_ipbin(path)
    finally:
        os.unlink(path)


# ── DCP structure tests (no xdelta binary needed) ─────────────────────────────

def test_dcp_is_zip():
    """Verify that a DCP file is recognized as a ZIP archive."""
    with tempfile.NamedTemporaryFile(suffix='.dcp', delete=False) as f:
        path = f.name
    try:
        with zipfile.ZipFile(path, 'w') as zf:
            zf.writestr('SOME_FILE.BIN', b'\x00' * 100)
        assert zipfile.is_zipfile(path)
    finally:
        os.unlink(path)
