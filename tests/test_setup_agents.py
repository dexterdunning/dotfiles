from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class AgentSetupMigrationTest(unittest.TestCase):
    def test_stowed_directory_backup_does_not_modify_source(self) -> None:
        """Backing up a child must not follow a previously backed-up parent symlink."""
        script = Path(__file__).resolve().parents[1] / "setup-agents.py"
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            home = root / "home"
            source = root / "stowed-agents"
            home.mkdir()
            source.mkdir()
            (source / "AGENTS.md").write_text("original source instructions\n")
            (source / "local-metadata").write_text("keep local metadata\n")
            (home / ".agents").symlink_to(source, target_is_directory=True)
            result = subprocess.run(
                [sys.executable, str(script), "--home", str(home), "--apply"],
                capture_output=True,
                text=True,
                check=False,
                timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((source / "AGENTS.md").read_text(), "original source instructions\n")
            self.assertEqual((home / ".agents/local-metadata").read_text(), "keep local metadata\n")
            self.assertFalse((home / ".agents").is_symlink())
            self.assertFalse((home / ".agents/AGENTS.md").is_symlink())


if __name__ == "__main__":
    unittest.main()
