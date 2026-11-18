# 개발 환경 안내

이 저장소를 처음 받는 사람이 클론부터 테스트까지 돌릴 수 있게 쓴 문서입니다.
적힌 명령은 모두 새 작업 트리에서 실제로 돌려 본 것입니다. 확인한 환경은 맨 아래에 있습니다.

## 먼저 알아 둘 것

- 컴퓨터에 Flutter 를 깔지 않습니다. Flutter SDK 는 도커 이미지 안에 있고, 아래 스크립트가 그 안에서 명령을 돌립니다.
- 필요한 것은 git, 도커, 파이썬 3, bash 입니다. 도커는 `sudo` 없이 돌아가야 합니다.
- 아이폰과 맥 앱은 이 방식으로 만들 수 없습니다. 맥에서 직접 하거나 CI 에 맡깁니다(아래 CI 절).
- 색, 간격 같은 디자인 값은 `design/tokens/` 에서 고치고, 코드가 아니라 값으로 다룹니다. 흐름은 디자인 토큰 절에 있습니다.

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

끝나면 `준비 끝. 훅: .githooks` 가 나옵니다. 이미지가 이미 있는 컴퓨터에서는 2초 안팎으로 끝납니다.

`tool/test.sh` 는 파이썬 도구 테스트 23개와 Flutter 테스트 10개를 차례로 돌리고, 이미지가 있는 상태에서 8초쯤 걸립니다.
마지막에 `All tests passed!` 가 나오면 환경이 제대로 된 것입니다.

## 도구 한눈에 보기

| 명령 | 하는 일 |
|---|---|
| `tool/setup.sh` | 클론 뒤 한 번. 훅, 이미지, 패키지 |
| `tool/test.sh` | 테스트 전부. push 전에 돌리는 것과 같습니다 |
| `tool/fl <flutter 인자>` | 도커 안에서 `flutter` 를 돌립니다 |
| `tool/fl_dart <dart 인자>` | 도커 안에서 `dart` 를 돌립니다 |
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

- 패키지와 Gradle 캐시는 도커 볼륨 `mood-clicker-pub-cache` 와 `mood-clicker-gradle` 에 쌓입니다. 두 번째 실행부터 빨라집니다. 지우려면 `docker volume rm` 으로 지웁니다.
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
design/tokens/*.json  →  python3 tool/gen_tokens.py  →  lib/design/tokens.g.dart  →  화면 코드
```

- 디자이너가 고치는 곳은 `design/tokens/` 의 JSON 입니다. 구성과 형식은 [DESIGN.md](DESIGN.md) 에 있습니다.
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
- 굵기를 더하려면 원본을 `design/fonts/` 에 넣고 스크립트를 돌린 뒤 `pubspec.yaml` 의 `fonts` 에 적습니다. 글꼴 이름은 `design/tokens/core.json` 의 `font.family` 와 같아야 합니다.
- 글꼴 라이선스는 `licenses/Pretendard-OFL.txt` 와 `THIRD_PARTY_NOTICES.md` 에 있습니다.

## CI

`.github/workflows/ci.yml` 이 PR 과 main 으로의 push 마다 돕니다. 결과가 초록이어야 합칩니다.

| 작업 | 환경 | 하는 일 |
|---|---|---|
| `check` | 리눅스, Flutter 이미지 | PR 의 커밋 개인정보 검사, 파이썬 테스트, `pub get`, 토큰 일치, 다트 형식, `analyze`, `flutter test`, 안드로이드 디버그 빌드 |
| `apple` | macOS, `check` 가 통과한 뒤 | 아이폰 디버그 빌드(서명 없이), 맥 디버그 빌드 |

개인정보 검사는 GitHub 가 만든 병합 커밋이 아니라 PR 에 실제로 들어 있는 커밋만 봅니다. 로컬 `tool/test.sh` 가 통과하면 `check` 의 대부분은 통과합니다.

## 에이전트 설정

코딩 에이전트(Claude Code 등)가 이 저장소에서 지킬 규칙을 파일로 둡니다.

| 파일 | 내용 |
|---|---|
| `AGENTS.md` | 에이전트용 규칙. 하지 않을 일, 확인 명령, git 규칙, 개인정보, 글쓰기. 사람은 README 부터 봅니다 |
| `CLAUDE.md` | `@AGENTS.md` 한 줄. Claude Code 가 같은 규칙을 읽게 하는 연결이라 규칙은 한 곳에서만 고칩니다 |
| `.claude/settings.json` | Claude Code 설정. 쓰는 플러그인(pstack, eli5)과, 확인 명령(`tool/fl`, `tool/fl_dart`, `privacy_scan`, `unittest`)을 묻지 않고 돌리는 허용 목록 |

개인 설정은 `.claude/settings.local.json` 에 두면 되고, 이 파일은 git 이 무시합니다.
규칙을 바꾸면 사람이 읽는 문서(이 문서, README)와 `AGENTS.md` 가 어긋나지 않게 함께 고칩니다.

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

- 확인일: 2026-11-18
- Linux, 도커 29, 파이썬 3.14, Flutter 3.44.0, Dart 3.12.0
- macOS 에서는 확인하지 못했습니다. 스크립트는 bash 와 도커만 쓰지만 같은 결과가 나오는지는 직접 확인한 적이 없습니다.
- 위 명령은 새 작업 트리에서 모두 통과했고, 개인정보 검사와 훅이 막는 경우는 일부러 어긴 입력으로 막히는 것까지 확인했습니다.
