"""Runs tool/test_fl_wrapper.sh so that unittest discovery (hook, CI, tool/test.sh) covers the shell wrappers."""
import os
import subprocess
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("test_fl_wrapper.sh")


class FlWrapper(unittest.TestCase):
    def test_wrappers_choose_local_flutter_or_docker(self):
        done = subprocess.run(["bash", str(SCRIPT)], capture_output=True, text=True, timeout=120)
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)

    def test_a_developer_environment_does_not_change_the_verdict(self):
        env = {**os.environ, "FL_ANDROID_SDK_VOLUME": "mine", "FL_GRADLE_VOLUME": "mine-gradle", "FL_DOCKER": "1"}
        done = subprocess.run(["bash", str(SCRIPT)], capture_output=True, text=True, timeout=120, env=env)
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)


if __name__ == "__main__":
    unittest.main()
