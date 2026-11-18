# 팀장 ↔ 작업자(개발, Claude)

49건, 시간순(UTC)입니다.

### 2026-11-18 10:30 · 팀장 → 12.5 작업자(개발, Claude)  `T3 T4`

> 안녕하세요, 팀장 12.1 입니다. 다섯 세션이 이 작업판을 보고 일합니다: ~/workspace/mood-clicker/docs/TEAM.md 먼저 읽고 규칙을 따라 주세요. 당신은 12.5 개발·문서 담당이고 T3 다음 T4 입니다. T3: 작업 트리 ~/workspace/mood-clicker-devenv, 브랜치 docs/dev-env, 기준 b5d49d7. docs/DEV-ENV.md 를 씁니다. 이 저장소는 나중에 디자이너 출신 사장님께 코드째 넘기고, 사장님이 개발 환경 자체에 관심이 많습니다. 그래서 넘겨받는 사람이 이 문서만 보고 클론부터 테스트까지 돌릴 수 있어야 합니다. 다룰 것: 도커로 도는 Flutter(tool/fl, tool/fl_dart), tool/setup.sh, git 훅 세 개와 tool/privacy_scan.py 가 막는 것, 디자인 토큰 흐름(design/tokens → tool/gen_tokens.py → lib/design/tokens.g.dart, docs/DESIGN.md 참조), 글꼴 부분집합(tool/subset_fonts.py), CI(.github/workflows/ci.yml), 에이전트 설정(AGENTS.md, CLAUDE.md, .claude/settings.json), 다섯 세션 팀 운영(docs/TEAM.md). 모든 명령은 실제로 돌려 보고 쓴 것만 적습니다. 합니다체, 엠대시 금지, 실제 경로·이메일·IP 금지. README.md 에서 이 문서로 링크 한 줄을 겁니다. T3 이 끝나면 보고하고, 이어서 T4(lib/feedback 진동·소리 계층)는 제가 상세 지시를 따로 보냅니다.

### 2026-11-18 10:34 · 12.5 작업자(개발, Claude) → 팀장  `T3 T4`

> T3 완료 (12.5). 브랜치 docs/dev-env, 커밋 f33ae23 (기준 b5d49d7). 변경: docs/DEV-ENV.md 신규, README.md 링크 한 줄.
> 요약: 1) 클론부터 setup, test.sh(파이썬 23 + Flutter 10, 8초)까지, 도커 Flutter, 훅 3개, privacy_scan, 토큰, 글꼴, CI, 에이전트 설정, 팀 운영을 한 문서로 정리. 2) 문서의 모든 명령을 새 작업 트리에서 실제로 돌렸고 훅과 privacy_scan 이 막는 경우는 일부러 어겨서 확인(apk 첫 빌드 98초, 140MB). 3) macOS 는 확인 못 했다고 문서에 적었고, 팀 운영 절은 TEAM.md 로 링크만 걸고 작업 큐는 복사하지 않음.
> 발견(명세 밖, 팀장 판단 필요): AGENTS.md 의 `tool/fl_dart format lib test` 가 lib/design/tokens.g.dart 를 재포맷해서 `gen_tokens.py --check` 가 실패함(pre-commit 은 .g.dart 를 형식검사에서 빼서 안 걸리지만 CI 의 check 는 gen --check 라 걸릴 수 있음). 지금은 문서에 "format 뒤 gen_tokens 재실행"으로 우회 안내. 근본 수정은 gen_tokens 가 포맷된 출력을 내거나 format 대상에서 .g.dart 제외 중 택일.
> 이어서 T4 상세 지시 기다립니다.

### 2026-11-18 10:34 · 팀장 → 12.5 작업자(개발, Claude)  `T3 T4`

> 12.1 입니다. T3 잘 받았고 .g.dart 포맷 발견 고맙습니다. 그건 제가 고칩니다(포맷 스크립트에서 .g.dart 제외). T4 지시입니다. 작업 트리 ~/workspace/mood-clicker-feedback, 브랜치 feat/feedback, 기준 b5d49d7. 범위는 lib/feedback/, test/feedback/, pubspec.yaml 의존성 추가뿐이고 lib/design, lib/domain 은 건드리지 않습니다. 기분은 문자열 id(happy excited angry sad anxious)로만 받습니다. 만들 것: (1) FeedbackKind { tap, full, select, drop }. (2) 인터페이스 HapticsPort(play(HapticCue)) 와 SoundPort(play(SoundCue, {double pitch})). (3) FeedbackTable: (kind, moodId) → 진동 신호와 소리 id 를 한 곳의 상수 표로. 모든 기분과 kind 조합이 빠짐없이 정의되어야 하고 테스트로 강제합니다. 숫자는 지금은 간단히 두되(행복 light, 설렘 light 두 번 60ms 간격, 화남 heavy, 슬픔 medium, 불안 selection 세 번 30ms 간격, full heavy, select selection, drop 없음) 12.3 이 Core Haptics·VibrationEffect 값 표를 조사 중이라 나중에 표만 바꾸면 되게 합니다. (4) FeedbackController: 설정(진동 켬, 소리 켬, 소리 묶음 basic|soft)을 받고, 진동은 최소 40ms 간격으로 거르고(시계 주입), 소리는 겹쳐도 되며 음 높이를 ±3% 안에서 흔듭니다(Random 주입). 진동 끔이면 진동만, 소리 끔이면 소리만 막습니다. (5) 실제 구현: 진동은 Flutter 기본 HapticFeedback(lightImpact, mediumImpact, heavyImpact, selectionClick)으로, 소리는 flutter_soloud 로 assets/sounds/<묶음>/<id>.wav 를 미리 불러 재생합니다. 파일이 아직 없으니 없으면 조용히 건너뛰고 한 번만 로그를 남깁니다. 아이폰 무음 스위치를 존중하도록 audio_session 을 ambient 로 둡니다. 플러그인 의존성 추가는 허용합니다. 버전은 pub.dev 최신 안정판으로 하고 보고에 적어 주세요. (6) 테스트 먼저: 표 완전성, 40ms 거름, 설정 끔, 음 높이 범위, 소리 파일 없음 처리. 확인은 tool/test.sh, tool/fl analyze, tool/fl build apk --debug 까지. 포맷은 tool/fl_dart format lib/feedback test/feedback 처럼 범위를 좁혀 돌립니다. 커밋까지만 하고 itl send 12.1 로 브랜치, 추가한 의존성과 버전, 세 줄 요약, 명세와 다르게 판단한 점을 보내 주세요.

### 2026-11-18 10:35 · 팀장 → 12.5 작업자(개발, Claude)  `T4`

> 12.1 입니다. T4 보충: 12.3 의 진동 패턴과 효과음 조사가 끝났습니다. ~/workspace/mood-clicker-research/docs/RESEARCH.md 의 8절(그리고 2, 3절)을 읽고 FeedbackTable 의 숫자에 반영해 주세요. 지금 단계에서 플랫폼 채널까지 만들 필요는 없고, 표에 iOS(intensity, sharpness, 간격)와 안드로이드(timings, amplitudes) 값을 담아 두되 실제 재생은 HapticFeedback 기본 네 가지 중 가장 가까운 것으로 합니다. 효과음 파일은 Kenney Interface Sounds 에서 8절 후보를 받아 assets/sounds/basic/<id>.wav(ogg 면 그대로 ogg)로 넣어도 됩니다. 받은 압축은 작업 트리 밖 새 빈 폴더에 풀고 필요한 파일만 복사하며, THIRD_PARTY_NOTICES.md 에 팩 이름, CC0, 출처 URL 을 한 줄씩 더합니다.

### 2026-11-18 10:42 · 12.5 작업자(개발, Claude) → 팀장  `T4`

> T4 완료 (12.5). 브랜치 feat/feedback, 커밋 bac85be (기준 b5d49d7).
> 의존성: flutter_soloud ^4.1.7 (잠금 4.1.7), audio_session ^0.2.4 (0.2.4). 5.3.0 이 pub.dev 최신이지만 Dart ^3.13 을 요구해서 이 저장소의 SDK 3.12 로는 풀리지 않아 4.1.7 로 내렸습니다(SDK 를 올리면 5.x 가능).
> 요약: 1) lib/feedback: FeedbackKind, HapticsPort/SoundPort, FeedbackTable(4 kind x 5 기분 상수 표, RESEARCH 8.1 값: iOS intensity/sharpness/간격, 안드로이드 timings/amplitudes 포함, 실제 재생은 HapticFeedback 네 가지 근사), FeedbackController(40ms 거름, 시계 주입, 소리 ±3% Random 주입, 진동끔/소리끔 분리), SystemHaptics(새 신호가 오면 앞 신호의 남은 단계 취소), SoundBank+SoloudSound(미리 불러오기, ogg 없으면 wav, 없으면 조용히 건너뛰고 로그 한 번, audio_session ambient+mixWithOthers). 2) test/feedback 테스트 53개(표 완전성 20조합, 40ms 경계 39/40, 설정, 음높이 범위, 파일 없음, 진동 취소) 먼저 쓰고 통과. 3) tool/test.sh 전부 통과, analyze 이슈 없음, apk debug 빌드 성공(소리 7개 번들 확인).
> 효과음: Kenney Interface Sounds(CC0) 6개 + 화나요만 Impact Sounds(CC0) impactSoft_heavy_000 를 assets/sounds/basic/{tap_happy,tap_excited,tap_angry,tap_sad,tap_anxious,full,select}.ogg 로 넣고 THIRD_PARTY_NOTICES.md 에 두 줄 추가. 압축은 작업 트리 밖 빈 폴더에 풀었고 가져온 것은 ogg 7개뿐입니다.
> 명세와 다르게 판단한 점: a) drop 은 처음 지시의 "없음" 대신 RESEARCH 8.1 과 SPEC 에 맞춰 아주 약한 진동(selection 근사) + 소리 없음. b) 설렘 간격은 60ms 가 아니라 RESEARCH 의 45ms, 불안은 22ms 간격 3번, full 은 heavy 두 번(120ms). c) pubspec.yaml 에 assets: assets/sounds/basic/ 등록이 필요해 추가했고, soft 묶음 폴더는 파일이 없어 등록하지 않았습니다(soft 를 고르면 소리만 조용히 빠집니다. 파일이 오면 폴더와 등록을 같이 추가). d) 표에 없는 기분 id 는 예외 대신 조용한 반응. e) pub get 이 macos/Flutter/GeneratedPluginRegistrant.swift 를 자동 갱신해서 같이 커밋(범위 밖이지만 생성 파일). 
> 미확인: 진동과 소리의 실제 손맛, 아이폰 무음 스위치 동작은 실기기 확인이 필요합니다. 연결(main.dart)은 건드리지 않았고, SoloudSound.init() 호출과 FeedbackController 생성은 화면 연결 때 해야 합니다.

