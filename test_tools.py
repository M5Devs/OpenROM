# OpenROM — Universal ROM Compression Suite
# M5 Dev | GPL v3 + Commons Clause

"""
Unit tests for OpenROM Compressor, M3U Generator, CUE Generator, BIN Merger, Header Remover, and CLI integration.
"""

import os
import tempfile
import pytest
import zipfile
import py7zr

from core.compressor import Compressor, CompressionJob, EXCLUDED_EXTENSIONS
from core.m3u_generator import generate_m3u, clean_disc_name
from core.cue_generator import generate_cue, detect_bin_mode
from core.bin_merger import merge_bins, parse_cue
from core.header_remover import detect_header, remove_header
from core.cli import build_parser, main


def test_compressor_zip_and_extract():
    with tempfile.TemporaryDirectory() as td:
        sample_file = os.path.join(td, "game.smc")
        with open(sample_file, "w") as f:
            f.write("Super Mario World ROM Data")

        out_dir = os.path.join(td, "out")
        os.makedirs(out_dir, exist_ok=True)

        job = CompressionJob(filepath=sample_file, output_dir=out_dir, format="zip")
        compressor = Compressor()

        ok = compressor.compress(job)
        assert ok is True
        assert job.status == "Done"
        assert job.progress == 100.0

        zip_path = os.path.join(out_dir, "game.zip")
        assert os.path.exists(zip_path)
        assert zipfile.is_zipfile(zip_path)

        # Test Extraction
        ext_dir = os.path.join(td, "ext")
        ext_job = CompressionJob(filepath=zip_path, output_dir=ext_dir, format="extract")
        ok_ext = compressor.extract(ext_job)
        assert ok_ext is True
        assert os.path.exists(os.path.join(ext_dir, "game.smc"))


def test_compressor_7z_and_skipped():
    with tempfile.TemporaryDirectory() as td:
        sample_file = os.path.join(td, "game.sfc")
        with open(sample_file, "w") as f:
            f.write("SNES ROM Data")

        out_dir = os.path.join(td, "out")
        job = CompressionJob(filepath=sample_file, output_dir=out_dir, format="7z", level="fast")
        compressor = Compressor()

        ok = compressor.compress(job)
        assert ok is True
        assert job.status == "Done"
        z7_path = os.path.join(out_dir, "game.7z")
        assert os.path.exists(z7_path)

        # Test Skipped extensions
        chd_file = os.path.join(td, "game.chd")
        with open(chd_file, "w") as f:
            f.write("CHD Data")

        job_chd = CompressionJob(filepath=chd_file, output_dir=out_dir, format="7z")
        ok_chd = compressor.compress(job_chd)
        assert ok_chd is True
        assert job_chd.error == "Skipped (already compressed)"


def test_m3u_generator_manual_and_auto_sort():
    with tempfile.TemporaryDirectory() as td:
        d1 = os.path.join(td, "Resident Evil 2 (Disc 1).chd")
        d2 = os.path.join(td, "Resident Evil 2 (Disc 2).chd")
        for d in (d1, d2):
            with open(d, "w") as f:
                f.write("disc")

        # Test manual order preservation
        m3u_manual = generate_m3u([d2, d1], td, relative=True, auto_sort=False)
        with open(m3u_manual, "r") as f:
            content_manual = f.read().splitlines()

        assert content_manual[0] == "Resident Evil 2 (Disc 2).chd"
        assert content_manual[1] == "Resident Evil 2 (Disc 1).chd"

        # Test auto sort
        m3u_auto = generate_m3u([d2, d1], td, relative=True, auto_sort=True)
        with open(m3u_auto, "r") as f:
            content_auto = f.read().splitlines()

        assert content_auto[0] == "Resident Evil 2 (Disc 1).chd"
        assert content_auto[1] == "Resident Evil 2 (Disc 2).chd"


def test_clean_disc_name():
    assert clean_disc_name("Final Fantasy VII (Disc 1).chd") == "Final Fantasy VII"
    assert clean_disc_name("Metal Gear Solid (Disk 2)") == "Metal Gear Solid"
    assert clean_disc_name("Game CD 1.iso") == "Game"


