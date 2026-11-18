# Development harness

This repository holds the app and also the way the app gets built. One person runs several coding agents
as a team, and machine checks stop mistakes instead of someone's memory. Cloning the repository is enough
to work the same way. No rule should live only in personal config such as `~/.claude`.

Korean: [HARNESS.md](HARNESS.md)

## At a glance

```
Person (decides)
  └─ Lead agent: splits work, assigns it, reviews it, merges it
       ├─ Worker: development      ┐
       ├─ Worker: research         ├─ each in its own git worktree and branch, commits only
       └─ Worker: adversarial review┘
                    │
   Machine checks: git hooks → Claude hooks → CI → test distribution
```

| Layer | Where | What it does |
|---|---|---|
| Rules | `AGENTS.md`, `CLAUDE.md` | Every agent reads these first. Claude, Codex, Antigravity and opencode share the same file |
| Machine checks | `.githooks/`, `.claude/hooks/`, `.github/workflows/` | Reject rule breaks at commit, push or command time |
| Skills | `.claude/skills/` | Bundle the steps and reference docs for recurring jobs |
| Team tools | `tool/team/` | Send work between tmux panes (`itl`) and start the team in one command (`start.sh`) |

## Setup

You need Docker, git, python3, tmux, the GitHub CLI (`gh`) and the agents you plan to use (Claude Code and others).
Flutter lives in a Docker image, so do not install it on the host.

```bash
git clone <repo> && cd <repo>
tool/setup.sh              # turns on the git hooks and fetches packages
tool/test.sh               # everything must pass before you start
tool/team/start.sh         # opens one lead pane and N worker panes; see tool/team/README.md
```

Install details and first build times are in [DEV-ENV.md](DEV-ENV.md).

## Roles

| Role | Does | Does not |
|---|---|---|
| Person | Decides what to build and what is right. Judges feel on a real device | Does not need to direct code details |
| Lead | Splits work into numbered tasks (T1, T2, …), reviews reports, merges them into the integration branch, pushes after tests. The only editor of `docs/TEAM.md` | Does not edit inside a worker's branch |
| Worker (development) | Changes only its assigned paths in its own worktree and commits | Does not push, open PRs or merge |
| Worker (research) | Writes findings with sources and access dates | Does not recommend without evidence |
| Worker (adversarial review) | Tries to break someone else's work and reports problems by severity | Does not change code |

Mix agent vendors. The same model misses the same things, so a different vendor reviews the work.

## How one task runs

1. **Assign.** The lead sends it with `tool/team/itl send <name> '…'`, all in one message:
   - task number, branch name, base commit
   - scope: paths to change and paths to leave alone
   - done criteria: which checks must pass and what must actually run
   - anything the person has not decided yet goes behind a single constant
2. **Work.** The worker stays in its own worktree.
   `git worktree add ../<repo>-<name> -b <branch> <base commit>`
3. **Report.** The worker commits and sends `itl send <lead pane> '…'` with the branch and commit, a
   three-line summary, where it departed from the spec, what it actually ran (pass counts, time taken)
   and what is left. Failures and skipped steps go in too.
4. **Review and merge.** The lead reads the change, merges it into the integration branch with `--no-ff`
   and runs `tool/test.sh && git push` as one command. Conflicts go back to the worker who wrote the code.
5. **CI and distribution.** CI builds Android, iOS and macOS. The iOS test build comes out as an unsigned
   `.ipa` artifact. Test distribution only ships files built from the same commit.
6. **To `main`.** When the integration branch is ready, one PR merges it into `main`. Nothing reaches
   `main` except through a PR.

Panes are addressed by name. `start.sh` names the lead pane `leader` and each worker pane by the name you give
(`ui`, `api` and so on). `itl send` prefixes the sender, as in `[from ui · reply: itl send ui '…']`, so the receiver
can answer right away. When this repository was first built, panes were tmux tab numbers (`12.1` lead, `12.2` to
`12.6` workers). Those numbers in the records are the same roles.

Every brief and report, exactly as written, is kept by role in [prompts/](prompts/README.md) (Korean). The task list is in [TEAM.md](TEAM.md).

## Rules the machine enforces

Rules that depend on memory get broken. A rule broken once becomes a check.

