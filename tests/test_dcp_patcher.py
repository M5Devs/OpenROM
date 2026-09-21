import os
import zipfile
import tempfile
import pytest
from core.dcp_patcher import DcpPatcher


def test_dcp_patcher_zip_slip_rejection(tmp_path):
    output_dir = tmp_path / "output"
    disc_dir = tmp_path / "disc"
    output_dir.mkdir()
    disc_dir.mkdir()

    # Create dummy file in disc_dir
    (disc_dir / "track01.bin").write_bytes(b"dummy track data")

    # Create a malicious DCP ZIP file with path traversal entry
    malicious_dcp = tmp_path / "malicious.dcp"
    with zipfile.ZipFile(malicious_dcp, "w") as zf:
        zf.writestr("../evil.txt", "malicious payload")

    patcher = DcpPatcher()
    res = patcher.apply(
        dcp_path=str(malicious_dcp),
        disc_dir=str(disc_dir),
        output_dir=str(output_dir)
    )

    assert res["success"] is False
    assert "Malicious archive entry detected" in res["error"]