def test_cue_generator():
    with tempfile.TemporaryDirectory() as td:
        bin_path = os.path.join(td, "game.bin")
        # 2352 bytes per sector with SYNC header and mode byte 0x02 (MODE2/2352)
        sync_hdr = b'\x00' + b'\xff' * 10 + b'\x00' + b'\x00\x00\x00\x02'
        sector_data = sync_hdr + b'\x00' * (2352 - len(sync_hdr))
        with open(bin_path, "wb") as f:
            f.write(sector_data * 10)

        cue_path = generate_cue(bin_path)
        assert os.path.exists(cue_path)
        with open(cue_path, "r") as f:
            lines = f.read().splitlines()
        assert 'FILE "game.bin" BINARY' in lines[0]
        assert 'TRACK 01 MODE2/2352' in lines[1]

        # Test suffix when cue exists
        cue_path_2 = generate_cue(bin_path)
        assert cue_path_2.endswith("game_generated.cue")


def test_bin_merger():
    with tempfile.TemporaryDirectory() as td:
        bin1 = os.path.join(td, "game (Track 1).bin")
        bin2 = os.path.join(td, "game (Track 2).bin")
        with open(bin1, "wb") as f:
            f.write(b"A" * 2352 * 5)
        with open(bin2, "wb") as f:
            f.write(b"B" * 2352 * 5)

        cue_path = os.path.join(td, "game.cue")
        with open(cue_path, "w") as f:
            f.write('FILE "game (Track 1).bin" BINARY\n')
            f.write('  TRACK 01 MODE2/2352\n')
            f.write('    INDEX 01 00:00:00\n')
            f.write('FILE "game (Track 2).bin" BINARY\n')
            f.write('  TRACK 02 AUDIO\n')
            f.write('    INDEX 01 00:00:00\n')

        merged_bin, merged_cue = merge_bins(cue_path)
        assert os.path.exists(merged_bin)
        assert os.path.exists(merged_cue)
        assert os.path.getsize(merged_bin) == 2352 * 10

        tracks = parse_cue(merged_cue)
        assert len(tracks) == 2


def test_header_remover():
    with tempfile.TemporaryDirectory() as td:
        # NES header test
        nes_file = os.path.join(td, "mario.nes")
        with open(nes_file, "wb") as f:
            f.write(b"NES\x1a" + b"\x00" * 12 + b"ROMDATA")

        info_nes = detect_header(nes_file)
        assert info_nes["has_header"] is True
        assert info_nes["header_size"] == 16

        clean_nes = remove_header(nes_file, backup=True)
        assert os.path.exists(nes_file + ".bak")
        with open(clean_nes, "rb") as f:
            assert f.read() == b"ROMDATA"

        # SNES header test (512 bytes header + 1024 bytes ROM)
        snes_file = os.path.join(td, "snes.smc")
        with open(snes_file, "wb") as f:
            f.write(b"H" * 512 + b"S" * 1024)

        info_snes = detect_header(snes_file)
        assert info_snes["has_header"] is True
        assert info_snes["header_size"] == 512

        clean_snes = remove_header(snes_file, backup=False)
        assert os.path.getsize(clean_snes) == 1024


def test_iso_to_chd_command_selection():
    from core.converter import Converter, ConversionJob
    class TestConverter(Converter):
        def _run(self, cmd, job):
            self.last_cmd = cmd
            return True

    c = TestConverter()
    job = ConversionJob('ps1_game.iso', '/tmp', 'CHD')
    c._to_chd(job, 'ps1_game.iso', 'ISO', {'platform': 'PS1'})
    assert c.last_cmd[1] == 'createcd'

    job = ConversionJob('dc_game.iso', '/tmp', 'CHD')
    c._to_chd(job, 'dc_game.iso', 'ISO', {'platform': 'Dreamcast'})
    assert c.last_cmd[1] == 'createcd'

    job = ConversionJob('ps2_game.iso', '/tmp', 'CHD')
    c._to_chd(job, 'ps2_game.iso', 'ISO', {'platform': 'PS2'})
    assert c.last_cmd[1] == 'createdvd'
