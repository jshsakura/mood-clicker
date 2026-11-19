# Unknown (가제)

`Unknown` 은 정식 이름이 정해질 때까지 쓰는 가제입니다. 패키지 이름 `mood_clicker` 와 앱 식별자(`com.example.…`)는 바꾸지 않았습니다.

오늘의 기분을 고르고 연타해서 그 기분이 얼마나 컸는지 남기는 앱의 파일럿입니다.
안드로이드, 아이폰, 맥을 Flutter 하나로 만듭니다.

- 계획: [docs/PLAN.md](docs/PLAN.md)
- 개발 규칙: [AGENTS.md](AGENTS.md)
- 일하는 방법(여러 에이전트 팀, 훅, 스킬): [docs/HARNESS.md](docs/HARNESS.md) · [English](docs/HARNESS.en.md)

## 시작

필요한 것은 `git`, `python3`, 도커입니다. Flutter SDK 는 도커 이미지(`ghcr.io/cirruslabs/flutter`, 약 7GB) 안에 있어서 따로 깔지 않습니다. 도커가 없으면 `tool/setup.sh` 가 `docker: command not found` 로 멈추니 먼저 설치합니다. 호스트에 Flutter 3.44.0 이 이미 PATH 에 있으면 도커 없이 그것을 씁니다.

```bash
git clone https://github.com/jshsakura/mood-clicker.git && cd mood-clicker
tool/setup.sh                    # git 훅을 켜고 이미지를 받고 패키지를 받습니다
tool/test.sh                     # 테스트 전부
tool/fl build apk --debug        # 안드로이드 디버그 빌드
```

처음 한 번은 오래 걸리는 단계가 있습니다. 새 컴퓨터에서 확인한 시간입니다(이미지는 이미 받아 둔 상태라 받는 시간은 빠져 있습니다).

| 단계 | 걸린 시간 | 처음에만 드는 것 |
|---|---|---|
| `tool/setup.sh` | 2초 | 이미지 받기(약 7GB, 회선에 따라 몇 분) |
| `tool/test.sh` | 41초 | 없음 |
| `tool/fl build apk --debug` | 약 7분 | 안드로이드 NDK 와 CMake 받기(도커 볼륨 `mood-clicker-android-sdk`, `mood-clicker-android-sdk-cmake` 에 약 3GB 남아 한 번만 받습니다), 작업 폴더마다 Gradle 캐시 볼륨 |

NDK 받기는 회선이 나쁘면 끊깁니다. 3번까지 스스로 다시 시도하고, 그래도 안 되면 같은 명령을 한 번 더 칩니다. 도커 사용법과 볼륨은 [docs/DEV-ENV.md](docs/DEV-ENV.md) 에 있습니다. 에이전트로 일할 때 켜지는 Claude Code 훅과 팀 도구(`tool/team`)도 거기서 안내합니다.

아이폰과 맥 빌드는 맥에서 `flutter build ios`, `flutter build macos` 로 하거나 CI 에 맡깁니다.
