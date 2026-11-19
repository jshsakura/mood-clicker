# AI 에게 맡기는 세팅 안내

새 컴퓨터에서 이 저장소의 개발 환경과 하네스(규칙, 훅, 팀 도구)를 코딩 에이전트가 직접 세팅하도록 쓴 문서입니다.
사람이 읽는 설치 설명은 [DEV-ENV.md](DEV-ENV.md), 맥 처음부터는 [SETUP.md](SETUP.md), 일하는 방법은 [HARNESS.md](HARNESS.md) 에 있습니다.

## 사람이 할 일

에이전트(Claude Code, Codex 등)를 저장소 폴더나 그 위에서 열고 아래 한 줄을 붙여 넣습니다.

```text
docs/AI_SETUP.md 를 읽고 그대로 이 컴퓨터를 세팅해 줘. 단계마다 확인 결과를 보여 주고, 문서에 "사람에게 묻습니다" 라고 적힌 곳에서는 멈추고 물어봐.
```

저장소를 아직 받지 않았다면 이렇게 붙여 넣습니다.

```text
https://github.com/jshsakura/mood-clicker 를 받아서 docs/AI_SETUP.md 대로 세팅해 줘. 단계마다 확인 결과를 보여 주고, "사람에게 묻습니다" 에서는 멈춰.
```

---

## 에이전트에게

여기부터는 세팅을 맡은 에이전트가 따르는 지시입니다. 위에서 아래로 한 단계씩 진행하고, 단계마다 "확인" 명령의 실제 출력을 근거로 통과 여부를 판단합니다. 출력 없이 통과라고 적지 않습니다.

### 지킬 것

- 호스트에 Flutter 를 깔지 않습니다. Flutter 는 도커 이미지 안에 있고 `tool/fl` 이 그것을 부릅니다.
- `sudo` 가 필요한 설치, 시스템 설정 변경, 전역 git 설정 변경은 하기 전에 사람에게 묻습니다.
- git 훅을 끄거나 `--no-verify` 로 건너뛰지 않습니다. 훅이 막으면 이유를 읽고 고칩니다.
- 실패한 테스트를 고치거나 지우지 않습니다. 세팅 문제인지 확인하고, 아니면 그대로 보고합니다.
- 실제 IP, 도메인, 이메일, 이름, 좌표, 키를 저장소 파일에 쓰지 않습니다.
- 오래 걸리는 명령(이미지 받기, 첫 빌드)은 백그라운드로 띄우고 끝날 때까지 기다립니다. 같은 확인을 반복해서 묻지 않습니다.

### 1. 환경 확인

```bash
uname -s; git --version; python3 --version; docker --version; tmux -V; gh --version | head -1
```

- `git`, `python3`, `docker` 는 필수입니다. 없으면 설치 방법을 운영체제에 맞게 제안하고 **사람에게 묻습니다**.
- 도커 데몬이 도는지 `docker info > /dev/null && echo ok` 로 봅니다. 권한 오류면 사람에게 알립니다(사용자를 docker 그룹에 넣는 일은 사람이 정합니다).
- `tmux`, `gh` 는 팀으로 일할 때만 필요합니다(6단계). 없어도 계속합니다.

### 2. 저장소와 git 훅

저장소 폴더 안에서 실행합니다.

```bash
tool/setup.sh
```

확인: 마지막 줄이 `Ready. Hooks: .githooks` 입니다. 처음에는 도커 이미지(약 7GB)를 받느라 몇 분 걸립니다.

```bash
git config core.hooksPath
```

확인: `.githooks`.

### 3. 테스트

```bash
tool/test.sh
```

확인: 파이썬 도구 테스트, 응원 문구 검사, Flutter 테스트가 끝까지 돌고 마지막에 `All tests passed!` 가 나옵니다. 처음 한 번은 1분 안팎입니다.
실패하면 실패한 테스트 이름과 첫 오류 몇 줄을 보고합니다. 도커 메모리 부족(`Killed`, 종료 코드 137)이면 세팅 문제이니 사람에게 알립니다.

### 4. 에이전트 훅

이 저장소는 에이전트가 명령을 실행하기 전에 검사하는 가드를 둡니다(`main` 으로 push, 테스트 없는 push, `--no-verify`, 이름 없는 `git stash`, 기다리기만 하는 폴링). 자기 제품에 맞는 절만 합니다.

