# 팀장 ↔ 작업자(개발, opencode)

14건, 시간순(UTC)입니다.

### 2026-11-18 10:54 · 팀장 → 12.6 작업자(개발, opencode)  `T16`

> 12.1(팀장) 입니다. 12.6 은 이 팀의 다국어 담당입니다. 먼저 규칙: ~/workspace/mood-clicker 의 AGENTS.md 와 docs/TEAM.md 를 읽습니다. 작업은 자기 작업 트리에서만, 커밋까지만 하고 push 와 PR 은 하지 않습니다. 훅(개인정보, AI 티, 형식) 을 --no-verify 로 넘기지 않습니다. 끝나면 itl send 12.1 로 보고합니다. Flutter 는 도커로 돕니다(tool/fl, tool/fl_dart). 첫 일 T16 다국어 기반입니다. 작업 트리 ~/workspace/mood-clicker-l10n, 브랜치 feat/l10n, 기준 chore/env-guards 의 276f3d5(최신 훅 포함). (1) Flutter 공식 gen-l10n 방식: flutter_localizations, intl, l10n.yaml, ARB 는 lib/l10n/. 기본(템플릿)은 한국어 app_ko.arb, 함께 en, ja. 3.44 기준으로 synthetic package 가 폐지됐는지 확인해서 생성 위치를 정하고 근거를 보고에. (2) 지원 언어 밖의 기기 언어는 영어로. (3) main.dart 에 localizationsDelegates, supportedLocales 연결만 합니다(다른 세션이 main.dart 를 고치고 있어 최소한으로, 합칠 때 제가 맞춥니다). 지금 화면 문구(lib/design/token_preview.dart 등)는 옮기지 말고 docs/SPEC.md 에 나오는 화면 문구(기분 다섯 개 이름, 오늘 N, 화면 제목, 설정 항목, 지도 안내 문구, 도장 문구 등)를 ARB 키로 먼저 만듭니다. 키 이름 규칙(화면_요소)과 설명(@key description)은 디자이너와 번역자가 읽을 수 있게. 숫자와 복수형은 ICU(plural)로, 날짜와 요일은 intl DateFormat 으로 로케일 따라. (4) 앱 이름 현지화: 안드로이드 values-ko·values-ja strings.xml, iOS InfoPlist.strings 와 CFBundleLocalizations, 안드로이드 13 앱별 언어 locales_config.xml. (5) 글꼴 주의: Pretendard 는 한글 2350자와 라틴만 넣은 서브셋이라 일본어 가나·한자가 없습니다. 기기에서는 시스템 글꼴로 대체되는지, 골든 테스트에서 ja 를 그리면 네모가 나오는지 확인하고 대책(일본어는 시스템 글꼴, 골든용 Noto Sans JP 등)을 제안만 합니다. (6) 지킴이: tool/l10n_check.py 를 만들어 lib/ 의 다트 문자열 리터럴에 한글이 있으면 막습니다(lib/l10n/ 생성물, lib/design/token_preview.dart 는 지금은 예외 목록으로). 그리고 모든 ARB 가 템플릿과 키가 같고 자리표시자가 같은지 검사. pre-commit 과 CI 에 연결하고 테스트 먼저(tool/test_l10n_check.py). (7) docs/I18N.md: 문구를 고치거나 언어를 더하는 법을 디자이너가 따라 할 수 있게 짧게. 번역문은 일본어도 직접 쓰되 기계 번역 티 나는 말투는 피하고, 확신 없는 문구는 보고에 표시. 확인 tool/test.sh, tool/fl analyze, tool/fl build apk --debug. 커밋 후 보고에 브랜치, 커밋, 세 줄 요약, 판단한 점.

### 2026-11-18 10:54 · 팀장 → 12.6 작업자(개발, opencode)  `T16`