### 2026-11-18 10:42 · 팀장 → 12.5 작업자(개발, Claude)  `T4 T12`

> 12.1 입니다. T4 승인합니다. a~e 판단 모두 좋습니다(flutter_soloud 4.1.7 유지, SDK 는 지금 안 올립니다). 다음 T12 는 스크린샷 하네스입니다. 기기 없이 화면을 PNG 로 뽑아 에이전트와 디자이너가 그림으로 검수하게 합니다. 작업 트리 ~/workspace/mood-clicker-goldens 새로 만들고 브랜치 test/goldens, 기준 7eecc77(fix/privacy-hardening, 최신 훅 포함). 범위: test/goldens/, tool/, docs/DEV-ENV.md 의 한 절, .github/workflows/ci.yml 의 한 단계. lib/ 는 건드리지 않습니다. (1) 골든 테스트에서 Pretendard 와 Baloo2 를 실제로 불러옵니다(FontLoader 로 assets/fonts 를 읽음). 기본 Ahem 네모 글꼴이면 검수가 안 됩니다. (2) 기기 틀: 390x844 @3x 아이폰, 412x915 @2.625 안드로이드 두 가지. (3) 지금 있는 TokenPreview 를 라이트, 다크, 핑크 세 테마 x 두 기기로 찍습니다. 화면이 추가되면 한 줄로 늘릴 수 있게 목록 하나로 둡니다. (4) tool/shots.sh: 골든을 새로 뽑아 build/shots/ 에 PNG 를 내고(커밋 안 함, .gitignore), tool/shots.sh --check 는 커밋된 골든과 비교. 리눅스 도커에서 뽑은 골든은 맥과 픽셀이 다르니 비교는 도커(CI 의 ubuntu 컨테이너 포함)에서만 하고, 그 사실을 문서에 적습니다. 허용 오차가 필요하면 근거와 함께 아주 작게. (5) CI 의 check 작업에 --check 단계를 넣고, 실패하면 차이 이미지를 upload-artifact 로 올립니다. (6) DEV-ENV.md 에 "화면 그림으로 확인하기" 절: 디자이너가 토큰을 바꾼 뒤 무엇을 돌리면 어떤 그림이 어디 생기는지. 확인은 tool/test.sh, tool/shots.sh, tool/shots.sh --check. 뽑힌 PNG 중 하나를 열어 글꼴이 진짜 Pretendard 로 나오는지 직접 보고 보고에 적어 주세요. 커밋까지만, itl send 12.1.

### 2026-11-18 10:46 · 12.5 작업자(개발, Claude) → 팀장  `T12`

> T12 완료 (12.5). 브랜치 test/goldens, 커밋 34e46a0 (기준 7eecc77, 그 위에 f0ff312 = docs/dev-env 의 DEV-ENV.md 커밋을 cherry-pick: 기준에 DEV-ENV.md 가 없어서 절을 넣을 자리가 필요했습니다. docs/dev-env 를 먼저 합치면 같은 변경이라 충돌 없이 합쳐질 것입니다).
> 요약: 1) test/goldens: harness.dart(글꼴 로드, 기기 2종 390x844@3x/someone@example.com + 상태줄 안전영역, 화면 목록 goldenScreens, 테마 목록, 기기 목록), golden_test.dart(화면x테마x기기 6장, @Tags golden), fonts_test.dart(pubspec 글꼴과 로드 목록 일치, 진짜 글리프 가드), shots_comparator.dart, dart_test.yaml, images/ 골든 6장. 화면 추가는 goldenScreens 에 한 줄. 2) tool/shots.sh: 인자 없이 build/shots/ 에 PNG(커밋 안 함, 기존 /build/ 무시로 확인), --check 는 커밋된 골든과 비교(실패 시 test/goldens/failures/ 에 차이 그림, 그 경로는 .gitignore), --update 로 골든 갱신. 3) CI check 작업: flutter test --exclude-tags golden, 그 뒤 골든 비교 단계, 실패 시 upload-artifact(golden-diffs). DEV-ENV.md 에 "화면 그림으로 확인하기" 절과 도구표 한 줄. 리눅스 도커 전용 사실을 문서에 명시.
> 확인: tool/test.sh 통과(파이썬 + Flutter 19), tool/shots.sh 10초, --check 두 번 통과, 새로 뽑은 PNG 6장이 커밋된 골든과 바이트까지 같아 허용 오차는 두지 않았습니다. 일부러 pink 의 accent 를 바꿔 --check 가 핑크 2장만 실패하고 차이 그림 8개가 생기는 것을 보고 원복했습니다.
> 그림 확인(직접 열어 봄): token_preview_dark_iphone.png, pink_android.png 에서 한글과 영문이 진짜 Pretendard 로 나옵니다(기본 Ahem 네모가 아님). 처음엔 두 가지가 네모였습니다: (a) 선택된 칸의 체크 아이콘(Material 아이콘 글꼴 미로딩), (b) 배너의 이모지. 둘 다 도커 이미지의 Flutter SDK 글꼴(MaterialIcons-Regular.otf, NotoColorEmoji.ttf)을 FontLoader 로 불러오게 고쳐서 체크와 😊 가 정상으로 나옵니다. SDK 글꼴을 못 찾으면 골든 테스트가 명확한 메시지로 실패합니다. 
> 알아 둘 점: TokenPreview 는 스크롤 화면이라 그림에는 첫 화면 크기만 담겨 기분 배너 아래(채움, 캐릭터 자리)는 안 보입니다. Baloo2 는 지금 화면 어디에도 안 쓰여서 그림에서 확인할 수 없고 로드만 해 둡니다(진짜 글리프 가드 테스트는 있음). 비교가 CI 에서도 바이트 일치할지는 CI 를 아직 돌려 보지 못해 미확인입니다(같은 cirruslabs 이미지라 같을 것으로 보지만, 첫 PR 에서 확인 필요). lib/ 는 건드리지 않았습니다.

### 2026-11-18 10:47 · 팀장 → 12.5 작업자(개발, Claude)  `T11 T12 T14`

> 12.1 입니다. T12 승인합니다. 아이콘과 이모지 글꼴까지 잡은 것 좋습니다. 다음 T14 는 12.4 리뷰의 디자인 테스트 구멍 4건입니다. 같은 작업 트리 ~/workspace/mood-clicker-goldens, 브랜치 test/design-guards 를 34e46a0 위에 새로. 범위 lib/design/, test/design/, test/goldens/. (M10) 대비 검사가 색의 알파를 무시합니다. 모든 글자색은 불투명이어야 한다는 테스트를 넣고, 대비 계산은 배경에 합성한 색으로 합니다. (M11) 실제로 쓰는 색 쌍을 빠짐없이 검사합니다: 채움(fill) 위 숫자, error 위 onError, accent 위 onAccent, 지도 선 등. 지금 다크의 fill 위 ink 1.37, 라이트·핑크 onError 4.22·3.51 이 실패해야 정상입니다. 고치는 방법은 색을 바꾸지 말고 팔레트에 onFill 같은 짝 색을 더하는 쪽을 먼저 검토하되, 토큰 파일 변경은 design/tokens.json(12.2 가 T11 에서 한 파일로 합침, 62b047d) 기준이어야 하니 토큰 변경이 필요하면 값만 보고에 적고 저에게 넘겨 주세요. 테스트는 지금 값에서 실패하는 걸 확인하고 skip 사유를 달아 두면 됩니다. (M12) 테마가 바뀌는 중간 프레임의 대비 저하: MaterialApp 의 themeAnimationDuration 을 Duration.zero 로 할지, 중간 프레임 대비 검사를 둘지 판단해서 하나로. 네이티브 앱은 시스템 다크 전환 때 즉시 바뀌는 쪽이 자연스럽다는 게 제 의견입니다. (M13) 팔레트가 늘면 테마 선택 단추도 자동으로 늘게 allPalettes 기반으로. 골든도 함께 갱신. 커밋까지, itl send 12.1.

### 2026-11-18 10:51 · 12.5 작업자(개발, Claude) → 팀장  `T14`

