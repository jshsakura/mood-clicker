# Setup guide for coding agents

This document is written for a coding agent (Claude Code, Codex, or similar) that sets up a new machine for this repository: the build environment, the git hooks, the agent guards, and, optionally, the multi-agent team tools. Humans read [DEV-ENV.md](DEV-ENV.md) (Korean), [SETUP.md](SETUP.md) for a fresh Mac, and [HARNESS.md](HARNESS.md) for how the team works.

## For the human

Open your agent in the repository folder (or the folder above it) and paste one line:

```text
Read docs/AI_SETUP.md and set up this machine exactly as it says. Show the real output of every check, and stop at every "ASK THE HUMAN".
```

If the repository is not cloned yet:

```text
Clone https://github.com/jshsakura/mood-clicker, then follow docs/AI_SETUP.md. Show the real output of every check, and stop at every "ASK THE HUMAN".
```

The agent reports in the language you write to it. Expect 10 to 20 minutes, most of it downloading the Flutter image (about 7 GB) and, if you ask for a build, the Android NDK.

---

## Instructions for the agent

Work top to bottom, one step at a time. Every step has a **Check** with the output that counts as a pass. Decide pass or fail from the actual output you saw, and quote one line of it in the final report. Never mark a step as passed without running its check.

### Ground rules

1. **Do not install Flutter on the host.** `tool/fl` runs Flutter `3.44.0` from the docker image `ghcr.io/cirruslabs/flutter:3.44.0`. If a `flutter` on `PATH` is exactly `3.44.0`, `tool/fl` uses it instead; any other version is ignored with a notice on stderr. `FL_DOCKER=1` forces docker.
2. **ASK THE HUMAN before** any `sudo`, any package install, adding the user to a group, changing global git config (`user.name`, `user.email`, `core.*`), or signing in to any service.
3. **Never bypass hooks.** No `--no-verify`, no `git commit -n`, no changing `core.hooksPath` away from `.githooks`. When a hook blocks you, read its message and fix the cause.
4. **Never edit or delete a failing test to make it pass.** Decide whether the failure is environmental (docker, memory, network). If it is not, report it as is.
5. **No personal or server data in repository files**: no real IPs, hostnames, domains, emails, names, coordinates, keys or tokens. Use `192.0.2.x`, `example.com`, and obviously fake keys. `tool/privacy_scan.py` blocks these at commit and push time.
6. **Long commands run in the background.** Start the command once and wait for it to finish. Do not loop on `sleep` or re-read the same log to check progress; the agent guard `idle_guard.py` blocks that pattern.
7. **Do not commit during setup.** Setup changes nothing that is tracked. If `git status --short` shows tracked changes at the end, something went wrong: report it.

### Step 1. Check the environment

```bash
uname -sm; git --version; python3 --version; docker --version; tmux -V; gh --version | head -1
docker info > /dev/null && echo "docker daemon ok"
```

**Required:** `git`, `python3`, `docker` with a running daemon.
**Optional:** `tmux` and `gh`, needed only for step 6 and for iOS builds through CI.

If something is missing, propose the install command for the OS and **ASK THE HUMAN** before running it:

| OS | Typical install |
|---|---|
| Ubuntu or Debian | `sudo apt install git python3 tmux gh` and Docker Engine from docs.docker.com |
| macOS | `brew install git python tmux gh` and Docker Desktop |
| Windows | Use WSL2 with Ubuntu and follow the Ubuntu row. The shell scripts need bash |

Known problems:

| Symptom | Cause | What to do |
|---|---|---|
| `permission denied while trying to connect to the Docker daemon socket` | The user is not in the `docker` group | ASK THE HUMAN. Adding the group (`sudo usermod -aG docker $USER`, then a new login) is their decision |
| `Cannot connect to the Docker daemon` | Docker is not running | Ask the human to start Docker Desktop, or `sudo systemctl start docker` with permission |
| Docker Desktop memory under 6 GB | Tests run in a 4 GB container, Android builds ask Gradle for 8 GB | Tell the human to raise the Docker Desktop memory limit to 8 GB or more |