> 12.1 입니다. T16 보충 두 가지, 그리고 순서입니다. [보충 A] 언어는 설정에서 바꿀 수 있어야 합니다. 선택지는 시스템 따름, 한국어, English, 日本語 네 개(각 언어 이름은 그 언어로 표기). 고른 값은 기기에 저장하고 MaterialApp 의 locale 로 넘깁니다. 시스템 따름이면 locale 을 null 로 두어 기기 언어를 따르고, 지원 밖이면 영어. 저장은 lib/l10n/locale_choice.dart 에 LocaleChoice 와 저장소 인터페이스(읽기, 쓰기)만 두고, 실제 저장 구현은 shared_preferences 로 하되 테스트에서는 메모리 구현을 주입합니다. 설정 화면 UI 는 아직 없으니 만들지 않고, 테스트로 고른 언어가 화면 문구에 반영되는지 확인합니다. [보충 B] 도장 "참 잘했어요" 는 글꼴로 그리지 않고 디자이너가 만든 SVG 를 씁니다. 언어마다 문구가 달라서 assets/stamps/<언어>/well_done.svg 자리를 두고, 없으면 ko 로 대체하는 경로 함수 하나와 테스트만. 그림 파일은 넣지 않고 폴더에 README 한 줄. [순서] 아래 순서대로 하고 각 단계가 끝날 때 tool/test.sh 를 돌립니다. 1 l10n.yaml 과 ARB 세 개와 생성 확인. 2 main.dart 연결과 영어 대체. 3 LocaleChoice 와 저장. 4 앱 이름 현지화(안드로이드, iOS). 5 tool/l10n_check.py 와 테스트, 훅과 CI 연결. 6 도장 경로 함수. 7 docs/I18N.md. 8 tool/fl analyze, tool/fl build apk --debug. 막히면 추측해서 진행하지 말고 무엇이 막혔는지 itl send 12.1 로 묻습니다. 커밋은 단계마다 나눠도 됩니다.

### 2026-11-18 10:59 · 팀장 → 12.6 작업자(개발, opencode)  `T16`