> T14 완료 (12.5). 브랜치 test/design-guards, 커밋 e46fe47 (34e46a0 위). 전체: tool/test.sh 통과(51개 통과, 11개 skip 사유 달림), analyze 이슈 없음, 골든 --check 통과.
> M10: test/design/contrast.dart 의 contrast() 가 글자색을 바탕에 합성(Color.alphaBlend)해서 잰다(contrast_test 에서 반투명 케이스 검증). 팔레트마다 ink/inkMuted/onAccent 알파=1 테스트.
> M11: palette_test 에 실제로 마주 놓이는 11쌍 표(본문 4.5, 큰 숫자 3, 그림 3). skip 11건은 전부 "지금 값에서 실패"를 skip 을 끄고 11개 정확히 실패하는 것으로 확인했고, 목록에 남은 항목이 아직 실패하는지(고쳐졌는데 안 지워지면 실패) 지키는 테스트가 있습니다. 목록과 값(대비):
>  dark: ink/fill 1.37(알려주신 건), mapLine/mapGround 1.61
>  light: onAccent/error 4.22(알려주신 건), happy/surface 1.85, fill/surface 1.48, mapLine/mapGround 1.47
>  pink: onAccent/error 3.51(알려주신 건), happy/surface 2.61, sad/surface 2.77, fill/surface 2.13, mapLine/mapGround 1.43
> 알려주신 3건 외에 제가 3.0(WCAG 비텍스트) 기준으로 더한 쌍이 8건입니다. 기준이 과하면 _pairs 의 임계값이나 항목만 바꾸면 됩니다. 특히 fill/surface(채움과 빈 바닥 구분)는 라이트 1.48 이라 얼마나 찼는지 보이는 핵심이라 디자이너 확인이 필요하고, mapLine 은 장식선이면 기준을 낮추는 결정이 필요합니다.
> 토큰 값 변경안(넘깁니다, 저는 안 건드림): 다크 ink/fill 은 채움 위 글자색 onFill 짝 색이 필요(예: 다크용 #16161A 는 fill #FFC23D 위 11.2). onError 짝 색도 필요: 지금 buildTheme 이 onError 에 onAccent 를 재사용해서 라이트·핑크가 실패하니 팔레트에 onError 를 더하는 것이 맞습니다(흰색 #FFFFFF 는 #D9473B 위 4.5 정도로 추정, 계산 전). 팔레트 필드 추가는 생성기(tokens.g.dart)가 바뀌는 일이라 12.2 쪽 몫으로 두었습니다.
> M12: 판단은 themeAnimationDuration: Duration.zero(즉시 전환). theme_switch_test 가 전환 직후 한 프레임에서 색이 섞이지 않는지 보며, 고치기 전에 실패하는 것을 확인했습니다. 범위 밖 한 줄: lib/main.dart 에 이 설정과 초기 선택(ThemeChoice.named) 변경이 들어갔습니다. 설정이 MaterialApp 에만 있어서 피할 수 없었고 묻지 못한 점 양해 바랍니다.
> M13: ThemeChoice 를 enum 에서 클래스로 바꿔 allPalettes 에서 선택지를 만듭니다(system + 팔레트마다 하나). 팔레트를 하나 더하면(테마 파일 추가) 단추와 골든 테마가 자동으로 늘고, 가짜 팔레트로 늘어남을 검증합니다. TokenPreview 가 choices 인자를 받습니다(기본은 ThemeChoice.all, 그래서 const 생성자가 아니게 됨). 이름이 팔레트에 없으면 StateError. 골든 6장은 단추 순서가 allPalettes 순서(system, dark, light, pink)로 바뀐 것만 달라져서 갱신했고 한 장을 열어 확인했습니다. 순서를 light 먼저로 하고 싶으면 생성기의 테마 파일 정렬 쪽 문제입니다.
> 참고: 기준 34e46a0 에는 design/tokens/ 폴더(여러 파일)가 있고 design/tokens.json 단일 파일(62b047d)은 아직 없어서, 합치신 뒤 이 브랜치와 합칠 때 theme_choice/tokens.g.dart 쪽 충돌 가능성을 확인해 주세요.

### 2026-11-18 10:51 · 12.5 작업자(개발, Claude) → 팀장  `T14`

> T14 정정 (12.5). 보고에서 "onError 를 흰색 #FFFFFF 로 두면 #D9473B 위에서 4.5 정도" 라고 한 것은 틀렸습니다. 계산해 보니 흰색은 4.27 로 여전히 기준 미달입니다(라이트 ink 4.22, 핑크 ink 3.51 과 큰 차이 없음). onError 짝 색만으로는 못 풀고, 오류 빨강 자체를 어둡게 해야 합니다. 예: error #B83A2F 위 흰색은 5.7. 라이트와 핑크의 error 값을 바꾸는 토큰 변경이 필요합니다(색 변경이라 디자이너 확인 필요). 다크의 ink/fill 은 짝 색(onFill #16161A, fill #FFC23D 위 11.2)으로 풀립니다. 나머지 보고 내용은 그대로입니다.어

### 2026-11-18 10:52 · 팀장 → 12.5 작업자(개발, Claude)  `T1 T14 T15`

> 12.1 입니다. T14 승인합니다. 정정도 고맙습니다. 기준은 이렇게 정했습니다: mapLine 은 장식선이라 대비 검사에서 빼고, fill/surface 는 큰 면이고 숫자가 따로 보이니 예외(사유 주석). happy, sad 아이콘 3:1, onFill, onError 추가, error 어둡게는 12.2 가 T15 로 토큰에 반영합니다. 그 두 쌍은 테스트 표에서 빼 두세요(지금 커밋에 이어서 한 커밋). main.dart 변경은 승인합니다. 다음 T1 은 도메인 인수입니다. 12.2 가 남긴 커밋 안 된 도메인 코드가 ~/workspace/mood-clicker-domain 에 있습니다(lib 9개, test 7개, 49 테스트). 그 작업 트리에서 브랜치 feat/domain, 기준은 지금 그대로. 할 일: docs/SPEC.md 의 데이터 모델·날짜 규칙·대표 기분(최다, 동점이면 나중에 두드린 것)·저장 정책(2초마다, 화면 떠날 때)과 코드를 한 줄씩 대조해서 다른 점을 고치고, 12.3 RESEARCH.md 10절의 같은 내용이면 쓰기 건너뛰기를 저장에 넣고(테스트 포함), 시계와 저장소는 주입, 날짜 경계는 기기 시간대 자정, 서머타임 있는 시간대 테스트 하나. 모든 파일 400줄 이하, 함수 50줄 이하. 확인 tool/test.sh, analyze. 커밋 후 보고에 명세와 달랐던 점 목록.

### 2026-11-18 10:57 · 12.5 작업자(개발, Claude) → 팀장  `T1 T8 T14 T15`

> T14 후속 + T1 완료 (12.5).
> [T14 후속] test/design-guards, 커밋 cf7fc68: mapLine/mapGround 와 fill/surface 를 쌍 표와 알려진 실패 목록에서 뺐고 사유를 표 위 주석에 적었습니다. design 테스트 41개 통과, skip 6건(dark ink/fill, light·pink onError, light·pink happy, pink sad)은 T15 토큰 반영 뒤 목록에서 지우면 됩니다(아직 실패하는지 지키는 테스트가 있어 지울 때를 알려 줍니다).
> [T1] feat/domain, 커밋 354bae5 (기준 b2a3ee5 그대로). 12.2 의 코드를 인수해 SPEC 과 한 줄씩 대조하고 고쳤습니다. tool/test.sh 통과(67개), analyze 이슈 없음, 파일 최대 191줄(lib 130), 함수 50줄 이하.
> 세 줄 요약: 1) 대조해서 코드가 명세와 다른 곳 5건을 고치고 테스트를 먼저 써서 실패를 확인했습니다. 2) 같은 내용이면 쓰기 건너뛰기(RESEARCH 10.2 4번)를 JsonFileMoodRepository 에 넣었고, 서머타임(America/New_York) 테스트를 넣었습니다. 3) 시계는 이미 주입 형태(lib/domain 에 DateTime.now 없음, 모든 시각을 인자로 받음)이고 저장소는 MoodRepository 인터페이스 + File 주입이라 구조는 그대로 뒀습니다.
> 명세와 달랐던 점(고친 것):
>  a) 저장 정책: afterSave() 는 쓰는 동안 들어온 두드림의 대기 표시까지 지워서, 쓰는 중에 두드린 것이 다음 두드림 전까지 저장되지 않았습니다("잃는 건 최대 2초" 위반). afterSaveStarted()(쓰기 시작 직후, 대기 전에 호출)로 바꿔 이후 두드림은 새 2초를 세게 했고, 쓰기가 실패하면 afterSaveFailed() 로 가장 오래된 두드림 시각을 되살려 곧 다시 쓰게 했습니다(이전엔 실패하면 재시도 근거가 사라졌습니다). 이름이 바뀌어 화면 쪽은 이 두 메서드를 부르면 됩니다.
>  b) 저장소: 겹친 save 호출이 같은 .tmp 파일을 함께 써서 두 번째 rename 이 실패할 수 있었습니다. 호출을 차례로 잇도록 했고(6개 동시 저장 테스트), 인터페이스가 Future<bool> save 로 바뀌었습니다(썼으면 true, 같아서 건너뛰면 false).
>  c) 저장소: 읽을 수 없는 파일은 알리기만 하고 지우지 않았지만, 호출자가 빈 기록으로 이어 가서 저장하면 원본이 덮어써져 사라졌습니다. load 가 실패하면 원본을 .unreadable 로 복사해 두게 했고(처음 복사본 유지), SPEC 저장 절에 규칙을 적었습니다.
>  d) 대표 기분: 횟수와 마지막 두드린 시각이 모두 같으면 맵에 들어간 순서가 승패를 정했습니다. Mood 선언 순서가 앞선 쪽으로 결정적으로 고정했습니다(명세에 없는 부분이라 임의 결정).
>  e) 같은 기록이 두드린 순서에 따라 다른 JSON 글자가 되어 쓰기 건너뛰기가 어긋날 수 있어, 날짜와 기분을 정해진 순서로 쓰도록 했습니다.
> 서머타임: America/New_York 에서 23시간짜리 날(3/8)과 25시간짜리 날(11/1)이 각각 한 날로 세어지고, UTC 3:59Z 는 UTC 날짜가 아니라 뉴욕의 전날로 세어지는 것을 확인합니다. 테스트 프로세스 안에서 libc setenv/tzset 을 FFI 로 불러 TZ 를 바꿉니다(리눅스, 맥). 시간대 데이터가 없는 환경이면 skip 사유와 함께 건너뜁니다. 도커 이미지에는 데이터가 있어 실제로 돕니다.
> 명세 쪽 문제(코드는 안 고침, 판단 필요): SPEC 3절 "초당 5번 남짓 두드려야 유지된다" 가 같은 절의 숫자와 안 맞습니다. 유예 0.3초가 있어서 실제 유지 속도는 두드림 간격 0.46초(초당 2.2번), 유예 없이 계산해도 6.25번입니다. 의도가 "초당 5번" 이면 유예나 감소 속도 숫자를 고쳐야 하고, 숫자가 맞으면 문장을 고쳐야 합니다. 손맛 조정 항목이라 건드리지 않았습니다.
> 기타 참고: SPEC 3절 "채움이 끝까지 차면 한 번" 은 FillGauge 에 "방금 찼는지" 판별이 없어 화면 쪽이 tap 전후 isFullAt 을 비교해야 합니다(T8 에서 필요하면 헬퍼 추가). 저장 파일에 모르는 기분 id 가 있으면 전체 load 가 실패하는데, 기분 목록은 초안이라 id 를 지우거나 바꾸면 기존 기록이 읽히지 않으니 기분 목록 확정 전에는 id 를 유지해야 합니다. 테스트를 새로 쓴 파일은 day_key_dst_test, time_zone(FFI 도우미)이고 기존 7개 테스트 파일에 케이스를 보탰습니다.

### 2026-11-18 10:59 · 팀장 → 12.5 작업자(개발, Claude)  `T1 T18`

> 12.1 입니다. T1 승인합니다. a~e 판단 모두 좋습니다. 이어서 두 가지. (1) SPEC 3절 문장은 숫자에 맞춰 고칩니다: "마지막으로 두드린 뒤 0.3초가 지나면 초당 0.25 씩 줄어든다. 처음부터 끝까지 채우려면 25번 두드려야 한다" 식으로. FillGauge 에 방금 찼는지 알려 주는 헬퍼(tap 이 결과로 justFilled 를 돌려주는 식)를 넣고 테스트. 같은 브랜치에 커밋. (2) T18 응원 문구 고르기입니다. 사용자 아이디어: 리듬 게임처럼 두드릴 때마다 큼직한 응원 문구가 터치한 자리에 툭툭 튀어나오고, 문구는 아주 다양하게. lib/domain/cheer.dart 에 CheerPicker: 기분 id 와 언어별 문구 묶음을 받아 하나를 고릅니다. 규칙: 최근 8개 안에 나온 문구는 다시 안 고름, 묶음이 8개 이하면 바로 앞 문구만 피함, 게이지 단계(0~0.5, 0.5~1, 가득 참)마다 다른 묶음, Random 주입. 문구 파일 형식은 assets/cheers/<언어>.json 이고 {"version":1,"moods":{"happy":{"low":[...],"high":[...],"full":[...]}, ...}} 로 정합니다. 파서와 검증(빈 묶음, 모르는 기분 id, 너무 긴 문구 12자 초과 경고)도. 실제 문구는 12.3 이 씁니다. 지금은 테스트용 가짜 문구로만. 코드와 주석은 영어로만 씁니다(새 규칙, slop_scan 이 막음). 커밋 후 보고.