| Rule | Enforced by | Why it exists |
|---|---|---|
| No personal or server data | `privacy_scan.py`: pre-commit, commit-msg, pre-push, CI | The repository is public. A real IP, domain, email, home path or key stays in history even after deletion |
| No AI tells or decoration | `slop_scan.py`: same places | Catches dashes used as connectors, decorative emoji, Korean in code, gradients and shadows |
| No push without tests | `.githooks/pre-push`, Claude hook | Tests once inherited hook environment variables and committed fake commits to the integration branch. `test_git_isolation.py` now pins this |
| No direct push to `main`, no skipped hooks | pre-push, Claude hook | One `--no-verify` turns every check above off |
| No bare use of the shared stash | Claude hook | Worktrees share one stash and can pop someone else's change |
| No repeated waiting and checking | Claude hook | Every agent tool call rereads the whole conversation, however cheap the command. Run long jobs in the background and wait for the notice |
| All three languages have the same keys | `l10n_check.py` | Changing one language and moving on happens often |
| Design values only in tokens | `gen_tokens.py --check` | Hard-coded colors and spacing scatter the places a designer has to touch |
| Cheer phrases follow the evidence rules | `cheers_check.py` | Blocks exclamation marks, emoji, laughter and banned words for angry, sad and anxious moods |
| Do not move on while CI is red | GitHub PR checks | The iOS build failed quietly for a day. Linux cannot compile iOS code, so nobody saw it |

Every hook and checker has tests (`tool/test_*.py`, `tool/test_fl_wrapper.sh`). False positives are a
checker's real risk, so tests include cases that must pass. Mark a line `privacy-ok` or `slop-ok` only
when it is truly safe.

## Habits people keep

These are hard to check by machine and get looked at in review.

- **Report real results.** Write the command you ran and what it printed, not "it should work". Report
  failed and skipped steps too. Haptic and animation feel is judged only on a real device.
- **Evidence first.** The app is for people with depression, so even a single phrase follows published
  research: research report ([EVIDENCE.md](EVIDENCE.md)) → six core values ([PRINCIPLES.md](PRINCIPLES.md))
  → check rules (`tool/cheers_rules.json`) → checker → skill. When the evidence changes, update from the top.
- **Batch exploration.** Do not chain calls that each peek at one slice of a file. Decide the files and
  ranges first and pull them in one call.
- **Keep going on reversible work.** Hide things the person must decide (names, policies, anything that
  conflicts with a principle such as showing comparisons) behind one constant and continue. Ask first
  before anything hard to undo (publishing, deleting, releasing).
- **Do not stay stuck.** After 30 minutes, report why you are stuck.
- **No leftover copies.** Do not create `.bak` or `.old` files. git already holds the history.

## Skills

They live in `.claude/skills/` and agents load them on their own when the job matches.

| Skill | When |
|---|---|
| `cheers-write` | Writing or editing cheer phrases |
| `principles-check` | Checking a feature, screen or phrase against the core values and safety rules |
| `l10n-add` | Adding UI copy keys |

Keep skills short and point at the reference docs in the repository. A rule written in two places goes
stale in one of them.

## File map

| Path | Contents |
|---|---|
| `AGENTS.md` | Shared agent rules. `CLAUDE.md` imports it |
| `docs/HARNESS.md` | How we work (this document in Korean) |
| `docs/TEAM.md` | Task board: roles, queue, open items |
| `docs/prompts/` | The real briefs and reports, verbatim, by role (Korean) |
| `docs/DEV-ENV.md` | Dev environment, Docker, cache volumes |
| `docs/PRINCIPLES.md`, `docs/EVIDENCE.md` | Core values and their evidence |
| `docs/SPEC.md`, `docs/DESIGN.md`, `docs/I18N.md`, `docs/PRIVACY.md` | Spec, design, localization, privacy |
| `.githooks/` | Commit and push checks |
| `.claude/settings.json`, `.claude/hooks/` | Claude Code plugins, allowed commands, hooks |
| `.claude/skills/` | Project skills |
| `.github/workflows/` | CI and the iOS test build |
| `tool/` | Docker Flutter runner (`fl`), checkers, generators and their tests |
| `tool/team/` | Team tools (`itl`, `start.sh`) |

## Taking it to another project

The parts that do not depend on the app carry over as they are.

1. Take the git, privacy and writing sections of `AGENTS.md` plus `CLAUDE.md`, and rewrite the project description.
2. Take `tool/privacy_scan.py`, `tool/slop_scan.py` and their tests, `.githooks/` and `tool/setup.sh`.
   Turn off or change project rules such as "no Korean in code" or the flat style in `slop_scan.py`.
3. Take the hooks and settings in `.claude/` and `tool/team/`.
4. Rewrite `docs/HARNESS.md` and `docs/TEAM.md` for the new project.
5. When the first incident happens, add one checker and one test on the spot. That is how the harness grows.
