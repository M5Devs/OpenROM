import os
import tempfile
import unittest
from core.detector import get_extension, get_output_name, detect_file

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
            ("game.iso", "ISO", ["CHD", "CSO", "ECM", "XISO", "RVZ"]),
            ("disc.bin", "BIN", ["CHD", "ECM"]),
            ("disc.cue", "CUE", ["CHD"]),
            ("sonic.gdi", "GDI", ["CHD"]),
            ("halo.chd", "CHD", ["ISO", "BIN/CUE"]),
            ("psp_game.cso", "CSO", ["ISO"]),
            ("psp_game.zso", "ZSO", ["ISO"]),
            ("xbox_iso.iso", "ISO", ["CHD", "CSO", "ECM", "XISO", "RVZ"]),
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

if __name__ == "__main__":
    unittest.main()