**Claude Code**: `.claude/settings.json` 이 훅을 이미 연결하므로 따로 할 일이 없습니다. 가드가 도는지 확인합니다.

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"git stash"},"cwd":"."}' | python3 .claude/hooks/stash_guard.py
```

확인: `"permissionDecision": "deny"` 가 든 JSON 이 나옵니다. 저장소가 쓰는 플러그인(pstack, eli5)을 설치할지 Claude Code 가 물으면 **사람에게 묻습니다**.

**Codex**: `.codex/hooks.json` 이 같은 가드를 `.claude/hooks/codex_adapter.py` 로 돌립니다. Codex 를 처음 열 때 훅을 신뢰할지 물으면 허용하도록 사람에게 알립니다. 어댑터를 확인합니다.

```bash
echo '{"tool_name":"exec_command","tool_input":{"cmd":"git stash"},"cwd":"."}' | python3 .claude/hooks/codex_adapter.py stash_guard.py
```

확인: `"permissionDecision": "deny"` 가 나옵니다.

**그 밖의 에이전트**: 에이전트 훅이 없습니다. `AGENTS.md` 의 규칙을 그대로 지키고, 커밋과 push 는 `.githooks` 가 막습니다.

### 5. 안드로이드 빌드 (선택)

```bash
tool/fl build apk --debug
```

확인: `Built build/app/outputs/flutter-apk/app-debug.apk`. 처음에는 NDK 와 CMake 를 받느라 7분쯤 걸리고 회선이 나쁘면 끊깁니다. 끊기면 같은 명령을 한 번 더 실행합니다.

**릴리스 빌드의 서명 키는 저장소에 없습니다.** 테스트 빌드를 이전 빌드 위에 덮어 설치하려면 팀이 쓰는 같은 키가 필요하고, 스토어 업데이트도 이 키로 서명합니다.

- 키를 **새로 만들지 않습니다.** 다른 키로 서명한 빌드는 기존 설치 위에 깔리지 않습니다.
- 키가 필요하면 **사람에게 묻습니다.** 받은 파일은 `android/key.properties` 와 `android/app/release.jks` 에 둡니다.
- 둔 뒤 `git check-ignore android/key.properties android/app/release.jks` 가 두 줄을 출력하는지 확인합니다(커밋되지 않는다는 뜻입니다).

아이폰 빌드는 맥이나 CI(`gh workflow run ios-test.yml --ref <브랜치>`)에서 합니다. 이 단계에서는 하지 않습니다.

### 6. 팀으로 일할 때 (선택)

사람이 여러 에이전트를 같이 돌리려는 경우에만 합니다. 할지 **사람에게 묻습니다**.

```bash
gh auth status                 # 로그인 안 돼 있으면 사람이 gh auth login 을 직접 실행합니다
tool/team/itl doctor           # tmux 와 팬 점검
```

팀 띄우기 예시는 `tool/team/README.md` 에 있습니다(`tool/team/start.sh claude ui api`). 작업자는 각자 `../<저장소>-<이름>` worktree 에서 일하고, 새 worktree 에서는 `tool/fl pub get` 을 한 번 돌린 뒤 테스트합니다.

### 7. 일 시작 전에 읽을 것

세팅이 끝나면 이 셋을 읽고, 읽었다고 보고에 적습니다.

- `AGENTS.md`: 하지 않을 일, 확인 명령, git 과 개인정보 규칙
- `docs/LESSONS.md`: 이 팀이 실제로 한 실수와 그것을 막는 검사
- `docs/HARNESS.md`: 역할과 일 하나가 도는 순서

### 8. 마지막 보고

아래 표를 채워 사람에게 보여 줍니다. 건너뛴 단계와 실패한 단계도 그대로 적습니다.

| 단계 | 결과 | 근거(실제 출력 한 줄) |
|---|---|---|
| 1. 환경 | | |
| 2. 저장소와 git 훅 | | |
| 3. 테스트 | | |
| 4. 에이전트 훅 | | |
| 5. 안드로이드 빌드 | 했음 / 건너뜀 | |
| 6. 팀 도구 | 했음 / 건너뜀 | |
| 7. 읽은 문서 | | |

그리고 사람이 정해야 할 것이 남았으면 목록으로 적습니다(설치 허락, 서명 키, 플러그인, 팀 구성).
