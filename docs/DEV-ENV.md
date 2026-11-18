# 일상 개발 환경 안내

이 저장소에서 테스트, 포맷, 토큰 생성, 화면 그림 비교, 커밋·푸시를 하는 일상 작업 안내입니다.
빈 맥에서 처음 개발 환경을 꾸리는 순서는 [SETUP.md](SETUP.md) 를 봅니다.

## 먼저 알아 둘 것

- `tool/fl` 과 `tool/fl_dart` 는 로컬에 지정 버전(Flutter `3.44.0`)이 있으면 로컬 명령을 쓰고, 없으면 도커(`ghcr.io/cirruslabs/flutter:3.44.0`)에서 돌립니다. 로컬 Flutter 가 있더라도 `FL_DOCKER=1` 을 주면 도커로 강제합니다.
- 도커 모드를 쓰려면 git, 도커(`sudo` 없이 실행), 파이썬 3, bash 가 필요합니다. 로컬 모드(맥)에는 도커가 필요 없지만 `tool/shots.sh` 는 골든 때문에 언제나 도커를 씁니다.
- 아이폰과 맥 앱은 맥의 로컬 Flutter 또는 GitHub Actions 의 macOS 러너에서 빌드합니다(아래 CI 절).
- 색, 간격 같은 디자인 값은 `design/tokens.json` 한 파일에서 고치고, 코드가 아니라 값으로 다룹니다. 흐름은 디자인 토큰 절에 있습니다.

## 클론부터 테스트까지

```bash
git clone <저장소 주소> mood-clicker
cd mood-clicker
tool/setup.sh     # 한 번만. 훅을 켜고, Flutter 이미지와 패키지를 받습니다
tool/test.sh      # 테스트 전부
```

`tool/setup.sh` 가 하는 일은 세 가지입니다.

1. `git config core.hooksPath .githooks` 로 git 훅을 켭니다.
2. Flutter 이미지(`ghcr.io/cirruslabs/flutter:3.44.0`, 약 7GB)를 받습니다. 처음 한 번만 오래 걸립니다.
3. `tool/fl pub get` 으로 패키지를 받습니다.

끝나면 `Ready. Hooks: .githooks` 가 나옵니다. 이미지가 이미 있는 컴퓨터에서는 2초 안팎으로 끝납니다.

`tool/test.sh` 는 파이썬 도구 테스트, 응원 문구 검사(`cheers_check.py`), Flutter 테스트(골든 포함)를 차례로 돌리고 전부 통과해야 끝납니다.
골든은 리눅스 도커 이미지 기준이라, 맥에서 로컬 Flutter 로 처음 돌릴 때는 `tool/fl test --exclude-tags golden` 을 씁니다(아래 화면 그림 절).
로컬에 Flutter 가 없는 환경이나 골든 제외 확인만 필요할 때는 `tool/fl test --exclude-tags golden` 으로 단위·위젯 테스트를 빠르게 돌릴 수 있습니다.

## 도구 한눈에 보기

| 명령 | 하는 일 |
|---|---|
| `tool/setup.sh` | 클론 뒤 한 번. 훅, 이미지, 패키지 |
| `tool/test.sh` | 테스트 전부. push 전에 돌리는 것과 같습니다 |
| `tool/fl <flutter 인자>` | 로컬 Flutter `3.44.0` 또는 도커 안에서 `flutter` 를 돌립니다 (`FL_DOCKER=1` 로 도커 강제) |
| `tool/fl_dart <dart 인자>` | 로컬 Dart 또는 도커 안에서 `dart` 를 돌립니다 (`FL_DOCKER=1` 로 도커 강제) |
| `tool/shots.sh` | 화면을 그림(PNG)으로 뽑아 `build/shots/` 에 냅니다. `--check` 는 골든과 비교 |
| `python3 tool/gen_tokens.py` | 디자인 토큰에서 다트 파일을 만듭니다 |
| `python3 tool/subset_fonts.py` | 앱에 넣을 가벼운 글꼴을 만듭니다 |
| `python3 tool/privacy_scan.py` | 개인정보 검사. 훅과 CI 가 부릅니다 |

