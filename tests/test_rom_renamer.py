import os
import pytest
from core.rom_renamer import load_dat_index, _read_dat_header


def test_rom_renamer_iterparse(tmp_path):
    dat_content = """<?xml version="1.0" encoding="UTF-8"?>
<datafile>
    <header>
        <name>Super Nintendo Entertainment System</name>
        <description>SNES ROMs</description>
        <url>https://www.no-intro.org</url>
    </header>
    <game name="Super Mario World (USA)">
        <description>Super Mario World</description>
        <rom name="Super Mario World (USA).sfc" size="524288" crc="b19ed489" md5="1234" sha1="5678"/>
    </game>
</datafile>
"""
    dat_file = tmp_path / "test.dat"
    dat_file.write_text(dat_content, encoding="utf-8")

    header = _read_dat_header(str(dat_file))
    assert header["name"] == "Super Nintendo Entertainment System"
    assert header["source"] == "No-Intro"
    assert header["game_count"] == 1

    index = load_dat_index(str(dat_file))
    assert "b19ed489" in index
    assert index["b19ed489"]["rom_name"] == "Super Mario World (USA).sfc"
    assert index["b19ed489"]["name"] == "Super Mario World (USA)"
