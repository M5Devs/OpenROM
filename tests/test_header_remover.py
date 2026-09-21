import os
import pytest
from core.header_remover import detect_header, remove_header


def test_snes_header_detection_and_backup(tmp_path):
    # Create a 0x80000 byte (512KB) fake SNES LoROM clean data
    rom_data = bytearray(0x80000)
    # Set valid LoROM internal header at 0x7FC0
    # checksum complement = 0x1234, checksum = 0xEDCB (0x1234 ^ 0xEDCB == 0xFFFF)
    rom_data[0x7FC0 + 0x1C] = 0x34
    rom_data[0x7FC0 + 0x1D] = 0x12
    rom_data[0x7FC0 + 0x1E] = 0xCB
    rom_data[0x7FC0 + 0x1F] = 0xED

    clean_rom = tmp_path / "game.sfc"
    clean_rom.write_bytes(rom_data)

    info_clean = detect_header(str(clean_rom))
    assert info_clean is not None
    assert info_clean["has_header"] is False
    assert info_clean["header_size"] == 0

    # Add 512-byte SMC copier header prefix
    header_data = b"SMC" + b"\x00" * 509 + rom_data
    header_rom = tmp_path / "game_header.smc"
    header_rom.write_bytes(header_data)

    info_hdr = detect_header(str(header_rom))
    assert info_hdr is not None
    assert info_hdr["has_header"] is True
    assert info_hdr["header_size"] == 512

    # Test remove_header in-place with backup
    original_bak = tmp_path / "game_header.smc.bak"
    original_bak.write_bytes(b"ORIGINAL GOOD BACKUP")

    clean_path = remove_header(str(header_rom), backup=True)
    assert os.path.exists(clean_path)
    # Ensure existing .bak was NOT overwritten
    assert original_bak.read_bytes() == b"ORIGINAL GOOD BACKUP"