## 도커로 도는 Flutter

`tool/fl` 과 `tool/fl_dart` 는 저장소 폴더를 컨테이너의 `/app` 에 연결해 명령을 돌리고 끝나면 컨테이너를 지웁니다.
자주 쓰는 명령은 이렇습니다.

```bash
tool/fl test                  # 위젯과 단위 테스트
tool/fl analyze               # 정적 분석. 정상이면 "No issues found!"
tool/fl_dart format lib test  # 코드 모양 정리
tool/fl build apk --debug     # 안드로이드 디버그 앱
tool/fl --version             # Flutter 3.44.0, Dart 3.12.0
```

알아 둘 점이 네 가지 있습니다.

- 패키지 캐시는 도커 볼륨 `mood-clicker-pub-cache` 에, Gradle 캐시는 작업 트리마다 `mood-clicker-gradle-<경로 해시 8자>` 볼륨에 쌓입니다. 두 번째 실행부터 빨라집니다. Gradle 은 캐시에 잠금을 걸어서 한 볼륨을 여러 빌드가 나눠 쓰면 서로 기다리다 시간 초과로 실패하기 때문에 트리마다 나눴습니다. 이름을 직접 정하려면 `FL_GRADLE_VOLUME=<이름>` 을 씁니다. 지우려면 `docker volume rm` 으로 지웁니다.
- 안드로이드 NDK(약 1GB, 풀면 3GB)는 컨테이너가 매번 새로 받으면 느리고 중간에 끊기기 쉬워서, 작업 트리와 상관없이 볼륨 `mood-clicker-android-sdk` 하나를 `ndk` 폴더에만 얹어 한 번 받으면 계속 씁니다. 빌드를 처음 돌릴 때 `tool/fl_container.sh` 가 잠금을 걸고 받기 때문에 두 빌드가 동시에 시작해도 한 번만 받고, 끊기면 세 번까지 다시 시도합니다. CMake 3.22.1 도 같은 방식으로 볼륨 `mood-clicker-android-sdk-cmake` 에 한 번만 받습니다. 이름을 바꾸려면 `FL_ANDROID_SDK_VOLUME=<이름>` 을 쓰고, CMake 볼륨은 그 이름 뒤에 `-cmake` 가 붙습니다.
- 컨테이너는 root 로 돕니다. 그래서 스크립트가 끝날 때 저장소 안의 root 소유 파일을 내 계정 소유로 되돌립니다. 직접 `docker run` 으로 돌리면 이 정리가 빠집니다.
- 이미지 이름은 `FLUTTER_IMAGE` 환경변수로 바꿀 수 있습니다. 버전을 올릴 때는 `tool/fl`, `tool/fl_dart`, `tool/setup.sh`, `.github/workflows/ci.yml`(컨테이너 이름과 `flutter-version`, 두 곳)을 함께 고칩니다.
- 안드로이드 빌드는 처음 한 번 Android SDK 일부를 받습니다. 이번에 확인한 첫 빌드는 1분 40초쯤 걸렸고 결과물 `build/app/outputs/flutter-apk/app-debug.apk` 는 약 140MB 였습니다. 이 폴더는 git 이 무시합니다.

## git 훅과 개인정보 검사

훅은 `.githooks/` 에 있고 `tool/setup.sh` 가 켭니다. 훅 설정은 저장소 하나에 한 번이면 되고, `git worktree` 로 만든 다른 작업 트리에도 같이 적용됩니다.
훅을 건너뛰는 `--no-verify` 는 쓰지 않습니다. 훅이 막으면 이유를 고칩니다.

| 훅 | 시점 | 막는 것 |
|---|---|---|
| `commit-msg` | 커밋 메시지를 쓴 직후 | 첫 줄이 `<type>: <설명>` 이 아닌 것, 메시지 안의 개인정보 |
| `pre-commit` | 커밋 직전 | 스테이징한 변경의 개인정보와 비밀 파일, 토큰 파일과 생성 파일의 불일치, 다트 형식과 분석 오류 |
| `pre-push` | push 직전 | main 이나 master 로 바로 올리기, 올릴 커밋 전체의 개인정보, 테스트 실패 |