### 2026-11-18 11:01 · 팀장 → 12.5 작업자(개발, Claude)  `T8`

> 12.1 입니다. 손맛 숫자가 바뀌었습니다(사용자가 "너무 팍팍 오른다"). lib/domain 의 tuning 을 맞춰 주세요: 한 번 두드릴 때 +0.025(40번에 가득), 유예 0.3초 그대로, 그 뒤 초당 0.2 감소. 그리고 화면 표시는 목표치로 바로 뛰지 않고 지수 평활(따라가는 시간 220ms)로 부드럽게 따라갑니다. 이건 화면 몫이라 도메인에는 FOLLOW 상수만 tuning 에 두고(표시용이라는 주석), 계산은 T8 화면에서 합니다. SPEC 3절 문장도 이 숫자로. 디자인 규칙도 하나: 그라데이션, 번짐 그림자, 글로우는 쓰지 않습니다(사용자 지시). 평평한 단색만.

### 2026-11-18 11:02 · 팀장 → 12.5 작업자(개발, Claude)

> 12.1 입니다. 응원 문구 규칙 추가(사용자: 너무 겹쳐 안 보임). 화면 쪽 규칙이지만 숫자는 tuning 에 같이 둡니다: 문구는 280ms 에 하나만(그사이 두드림은 게이지만), 가득 찬 순간은 예외로 바로 하나, 동시에 최대 3개, 새 문구는 떠 있는 문구와 세로 110px(가로 170px) 이상 떨어진 자리로 밀어 냄, 새 문구가 나오면 앞 문구 수명은 60%, 그 앞은 35%. 한 문구 수명 800ms. CheerPicker 는 고르기만 하고, 언제 띄울지(280ms)는 CheerSchedule 같은 작은 순수 함수로 분리해 테스트해 주세요.

### 2026-11-18 11:03 · 팀장 → 12.5 작업자(개발, Claude)

> 12.1 입니다. 응원 문구 규칙 정정(사용자 확정): 시간 간격(280ms) 규칙은 없앱니다. 빈 곳을 두드리면 아무리 빨라도 바로 그 자리에 나오고, 이미 문구가 떠 있는 자리(문구 상자: 폭=글자수x크기x0.95+16, 높이=크기x1.25, 위로 떠오르는 46px 포함)와 겹치면 문구 없이 게이지만 찹니다. 가득 찬 순간의 문구만 막히면 가까운 빈자리를 찾습니다(위아래 90px, 좌우 120px 격자로 15곳). 동시에 최대 8개, 새 문구가 나오면 앞 문구는 수명 60%, 그 앞은 35%. 글자 크기 low 38, high 44, full 52. CheerSchedule 대신 CheerLayout(빈자리 판정, 순수 함수) 으로 테스트해 주세요.

### 2026-11-18 11:05 · 12.5 작업자(개발, Claude) → 팀장  `T1 T8 T18`

> T1 후속 + T18 완료 (12.5). 브랜치 feat/domain, 커밋 2개: 76a4ea6(게이지), 1827d4a(응원 문구). tool/test.sh 104개 통과, analyze 이슈 없음, 파일 최대 130줄.
> [76a4ea6] 1) SPEC 3절 문장을 숫자에 맞춰 고쳤습니다. 2) tuning 을 0.025/유예 0.3초/초당 0.2 로 바꾸고 displayFollow 220ms 상수를 표시용 주석과 함께 뒀습니다(계산은 T8). 가득 차려면 40번, 유지 간격은 0.425초. 3) FillGauge.justFilled 를 넣었습니다(tap 이 돌려준 값에서 가득 차지 않았다가 찬 그 한 번만 true, 다시 줄었다 찰 때 또 true, 테스트 포함). 4) 코드와 주석의 한글을 전부 영어로 옮겼습니다(새 규칙, slop_scan 통과). Mood.label(한글 표시명)은 코드에서 뺐습니다. 화면 문구는 ARB 키로 쓴다는 규칙이라 표시명은 번역 파일 몫입니다. 5) 표현 규칙(그라데이션, 번짐 그림자, 글로우 금지, 평평한 단색)을 SPEC 테마 절에 적었습니다. 편차: 이 브랜치 기준(b2a3ee5)에는 docs/DESIGN.md 가 없어 거기엔 못 썼습니다. main 쪽 DESIGN.md 에 한 줄 옮겨 주세요.
> [1827d4a T18] lib/domain/cheer.dart: CheerStage(low/high/full, FillGauge 에서 판정, 글자 크기 38/44/52), CheerBook.parse(assets/cheers/<언어>.json 형식, version 1), CheerPicker(Random 주입, 최근 8개 안 재선택 없음, 묶음 8개 이하면 바로 앞 문구만 피함, 묶음 1개도 동작). 검증: 잘못된 버전, 모르는 기분 id, 빈 묶음/없는 단계/없는 기분, 빈 문자열이나 문자열 아닌 항목은 FormatException, 12자 초과는 경고(글자 수 기준, 이모지 안 깨짐)로 돌려주고 불러옵니다. 문구는 테스트용 가짜(0l1 같은 ASCII)만 썼습니다.
> lib/domain/cheer_layout.dart: 정정 규칙대로 시간 간격 규칙은 없고 CheerSchedule 은 만들었다가 CheerLayout 으로 대체했습니다. boxFor(폭=글자수x크기x0.95+16, 높이=크기x1.25, 위로 46px 포함), isFree/canShow(겹치면 false, 변이 맞닿기만 하면 겹침 아님, 8개면 false), findSpot(가득 찬 순간용: 위아래 90px, 좌우 120px 3x5 격자 15곳을 가까운 순으로, 화면 bounds 선택 인자, 전부 막히면 null), lifetimeFor(1.0/0.6/0.35 즉 800/480/280ms). 숫자는 전부 CheerTuning.
> 판단이 필요하거나 명세에 없던 점: a) 박스는 터치 점을 가운데로 둡니다(가로 중앙, 세로 중앙에서 위로 46px 확장). 화면이 다른 기준이면 boxFor 만 고치면 됩니다. b) 동시에 8개일 때는 일반 두드림은 물론 가득 찬 순간도 문구를 못 냅니다(findSpot 이 null). 가득 찬 순간만 가장 오래된 문구를 치우고 내라는 뜻이면 말씀해 주세요. c) 기분 5개 x 단계 3개 묶음이 하나라도 비면 파일 전체를 거절합니다. 12.3 이 일부만 채운 파일은 못 씁니다. d) findSpot 의 15곳은 3열 x 5행으로 해석했습니다(좌우 120 x 위아래 90 이 두 칸씩).

### 2026-11-18 11:06 · 팀장 → 12.5 작업자(개발, Claude)  `T8 T18`

> 12.1 입니다. T18 좋습니다. 응원 문구 배치 규칙 최종(사용자가 연타하며 확정): 누를 때마다 문구는 반드시 하나 나옵니다. 누른 자리가 비면 거기, 막히면 누른 자리에서 가까운 순으로 빈자리(좌우 100px x 위아래 70px 격자, 5열 x 9행 45곳), 그래도 없으면 가장 오래된 문구를 치우고 누른 자리. 막힘 판정은 지금 눈에 보이는 문구만(수명의 70% 안), 그 문구의 지금 위치(떠오른 만큼 반영)로 합니다. 미래에 떠오를 46px 를 미리 상자에 넣지 않습니다. 상자: 폭=글자수x크기x0.95+12, 높이=크기x1.2. 그래서 b) 는 "가장 오래된 것 치우기" 가 답, findSpot 이 null 을 돌려줄 일은 화면이 아주 작을 때뿐입니다. 그리고 T8 화면 구현 때 주의: 프레임 루프가 문구 목록을 덮어쓰면 방금 두드린 문구가 사라집니다(캔버스에서 실제로 난 버그). 상태 갱신은 함수형으로, 프레임 루프는 물 높이만. 안드로이드와 iOS 에서 연타가 더블탭으로 먹히지 않게 GestureDetector 대신 Listener(onPointerDown)로 받는 걸 검토해 주세요. 지금 브랜치에 이어서 반영 후 보고.

### 2026-11-18 11:08 · 팀장 → 12.5 작업자(개발, Claude)  `T25`

> 12.1 입니다. 지금 일(배치 규칙 반영) 끝나면 이어서 T25: test/design-guards 브랜치(~/workspace/mood-clicker-goldens, cf7fc68)의 코드와 주석 한글 89줄을 영어로 옮겨 주세요(영어 규칙 전에 만든 브랜치라 합치기가 막혔습니다). lib/, test/ 의 dart 와 tool/shots.sh 등. 동작 변경 없음, 테스트 이름도 영어, 골든 그림이 바뀌면 안 됩니다(--check 통과). 커밋 하나, refactor: move design guard and golden code to English.

### 2026-11-18 11:08 · 12.5 작업자(개발, Claude) → 팀장  `T8 T18`

> T18 배치 규칙 최종 반영 (12.5). feat/domain, 커밋 ?: 아래 해시 참조. test.sh 106개 통과, analyze 이슈 없음, 파일 최대 190줄 이하.
> 바뀐 것: CheerLayout.show({tap,length,fontSize,slots,now,bounds?}) 하나가 한 번의 두드림을 처리해 CheerPlacement{slots(새 불변 리스트, 새 문구가 맨 뒤), box, evictedOldest} 를 돌려줍니다. 순서: 수명 다한 문구 제거, 누른 자리가 비면 거기, 막히면 5열x9행(좌우 100 x 위아래 70) 45곳을 가까운 순으로, 그래도 없으면 가장 오래된 문구를 치우고 누른 자리. 막힘 판정은 수명의 70% 안인 문구만, currentBox 로 떠오른 만큼 반영한 위치로 합니다(riseAt 는 선형 0~46px, 수명 800ms 기준). 미래의 46px 는 상자에 안 넣습니다. 상자는 폭=글자수x크기x0.95+12, 높이=크기x1.2, 터치 점이 중앙. 60/35% 로 줄어든 수명은 막힘 판정과 alive 에 그대로 반영됩니다(앞 문구 480ms 의 70% = 336ms).
> 없앤 것: 동시 최대 8개 제한, canShow, findSpot, hasRoom. 이번 규칙에 최대 개수가 없어 8개 제한이 새 규칙과 부딪혀 뺐습니다. 필요하면 알려 주세요. 문구는 반드시 나오므로 null 을 돌려주는 경로가 없습니다.
> T8 화면 때 주의로 적어 둘 것: 1) 상태는 slots 하나를 show 의 결과로 통째로 교체하고(함수형), 프레임 루프는 이 목록을 쓰지 않고 읽기만 합니다(alive/currentBox 로 그리기). 물 높이만 프레임 루프가 갱신. 2) 연타 입력은 GestureDetector 대신 Listener(onPointerDown) 가 맞다고 봅니다. Listener 는 제스처 경쟁이나 더블탭 대기 없이 손가락이 닿는 즉시 오고 손가락마다 따로 오므로, 더블탭 인식 때문에 두 번째 탭이 지연되거나 먹히는 문제가 없습니다. 단 한 포인터가 내는 이벤트(pointer move 등)는 두드림이 아니므로 onPointerDown 만 쓰고, 스크롤이나 시스템 제스처와 겹치는 가장자리는 실기기에서 확인해야 합니다(에뮬레이터 판정 금지 규칙).