**Check:** each required tool prints a version, and `docker daemon ok` is printed.

### Step 2. Clone and enable the git hooks

Skip the clone if the repository is already there.

```bash
git clone https://github.com/jshsakura/mood-clicker.git && cd mood-clicker
tool/setup.sh
```

`tool/setup.sh` does three things: sets `core.hooksPath` to `.githooks`, pulls the Flutter image when no matching local Flutter exists, and runs `tool/fl pub get`. The first run downloads about 7 GB, so start it in the background.

**Check:**

```bash
git config core.hooksPath     # prints: .githooks
```

The last line of `tool/setup.sh` is `Ready. Hooks: .githooks`.

What the git hooks do (they apply to humans and agents alike):

| Hook | Blocks |
|---|---|
| `pre-commit` | Personal data and secret files (`privacy_scan.py`), AI tells such as em dashes, curly quotes and debug prints, Hangul in new code lines (`slop_scan.py`), ARB key mismatches (`l10n_check.py`), cheer phrase rule violations (`cheers_check.py`), design tokens out of sync with generated files, Dart format and analyzer errors |
| `commit-msg` | A first line that is not `<type>: <summary>` with type `feat fix refactor docs test chore perf ci`, plus the same privacy and slop scans on the message |
| `pre-push` | Any push to `main` or `master`, then rescans every outgoing commit and runs `tool/test.sh` |

### Step 3. Run the full test suite

```bash
tool/test.sh
```

It runs, in order: the Python tool tests (`python3 -m unittest discover -s tool -p 'test_*.py'`), the cheer phrase check, and `tool/fl test` (widget, unit and golden tests). About 40 seconds after the first run; the first run is slower.

**Check:** the last line contains `All tests passed!`. One skipped test (`~1`) is normal.

| Symptom | Cause | What to do |
|---|---|---|
| `Killed` or exit code 137 | The test container hit its 4 GB cap, or Docker has too little memory | Retry once with `FL_TEST_MEMORY=6g tool/test.sh`. If it still fails, tell the human about the Docker memory limit |
| Golden test failures with pixel differences | Rendering differs from the pinned environment (usually a local Flutter on a different OS) | Rerun with `FL_DOCKER=1 tool/test.sh`. Never regenerate goldens during setup |
| `pub get` errors in a fresh worktree | `.dart_tool` does not exist yet | Run `tool/fl pub get` once, then retry |

### Step 4. Verify the agent guards

The repository ships guards that run before every shell command an agent executes. They block: pushing to `main` or `master`, a `git push` that is not preceded by `tool/test.sh &&` in the same command, `--no-verify` and `git commit -n`, changing `core.hooksPath`, a bare `git stash` or `git stash pop` (the stash list is shared by every worktree), and idle polling (`sleep` loops, foreground sleeps over 30 seconds, re-reading an unchanged background log).

Do only the part for the product you are.

