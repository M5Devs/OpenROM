import os
import tempfile
import unittest
from core.detector import get_extension, get_output_name, detect_file, _header_has_saturn_magic, _header_has_segacd_magic, _header_has_pcecd_magic, _header_has_neogeocd_magic

class TestDetector(unittest.TestCase):
    def test_get_extension(self):
        self.assertEqual(get_extension("tom_jerry.bin.ecm"), "ecm")
        self.assertEqual(get_extension("game.iso"), "iso")
        self.assertEqual(get_extension("disc.cue"), "cue")
        self.assertEqual(get_extension("archive.tar.gz"), "gz")

    def test_get_output_name(self):
        self.assertEqual(get_output_name("tom_jerry.bin.ecm", "bin"), "tom_jerry.bin")
        self.assertEqual(get_output_name("tom_jerry.bin.ecm", ".bin"), "tom_jerry.bin")
        self.assertEqual(get_output_name("game.iso", "chd"), "game.chd")
        self.assertEqual(get_output_name("disc.bin", "ecm"), "disc.ecm")

    def test_detect_file_cases(self):
        cases = [
            ("tom_jerry.bin.ecm", "ECM", ["ISO", "BIN"]),
            ("game.iso", "ISO", ["CHD", "CSO", "ECM", "XISO", "RVZ", "NKIT"]),
            ("disc.bin", "BIN", ["CHD", "ECM"]),
            ("disc.cue", "CUE", ["CHD"]),
            ("sonic.gdi", "GDI", ["CHD"]),
            ("halo.chd", "CHD", ["ISO", "BIN/CUE"]),
            ("psp_game.cso", "CSO", ["ISO"]),
            ("psp_game.zso", "ZSO", ["ISO"]),
            ("xbox_iso.iso", "ISO", ["CHD", "CSO", "ECM", "XISO", "RVZ", "NKIT"]),
        ]

        with tempfile.TemporaryDirectory() as tmpdir:
            for filename, expected_fmt, expected_targets in cases:
                filepath = os.path.join(tmpdir, filename)
                with open(filepath, "wb") as f:
                    f.write(b"\x00" * 1024)

                res = detect_file(filepath)
                self.assertNotIn("error", res)
                self.assertEqual(res["format"], expected_fmt, f"Failed format check for {filename}")
                self.assertEqual(res["valid_targets"], expected_targets, f"Failed targets check for {filename}")

    def test_xbox_magic_detection(self):
        xbox_magic = b"MICROSOFT*XBOX*MEDIA"
        with tempfile.TemporaryDirectory() as tmpdir:
            # Fast path (offset 0x10000)
            fast_path = os.path.join(tmpdir, "xbox_fast.iso")
            with open(fast_path, "wb") as f:
                f.write(b"\x00" * 0x10000)
                f.write(xbox_magic)
                f.write(b"\x00" * 1024)

            res_fast = detect_file(fast_path)
            self.assertEqual(res_fast["platform"], "Xbox")

            # Slow path (offset 0x2090000)
            slow_path = os.path.join(tmpdir, "xbox_slow.iso")
            with open(slow_path, "wb") as f:
                f.seek(0x2090000)
                f.write(xbox_magic)

            res_slow = detect_file(slow_path)
            self.assertEqual(res_slow["platform"], "Xbox")

    def test_saturn_detection(self):
        header = bytearray(0x210000)
        header[0x10:0x10+15] = b"SEGA SEGASATURN"
        self.assertTrue(_header_has_saturn_magic(bytes(header)))

    def test_segacd_detection(self):
        header = bytearray(0x210000)
        header[0x10:0x10+14] = b"SEGADISCSYSTEM"
        self.assertTrue(_header_has_segacd_magic(bytes(header)))

    def test_pcecd_detection(self):
        header = bytearray(0x210000)
        header[0:len(b"PC Engine CD-ROM SYSTEM")] = b"PC Engine CD-ROM SYSTEM"
        self.assertTrue(_header_has_pcecd_magic(bytes(header)))

    def test_neogeocd_detection(self):
        header = bytearray(0x210000)
        header[0:len(b"NEO-GEO CD")] = b"NEO-GEO CD"
        self.assertTrue(_header_has_neogeocd_magic(bytes(header)))

if __name__ == "__main__":

    unittest.main()