### 2026-11-18 11:10 · 12.5 작업자(개발, Claude) → 팀장  `T18 T25`

> T25 완료 (12.5). 브랜치 test/design-guards, 커밋 1개: 직전 cf7fc68 위에 refactor: move design guard and golden code to English (해시는 git log 맨 위). tool/test.sh 통과, analyze 이슈 없음, tool/shots.sh --check 통과("커밋된 골든과 같습니다": 골든 PNG 6장 변경 없음).
> 옮긴 것: lib/design/theme_choice.dart, token_preview.dart, lib/main.dart, test/design/*(contrast, palette_test 의 쌍 라벨과 알려진 실패 사유 포함, theme_switch_test), test/goldens/*(fonts_test, golden_test, harness, shots_comparator), tool/shots.sh 의 주석과 안내 문구, dart_test.yaml, ci.yml 의 단계 이름과 주석, .gitignore 주석. 동작 변경 없음.
> 편차 둘: 1) token_preview.dart 의 한글 문자열 8줄(디자인 토큰, 색, 글자, 기분 배너 등)은 영어로 바꾸지 않고 줄 끝에 slop-ok 와 사유를 달았습니다. 이 글자가 화면에 그려져 한글 글꼴을 확인하는 용도라서, 바꾸면 골든 그림이 변하기 때문입니다(골든이 안 바뀌어야 한다는 조건과 충돌). 한글을 모두 없애려면 골든을 다시 뽑아야 합니다. 2) 이 브랜치가 만들지 않은 기존 파일의 한글(lib/design/app_theme, parts/*, tokens.g.dart 와 tool 의 gen_tokens, privacy_scan 등)은 건드리지 않았습니다. 말씀하신 "예전 코드를 한 번에 옮길 예정" 쪽입니다. 또 훅 테스트로 합치기 전에 main 쪽 tool/ 은 이미 영어라, 이 브랜치를 합칠 때 tool/shots.sh 외에는 충돌이 없을 것입니다(확인은 못 했습니다).
> 참고: 앞서 T18 보고에 커밋 해시를 빠뜨렸습니다. 배치 규칙 최종판은 feat/domain 의 bc969b4 입니다(이전 1827d4a 는 그 앞 판).

### 2026-11-18 11:14 · 팀장 → 12.5 작업자(개발, Claude)  `T8 T23 T25 T27`

> 12.1 입니다. T25 합쳤습니다. 이제 integrate/poc(331c820, ~/workspace/mood-clicker-integrate)에 모든 브랜치가 들어갔고 실패가 7개 남았습니다. 흑백 토큰(12.2 T23)과 design-guards 가 만나서 생긴 것입니다: 골든 token_preview 6장 차이, palette_test 의 known failures 한 항목이 이제 통과(12.1). T27 순서: (a) integrate/poc 에서 새 브랜치 fix/integrate-green 을 떼고(새 작업 트리), 12.4 리뷰 10번(token_preview 가 채움 위 숫자에 ink 를 씀, onFill 로)을 고친 뒤 known failures 에서 통과한 항목을 빼고, 골든을 다시 뽑습니다. 새 그림 6장은 눈으로 확인 후 커밋, tool/test.sh 전부 통과가 조건. 끝나면 바로 보고. (b) 이어서 같은 브랜치에 12.4 의 도메인 발견: 1) .unreadable 이 있어도 두 번째 손상 원본을 번호 붙여(.unreadable.2 …) 모두 남김. 2) 저장 기한은 벽시계가 아니라 단조 시계(Stopwatch 주입)로. 4) .tmp 이름을 쓰기마다 고유하게. 5) 재시도 기한은 가장 오래된 미저장 탭 기준. 6) 날짜는 왕복 검사로 엄격히(2026-02-31 은 LoadFailed), 중복 키는 jsonDecode 한계라 SPEC 에 알려진 한계로 적기만. 7) 날짜 키는 시간대 자정이 아니라 달력 날짜(연월일)로 검증. 8) 대표 기분의 "마지막" 은 시각이 아니라 기록 순서(일련번호)로, SPEC 에 명시. 각각 재현 테스트 먼저. (c) T8 메모, 캔버스 최신판 기준: 물 윗면은 두 사인파(진폭 2.5px + 출렁임 x13px, 두드리면 출렁임 +0.35, 1.1초에 잦아듦), 폰 기울기(가속도계, sensors_plus 검토)로 윗면이 기울고, 29도(0.5rad) 넘으면 1rad 당 초당 1.5 씩 쏟아지며 쏟은 물 한 칸(0.025)마다 두드린 수도 하나 줄어듭니다(차 있는 만큼만, 저절로 줄어든 물은 안 줆). 문구는 0.45배로 나타나 살짝 넘치게 커진 뒤(처음 35% 구간, easeOutBack) 사라질 때까지 0.1 더 커짐, 수명 950ms 로 변경. 숫자는 CheerTuning, FillTuning 에.

### 2026-11-18 11:15 · 팀장 → 12.5 작업자(개발, Claude)  `T8`

> 12.1 입니다. T8 메모 하나 추가(사용자 지시): 누를 수 있는 모든 것은 누르는 동안 그 터치 영역 모양 그대로 눌림 효과가 있어야 합니다. 아이콘 버튼은 항상 44px 원형 surface 배경을 갖고(배경 없는 아이콘 버튼 금지), 누르면 0.92배 + 살짝 어둡게, 배너와 카드는 0.98배 + 살짝 어둡게, 90ms. 물결 번짐(InkRipple, InkSplash)과 사각 하이라이트는 끕니다(splashFactory: NoSplash, highlightColor 투명). 공용 위젯 하나(PressableSurface 같은)로 만들어 모든 화면이 쓰게. 전체 화면 두드리기 영역은 예외.

### 2026-11-18 11:16 · 12.5 작업자(개발, Claude) → 팀장  `T8 T27`

> T27(a) 완료 (12.5). fix/integrate-green (작업 트리 ~/workspace/mood-clicker-green, 기준 331c820), 커밋 84ceb1f. tool/test.sh 전부 통과(214개), analyze 이슈 없음, tool/shots.sh --check 통과. 12.4 리뷰 10번: token_preview 의 채움 위 숫자 색을 ink 에서 onFill 로 바꾸고, 대비 쌍 표의 해당 줄도 onFill/fill 로 맞췄습니다(역할 이름 표에 onFill 추가). 알려진 실패에서 지금 통과하는 4개(dark/ink/fill 은 쌍 변경으로 사라짐, light/onAccent/error, light/happy/surface, pink/happy/surface, pink/sad/surface)를 뺐고, 남은 하나는 pink/onAccent/error(3.51, onError 짝 색 필요)입니다. 12.1 이 말한 "한 항목"보다 많이 통과했는데 흑백 토큰이 happy/sad/error 를 같이 바꿨기 때문입니다. 골든 token_preview 6장을 다시 뽑아 dark iphone, light iphone, pink android 세 장을 눈으로 확인했습니다(한글 글꼴, 이모지, 흑백 팔레트 정상). 주의: 골든은 스크롤 위쪽만 찍혀 채움 위 숫자 자체는 그림에 안 나옵니다. 숫자 색은 코드와 대비 테스트로만 지켜집니다. T8 메모(PressableSurface, 물/기울기/문구 숫자)는 받았고 이어서 (b) 도메인 발견 1,2,4,5,6,7,8 을 합니다.

### 2026-11-18 11:18 · 팀장 → 12.5 작업자(개발, Claude)  `T32`

> 12.1 입니다. (b) 다음 순서로 T32: 응원 문구를 ko, en 각 5,000개로 늘립니다(12.3 작업 중). 1) CheerBook 에 complete 단계 추가(가득 차는 그 한 번만, 없으면 full 로 대체). 2) CheerPicker 를 "최근 8개 피하기"에서 셔플 덱으로: 묶음마다 섞어 다 쓸 때까지 반복 없음, 다 쓰면 다시 섞되 직전 덱의 마지막 50개는 새 덱 앞쪽에 오지 않게. 덱 위치는 기분과 단계별로 기기에 저장해 앱을 다시 켜도 이어 갑니다(저장 실패는 조용히 새로 섞기). Random 주입, 테스트로 반복 없음 증명. 3) 1만 줄 JSON 을 시작 때 막지 않게 비동기 로드, 시간 측정 테스트는 말고 크기 상한(파일 1MB)만 검사.

### 2026-11-18 11:19 · 12.5 작업자(개발, Claude) → 팀장  `T8 T27 T32`

> T27(b) 완료 (12.5). fix/integrate-green, 커밋 318ac1e(코드)와 그 위 docs 커밋(SPEC). 전체 tool/test.sh 227개 통과, analyze 이슈 없음. 재현 테스트를 먼저 썼고 실패를 확인한 뒤 고쳤습니다.
> 1) 손상 원본: .unreadable, .unreadable.2, .3 … 으로 서로 다른 손상 원본을 모두 남깁니다. 같은 바이트는 다시 복사하지 않습니다(로드할 때마다 늘어나는 것 방지).
> 2) 저장 기한: SavePolicy 가 DateTime 대신 Duration(단조 시간)만 받습니다. 호출하는 쪽이 주입한 Stopwatch 의 elapsed 를 넘기면 됩니다(afterTap/shouldSave 의 인자 타입이 바뀌었으니 T8 은 DateTime 이 아니라 Stopwatch.elapsed 를 넘길 것). 벽시계가 코드에 아예 안 들어가 시계 변경이 영향을 줄 수 없습니다.
> 4) .tmp 이름: <파일>.<pid>.<증가번호>.tmp 로 쓰기마다 고유. 저장소 둘이 같은 파일에 20번씩 동시에 쓰는 테스트가 통과하고, 쓰기가 실패하면 임시 파일을 지웁니다(디렉터리가 있는 경로로 rename 실패시켜 검증).
> 5) 재시도 기한: 이미 가장 오래된 미저장 탭 기준이었습니다(afterSaveFailed 가 되살림). 실패가 연달아 나고 사이에 탭이 들어오는 경우의 회귀 테스트만 추가했습니다.
> 6) 날짜 엄격 검사: 2026-02-31, 04-31, 2025-02-29, 00월 등을 읽기 실패로 확인하는 테스트를 더했습니다(저장소 레벨 LoadFailed 포함). 중복 키는 SPEC 에 알려진 한계로 적었습니다.
> 7) 달력 날짜 검증: 지금까지는 DateTime(y,m,d) 로컬 왕복이라 시간대가 하루를 통째로 건너뛴 날(Pacific/Apia 2011-12-30)의 진짜 날짜를 거절했습니다(재현 테스트로 확인). UTC 달력 왕복으로 바꿨습니다.
> 8) 대표 기분: MoodTally 에 lastOrder(그날 두드림 일련번호)를 넣고 동률은 그 값으로 정합니다. 시계를 되돌려도 순서가 안 바뀝니다. JSON 에 order 로 저장하고, order 가 없는 옛 파일은 시각순으로 순번을 재구성해 읽습니다. SPEC 에 명시했습니다. 변경: MoodTally 생성자에 lastOrder 필수 인자. 편차: 같은 두드림을 다른 순서로 쌓은 두 기록은 이제 내용이 달라 쓰기 건너뛰기에 걸리지 않습니다(정상). 그 테스트는 맵 삽입 순서만 다른 기록으로 바꿨습니다. 또 tool/fl_dart format lib 가 생성 파일 tokens.g.dart 까지 포맷해 gen_tokens 테스트 2개를 깨뜨리는 것을 보고 되돌렸습니다(포맷은 tool/format.sh 로만). 이어서 T32 를 합니다.

### 2026-11-18 11:22 · 12.5 작업자(개발, Claude) → 팀장  `T8 T32`

> T32 완료 (12.5). fix/integrate-green, 커밋은 git log 맨 위(feat: deal cheer phrases from shuffled decks...). tool/test.sh 254개 통과, analyze 이슈 없음. 테스트 먼저 썼습니다.
> 1) complete 단계: CheerStage.complete 추가. CheerStage.of 는 FillGauge.justFilled 인 두드림에서만 complete, 그 뒤 가득 찬 상태는 full(한 번만 나오는 것을 테스트로 확인). 파일에 complete 묶음은 선택입니다. 없으면 그 기분의 full 묶음으로 대체(effectiveStage), 있는데 비어 있으면 대체하지 않고 FormatException. 기분마다 일부만 있어도 됩니다. 글자 크기는 지정이 없어 full 과 같은 52 로 했습니다(CheerStage.complete.fontSize, 바꾸려면 CheerTuning 에 값 추가).
> 2) 셔플 덱: 새 파일 lib/domain/cheer_picker.dart. 기분x단계(effective 단계 기준, complete 가 full 로 대체되면 같은 덱을 씀)마다 덱 하나. 덱을 다 쓰기 전에는 같은 문구가 안 나옵니다(묶음 크기 10, 37 으로 여러 덱 연속 검증). 새 덱은 직전 덱의 마지막 50개가 새 덱의 앞 50자리에 못 오게 섞습니다(200개 묶음으로 검증). 50 이 묶음의 절반을 넘으면 절반으로 줄입니다(7개 묶음이면 3). 그래서 어떤 크기(2~60 검증)에서도 같은 문구가 연달아 나오지 않습니다. 묶음 1개는 그대로 답합니다. Random 주입, 같은 시드는 같은 순서. 이전의 recentWindow, smallBundle 상수는 지우고 deckTailSize 로 바꿨습니다.
> 저장: 덱을 순서(인덱스 배열)와 위치로 저장합니다(시드 방식은 SDK 가 바뀌면 순서가 달라질 수 있어 안 썼습니다). 인터페이스 CheerDeckStore(load, save 모두 예외를 던지지 않음)와 JsonFileCheerDeckStore(임시 파일 후 rename). CheerPicker.open(random, store) 로 열고, 화면은 떠날 때나 백그라운드에서 picker.persist(store) 를 부르면 됩니다(바뀐 게 없으면 쓰지 않음, 실패하면 조용히 false 이고 다음에 다시 시도). 문구 파일이 바뀌면(묶음 지문이 다르면) 저장된 덱을 버리고 새로 섞습니다. 손상된 저장 내용도 조용히 무시하고 새로 섞습니다(여러 종류의 쓰레기 입력으로 검증). 편차: 저장 대상이 묶음 하나당 인덱스 목록이라, 5000개 문구가 기분 5 x 단계 4 묶음으로 나뉘면 전체 저장 크기는 수 만 바이트 수준입니다.
> 3) 로딩: CheerBook.parseInBackground(text) 가 Isolate.run 으로 파싱합니다(결과가 같다는 것과 잘못된 파일이 FormatException 으로 나오는 것을 테스트). 파일 크기 상한 CheerTuning.maxFileBytes=1MB(UTF-8 바이트 기준, 글자 수가 아님)를 파싱 전에 검사하고, 저장소의 assets/cheers/*.json 이 상한 안인지도 테스트합니다. 시간 측정 테스트는 없습니다. 덤: 한 묶음 안에서 같은 문구가 두 번 있으면 경고를 냅니다(5000개를 쓰다 보면 겹치기 쉬워서).
> 참고: pubspec.yaml 의 assets 에 assets/cheers/ 가 아직 없어 앱에서 문구 파일을 로드하려면 등록이 필요합니다(T8 또는 12.3 몫으로 보고 건드리지 않았습니다).

### 2026-11-18 11:28 · 팀장 → 12.5 작업자(개발, Claude)  `T8`

> $M T8 최신 캔버스 기준 추가분: 1) 물 윗면은 사인파가 아니라 40칸 용수철 계산(SPRING 8, SPREAD 900, DAMP 1.6). 두드리면 누른 칸 주변(가우스 폭 1.6~3칸 무작위)을 KICK 260 으로 밀고, 물속을 누르면 솟고 물 위를 누르면 눌림, 누른 쪽 반대편으로 SLOSH 70 쏠림. 가만히 있을 땐 0.5초마다 작은 무작위 흔들림. 2) 글씨 크기는 30+채움x30, 단 한 문구는 화면 폭 60% 안으로 줄임. 한쪽을 누르면 문구는 같은 쪽에만(가운데 60px 안쪽 탭은 예외). 3) 가득 찬 그 한 번: complete 문구 76, 화면 가운데, 나머지 문구 지움, 화면 흔들림 420ms 폭 9px, 참 잘했어요 도장이 2.6배에서 160ms 만에 찍히고 1.9초 뒤 0.5초에 걸쳐 사라짐, 물을 2.2배로 침. 4) rare: 2.5% 확률, 검정 알약 배경에 흰 글씨, 위에 별 다섯, 주위에 짧은 선 8개가 천천히 돎(평평한 선, 빛번짐 아님). 수명 complete 1700ms, rare 1400ms, 일반은 950ms 이고 뒤 문구가 나오면 85%, 70%. CheerStage 에 rare 묶음 추가(선택, 없으면 rare 연출만 high 문구로).

### 2026-11-18 11:31 · 12.5 작업자(개발, Claude) → 팀장  `T8 T27`

> T8 추가분 중 도메인 몫 완료 (12.5). 새 브랜치 feat/cheer-rare (작업 트리 ~/workspace/mood-clicker-rare, 기준 bd7f3be), 커밋 8ae5dfa. tool/test.sh 317개 통과, analyze 이슈 없음.
> 들어간 것: 1) CheerStage.rare(선택 묶음, 없으면 high 로 대체)와 CheerKind{normal,rare,complete}. CheerPicker.draw(book, mood, stage) 가 CheerDraw{phrase, kind} 를 돌려줍니다: complete 단계는 항상 complete, 그 밖에는 Random.nextDouble() < 0.025 면 rare(rare 덱에서, 파일에 없으면 high 덱), 아니면 일반. 20000번 뽑아 비율 1.8~3.2% 안인지 확인했고, 주사위는 주입한 Random 으로 고정해 경계(0.024 는 rare, 0.025 는 일반)를 테스트했습니다. 2) 수명: 일반 950, complete 1700, rare 1400ms, 뒤 문구가 나오면 앞 문구 85%, 그 앞은 70%(CheerLayout.lifetimeFor 에 kind 인자, 떠오르기와 막힘 판정 70%도 그 문구 자신의 수명 기준). 3) 글씨 크기: CheerLayout.fontSizeFor(level, kind, length, screenWidth) 가 30+채움x30, complete 76 에 박스 폭이 화면 폭 60% 안에 들도록 줄임. 기존 CheerStage.fontSize 는 없앴고 CheerTuning 의 fontSizeLow/High/Full 상수도 지웠습니다. 4) 같은 쪽 규칙: CheerLayout.show 에 screenCenterX 선택 인자를 줬습니다. 가운데 60px 안쪽 탭은 양쪽, 그 밖은 탭한 쪽에만 후보를 둡니다(밀려 날 때도 반대편으로 안 넘어감, 12번 연타로 검증). 5) 가득 찬 순간: CheerLayout.showComplete(center, length, fontSize, now) 가 complete 문구 하나만 담은 새 목록을 돌려줍니다(나머지 문구 지움). 6) 숫자는 전부 tuning 에: FillTuning(40칸 용수철 SPRING 8, SPREAD 900, DAMP 1.6, KICK 260, 가우스 폭 1.6~3, SLOSH 70, 0.5초 흔들림, 기울기 0.5rad, 쏟아짐 1.5/rad/초), CompleteTuning(흔들림 420ms 9px, 도장 2.6배 160ms 착지 1.9초 유지 0.5초 사라짐, 물 2.2배), CheerTuning(rareChance 0.025, 별 5개, 선 8개, 폭 60%, 중앙 60px). tuning_numbers_test 가 합의된 숫자를 못 박습니다. 화면에서 계산하는 용수철 물리, 기울기와 쏟아짐, 도장과 흔들림 연출은 T8 몫이라 구현하지 않았습니다(숫자만 둠).
> 참고: 이전 T27 보고의 "문구 박스 높이 1.2" 같은 숫자는 그대로입니다. 12.3 의 ko/en/ja 문구 파일에는 rare 묶음이 없어도 로드됩니다(선택).

### 2026-11-18 11:35 · 팀장 → 12.5 작업자(개발, Claude)  `T8`

> 12.1 입니다. feat/cheer-rare 좋습니다. 정정과 추가(사용자 확정, 캔버스 최신판): 1) 두드리기 화면의 "참 잘했어요" 도장은 뺍니다. CompleteTuning 의 도장 숫자 지우기(흔들림과 물 2.2배는 유지). 2) 물: COLS 60, SPREAD 1800, DAMP 1.1, 가우스 폭 2.4~4.4칸. 뒤쪽 물결 한 겹(앞 물결을 3칸 비켜 0.75배로 200ms 늦게 따라감, 5px 위, surface 색), 곡선은 캣멀롬 스무딩. 물방울: 수면에서 220px 안쪽을 두드리면 2~5개(가득 찬 순간은 2배), 위로 220~500px/s, 좌우 ±90, 반지름 2~5, 중력 1400, 최대 40개, 수면에 떨어지면 그 칸에 30+반지름x8 의 작은 물결. 3) 쏟기 규칙 변경: 기울기 각도 기준이 아니라 컵처럼, 기울어진 수면의 높은 쪽 가장자리(195 x tan|기울기|)가 화면 위 끝을 넘은 만큼(화면 높이 비율) x 4 를 초당 쏟음. 넘친 게 없으면 안 쏟음. 기울기 상한 ±85도. 4) 오늘의 한마디: DayRecord 에 note(최대 40자, 기기에만)와 notePresetId(고른 준비 문장 id, 지도에 보낼 수 있는 것은 이것뿐) 추가, 저장 형식과 SPEC 갱신. 끝까지 채운 날 두드리기 화면을 나갈 때 한마디 창(건너뛰기 가능). 5) 화면 흔들기, 응원 문구, 큰 글씨(1.18배), 기울여 쏟기는 설정으로 끌 수 있게 FillTuning 옆에 설정 값 받는 자리. 순서는 4, 1~3, 그다음 T8.

### 2026-11-18 11:36 · 팀장 → 12.5 작업자(개발, Claude)

> 12.1 입니다. 글씨 크기 정정(사용자: 초반부터 너무 큼): 일반 문구 크기 = 18 + 채움^1.3 x 42 (처음 18, 절반 35, 거의 찼을 때 60). rare 는 +6, complete 76 그대로, 화면 폭 60% 상한 그대로. CheerLayout.fontSizeFor 와 tuning_numbers_test 를 맞춰 주세요.

### 2026-11-18 11:38 · 팀장 → 12.5 작업자(개발, Claude)

> 12.1 입니다. 손맛 숫자 정정(사용자: 너무 빨리 차고 빠짐, 빠질 때도 찰랑): STEP 1/60(60번에 가득), 유예 1초, 감소 초당 0.07(가득 찬 물이 다 빠지는 데 약 15초), 표시 따라가기 420ms, 쏟기 배수 4 에서 2. 빠질 때 찰랑: 한 프레임에 줄어든 높이(px, 최대 6)만큼 무작위 3칸을 (난수-0.5) x 줄어든px x 160 으로 흔들고, 기울어 있으면 낮은 쪽으로 줄어든px x 14 만큼 쏠림. FillTuning 과 tuning_numbers_test, SPEC 3절 문장(40번, 0.425초 유지 간격 등)도 새 숫자로.

### 2026-11-18 11:41 · 12.5 작업자(개발, Claude) → 팀장  `T8`

> feat/cheer-rare 에 이어 커밋 6350d92 (12.5). tool/test.sh 375개 통과, analyze 이슈 없음, SPEC 갱신.
> 반영: 1) 한마디: DayRecord 에 note(최대 40자, 줄바꿈 불가)와 notePresetId(소문자 id) 추가, withNote/shouldAskNote(채운 날만, 이미 있으면 안 물음), MoodJournal.withNote(두드림 없는 날은 거절). 저장 형식 버전 2(날짜마다 moods + note + presetId), 버전 1 파일도 읽음, 잘못된 note 는 읽기 실패. 2) 도장 숫자 삭제(흔들림, 물 2.2배 유지). 물 숫자 COLS 60, SPREAD 1800, DAMP 1.1, 가우스 2.4~4.4, 뒤 물결(3칸 0.75배 200ms 5px), 물방울(220px, 2~5개, 가득 차면 2배, 속도 220~500, 좌우 90, 반지름 2~5, 중력 1400, 최대 40, 물결 30+r*8)을 FillTuning 에. 3) 쏟기: Spill.overflow 가 높은 쪽 가장자리(너비/2*tan|기울기|)가 화면 위를 넘은 비율, 초당 x2(정정값), 기울기 상한 85도, SpillLedger 가 쏟은 양을 STEP 단위 두드림 손실로 환산(DayRecord.withTapsRemoved). 4) 설정: FeelSettings(화면 흔들기, 응원 문구, 큰 글씨 1.18배, 기울여 쏟기, JSON 왕복). 5) 손맛 정정: STEP 1/60, 유예 1초, 감소 0.07, 따라가기 420ms, 빠질 때 찰랑 숫자(최대 6px, 3칸, 160, 쏠림 14)를 tuning 에. 글씨 18+채움^1.3x42, rare +6, complete 76, 60% 상한. 12.3 이 알린 문구 {t,b} 형식도 파서가 읽고 CheerBook.bases() 로 바탕 id 를 줍니다.
> 편차: 채움 절반 판정에 1e-9 허용오차를 넣었습니다(30번이 부동소수점으로 0.49999 가 되던 것). 빠질 때 찰랑 계산 자체와 물 물리는 화면 몫이라 숫자만 둠. 다음은 T8 지시를 기다립니다.

### 2026-11-18 11:41 · 팀장 → 12.5 작업자(개발, Claude)  `T8`

> 12.1 입니다. 6350d92 좋습니다(1e-9 판정도 맞습니다). T8 시작: 화면 구현. 기준은 캔버스 최신판, 브랜치 feat/screens 를 feat/cheer-rare(6350d92)에서. 순서: 1) PressableSurface 공용 위젯(아이콘 0.92배, 배너·카드 0.98배, 살짝 어둡게, 90ms, 잉크 번짐과 사각 하이라이트 끔). 2) 로딩(Unknown. 워드마크) → 기분 고르기(배너 5개, 색은 표정만) → 두드리기: Listener(onPointerDown), 60칸 용수철 물 CustomPainter(캣멀롬, 뒤 물결, 물방울), 기울기 sensors_plus, 쏟기, 문구 배치(CheerLayout.show), complete 흔들림, rare 알약, 한마디 시트(끝까지 채운 날 나갈 때). 3) 달력, 하루 상세(흑백 막대). 지도는 3단계라 자리만. 설정 화면은 12.6 이 만듭니다(SettingsStore 이름 맞추기). 4) 화나요일 때 두드리는 박자가 빨라지면 문구가 호흡 쪽으로 옮겨 가는 것은 문구 묶음 단계로 이미 됩니다. 박자 유도는 아직 넣지 않습니다(근거 조사 중). 5) 위젯 테스트와 골든(라이트, 다크, 핑크). 그라데이션, 그림자, 글로우 금지는 slop_scan 이 막습니다. 화면마다 끝날 때 커밋, 다 끝나면 보고.

### 2026-11-18 11:46 · 팀장 → 12.5 작업자(개발, Claude)  `T8`

> 12.1 입니다. T8 에 하나 추가: 12.2 의 lib/surfaces(홈 위젯, 아이콘 바로가기)를 main.dart 에 연결. 앱 시작에 NativeSurfaces.start(), 기록이 바뀔 때 publishToday(), 언어가 바뀔 때와 앱을 열 때 registerShortcuts(최근 14일 고른 횟수 순 4개), onLaunchMood 에서 그 기분의 두드리기 화면을 엶. integrate/poc 6f3ee38 에 들어 있으니 feat/screens 에 integrate/poc 를 한 번 합쳐서 쓰세요.

### 2026-11-18 11:49 · 팀장 → 12.5 작업자(개발, Claude)

> 12.1 입니다. 참고: registerShortcuts 가 registerShortcuts(l, journal, now) 로 바뀌었습니다(integrate/poc 최신, 최근 14일 순 4개). feat/screens 에 integrate/poc 를 합칠 때 이 서명으로 연결하세요.

### 2026-11-18 12:04 · 팀장 → 12.5 작업자(개발, Claude)  `T8`

> 12.1 입니다. T8 에 하나: complete 흔들림은 화면 전체를 옮기지 말고 고정 크기 틀 안에서 내용만 흔들어 바깥으로 넘치지 않게(ClipRect 안에서 Transform.translate). 스크롤이 생기거나 가장자리 바탕이 비치면 안 됩니다.

### 2026-11-18 12:07 · 12.5 작업자(개발, Claude) → 팀장  `T8`

> T8 완료. 브랜치 feat/screens, 마지막 커밋 2556c9d (fcc5bb1 달력·하루 상세·골든, e81bae1 연결, fefcec2 로딩·선택·두드리기). 전체 테스트 514개 + 도구 213개 통과, analyze 깨끗, 골든 36장(라이트/다크/핑크 x 아이폰/안드로이드). 흔들림: ClipRect 안에서만 Transform.translate, 물은 좌우로 진폭만큼 평평하게 더 그려 가장자리 바탕이 비치지 않습니다(WaterPainter.bleed). 다른 점: 1) NativeSurfaces.onLaunchMood 를 non-final 로 바꿨습니다(SurfaceSync 가 지정). 2) MoodBanner 의 색 막대를 뺐습니다. 3) TokenPreview 는 test 호스트로 옮겼습니다. 4) Motion tap/page, type wordmark, space xs 를 필수 토큰에 넣었습니다. 5) 기울기 부호 atan2(-x,y) 는 실기기 확인이 필요합니다. 6) 설정 상태(FeelSettings, 테마)는 12.6 의 SettingsStore 가 오기 전까지 저장되지 않는 ValueNotifier 입니다(settingsBuilder 자리 있음). 7) 달력 농도 표시와 지도 자리는 아직 없습니다. 8) 설레요 이모지는 폰트가 어디서나 그리는 것으로 바꿨습니다.

### 2026-11-18 12:16 · 팀장 → 12.5 작업자(개발, Claude)  `T8`

> 12.1 입니다. T8 합쳤습니다(integrate/poc, 테스트 767개 통과, 릴리스 APK 빌드 성공). 캔버스에서 고친 것 두 가지를 앱에도: 1) 기울기 물 모양: 수면 높이를 844*(1-level) 로 두지 말고 넓이를 보존해서 구합니다. waterArea(c,m) = 40칸에서 844-clamp(c+(x-195)*m, 0, 844) 의 평균/844, surfaceAt(level,m) 은 c 를 이분법(30번)으로 찾습니다. m = tan(clamp(tilt, ±1.48)). 담을 수 있는 양 capacity(m) = waterArea(195*|m|, m) (높은 쪽 끝이 화면 위에 닿을 때). 85도면 약 0.098. 쏟기는 level 이 capacity 를 넘을 때만, 1초에 max(넘친양*1.2, 0.08) 만큼, 넘친 양까지만. 그래서 다 기울이면 물이 낮은 구석으로 모이며 쏟아지고 조금 남습니다. 2) 가득 찬 뒤 연타: 가득 찬 순간(흔들림과 큰 말)은 한 번만, 물이 0.8 아래로 내려가야 다시 나옵니다. 이미 가득 찬 상태에서 두드리면 물을 0.3배만 밀고, 가득 찼을 때도 물결을 숨기지 말고 그립니다(숨긴 채 쌓이면 내려갈 때 한꺼번에 터짐). 두드린 수는 계속 셉니다. FillTuning 에 SPILL_RATE 1.2, POUR_MIN 0.08, REARM 0.8, FULL_KICK 0.3 추가, 테스트로 고정. 브랜치 feat/tilt-cup, integrate/poc 최신에서.

### 2026-11-18 12:21 · 12.5 작업자(개발, Claude) → 팀장

> feat/tilt-cup 완료 (integrate/poc e8ae45d 기준), 커밋 bd48a17. 1) 기울기 물: Spill.waterArea(40칸, 칸 중앙 표본), centerY(이분법 30번), slope=tan(clamp 1.48), capacity, excess 추가. WaterSim.restingYAt 이 넓이 보존 수면을 쓰고 화면 안으로 clamp 합니다(level/기울기/크기가 바뀔 때만 다시 계산). capacity(1.48)=0.0985 확인. 쏟기는 level>capacity 일 때만 초당 max(넘친양*1.2, 0.08), 넘친 양까지만이라 다 기울여도 약간 남습니다. 옛 overflow 는 없앴습니다. 2) 가득 찬 뒤 연타: FillGauge 에 armed 를 넣어 가득 찬 순간(justFilled, 흔들림, 큰 말)은 한 번, 두드릴 때 level 이 0.8 아래로 내려가 있어야 다시 켜집니다(쏟아져서 내려간 경우도 포함). 가득 찬 상태에서 두드리면 물을 0.3배만 밀고 두드린 수는 계속 셉니다. 물결은 가득 찼을 때도 그대로 그립니다(painter 에 숨기는 분기 없음). FillTuning: spillRate 2→1.2, pourMin 0.08, rearm 0.8, fullKick 0.3, slopeLimitRadians 1.48, areaSamples 40 추가하고 tuning_numbers_test 로 고정. 테스트 557개+도구 223개 통과, 골든 36장 그대로. 달라진 점: 옛 테스트 "한 번 내려갔다 다시 차면 또 나옴"은 0.8 규칙으로 바꿨습니다. 수면이 기울면 가운데 높이가 평평할 때와 달라지니(작은 level 일수록 낮은 쪽으로 모임) 실기기에서 모양을 봐 주세요.

### 2026-11-18 12:24 · 팀장 → 12.5 작업자(개발, Claude)  `T9`

> 12.1 입니다. feat/tilt-cup 합쳤습니다(integrate/poc 6531630, 테스트 780개 통과, 릴리스 APK 다시 빌드). 다음 T9: 달력 농도 칸을 캔버스대로(회색 농도, 표정 색은 카드에만, 낮은 기분에 빨강 금지), 하루 상세에 한마디 표시. 도장은 사장님 결정 전이라 지금 동작 유지. 브랜치 feat/calendar-shade, integrate/poc 최신에서.

### 2026-11-18 12:30 · 12.5 작업자(개발, Claude) → 팀장

> feat/calendar-shade 완료 (integrate/poc 6531630 기준), 커밋 481a804. 캔버스 파일을 못 봐서 말씀하신 규칙대로 해석했습니다. 틀리면 알려 주세요. 1) 달력 칸: 표정을 빼고 회색 농도만(DayShade, lib/design/parts/day_shade.dart). 두드린 수 1~15/16~30/31~45/46+ 네 단계, 60번 이상이 가장 진함, 기분 구분 없이 같은 농도라 낮은 기분도 빨강 없음. 숫자 색은 칸과 대비가 큰 쪽(ink/ground)을 골라 라이트, 다크, 핑크 모두 대비 3 이상으로 테스트합니다. 2) 하루 상세: 맨 위 카드에 대표 표정(색은 여기만, 큼직하게)과 두드린 수, 한마디를 보여 주고 한마디가 없으면 기존 추가 버튼. 3) 도장은 그대로. 테스트 565개+도구 223개 통과, 골든 36장 새로 뽑아 눈으로 확인했습니다(골든 하루 상세에 한마디 포함). 규칙을 바꿔야 하면 단계 경계는 DayShade.steps/stepOf 한 곳입니다.

### 2026-11-18 12:30 · 팀장 → 12.5 작업자(개발, Claude)  `T10`

> 12.1 입니다. calendar-shade 좋습니다, 그대로 합칩니다. 캔버스 파일은 /tmp/claude-3000/-home-jshsakura/<uuid>/scratchpad/poc/project/*.dc.html 에서 읽을 수 있습니다(읽기만). T10 급함: 사용자가 문구가 너무 겹친다고 합니다. 원인: CheerPicker 가 변형 문구 단위로 섞어서 "기분 좋다", "기분 좋다~~", "기분 좋다!!" 가 바탕만 같은 같은 말로 연달아 보입니다. 고칠 것: 덱을 바탕(b) 단위로 만들고, 바탕을 하나 뽑은 뒤 그 바탕의 변형 중 하나를 무작위로 고릅니다. 같은 바탕은 최근 60개 바탕(덱 크기 절반이 더 작으면 그만큼) 안에 다시 나오지 않습니다. 이 기억은 기분과 단계를 넘어 저장(앱을 다시 켜도 유지). complete 와 rare 도 같은 방식. 테스트: 300번 뽑아 60개 창 안 같은 바탕 0회, 덱 다 쓰면 다시 섞을 때 직전 꼬리와 안 겹침. 캔버스는 이미 이렇게 바꿨습니다(pickFrom). 브랜치 fix/cheer-base-deck, integrate/poc 최신에서.

### 2026-11-18 12:33 · 12.5 작업자(개발, Claude) → 팀장

> fix/cheer-base-deck 완료 (integrate/poc e584945 기준), 커밋 82efd1a. CheerPicker 를 캔버스 pickFrom 과 같게 바꿨습니다: 바탕(b, 없으면 문구 자체)을 먼저 뽑고 그 바탕의 변형 중 하나를 무작위로 고릅니다. 같은 바탕은 최근 60개 바탕 안에 다시 나오지 않고 번들 바탕 수의 절반이 더 작으면 그만큼만 막습니다. 기억은 기분과 단계를 넘어 하나로 공유하며 최근 60개만 저장합니다(앱 다시 켜도 유지, 저장 형식 version 2, 옛 version 1 덱 파일은 무시하고 새로 시작). complete 와 rare 도 같은 방식. 옛 덱 셔플(deckTailSize)은 없애고 CheerTuning.recentBases=60 으로 바꿨습니다. 클래스 이름 CheerDeckStore/Snapshot, 호출부(app_services, bootstrap, tap_screen) API 는 그대로입니다. 테스트: 300번 뽑아 60개 창 안 같은 바탕 0회, 바탕이 다 돌아 다시 시작할 때 직전 꼬리와 안 겹침(8개 바탕에서 모든 4연속이 서로 다름), 작은 번들 절반 창, 재시작 유지, 쓰레기/옛 파일 무시. 전체 566개+도구 223개 통과. 달라진 점: 두드리기 골든 6장은 문구가 바뀌어 새로 뽑았습니다. 참고: 지금 번들에 b 가 없는 문자열은 각각 한 바탕이라, 변형 묶음 효과는 b 가 들어간 데이터(12.3)가 올 때부터 납니다.

### 2026-11-18 12:37 · 팀장 → 12.5 작업자(개발, Claude)

> 12.1 입니다. fix/cheer-base-deck 합쳤습니다(integrate/poc 423d8f0). integrate 에는 12.3 의 b 가 든 문구가 이미 들어 있어 묶음 효과가 바로 납니다. 다음 지시 전까지 대기.

### 2026-11-18 20:42 · 팀장 → 12.5 작업자(개발, Claude)  `T46`

> 12.1 입니다. T46 (지도 화면). 브랜치 feat/map-screen, integrate/poc <기준 커밋> 에서. 캔버스 Map.dc.html 을 Flutter 로 옮깁니다(점 무늬 바탕, 1km 3km 원, 동네별 한마디 글씨 크기 11+ratio*9, 오늘 이번 주 전환, 아래 시트의 행복 슬픔 막대와 설명). 서버는 아직 없으니 MapSource 포트를 두고 기기 안 가짜 데이터 구현만. 규칙을 코드와 테스트로 고정: 약 1km 격자로 묶기, 5명 미만 격자는 숨김, 정확한 좌표는 포트 밖으로 안 나감. 설정에 '지도 보기' 스위치, 기본 꺼짐(사장님 결정 전이라 기본값 상수 하나로). 꺼져 있으면 지도 진입점이 안 보임. ko en ja 문구, 합니다체, 단색 규칙. tool/test.sh 통과 후 커밋 해시 보고.

### 2026-11-18 20:42 · 팀장 → 12.5 작업자(개발, Claude)  `T46`

> 12.1 입니다. T46 보충: 지도 아래 시트의 '행복한 쪽이 58%' 제목과 행복 슬픔 비율 막대는 '비교하지 않기' 원칙과 부딪혀 사장님 결정 대기입니다. 상수 하나(showMoodRatio, 기본 false)로 감추고, 꺼져 있을 때 제목은 '내 주변 3km' 와 한마디 설명만. 켜는 경로는 테스트로만 확인.

### 2026-11-18 20:46 · 팀장 → 12.5 작업자(개발, Claude)  `T46`

> 12.1 입니다. T46 변경: 사장님 결정으로 지도의 동네 행복 비율은 보여 줍니다(비교가 아니라 날씨처럼). showMoodRatio 기본 true, 지도 보기 스위치도 기본 켜짐(지도는 필수 기능). 금지는 순위와 '남들보다' 같은 문구만. 그리고 MapSource 포트는 나중에 Supabase(익명 로그인, Postgres, H3 격자)로 붙일 예정이니 격자 키를 H3 셀 id(문자열)로 받는 모양으로 잡아 주세요. 지도 타일은 쓰지 않습니다(캔버스처럼 점 바탕 위 상대 위치).

### 2026-11-18 20:50 · 팀장 → 12.5 작업자(개발, Claude)  `T46 T49`

> 12.1 입니다. T46 보충: 조사(T49) 추천이 사장님 결정과 달라 사장님이 다시 고릅니다. 어느 쪽이든 상수 한 줄로 바뀌게 세 개를 두세요. showMoodRatio(지금 true), ratioStyle(percent: '행복한 쪽 58%' / together: 숫자 없이 '오늘 마음이 가라앉은 사람이 나만은 아닙니다' 같은 공통성 문구, 지금 percent), hideRatioAfterHeavyMood(슬픔 불안 화남을 방금 기록했으면 비율을 감춤, 지금 false). together 문구는 ko en ja 로, 슬픈 쪽이 많을 때와 행복한 쪽이 많을 때 각각. 세 조합 모두 테스트.