- type 은 `feat fix refactor docs test chore perf ci` 중 하나입니다. `feat(scope): 설명` 처럼 괄호로 범위를 붙일 수 있습니다.
- `pre-commit` 의 다트 검사는 스테이징한 `.dart` 파일이 있을 때만 돌고, 생성 파일 `*.g.dart` 는 형식 검사에서 뺍니다.
- `pre-push` 는 `tool/test.sh` 를 돌리므로 push 가 몇 초 걸립니다.
- 막히면 이렇게 풀고 다시 시도합니다. 형식 오류는 `tool/fl_dart format lib test`, 토큰 불일치는 `python3 tool/gen_tokens.py` 를 돌립니다.

### `tool/privacy_scan.py` 가 막는 것

저장소에는 개인정보와 서버 정보를 넣지 않는다는 규칙이 있고, 이 도구가 기계로 지킵니다.
코드, 문서, 테스트, 커밋 메시지, PR 본문이 모두 대상입니다.

| 종류 | 예 |
|---|---|
| 사설 IP, 네트워크 문맥의 공인 IP | 집이나 사무실 망 주소 |
| 실제 이메일 | 문서용 도메인(`example.com` 등)과 `noreply` 주소는 통과합니다 |
| Tailscale 주소 | Tailscale 가 주는 터널 도메인 이름 |
| 운영 서버 경로 | 마운트 경로, appdata, 볼륨 경로 모양 |
| 홈 디렉터리 경로 | 사용자 이름이 들어간 경로 |
| 긴 hex 문자열, 비밀값 대입, 알려진 키 모양 | 토큰, API 키 |
| 소수점 넷째 자리 이상의 좌표 쌍 | 실제 위치를 가리킬 수 있는 값 |
| 비밀 파일 | `.env`, 서명 키, `key.properties`, `google-services.json`, `GoogleService-Info.plist` |

찾아도 값은 출력하지 않고 `파일:줄 종류` 만 알려 줍니다. 예를 들어 사설 IP 가 든 줄을 스테이징하면 `notes.txt:1 IP` 처럼 나옵니다.
대신 쓸 값은 이렇습니다.

- IP: `192.0.2.x`, `198.51.100.x`, `203.0.113.x`
- 이메일과 도메인: `example.com`
- 키와 해시: 눈에 띄게 가짜인 값
- 좌표: 소수 둘째 자리까지만, 또는 바다 한가운데 같은 가짜 값

정말 괜찮은 줄이라면 그 줄에 `privacy-ok` 를 적으면 통과합니다. 실제로 안전한 경우에만 씁니다.

직접 돌려 볼 수도 있습니다.

```bash
python3 tool/privacy_scan.py --staged                    # 스테이징한 변경
python3 tool/privacy_scan.py --message <메시지 파일>      # 커밋 메시지
python3 tool/privacy_scan.py --range origin/main..HEAD   # 커밋 범위
```

## 디자인 토큰 흐름

```
design/tokens.json  →  python3 tool/gen_tokens.py  →  lib/design/tokens.g.dart  →  화면 코드
```

- 디자이너가 고치는 곳은 `design/tokens.json` 한 파일입니다. 구성과 형식은 [DESIGN.md](DESIGN.md) 에 있습니다.
- `lib/design/tokens.g.dart` 는 생성 파일이라 손으로 고치지 않습니다. 고쳤다면 훅과 CI 가 막습니다.
- 화면 코드는 `context.palette`, `Space`, `Radii`, `TypeScale`, `Motion` 만 씁니다. 색이나 숫자를 위젯에 직접 쓰지 않습니다.
- 값을 고친 뒤에는 생성기를 돌리고 테스트합니다. 생성 파일과 토큰 파일을 같은 커밋에 올립니다.

```bash
python3 tool/gen_tokens.py          # 생성 파일을 만듭니다
python3 tool/gen_tokens.py --check  # 맞는지만 봅니다. 훅과 CI 가 쓰는 방식입니다
tool/fl test                        # 글자와 바탕의 대비 검사까지 돕니다
```