**Claude Code.** `.claude/settings.json` already wires the four guards (`push_guard.py`, `no_verify_guard.py`, `stash_guard.py`, `idle_guard.py`) through `$CLAUDE_PROJECT_DIR`. Nothing to install. Verify one:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"git stash"},"cwd":"."}' | python3 .claude/hooks/stash_guard.py
```

**Check:** a JSON object containing `"permissionDecision": "deny"`.

The project also enables two plugins (`pstack`, `eli5`) from marketplaces listed in the same file. If Claude Code asks whether to trust or install them, **ASK THE HUMAN**. Personal overrides go in `.claude/settings.local.json`, which git ignores.

**Codex.** `.codex/hooks.json` runs the same four guards through `.claude/hooks/codex_adapter.py`, which turns Codex's `exec_command` and `shell` tool calls into the shape the guards read. The first time Codex opens the repository it asks whether to trust the project hooks: tell the human to allow it. Verify the adapter:

```bash
echo '{"tool_name":"exec_command","tool_input":{"cmd":"git stash"},"cwd":"."}' | python3 .claude/hooks/codex_adapter.py stash_guard.py
```

**Check:** a JSON object containing `"permissionDecision": "deny"`. `tool/test_codex_hooks.py` (part of `tool/test.sh`) keeps the Codex guard list identical to the Claude one.

**Any other agent.** There is no hook integration. Follow `AGENTS.md` by hand. The git hooks from step 2 still block bad commits and pushes.

### Step 5. Android build (optional, ASK THE HUMAN whether to do it)

```bash
tool/fl build apk --debug
```

The first build downloads the Android NDK and CMake into shared docker volumes (`mood-clicker-android-sdk` and `mood-clicker-android-sdk-cmake`, about 3 GB, once per machine) and takes about 7 minutes. Run it in the background. If the download times out on a slow network, run the same command once more; it resumes from the volume.

**Check:** `Built build/app/outputs/flutter-apk/app-debug.apk`.

Release builds and the signing key:

- The release signing key is **not** in the repository. `android/key.properties` and `android/app/release.jks` are git-ignored.
- **Never generate a new key.** A build signed with a different key cannot be installed over earlier test builds, and the same key signs store updates.
- Without the key, Gradle signs release builds with the debug key. That is fine for local use.
- If the human wants release builds that update the team's test builds, **ASK THE HUMAN** for the key files, place them at those two paths, and confirm they are ignored:

  ```bash
  git check-ignore android/key.properties android/app/release.jks   # must print both paths
  ```

- Team test builds use `tool/fl build apk --release --split-per-abi` and ship the arm64 file (about 39 MB).

iOS builds need macOS. Without a Mac, build an unsigned IPA on CI (requires `gh` signed in with access to the repository):

```bash
gh workflow run ios-test.yml --ref <branch>
gh run list --workflow ios-test.yml --limit 1          # get the run id
gh run watch <run-id> --exit-status
gh run download <run-id> -n ios-unsigned
```

The iOS minimum version is 15.5 (required by the MapLibre package). Do not run this during setup unless asked.

### Step 6. Team tools (optional, ASK THE HUMAN whether they want a multi-agent team)

```bash
gh auth status            # if not signed in, the human runs `gh auth login` themselves
tool/team/itl doctor      # checks tmux and the pane registry
```

`tool/team/start.sh` opens one tmux session with a leader pane and one pane per worker. Each worker gets its own git worktree at `../<repo>-<name>` on branch `work/<name>`. Examples are in `tool/team/README.md`:

```bash
tool/team/start.sh claude ui api                 # leader and workers run claude
tool/team/start.sh claude ui=codex research=agy  # a different product per worker
tmux attach -t <session>
```

Rules the team follows (details in `docs/HARNESS.md`):

- Workers change only their own scope in their own worktree and stop at a commit. Only the leader merges, pushes and opens PRs.
- Work is merged with `--no-ff` into `integrate/poc`, tested with `tool/test.sh && git push origin integrate/poc`, and reaches `main` only through a PR.
- A worker reports to the leader with `tool/team/itl send <leader> '...'`: branch, commit hash, a three line summary, where it departed from the spec, and the checks it actually ran, including failures and skips.
- In a new worktree, run `tool/fl pub get` once before testing.

### Step 7. Read before doing any work

Read these three files and say in the report that you read them:

- `AGENTS.md`: what not to do, the check commands, git and privacy rules, writing rules.
- `docs/LESSONS.md`: mistakes this team actually made and the check that now prevents each one.
- `docs/HARNESS.md`: roles and how one task flows from assignment to merge.

### Step 8. Final report

Show this table to the human, filled in. Report skipped and failed steps as they are.

| Step | Result | Evidence (one real output line) |
|---|---|---|
| 1. Environment | | |
| 2. Clone and git hooks | | |
| 3. Tests | | |
| 4. Agent guards | | |
| 5. Android build | done / skipped | |
| 6. Team tools | done / skipped | |
| 7. Documents read | | |

Then list anything the human still has to decide or do: installs waiting for permission, the signing key, plugin trust, Codex hook trust, `gh` sign-in, team layout.
