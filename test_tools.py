# OpenROM — Universal ROM Compression Suite
# M5 Dev | GPL v3 + Commons Clause

"""
Unit tests for OpenROM Compressor, M3U Generator, and CLI integration.
"""

import os
import tempfile
import pytest
import zipfile
import py7zr

from core.compressor import Compressor, CompressionJob, EXCLUDED_EXTENSIONS
from core.m3u_generator import generate_m3u, clean_disc_name
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