생성기는 틀린 곳을 알려 줍니다. 예를 들어 색 자리에 `red` 라고 쓰면 `light.color.ground: 색은 #RRGGBB 나 #RRGGBBAA 로 씁니다` 처럼 어느 값이 왜 틀렸는지 나오고 멈춥니다.

**주의: `tool/fl_dart format lib test` 는 생성 파일의 모양도 바꿉니다.** 그러면 `--check` 가 실패합니다. 서식을 정리한 뒤에는 `python3 tool/gen_tokens.py` 를 한 번 더 돌려 생성 파일을 되돌립니다. 스테이징한 파일만 검사하는 `pre-commit` 은 `*.g.dart` 의 형식을 보지 않으므로 이 순서만 지키면 막히지 않습니다.

## 글꼴 부분집합

한글 글꼴 전체는 파일이 커서, 쓰는 글자만 남긴 판을 앱에 넣습니다.

```
design/fonts/*.otf (원본, 각 1.5MB)  →  python3 tool/subset_fonts.py  →  assets/fonts/*.otf (각 약 350KB)
```

- 남기는 글자는 KS X 1001 한글 2,350자, 한글 자모, 영문과 숫자, 라틴 기본 기호, 일반 문장부호 등입니다. 빠진 드문 글자는 기기의 시스템 글꼴로 그려집니다.
- 이 스크립트만 파이썬 패키지 `fonttools` 가 필요합니다. 없으면 `pip install fonttools` 로 깝니다. 같은 입력이면 같은 결과가 나오며, 지금 저장소의 결과물과 바이트까지 같은 것을 확인했습니다.
- 굵기를 더하려면 원본을 `design/fonts/` 에 넣고 스크립트를 돌린 뒤 `pubspec.yaml` 의 `fonts` 에 적습니다. 글꼴 이름은 `design/tokens.json` 의 `font.family` 와 같아야 합니다.
- 글꼴 라이선스는 `licenses/Pretendard-OFL.txt` 와 `THIRD_PARTY_NOTICES.md` 에 있습니다.

## 화면 그림으로 확인하기

기기나 에뮬레이터 없이 화면을 PNG 로 뽑아 눈으로 확인합니다. 디자이너와 에이전트가 같은 그림을 봅니다.

```bash
tool/shots.sh            # 그림을 새로 뽑습니다 → build/shots/*.png (커밋하지 않습니다)
tool/shots.sh --check    # 커밋된 골든과 비교합니다. 다르면 실패하고 차이 그림이 test/goldens/failures/ 에 생깁니다
tool/shots.sh --update   # 의도한 변경이면 골든을 새 그림으로 바꿉니다
```

디자이너가 토큰을 바꾼 뒤의 순서는 이렇습니다.

1. `design/tokens.json` 을 고치고 `python3 tool/gen_tokens.py` 를 돕니다.
2. `tool/shots.sh` 를 돌립니다. 10초쯤 걸립니다.
3. `build/shots/` 의 그림을 엽니다. 파일 이름은 `<화면>_<테마>_<기기>.png` 입니다. 예: `token_preview_pink_iphone.png`
4. 바뀐 모습이 의도한 것이면 `tool/shots.sh --update` 로 골든을 바꾸고, 바뀐 그림을 열어 확인한 뒤 코드와 함께 커밋합니다.
5. 의도하지 않은 변화가 있으면 `tool/shots.sh --check` 가 어느 그림이 달라졌는지 알려 줍니다. 차이 그림은 `*_masterImage`(기존), `*_testImage`(지금), `*_isolatedDiff`(다른 곳만)입니다.

