# AGENTS.md

코딩 에이전트를 위한 안내다. 사람은 README.md 부터 본다.

기분을 고르고 연타한 횟수로 그날 기분의 크기를 남기는 앱의 파일럿이다. Flutter 하나로 안드로이드,
아이폰, 맥을 낸다. 계획은 `docs/PLAN.md` 에 있다.

## 지금 할 일과 하지 않을 일

- 파일럿과 개발 환경에 집중한다. 화면은 꾸미지 않는다. 디자인은 디자이너가 맡는다.
- 색, 간격, 둥글기, 글자, 움직임 값은 `design/tokens/` 에만 둔다. 화면 코드는 `context.palette`,
  `Space`, `Radii`, `TypeScale`, `Motion` 만 쓴다. `Color(0x…)` 나 숫자 간격을 위젯에 직접 쓰지 않는다.
- `lib/design/tokens.g.dart` 는 생성 파일이다. 손대지 말고 `python3 tool/gen_tokens.py` 로 만든다.
- 화면 부품은 `lib/design/parts/` 에 둔다. 디자이너가 고치는 곳이 이 두 군데여야 한다. 자세한 것은 `docs/DESIGN.md`.
- 지도와 서버는 3단계다. 그 전에는 기기 밖으로 데이터를 보내지 않는다.

## 확인

호스트에 Flutter 를 깔지 않는다. 도커로 돌린다.

```bash
tool/setup.sh                                   # 클론 뒤 한 번. git 훅을 켠다
tool/test.sh                                    # 테스트 전부. push 전에 이것을 먼저 돌린다
tool/fl test                                    # 위젯, 단위 테스트
tool/fl analyze
tool/format.sh                                  # 포맷. 생성 파일 *.g.dart 는 건드리지 않는다
python3 -m unittest discover -s tool -p 'test_*.py'
tool/fl build apk --debug
```

아이폰과 맥 빌드는 맥이나 CI 의 macOS 러너에서 한다(`.github/workflows/ci.yml`).
진동과 애니메이션의 손맛은 실기기에서만 판정한다. 에뮬레이터 결과로 통과라고 하지 않는다.

## git

- `main` 에 바로 push 하지 않는다. 브랜치를 올리고 PR 로 합친다.
- 커밋 메시지는 `<type>: <설명>`. type 은 feat fix refactor docs test chore perf ci.
- 훅(`.githooks/`)을 `--no-verify` 로 건너뛰지 않는다.

## 개인정보와 서버 정보

코드, 테스트, 픽스처, 주석, 문서, 커밋 메시지, PR 본문 어디에도 넣지 않는다.
`tool/privacy_scan.py` 가 커밋, 커밋 메시지, push, PR 에서 막는다.

코드와 주석은 영어로만 쓴다. 한글은 문서(.md), 번역(lib/l10n/*.arb), 토큰 데이터(design/tokens.json)에만 둔다. 화면 문구는 코드에 적지 않고 ARB 키로 쓴다. `tool/slop_scan.py` 가 새로 추가한 코드 줄의 한글을 막는다. 예전 코드의 한글은 한 번에 영어로 옮길 예정이다.

`tool/slop_scan.py` 는 같은 자리에서 AI 티를 막는다. 엠대시와 엔대시, 둥근 따옴표, 정해 둔 AI 말투, 제목과 목록의 꾸밈 이모지, `lib/` 의 `print`·`debugPrint`·`as dynamic` 이다. 기계로 못 가리는 것(수동태, 군더더기, 과한 방어 코드)은 리뷰 때 pstack 의 `unslop`(글), `deslop`(코드) 스킬로 본다. 정말 필요한 줄에만 `slop-ok` 를 적는다.

- 실제 IP, 호스트명, 도메인, 이메일, 사람 이름, 운영 경로, 홈 경로, 키, 토큰.
- 실제 좌표. 위치 기반 앱이라 특히 조심한다. 테스트 좌표는 소수 둘째 자리까지만 쓰거나 바다 한가운데 같은 가짜 값을 쓴다.
- 서명 키, `key.properties`, `google-services.json`, `GoogleService-Info.plist`, `.env`.

대신 `192.0.2.0/24`, `example.com`, `"a" * 64` 같은 문서용 값을 쓴다.
정말 괜찮은 줄만 그 줄에 `privacy-ok` 를 적는다.

## 글쓰기

UI 문구와 문서는 합니다체로 쓴다. 엠대시로 문장을 잇지 않는다.
