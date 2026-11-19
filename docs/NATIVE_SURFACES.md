# 홈 화면 위젯과 앱 아이콘 바로가기

웹앱은 못 하는 기능을 네이티브에 잇는 부분입니다. 둘 다 오늘의 기록(`DayRecord`)을 읽기만 하고 쓰지 않습니다.

## 무엇이 되나

| 기능 | 동작 |
|---|---|
| 홈 화면 위젯 | 오늘 가장 많이 두드린 기분의 표정과 오늘 두드린 횟수를 보여 줍니다. 누르면 그 기분의 두드리기 화면으로 갑니다. 아직 안 두드렸으면 횟수 0 만 보이고, 누르면 앱만 엽니다. |
| 앱 아이콘 길게 누르기 | 최근 14일 동안 많이 고른 기분 네 개가 바로가기로 뜹니다. 고르면 그 기분의 두드리기 화면으로 갑니다. |

표현 규칙은 그대로입니다. 위젯 바탕과 글자는 흑백 토큰(`light.ground`, `light.ink`, `light.line`)이고, 색이 있는 것은 표정뿐입니다. 그라데이션, 번지는 그림자, 글로우는 없습니다.

## 코드 위치

| 위치 | 역할 |
|---|---|
| `lib/surfaces/native_surfaces.dart` | 위젯 갱신, 바로가기 등록, 링크로 열린 기분 전달. 포트만 알고 패키지는 모릅니다 |
| `lib/surfaces/widget_snapshot.dart` | `DayRecord` 에서 위젯이 보여 줄 값(날짜, 대표 기분, 횟수)을 뽑습니다 |
| `lib/surfaces/mood_links.dart` | 위젯 링크 `moodclicker://tap/<기분 id>` 와 바로가기 종류 `tap_<기분 id>` |
| `lib/surfaces/home_widget_adapters.dart` | `home_widget`, `quick_actions` 패키지에 닿는 실제 어댑터 |
| `lib/surfaces/mood_face_mark.dart` | 표정 자리 표시. 디자이너의 표정이 오면 이 안쪽만 바꾸면 위젯도 바뀝니다 |
| `android/.../MoodWidgetProvider.kt`, `res/layout/mood_widget.xml` 등 | 안드로이드 위젯 |
| `ios/MoodWidget/` | iOS WidgetKit 확장의 소스 |

위젯 색은 `design/tokens.json` 에서 `python3 tool/gen_tokens.py` 가 만듭니다. 안드로이드는 `values/colors.xml` 의 `widget_ground`, `widget_ink`, `widget_line`, iOS 는 `ios/MoodWidget/WidgetColors.g.swift` 입니다. 손으로 고치지 않습니다.

## 네이티브와 주고받는 값

앱이 `home_widget` 으로 저장하고 두 위젯이 읽습니다.

| 키 | 값 |
|---|---|
| `day` | `YYYY-MM-DD`. 오늘이 아니면 위젯은 빈 상태로 그립니다(자정 뒤에 어제 횟수를 보여 주지 않기 위해서) |
| `mood` | 대표 기분 id. 안 두드렸으면 빈 문자열 |
| `count` | 오늘 두드린 횟수 |
| `link` | 누르면 여는 링크 |
| `face_png` | 표정 그림 파일 경로(앱이 `MoodFaceMark` 를 그려 저장) |

이름이 둘 사이에서 어긋나면 기기에서야 드러나므로 `tool/test_native_surfaces.py` 가 Dart, Kotlin, Swift, 매니페스트, plist 의 같은 이름을 맞춰 봅니다.

## iOS: Xcode 에서 한 번 해야 하는 일

저는 Xcode 가 없는 서버에서 만들어서 프로젝트 파일(`project.pbxproj`)은 고치지 않았습니다. 소스는 다 있고, 아래는 Xcode 에서 직접 합니다.

1. File, New, Target, Widget Extension 으로 `MoodWidget` 을 만들고(Include Live Activity, Configuration App Intent 는 끕니다), 만들어진 기본 파일은 지우고 `ios/MoodWidget/` 의 파일(`MoodWidget.swift`, `WidgetColors.g.swift`, `Info.plist`, `MoodWidget.entitlements`, `*.lproj`)을 그 타깃에 넣습니다.
2. 위젯 타깃의 Deployment Target 을 iOS 14 이상으로 올립니다(`WidgetKit` 이 14부터입니다).
3. Runner 와 MoodWidget 두 타깃 모두 Signing & Capabilities 에서 App Groups 를 켜고 `group.com.example.moodClicker` 를 넣습니다. 파일은 `ios/Runner/Runner.entitlements`, `ios/MoodWidget/MoodWidget.entitlements` 로 이미 있으니 타깃의 Code Signing Entitlements 에 연결만 하면 됩니다.
4. 앱 식별자를 바꿀 때는 앱 그룹 이름도 같이 바꿉니다(`lib/surfaces/home_widget_adapters.dart` 의 `widgetAppGroupId`, Swift 파일, 두 entitlements).
5. Runner 의 URL 스킴 `moodclicker` 는 `Info.plist` 에 이미 넣었습니다.

## 실기기에서 확인할 것

에뮬레이터나 이 서버로는 아래를 판정하지 못합니다.

안드로이드
- 위젯 선택 화면에 "Unknown" 위젯이 보이고, 설명이 기기 언어(ko, en, ja)로 나옵니다.
- 위젯을 추가하면 처음에는 0 만 보이고, 앱에서 두드린 뒤 표정과 횟수가 바뀝니다.
- 위젯을 누르면 앱이 열리고 그 기분의 두드리기 화면으로 갑니다(앱이 꺼진 상태와 켜진 상태 둘 다).
- 자정이 지난 뒤 앱을 열지 않아도 0 으로 돌아옵니다(최대 한 시간 안에).
- 어두운 배경화면에서도 흰 카드의 테두리가 보입니다.
- 앱 아이콘을 길게 누르면 바로가기가 뜨고 기분 이름이 기기 언어로 나옵니다. 고르면 그 기분으로 갑니다.

iOS(Xcode 설정 뒤)
- 위젯 갤러리에 위젯이 보이고, 추가하면 앱에서 두드린 횟수가 따라옵니다.
- 위젯을 누르면 앱이 열리고 그 기분으로 갑니다.
- 다크 모드에서도 위젯 바탕이 흰색입니다(앱은 라이트가 기본이라 일부러 그렇게 했습니다).
- 앱 아이콘을 길게 누르면 바로가기가 뜹니다. 바로가기는 보통 네 개까지만 보입니다.

## 알려진 한계

- 바로가기는 iOS 와 대부분의 안드로이드 런처가 네 개까지만 보여 줍니다. 그래서 최근 14일(오늘 포함) 동안 많이 고른 기분 네 개만 올리고(`lib/surfaces/shortcut_order.dart`), 횟수가 같거나 기록이 없는 기분은 `happy`, `excited`, `angry`, `sad`, `anxious` 순서를 따릅니다. 기록이 없으면 행복, 설레, 화나, 슬퍼입니다. 앱을 열 때마다 `registerShortcuts(l, journal, now)` 를 다시 불러야 메뉴가 따라옵니다.
- 현재 기능: 기분을 고른 뒤 가는 두드리기 화면과 `NativeSurfaces` (`onLaunchMood`, `start()`, `publishToday()`) 연결은 앱에 구현되어 있습니다. 안드로이드·iOS 실기기에서 위젯과 바로가기가 해당 화면을 여는지 확인이 남아 있습니다.
- 표정은 자리 표시용 그림입니다.