- 그림은 지금 테마 3개(라이트, 다크, 핑크) × 기기 2개(아이폰 390x844 @3x, 안드로이드 412x915 @2.625)로 뽑힙니다. 화면 한 장은 기기 화면 크기만큼만 담기므로, 스크롤로 넘어가는 아랫부분은 그림에 없습니다.
- 글자는 앱의 진짜 글꼴(Pretendard, Baloo2)로 그려집니다. 아이콘과 이모지는 도커 이미지 안의 Flutter SDK 글꼴(Material 아이콘, Noto Color Emoji)을 씁니다. 이모지 모양은 이 그림용이고 실제 기기에서는 기기의 이모지가 나옵니다.
- 화면을 새로 만들면 `test/goldens/harness.dart` 의 `goldenScreens` 목록에 한 줄을 더합니다. 테마와 기기는 같은 파일의 `goldenThemes`, `goldenDevices` 입니다.
- **골든 비교는 도커에서만 맞습니다.** 골든은 리눅스 도커 이미지에서 뽑았고, 맥이나 다른 환경에서는 같은 화면도 픽셀이 조금 다르게 그려집니다. 그래서 비교는 `tool/shots.sh` 와 CI(같은 이미지를 씁니다)에서만 합니다. 맥에서 `flutter test` 를 직접 돌릴 때는 `--exclude-tags golden` 을 붙입니다. `tool/shots.sh` 는 로컬 Flutter 가 있어도 `FL_DOCKER=1` 로 도커를 강제하므로, 맥에서 골든을 보려면 도커(Docker Desktop)가 필요합니다.
- 허용 오차는 두지 않았습니다. 같은 이미지에서 두 번 돌려 바이트까지 같은 그림이 나왔습니다. CI 가 로컬과 다르게 나오는 일이 실제로 생기면 그때 근거와 함께 아주 작게 둡니다.
- CI 에서 비교가 실패하면 차이 그림이 `golden-diffs` 이름의 산출물로 올라갑니다.

## CI

`.github/workflows/ci.yml` 이 PR 과 main 으로의 push 마다 돕니다. 결과가 초록이어야 합칩니다.

| 작업 | 환경 | 하는 일 |
|---|---|---|
| `check` | 리눅스, Flutter 이미지 | PR 의 커밋 개인정보 검사, 파이썬 테스트, `pub get`, 토큰 일치, 다트 형식, `analyze`, `flutter test`, 화면 그림 비교(골든), 안드로이드 디버그 빌드 |
| `apple` | macOS, `check` 가 통과한 뒤 | 아이폰 디버그 빌드(서명 없이), 맥 디버그 빌드 |

개인정보 검사는 GitHub 가 만든 병합 커밋이 아니라 PR 에 실제로 들어 있는 커밋만 봅니다. 로컬 `tool/test.sh` 가 통과하면 `check` 의 대부분은 통과합니다.

## 에이전트 설정

코딩 에이전트(Claude Code 등)가 이 저장소에서 지킬 규칙을 파일로 둡니다.

| 파일 | 내용 |
|---|---|
| `AGENTS.md` | 에이전트용 규칙. 하지 않을 일, 확인 명령, git 규칙, 개인정보, 글쓰기. 사람은 README 부터 봅니다 |
| `CLAUDE.md` | `@AGENTS.md` 한 줄. Claude Code 가 같은 규칙을 읽게 하는 연결이라 규칙은 한 곳에서만 고칩니다 |
| `.claude/settings.json` | Claude Code 설정. 쓰는 플러그인(pstack, eli5)과, 확인 명령(`tool/fl`, `tool/fl_dart`, `privacy_scan`, `unittest`)을 묻지 않고 돌리는 허용 목록, 아래 훅 연결 |
| `.claude/hooks/` | Claude Code 훅. 아래 "Claude 훅" 절 |
| `tool/team/` | 여러 에이전트 세션을 tmux 에 띄우고 서로 말을 주고받는 도구. `tool/team/README.md` |

개인 설정은 `.claude/settings.local.json` 에 두면 되고, 이 파일은 git 이 무시합니다.
규칙을 바꾸면 사람이 읽는 문서(이 문서, README)와 `AGENTS.md` 가 어긋나지 않게 함께 고칩니다.

## Claude 훅

`.claude/hooks/` 의 파이썬 파일이 Claude Code 가 Bash 를 부르기 전에 명령을 검사하고, 어긋나면 거절하면서 고칠 방법을 알려 줍니다. `python3` 만 있으면 되고 `.claude/settings.json` 의 `hooks` 에 `$CLAUDE_PROJECT_DIR` 기준 상대 경로로 연결돼 있어 클론하면 바로 켜집니다. 이 훅은 에이전트를 막을 뿐이고 사람이 터미널에서 치는 명령에는 닿지 않습니다. 사람 쪽은 `.githooks` 가 막습니다.

