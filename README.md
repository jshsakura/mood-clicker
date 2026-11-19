# Unknown (가제)

오늘의 기분을 고르고 연타해서 그 기분이 얼마나 컸는지 남기는 앱입니다. 안드로이드와 아이폰을 Flutter 하나로 만듭니다(맥은 파일럿).
`Unknown` 은 이름이 정해질 때까지 쓰는 가제입니다. 패키지 이름 `mood_clicker` 와 앱 식별자 `com.example.mood_clicker` 도 아직 그대로입니다.

이 문서는 팀이 처음 들어와 "지금 무엇이 있고, 어디를 보고, 어떻게 돌리는지" 를 한 번에 잡도록 씁니다.

## 지금 상태

`main` 이 가장 최근에 합친 상태이고, 작업은 `integrate/poc` 에 모은 뒤 PR 로 `main` 에 합칩니다. 테스트 빌드는 매번 `integrate/poc` 한 커밋에서 안드로이드와 아이폰을 같이 만듭니다.

| 기능 | 상태 |
|---|---|
| 기분 고르기 | 다섯 기분(행복해요, 설레요, 화나요, 슬퍼요, 불안해요). 기분마다 색이 따로 있습니다. 맨 위에 날짜 라벨과 날씨 칩 |
| 두드리기 | 두드리면 물이 차고, 쉬면 내려가고, 기울이면 넘쳐 화면 숫자가 줄어듭니다(저장된 기록은 그대로). 95~100% 를 3초 유지하면 보상. 응원 문구는 기분마다 1,000 문장 이상, 세 언어 |
| 가득 찼을 때 | 행복, 설렘은 축하. 화남, 슬픔, 불안은 부드러운 소리와 맑아지는 빛, 마무리 한 줄. 연타는 끊기지 않습니다 |
| 달력과 하루 상세 | 날짜 칸에 그날 대표 기분 색, 이달의 흐름 막대(누르면 날짜와 횟수), 오늘의 한마디 |
| 설정 | 테마 셋, 언어 셋(ko, en, ja), 글자 크기, 소리와 진동, 저녁 알림, 날씨 보기, 기록 내보내기와 지우기, 지역별 마음 상담 연락처 |
| 홈 화면 | 위젯, 앱 아이콘 길게 누르기 바로가기(기분별 얼굴 아이콘, 안드로이드 5개, iOS 4개) |
| 지도 | 실제 지도(MapLibre + OpenFreeMap)에 동네 육각 칸과 기분 얼굴. **자료는 아직 예시 자료**이고 서버는 3단계입니다 |
| 원형 ESP32 기기 | 별도 저장소에서 LVGL 로 옮기는 중(1차) |

### 기기 밖으로 나가는 것

기록은 전부 기기 안에 있습니다. 밖으로 나가는 것은 둘뿐입니다.

- 날씨: 소수 첫째 자리로 뭉갠 좌표만 MET Norway 에 보냅니다. 설정에서 끄면 위치도 묻지 않습니다.
- 지도 타일: OpenFreeMap 에서 지도 그림을 받습니다.

자세한 것은 [docs/PRIVACY.md](docs/PRIVACY.md).

## 어디를 보나

| 알고 싶은 것 | 문서 |
|---|---|
| 만드는 이유, 단계 계획 | [docs/PLAN.md](docs/PLAN.md) |
| 화면별 동작 규격 | [docs/SPEC.md](docs/SPEC.md) |
| 가치와 문구 원칙, 그 근거 | [docs/PRINCIPLES.md](docs/PRINCIPLES.md), [docs/EVIDENCE.md](docs/EVIDENCE.md) |
| 색, 간격, 글자(디자인 토큰), 화면 부품 | [docs/DESIGN.md](docs/DESIGN.md), `design/tokens.json`, `lib/design/parts/` |
| 시안과 실제 화면 비교 | [docs/SCREEN_PARITY.md](docs/SCREEN_PARITY.md), `design/canvas/` |
| 번역과 문구 키 | [docs/I18N.md](docs/I18N.md) |
| 개인정보, 처리방침 | [docs/PRIVACY.md](docs/PRIVACY.md), `docs/privacy-policy/` |
| 위젯, 바로가기 같은 네이티브 기능 | [docs/NATIVE_SURFACES.md](docs/NATIVE_SURFACES.md) |
| 스토어 문구 초안 | [docs/STORE.md](docs/STORE.md) |
| 조사 기록(음악 라이선스, 날씨 API 등) | `docs/research/` |
| 리뷰 기록 | `docs/reviews/` |
| **이 팀이 실제로 한 실수와 막는 검사** | [docs/LESSONS.md](docs/LESSONS.md). 일 시작 전에 자기 일과 닿는 절을 읽습니다 |
| AI 에이전트에게 새 컴퓨터 세팅 맡기기 | [docs/AI_SETUP.md](docs/AI_SETUP.md). 에이전트에게 "이 문서대로 세팅해 줘" 한 줄이면 됩니다 |
| 개발 규칙(에이전트 포함) | [AGENTS.md](AGENTS.md) |
| 여러 에이전트로 일하는 방법 | [docs/HARNESS.md](docs/HARNESS.md) · [English](docs/HARNESS.en.md) |

