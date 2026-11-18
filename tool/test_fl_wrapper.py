"""Runs tool/test_fl_wrapper.sh so that unittest discovery (hook, CI, tool/test.sh) covers the shell wrappers."""
import subprocess
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("test_fl_wrapper.sh")


class FlWrapper(unittest.TestCase):
    def test_wrappers_choose_local_flutter_or_docker(self):
        done = subprocess.run(["bash", str(SCRIPT)], capture_output=True, text=True, timeout=120)
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)


if __name__ == "__main__":
    unittest.main()