| 파일 | 막는 것 | 대신 할 일 |
|---|---|---|
| `push_guard.py` | `main`, `master` 로 push(`--all`, `--mirror`, 인자 없는 push 를 main 에서 칠 때 포함), 같은 명령 안에서 `tool/test.sh &&` 로 테스트를 먼저 돌리지 않은 push | 브랜치를 올리고 PR 로 합칩니다. `tool/test.sh && git push -u origin <브랜치>` 로 한 명령에 묶습니다 |
| `no_verify_guard.py` | `--no-verify`, `git commit -n`, `core.hooksPath` 바꾸기 | 훅이 알려 준 것을 고치고 플래그 없이 다시 합니다 |
| `stash_guard.py` | 이름 없는 `git stash`, 참조 없는 `stash pop`, `apply`, `drop` | stash 목록은 모든 worktree 가 같이 쓰므로 `git stash push -m "<무엇>"` 로 이름을 붙이고 `git stash pop stash@{n}` 로 가리킵니다 |
| `idle_guard.py` | 아무 일도 안 하는 호출, `sleep` 만 하는 호출, `sleep` 이 든 폴링 루프, 30초가 넘는 전경 `sleep`, 늘지 않은 백그라운드 작업 출력 파일 다시 읽기 | Bash 한 번은 명령이 무엇이든 대화 전체를 다시 청구하므로, 오래 걸리면 `run_in_background`, 조건을 기다리면 Monitor 의 `until` 을 한 번만 씁니다 |

공통 파서 `shellparse.py` 는 따옴표와 heredoc 안의 글을 명령으로 읽지 않고, `bash -c "..."` 안과 `&&`, `;`, `|` 로 이은 명령을 따로 봅니다. 테스트는 `tool/test_claude_hooks.py` 이고 `tool/test.sh` 가 같이 돌립니다. 훅을 고칠 때는 오탐(정상 명령을 막는 것)이 제일 큰 위험이라서 "통과해야 하는 명령" 목록에도 케이스를 먼저 추가합니다. 급할 때는 개인 설정 `.claude/settings.local.json` 에서 훅을 끄면 되지만, 규칙이 마음에 안 들면 끄지 말고 고칩니다.

## 다섯 세션 팀 운영

지금은 에이전트 세션 다섯이 나눠 일합니다. 운영 규칙과 작업 큐는 [TEAM.md](TEAM.md) 에 있고 이 파일은 팀장 세션만 고칩니다.
넘겨받은 뒤 세션을 이렇게 쓰지 않아도 되지만, 여러 세션이 한 저장소에서 부딪히지 않게 하는 방식은 참고가 됩니다.

- 세션마다 작업 트리를 따로 씁니다. 원래 폴더는 팀장 자리입니다.

  ```bash
  git -C <원래 폴더> worktree add ../mood-clicker-<이름> -b <브랜치> <기준 커밋>
  ```

- 맡은 경로 밖의 파일은 고치지 않고, 필요하면 먼저 묻습니다.
- 커밋까지만 합니다. push, PR, 합치기는 팀장이 합니다.
- 끝나면 팀장에게 브랜치, 커밋, 세 줄 요약, 명세와 다르게 판단한 점을 보고합니다.
- 막히면 30분 넘게 붙들지 않고 이유를 보고합니다.

작업 트리를 새로 만든 직후에는 `.dart_tool` 이 없으므로 `tool/fl pub get`(또는 `tool/setup.sh`)을 한 번 돌린 뒤 테스트합니다. 훅 설정은 이미 공유되어 있습니다.

## 확인한 환경

- 확인일: 2026-11-19
- Linux, 파이썬 3.14, Flutter 3.44.0 (도커 이미지)
- `tool/test.sh`: 파이썬 도구 테스트, 응원 문구 검사, Flutter 테스트(골든 포함) 전부 통과
- macOS 로컬 Flutter 자동 선택(`FL_DOCKER=1` 미지정)은 맥이 없어 직접 확인하지 못했습니다.