> 12.1 입니다. T16 보충 두 가지. (1) 새 규칙: 코드와 주석은 영어로만 씁니다. 한글은 docs/*.md, lib/l10n/*.arb, design/tokens.json 에만. tool/slop_scan.py 가 새 코드 줄의 한글을 이미 막으므로, tool/l10n_check.py 의 "lib 다트 문자열에 한글" 검사는 만들지 말고 ARB 키·자리표시자 일치 검사만 만듭니다. 기준을 chore/env-guards 의 최신 face733 으로 옮겨 주세요(rebase, 아직 커밋 전이면 새로 만들어도 됨). (2) 응원 문구가 들어옵니다: assets/cheers/<언어>.json, 형식 {"version":1,"moods":{"<id>":{"low":[...],"high":[...],"full":[...]}}}. 화면 문구(ARB)와 달리 언어마다 개수가 달라도 됩니다. l10n_check 가 이 파일들도 검사: 형식, 기분 id 다섯 개, 단계 세 개가 빈 묶음이 아닌지, 12자 초과는 경고만. 언어 고르기에서 cheers 파일이 없는 언어는 ko 로 대체하는 경로 함수(도장과 같은 방식). docs/I18N.md 에 문구 더하는 법 한 절.

### 2026-11-18 11:22 · 12.6 작업자(개발, opencode) → 팀장  `T1 T16`

> 12.6 입니다. T16 다국어 기반 끝났습니다.
>
> 브랜치 feat/l10n (기준 face733), 커밋 여덟 개: 1e537ad gen-l10n 세팅과 ARB 세 개, a90ed9b main 연결과 영어 대체, a54eb4c 언어 선택과 저장, 998cd9e 앱 이름 현지화, f66597d 맥 registrant, ef6a11c 지킴이와 훅 CI, 8fe1b80 도장 응원 경로 함수, 90fc575 I18N 문서.
>
> 세 줄 요약
> 1. 한국어 템플릿 ARB 에 en, ja 가 키를 추종합니다. 3.44 에서 synthetic package 폐지를 확인해서(플래그가 사용 불능 상태) 생성물을 lib/l10n 의 *.g.dart 로 커밋하고 CI 가 gen-l10n 재생성 후 drift 를 검사합니다. pub get 이나 test 는 자동 생성 안 하는 것도 확인했습니다.
> 2. 지원 밖 기기 언어는 locale_resolution.dart 가 명시적으로 영어로 정합니다(지원 목록 순서라는 우연에 의존하지 않게). 언어 선택은 LocaleChoice 와 shared_preferences 저장소 인터페이스, 설정 UI 없이 위젯 테스트로 문구 반영을 확인했습니다.
> 3. 앱 이름은 안드로이드 values, values-ko, values-ja, locales_config 와 매니페스트 속성, iOS InfoPlist.strings en ko ja 를 pbxproj 변형 그룹으로 등록하고 CFBundleLocalizations 추가. APK 안에서 aapt2 로 ko ja 라벨을 확인했습니다.
>
> 판단한 점
> - 생성 파일명을 app_localizations.g.dart 로 정해 저장소의 *.g.dart 관례(한글 검사와 포맷 검사 제외 대상)에 맞췄습니다. l10n.yaml 키는 output-localization-file 단수형이고 pubspec 에 flutter generate true 가 필요했습니다.
> - 언어 고유 이름(한국어, English, 日本語)은 코드에 한글을 둘 수 없어 ARB settings_languageKo En Ja 키로 두고 모든 언어에서 같은 값을 갖게 했으며 테스트로 지켰습니다.
> - 응원 문구 기분 id 는 happy excited angry sad anxious(ARB 키 접미와 동일)로 정했습니다. T1 domain id 와 맞춰 주세요.
> - 응원 문구 세 언어 초안을 넣고 pubspec assets 에 등록했습니다. 12자 초과는 경고로만. 도장은 그림이 없어 README 한 줄만.
> - main.dart 는 localizationsDelegates, supportedLocales, onGenerateTitle, 해석 콜백만 넣었습니다. 저장값을 locale 로 넘기는 이음새는 합칠 때 맞추시라고 남겼습니다.
> - 글꼴: Pretendard 서브셋을 fontTools 로 확인해 가나 한자 없음(한글과 라틴 2912자). 기기에서는 시스템 글꼴 대체이지만 모양과 줄 높이가 섞일 수 있어 실기기 확인이 필요하고, 골든 테스트는 네모로 그려집니다. 대책(일본어는 시스템 글꼴 또는 Noto Sans JP 번들, 골든에서는 FontLoader)은 docs/I18N.md 에 제안만 두었습니다.
> - 앱 이름은 가칭(기분 클리커, Mood Clicker, 気分クリッカー)입니다. 맥 러너 앱 이름 현지화는 요청에 없어 하지 않았습니다.
>
> 확인: tool/test.sh 40 통과, analyze 이상 없음, apk 디버그 빌드 성공, 생성물 drift 없음.
>
> 번역 확신 없는 것: ja 기분 이름(幸せ わくわく イライラ 悲しい 不安, 짧은 명사형 선택), ja 오늘 N회(다른 언어는 단위 없음, 통일 논의 필요), 幸せ側 悲しい側 표기, map_title 近所の今日, ja 앱 이름, 응원 문구 전반(특히 はきだそう, すうはー).

### 2026-11-18 11:28 · 팀장 → 12.6 작업자(개발, opencode)  `T35`

> $M T35: 저녁 알림(웹앱이 아이폰에서 못 하는 것). flutter_local_notifications 로 하루 한 번 정한 시각(기본 꺼짐, 설정에서 켬, 기본 21:00)에 "오늘 기분은 어땠나요" 류 알림. 문구는 ko, en, ja ARB, 알림을 누르면 기분 고르기 화면. 권한 요청은 사용자가 켤 때만. 그날 이미 기록했으면 보내지 않음. 새 브랜치 feat/reminder. I18N 판단들(생성 파일 커밋, 지원 밖 언어는 영어) 좋습니다. 앱 이름은 전 언어 Unknown 으로 바꿨습니다.

### 2026-11-18 11:35 · 팀장 → 12.6 작업자(개발, opencode)  `T35 T36`

> 12.1 입니다. T35 다음에 T36: 설정 화면. 캔버스 최신판(설정 화면) 그대로가 기준입니다. 섹션: 테마(라이트, 다크, 핑크, 시스템 따라가기를 작은 미리보기 카드로, 누르면 바로 앱 전체 적용, 기본 라이트), 언어(기기 언어, 한국어, English, 日本語), 두드리기(진동+세기 약/보통/세게, 소리+소리 묶음, 응원 문구+보통/큰 글씨, 가득 찰 때 화면 흔들기, 기울여 쏟기), 알림(저녁 알림+오후 8/9/10시, T35 연결), 지도(내 기분 보태기, 한마디도 보태기: 고른 준비 문장만), 기록(내보내기는 JSON 파일을 공유 시트로, 모든 기록 지우기는 확인 시트 후), 정보(버전, 오픈소스 라이선스는 showLicensePage, 개인정보 처리방침 링크 자리). 모든 문구 ARB 3개 언어, 설정 값은 SettingsStore(shared_preferences) 하나에 모으고 테마·언어 선택도 거기로 합칩니다. 토글을 켜면 그 아래 세부 선택이 펼쳐지는 구조. 공용 눌림 위젯은 12.5 의 PressableSurface 를 씁니다(없으면 자리만 두고 12.5 와 이름 맞춤). 브랜치 feat/settings, bd7f3be 기준.

### 2026-11-18 11:59 · 12.6 작업자(개발, opencode) → 팀장  `T35 T36`

> 12.6 입니다. T35 저녁 알림 끝났습니다.
>
> 브랜치 feat/reminder (기준 bd7f3be), 커밋 f~ 하나: lib/reminder 하위계층, ARB 문구, 안드로이드 플랫폼 세팅, 테스트.
>
> 세 줄 요약
> 1. lib/reminder 에 순수 계획기(다음 발생 시각, 그날 기록 있으면 넘김), 알림 포트 인터페이스, 플러그인 구현, 컨트롤러를 나눴습니다. 권한은 사용자가 켤 때만 물어봅니다(거절하면 켜지지 않음). 알림 문구는 ARB 네 키(저녁 알림, 알림 시각, 제목, 본문) 세 언어.
> 2. 안드로이드는 부정확(inexact) 반복 알람이라 exact 권한이 필요 없고, 리부트 뒤에도 유지되는 수신자 두 개와 디슈가링을 넣었습니다. APK 매니페스트에 병합된 것을 aapt2 로 확인했습니다.
> 3. 화면이 아직 없어 앱 배선은 넣지 않았습니다. 알림 누름 페이로드는 mood_select 이고, 컨트롤러 refresh 를 시작·복귀·기록 저장 후에 부르면 됩니다. T36 설정 화면에서 enable/disable/setTime 을 부릅니다.
>
> 판단한 점
> - flutter_local_notifications 23 은 compileSdk 37 을 요구하는데 빌드 이미지와 CI 가 platform 36 까지라 22.3.3 으로 고정했습니다(같은 API). 23 을 쓰려면 이미지 교체가 먼저 필요합니다.
> - 부정확 알람을 골라 정각에서 몇 분 흔들릴 수 있습니다. 정확한 시각이 중요하면 SCHEDULE_EXACT_ALARM 논의가 필요합니다.
> - ja 알림 본문(ちょっとだけたたいてみませんか) 뉘앙스 검토 부탁드립니다.
> - T36 은 feat/reminder 위에 feat/settings 브랜치를 올려 작업합니다(알림 연결이 컴파일되려면 T35 코드가 필요). PR 은 reminder 먼저 합쳐 주시면 됩니다.
>
> 확인: tool/test.sh 322 통과, analyze 이상 없음, apk 디버그 빌드 성공.

### 2026-11-18 12:00 · 팀장 → 12.6 작업자(개발, opencode)  `T35 T36`

> 12.1 입니다. T35 합쳤습니다(integrate/poc de9b888, pubspec 충돌은 양쪽 의존성 다 살려 풀었음). 22.3.3 고정과 부정확 알람 둘 다 좋습니다. 정정 하나: 이 앱은 우울증을 돕는 앱이고, 화났을 때 두드려 푸는 것은 화를 키운다는 연구가 있어 분출 뉘앙스를 뺍니다. en "Take a moment to tap it out" 은 분출로 읽혀서 "A moment to check in with yourself" 로, ja "ちょっとだけたたいてみませんか" 는 "少しだけ、今日の気持ちを残してみませんか" 로, ko 는 "잠깐 들러 오늘 마음을 남겨 보세요" 로 바꿉니다. 원칙: 알림은 죄책감을 주지 않습니다(어제 안 했다, 연속 기록 등 금지), 잠금 화면에 기분 내용을 드러내지 않습니다, 같은 날 두 번 보내지 않습니다. 이 셋을 계획기 테스트로 확인해 주세요. T36 은 feat/reminder 대신 integrate/poc 최신(de9b888) 위에서 feat/settings 로. 설정 화면은 캔버스 최신판(마음 돌봄 항목과 위기 시트 포함: 109, 1577-0199 는 가까운 정신건강복지센터 연결, 카카오톡 마들랜, 112/119, "이 앱은 의료기기가 아니며 진료를 대신하지 않습니다") 기준. 위기 시트 번호는 상수 하나에 두고 테스트로 고정.

### 2026-11-18 12:32 · 12.6 작업자(개발, opencode) → 팀장  `T4 T8 T35 T36`

> 12.6 입니다. T35 후속과 T36 끝났습니다.
>
> 브랜치 1) fix/reminder-tone (de9b888 기반, 커밋 1de77ed): 알림 문구 교정과 세 원칙 테스트. 2) feat/settings (de9b888 기반, 커밋 d21c213): 설정 화면. 두 브랜치는 서로 독립입니다.
>
> fix/reminder-tone 세 줄 요약
> 1. 알림 본문을 세 언어 모두 점검 초대형으로 바꿨습니다(ko 잠깐 들러 오늘 마음을 남겨 보세요, en A moment to check in with yourself, ja 少しだけ、今日の気持ちを残してみませんか). ARB 설명에도 죄책감 금지와 잠금 화면 규칙을 적어 두었습니다.
> 2. 세 원칙을 테스트로 고정했습니다. 죄책감 단어(어제, 연속, missed, streak, 忘れ 등) 금지 사전 검사, 알림 제목·본문에 다섯 기분 이름 미포함 검사, 하루 한 번(지나간 시각은 다음 날로만 잡고 단일 id 교체 스케줄) 플래너·컨트롤러 테스트.
>
> feat/settings 세 줄 요약
> 1. Settings 값 하나에 모든 설정을 담고 SettingsStore(shared_preferences) 하나로 저장합니다. 언어 선택을 여기로 합쳤고, 알림은 이미 나간 reminder 키를 그대로 써서(어댑터로 단일 저장소) 기존 설정이 살아 있습니다.
> 2. 설정 화면은 캔버스 섹션 그대로입니다. 테마 미리보기 카드(누르면 즉시 전체 적용), 언어, 두드리기(토글 켜면 세부 선택이 펼쳐짐), 알림(저녁 알림 + 오후 8/9/10시, 권한은 켤 때만), 마음 돌봄, 지도, 기록(내보내기 공유 시트, 지우기 확인 시트), 정보(버전, 라이선스, 개인정보 준비 중). main.dart 가 저장소에서 테마·언어를 읽고 시작 시 알림을 오늘 기록과 맞춥니다.
> 3. 위기 시트는 번호를 상수 하나(crisisPhoneNumbers: 109, 1577-0199, 112, 119)에 두고 테스트로 고정했고, 각 번호는 tel: 로 연결되며 "의료기기가 아님" 고지가 맨 아래 늘 보입니다. 카카오톡 마들랜은 연결 수단이 없어 표시만 둘었습니다.
>
> 판단한 점
> - 캔버스 이미지를 저장소에서 찾지 못해 메시지의 섹션 설명을 기준으로 만들었습니다. 그림과 다른 점이 있으면 알려 주세요.
> - 설정 화면으로 들어가는 길이 아직 없습니다(홈이 토큰 프리뷰). 진입 버튼은 T8 화면과 합칠 때 붙이고, 지금은 위젯 테스트로 검증했습니다.
> - 기록 파일 경로를 lib/settings/records_port.dart 의 moodJournalFile 하나로 정했습니다. T8 의 저장소가 같은 함수를 쓰게 맞춰 주세요. 내보내기는 기록이 없으면 조용히 넘어갑니다.
> - PressableSurface 를 lib/design/parts 에 평면 스타일 자리로 만들었습니다. 12.5 가 이름 그대로 교체하면 됩니다.
> - 진동 세기, 응원 문구 크기, 화면 흔들기, 기울여 쏟기, 지도 두 값은 지금 저장만 하고 소비는 각 담당(T4, T8, 3단계)이 가져갑니다.
> - 언어의 시스템 항목 문구를 캔버스 표기대로 기기 언어로 바꿨습니다. 그러다 en ARB 에 한국어 값이 섞여 있던 다섯 키(저녁 알림, 알림 시각, 오후 8/9/10시)를 발견해 바로잡았습니다.
> - 예전 언어 저장 키(locale_choice)는 파일럿이라 옮기지 않았습니다. 필요하면 마이그레이션 넣겠습니다.
>
> 확인: tool/test.sh 394 통과(파이썬 213 포함), analyze 이상 없음, apk 디버그 빌드 성공(share_plus, url_launcher, path_provider 포함).
>
> 번역 확신 없는 것: ja 위기 시트 라벨(自殺予防相談, こころの健康相談電話), ja 진동 세기(弱く/ふつう/強く), ja 두드리기 섹션 이름(たたく), 마들랜 ja 표기(カカオトーク マドゥルランド), en 마음 돌봄(Mind care).

### 2026-11-18 12:32 · 팀장 → 12.6 작업자(개발, opencode)  `T36b`

> 12.1 입니다. fix/reminder-tone 합쳤습니다(integrate/poc 423b1d4). 좋습니다. feat/settings 는 integrate/poc 와 충돌합니다(main.dart, ARB 두 개, lib/design/parts/pressable_surface.dart 가 12.5 것과 겹침). T36b: feat/settings 에 integrate/poc 최신을 합쳐서 직접 풀어 주세요. 기준: PressableSurface 는 12.5 것(integrate 쪽)을 쓰고 네 것은 지웁니다. 앱 셸은 12.5 의 lib/app(bootstrap, app_services, settingsBuilder 자리)이 기준이라 SettingsStore 를 거기에 꽂아 FeelSettings 와 테마가 저장되게 하고, 두드리기와 기분 고르기 화면에 설정 진입 버튼(톱니 아이콘, 표면 원 배경)을 붙입니다. 기록 파일 경로는 12.5 의 lib/app/journal_store.dart 와 하나로 맞추세요(둘 중 하나만 남김). 캔버스는 /tmp/claude-3000/-home-jshsakura/<uuid>/scratchpad/poc/project/Settings.dc.html 를 읽으면 됩니다. 마들랜은 표시만 두는 것 맞습니다. 번역: en Mind care 좋음. ja 위기 라벨은 한국 번호라 自殺予防相談電話(韓国) 처럼 나라를 붙이고, 기기 지역이 일본이면 일본 24시간 번호(#いのちSOS 0120-061-338, よりそいホットライン 0120-279-338)를 보여 주는 지역 분기를 넣어 주세요(번호는 상수와 테스트로). 브랜치 그대로 feat/settings.

### 2026-11-18 12:58 · 12.6 작업자(개발, opencode) → 팀장  `T36b`

> 12.6 입니다. T36b 끝났습니다. feat/settings 에 integrate/poc(423b1d4) 를 합치고(커밋 ae9f1da) 충돌을 직접 풀었습니다.
>
> 세 줄 요약
> 1. PressableSurface 는 12.5 것만 남기고 제 자리를 지웠고, 설정 화면 전체를 그 위젯과 앱 셸(lib/app) 기준으로 다시 지었습니다. bootstrap 이 SettingsStore 하나를 만들어 FeelSettings, 테마, 언어 노티파이어를 시드하고 settingsBuilder 슬롯에 설정 화면을 얹었습니다. 두드리기 화면 머리글에도 톱니 단추(원형 표면)를 붙였습니다.
> 2. 기록 파일 경로는 lib/app/journal_store.dart 의 journalFile 하나로 합쳤습니다(앱 보호 폴더 journal.json). bootstrap 과 설정 내보내기가 같은 파일을 봅니다.
> 3. 화면을 캔버스(Settings.dc.html) 그대로 다시 그렸습니다: 둥근 카드 섹션, 알약 스위치와 접히는 세부 선택, 두 줄 테마 미리보기 카드(고르면 즉시 전체 적용 안내 포함), 캔버스 문구 세 언어(각 항목 설명, 확인 시트, 위기 시트 인트로와 각주, 닫기 단추, 내보내기 토스트).
>
> 추가로 정해 주신 것
> - 위기 연락처: 한국 번호 상수(109, 1577-0199, 112, 119)와 일본 번호 상수(#いのちSOS 0120-061-338, よりそいホットライン 0120-279-338)를 각각 하나의 상수에 두고 테스트로 고정했습니다. 기기 지역이 JP 이면 일본 두 줄이 한국 세 줄 대신 나오고, 112/119 는 캔버스대로 각주 문장 안에만 있습니다. ja 라벨에는 (韓国) 를 붙였습니다.
> - 기본값을 캔버스 DEFAULTS 에 맞췄습니다: 기울여 쏟기 기본 켜짐(FeelSettings.tiltSpill 과 일치), 진동 세기 선택지는 약하게/보통/세게, 글자 크기는 보통 글씨/큰 글씨.
>
> 판단한 점
> - AppServices 새 필드(언어, 저장소, 알림, 기록, 버전)는 테스트 가짜(AppServices 생성)를 깨뜨리지 않으려 모두 선택형으로 두었습니다. 실제 앱(bootstrap)은 항상 채워 넣습니다.
> - 개인정보 처리방침 줄은 값으로 준비 중입니다 를 보여 주고 동작은 없습니다. 캔버스는 토스트만 있어 실제 링크가 정해지면 붙이겠습니다.
> - 위기 시트에서 마들랜은 표시만(지시 확인). 국내 112/119 는 전화 걸기 행이 아니라 각주로 두었습니다(캔버스 그대로).
> - 언어 선택 저장 키는 settings.language 입니다(예전 locale_choice 키는 무시).
> - 일본 지역 판정은 기기 로케일 국가 코드(locale.countryCode == JP)로 했습니다.
>
> 확인: tool/test.sh 599 통과(위기 지역 분기, 세그먼트, 알약 스위치 테스트 포함), analyze 이상 없음, l10n parity 통과, apk 디버그 빌드 성공.
>
> 번역 확인 부탁: ja 위기 시트(自殺予防相談電話(韓国) 등), ja 두드리기 설명들, en/Japan 라벨(#Inochi SOS, Yorisoi Hotline), 마들랜 표기.

### 2026-11-18 12:59 · 팀장 → 12.6 작업자(개발, opencode)  `T36b`

> 12.1 입니다. T36b 좋습니다. 통합 브랜치에 합쳤고(3c0b167, 테스트 835개 통과) iOS 빌드가 끝나면 올립니다. 번역은 그대로 둡니다(ja (韓国) 표기, #Inochi SOS, Yorisoi Hotline 좋음). 마들랜은 en "Madeullaen (KakaoTalk)", ja "マドゥルレン(カカオトーク)" 로 맞춰 주세요. 이 수정은 새 브랜치 fix/settings-labels 로, integrate/poc 3c0b167 에서. 그 뒤 대기.

### 2026-11-18 13:00 · 12.6 작업자(개발, opencode) → 팀장

> 12.6 입니다. 마들랜 표기 바꿨습니다.
>
> 브랜치 fix/settings-labels (3c0b167 기준), 커밋 517cb7b. en 은 Madeullaen (KakaoTalk), ja 는 マドゥルレン(カカオトーク) 로 하고 생성물을 다시 만들었습니다. ko 는 그대로입니다. 확인: tool/test.sh 600 통과, analyze 이상 없음, l10n parity 통과. 이제 대기합니다.

### 2026-11-18 20:42 · 팀장 → 12.6 작업자(개발, opencode)  `T47`

> 12.1 입니다. T47 (개인정보 처리방침 초안). 브랜치 docs/privacy-policy, integrate/poc <기준 커밋> 에서. docs/privacy-policy/ko.md, en.md, ja.md 로 초안을 씁니다. 지금 앱 기준 사실만: 기분 기록은 기기 안에만 저장(journal.json), 서버 전송 없음, 계정 없음, 알림은 기기 안 예약, 내보내기는 사용자가 직접. 기분 기록은 개인정보보호법상 민감정보가 될 수 있다는 점, 지도 기능이 켜질 때 바뀌는 점(1km 격자, 5명 미만 숨김)은 '도입 시 고지' 로 따로. 치료 표현 금지, 위기 연락처 109. 맨 위에 '법률 검토 전 초안' 표시. 설정의 개인정보 처리방침 줄은 앱 안에서 이 문서를 보여 주는 화면으로 연결(assets 로 넣고 간단한 마크다운 표시, 새 패키지 필요하면 가장 가벼운 것). 연락처 이메일은 privacy@example.com 자리표시. tool/test.sh 통과 후 커밋 해시 보고.