## 시작

필요한 것은 `git`, `python3`, 도커입니다. Flutter SDK 는 도커 이미지(`ghcr.io/cirruslabs/flutter`, 약 7GB) 안에 있어 따로 깔지 않습니다. 호스트 PATH 에 Flutter 3.44.0 이 있으면 그것을 씁니다.

```bash
git clone https://github.com/jshsakura/mood-clicker.git && cd mood-clicker
tool/setup.sh                    # git 훅을 켜고 이미지와 패키지를 받습니다
tool/test.sh                     # 테스트 전부. push 전에 반드시 돌립니다
tool/fl build apk --debug        # 안드로이드 디버그 빌드
```

| 단계 | 걸린 시간 | 처음에만 드는 것 |
|---|---|---|
| `tool/setup.sh` | 2초 | 이미지 받기(약 7GB) |
| `tool/test.sh` | 약 40초 | 없음 |
| `tool/fl build apk --debug` | 약 7분 | 안드로이드 NDK 와 CMake(도커 볼륨에 약 3GB, 한 번만) |

도커 사용법과 볼륨은 [docs/DEV-ENV.md](docs/DEV-ENV.md).

## 자주 쓰는 명령

```bash
tool/fl test                                      # 위젯, 단위 테스트
tool/fl test --update-goldens test/goldens/golden_test.dart   # 화면 그림(골든) 다시 만들기. 바뀐 그림은 눈으로 확인합니다
tool/fl analyze
tool/format.sh
python3 tool/gen_tokens.py                        # design/tokens.json 을 고친 뒤
python3 tool/gen_shortcut_icons.py                # 기분 색이나 얼굴을 고친 뒤
tool/fl gen-l10n                                  # lib/l10n/*.arb 를 고친 뒤
python3 tool/cheers_check.py                      # 응원 문구 검사
```

## 테스트 빌드

```bash
tool/fl build apk --release --split-per-abi       # 안드로이드. arm64 파일(약 39MB)을 배포합니다
gh workflow run ios-test.yml --ref integrate/poc  # 아이폰. 서명 없는 IPA 를 CI 의 맥에서 만듭니다
```

- **릴리스 서명 키는 저장소에 없습니다.** `android/key.properties` 와 `android/app/release.jks` 는 `.gitignore` 에 있고, 팀장이 보관한 키를 빌드하는 작업 트리에만 복사합니다. 키가 없으면 디버그 키로 서명되어 이전 테스트 빌드 위에 덮어 설치되지 않습니다. 이 키로 스토어 업데이트도 서명하므로 잃어버리면 안 됩니다.
- 아이폰 최소 버전은 15.5 입니다(지도 패키지 요구).
- 테스트 빌드 내려받기 페이지 주소는 팀 채널에서 받습니다. 저장소에는 적지 않습니다.

## 같이 일하는 방법

- `main` 에 바로 push 하지 않습니다. 브랜치 → `integrate/poc` 에 합치기 → PR 로 `main`.
- 커밋은 `<type>: <설명>`(feat fix refactor docs test chore perf ci). 훅을 `--no-verify` 로 건너뛰지 않습니다.
- 코드와 주석은 영어, 화면 문구는 ARB 키로, 문서와 UI 문구는 합니다체로 씁니다.
- 색과 간격은 `design/tokens.json` 에만 둡니다. 위젯에 `Color(0x…)` 나 숫자 간격을 쓰지 않습니다.
- 개인정보(실제 IP, 도메인, 이메일, 이름, 좌표, 키)는 코드, 테스트, 커밋, PR 어디에도 넣지 않습니다. 커밋과 push 에서 검사가 막습니다.
- 소리, 글꼴을 넣으면 출처를 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 에 먼저 적습니다. 수노 녹음본과 Pixabay 는 넣지 않습니다.
- 훅은 Claude Code(`.claude/`)와 Codex(`.codex/hooks.json`) 모두 같은 가드를 돌립니다.

## 정해야 할 것

- 앱 이름과 앱 식별자(`com.example` 은 플레이 스토어가 받지 않습니다)
- 웰니스 앱으로 낼지, 디지털 치료기기 쪽으로 갈지
- 지도의 실제 자료(서버)를 붙이는 시점
- 행복 노랑을 더 밝게 할지(흰 바탕 대비 3:1 을 지키느라 황금빛입니다)
