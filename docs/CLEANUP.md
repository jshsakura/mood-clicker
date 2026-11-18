# 릴리스 정리 목록

기준은 integrate/poc 4291976 입니다. 코드는 고치지 않았고 조사만 했습니다.
확신은 높음(참조 0 이고 지워도 동작이 같음), 중간(참조 0 이지만 의도를 확인해야 함), 낮음(합칠 수 있어 보이나 판단이 필요함)으로 적습니다.
참조 수는 `lib/` 에서 생성 파일(`*.g.dart`)을 뺀 값이고, 테스트 참조는 따로 적었습니다.
테스트만 쓰는 코드를 지우면 그 테스트도 함께 지워야 합니다.

## 1. 안 쓰는 Dart 파일

| 파일 | 근거 | 확신 |
|---|---|---|
| `lib/feedback/shake_detector.dart:7,18` (`SloshSignal`, `ShakeDetector`) | 어느 `lib/` 파일도 가져오지 않습니다. 테스트 1개(`test/feedback/shake_detector_test.dart`)만 씁니다. 실제 앱의 기울이기는 `bootstrap.dart` 의 `sensors_plus` 로 처리합니다 | 중간. 지우면 테스트도 지웁니다 |
| `lib/feedback/platform_haptics.dart:9` (`PlatformHaptics`) | `lib/` 가져오기 0. 테스트 1개만 씁니다. 앱은 `system_haptics.dart` 를 씁니다 | 중간 |
| `lib/l10n/locale_choice_prefs.dart:6` (`SharedPreferencesLocaleChoiceStore`) | `lib/` 가져오기 0, 테스트 1개. `AppServices.language`(`lib/app/app_services.dart:65`)도 부트스트랩에서 채우지 않습니다 | 지우지 말고 먼저 확인. 지워야 할 코드가 아니라 연결이 빠진 것일 수 있습니다. 설정의 언어 선택이 재시작 뒤에 남는지 실기기로 확인합니다 |
| `lib/design/token_preview.dart` | `lib/` 가져오기 0. 골든과 테스트(`test/goldens/harness.dart:116`, `test/design/token_preview_test.dart`)만 씁니다. 화면 문구가 한글로 박혀 있습니다(36행 근처 8줄, `slop-ok`) | 중간. 릴리스 빌드에 들어가므로 `test/` 로 옮기는 것이 맞습니다 |

## 2. 안 쓰는 함수와 상수

모두 `lib/` 참조 0 이고 테스트에서만 부릅니다.

| 위치 | 이름 | 근거 | 확신 |
|---|---|---|---|
| `lib/domain/cheer.dart:71` | `CheerBook.fingerprint` | 참조 0, 테스트 참조도 0 | 높음 |
| `lib/settings/settings.dart:73` | `Settings.fromFeel` | 참조 0, 테스트 참조도 0 | 높음 |
| `lib/l10n/asset_paths.dart:16` | `stampAssetPath` | 참조 0, 테스트 5 | 중간(도장 그림이 아직 없어 앞으로 쓸 자리일 수 있음) |
| `lib/l10n/date_labels.dart:34` | `monthTitle` | 참조 0, 테스트 6. 달력이 연도와 월을 따로 그립니다 | 중간 |
| `lib/domain/fill_gauge.dart:69` | `FillGauge.emptiesAt` | 참조 0, 테스트 3 | 중간 |
| `lib/domain/cheer_picker.dart:67,69` | `snapshotJson`, `snapshotFromJson` | 참조 0, 테스트 3 | 중간(덱 저장에 쓰려던 것인지 확인) |
| `lib/domain/tuning.dart:68` | `CheerTuning.rareRays` | 참조 0, 테스트 1 | 중간 |
| `lib/domain/spill.dart:103` | `ratePerSecond` | 참조 0, 테스트 2 | 중간 |
| `lib/feedback/sound_bank.dart:24` | `missingCount` | 참조 0, 테스트 2 | 낮음 |
| `lib/feedback/system_haptics.dart:26` | `resetGlobalGapForTest` | 테스트 전용 이름 | 낮음(테스트용 문은 두어도 됩니다) |
| `lib/feedback/feedback_settings.dart:4` | `SoundPack.soft` | 소리 묶음이 아직 없어 목록에서 숨깁니다. 테스트 5 | 낮음(준비 중 기능) |

## 3. 안 쓰는 ARB 키

세 언어(ko, en, ja)의 키 이름은 서로 같습니다. 아래 키는 `lib/` 어디에서도 쓰지 않습니다. 지울 때는 세 파일에서 함께 지우고 `tool/fl gen-l10n` 을 다시 돌립니다.
줄은 `lib/l10n/app_ko.arb` 기준입니다.

| 줄 | 키 | 테스트 참조 | 확신 |
|---|---|---|---|
| 15, 19 | `common_on`, `common_off` | 0 | 높음 |
| 35 | `moodSelect_today` | 0 | 높음(제목은 `moodSelect_title` 로 바뀜) |
| 100, 104, 108, 120, 129, 139, 143, 147 | `review_thisWeek`, `review_thisMonth`, `review_ratioLine`, `review_topMood`, `review_mostTappedDay`, `review_trendUp`, `review_trendDown`, `review_trendSame` | 0 | 중간(돌아보기 화면이 아직 없어 앞으로 쓸 문구일 수 있음) |
| 151, 155, 167 | `map_title`, `map_legendLine`, `map_permissionReason` | 0 | 중간(지도 화면 문구 정리 때 함께 확인) |
| 227, 235, 356 | `settings_vibrationStrength`, `settings_soundPack`, `settings_cheersSize` | 0 | 높음 |
| 243 | `settings_reminderTime` | 2 | 높음(화면은 다른 키를 씀. 테스트 2곳은 같이 고침) |
| 299 | `dayDetail_note` | 0 | 중간(상세 화면 개편이 끝나면 확인) |
| 400, 404 | `settings_mindCarePolice`, `settings_mindCareMedical` | 0 | 중간(위기 연락처는 `crisis_contacts.dart` 가 따로 가집니다. 안전에 관한 문구라 지우기 전에 사람이 봅니다) |

## 4. 같은 일을 하는 부품과 함수

| 항목 | 위치 | 설명 | 확신 |
|---|---|---|---|
| 손으로 만든 누르는 면 | `lib/settings/settings_screen.dart:507,590,669,754,894`, `lib/map/map_screen.dart:83,360,471`, `lib/screens/calendar_screen.dart:491` | `GestureDetector` 와 `InkWell` 로 직접 만든 눌림 처리입니다. `PressableSurface` 가 쓰는 포커스, 키보드, 눌림 효과가 없습니다 | 중간. 합치면 키보드 접근도 같이 해결됩니다 |
| 화면 위쪽 뒤로 줄 | `settings_screen.dart:391`(`_Header`), `settings/privacy_screen.dart:60` 근처, `screens/calendar_screen.dart`, `screens/day_detail_screen.dart`, `screens/tap/tap_screen.dart`, `map/map_screen.dart` | 뒤로 단추와 제목을 놓는 줄이 화면마다 따로 있습니다 | 낮음. 공용 머리글 부품 후보입니다. 화면마다 오른쪽에 놓는 것이 달라 판단이 필요합니다 |
| 선택 막대 | `settings_screen.dart:619`(`_SegmentBar`), `map/map_screen.dart:333`(`_RangeSwitch`) | 둘 다 칸 하나를 골라 켜는 막대입니다 | 낮음 |
| 시트 | `settings_screen.dart:939`(`_ConfirmSheet`), `settings_screen.dart:383` 의 도움 시트, `screens/tap/note_sheet.dart:33` | 위 손잡이, 안쪽 여백, 제목, 단추 줄이 시트마다 따로입니다 | 낮음. 공용 시트 틀 후보입니다 |
| 대화 상자 | `screens/loading_screen.dart:72`(`AlertDialog`) | 앱의 나머지는 시트를 쓰는데 여기만 기본 대화 상자입니다 | 낮음. 모양이 다릅니다 |
| 기본 단추 | `note_sheet.dart:245,254`(`TextButton`, `FilledButton`), `loading_screen.dart:79`(`TextButton`) | 시안의 단추 모양이 아니라 Material 기본 단추입니다 | 중간. 시안 대조 때 함께 바꿉니다 |

아이콘은 `LineIcon`, 기분 얼굴은 `MoodFace` 하나뿐이고 Material 아이콘과 이모지는 남지 않았습니다(`test/design/no_material_icons_test.dart` 가 지킵니다).

## 5. 남은 한글

`lib/`, `test/`, `tool/` 의 주석에 남은 한글은 없습니다. 한글이 있는 파일은 아래 하나뿐입니다.

| 위치 | 내용 | 확신 |
|---|---|---|
| `lib/design/token_preview.dart:36` 근처 8줄 | 화면에 한글 글꼴을 보여 주려는 문구와 `slop-ok` 표시 | 위 1번과 함께 `test/` 로 옮기거나 ARB 키로 바꿉니다 |

## 6. 쓰지 않는 의존성

| 위치 | 의존성 | 근거 | 확신 |
|---|---|---|---|
| `pubspec.yaml:42` | `cupertino_icons` | `CupertinoIcons` 사용 0, 가져오기 0. 아이콘은 모두 `assets/icons` 입니다 | 높음 |
| `pubspec.yaml` | `uses-material-design: true`(97행 근처) | Material 아이콘 글꼴을 번들에 넣습니다. 아이콘을 쓰지 않으므로 필요 없지만, Material 위젯은 켜 둔 값을 기대합니다 | 낮음. 끄고 앱이 도는지 확인합니다 |

나머지 의존성은 `lib/` 에서 가져오기가 1 이상입니다. `flutter_localizations` 는 생성된 번역 파일이 씁니다. `flutter_lints` 와 `flutter_launcher_icons` 는 개발용입니다.
`table_calendar` 와 `fl_chart` 는 달력과 상세 화면이 씁니다. 12.3 이 달력을 직접 그리는 쪽으로 바꾸면 쓰는 곳이 사라지므로 그때 다시 확인합니다.

## 7. 오래된 문서 줄

| 위치 | 내용 | 확신 |
|---|---|---|
| `docs/SETUP.md:135` | `design/tokens/*.json` 이라고 쓰지만 실제 파일은 `design/tokens.json` 하나입니다 | 높음 |
| `docs/DEV-ENV.md:171` | 골든 그림이 Material 아이콘과 Noto Color Emoji 글꼴을 쓴다고 쓰지만 이제 화면에 둘 다 없습니다 | 높음 |
| `docs/TEAM.md:26,29,35,37,40,48` | `docs/dev-env`, `docs/research`, `docs/setup`, `test/design-guards` 는 실제 경로가 아닙니다(이름만 부르는 표기로 보입니다) | 중간. 경로로 읽히지 않게 다시 씁니다 |
| `docs/RESEARCH.md:606-624` | `design/tokens/` 다중 파일 구조를 권합니다. 지금은 단일 파일입니다 | 낮음. 조사 기록이라 날짜를 붙여 두는 정도로 충분합니다 |
| `docs/DEV-ENV.md:200,214` | `.claude/settings.local.json` 은 저장소에 없는 개인 파일입니다 | 낮음. 개인 파일이라 설명이 필요하면 그대로 둡니다 |
| `docs/prompts/*` (3302줄) | 작업 지시와 보고 기록입니다. 코드나 사용자 문서가 가리키지 않습니다 | 중간. 릴리스 때 `docs/prompts/README.md` 한 줄 설명만 두고 나머지를 지울지 사장님이 정합니다 |

## 조사 방법과 한계

- 가져오기 검사는 파일 이름이 `lib/` 의 `import` 줄에 나오는지 봤습니다. 이름을 문자열로 조립해 부르는 코드는 잡지 못합니다. 이 저장소에는 그런 코드가 없는 것으로 보입니다.
- 함수와 상수는 이름이 `lib/` 전체에서 한 번만 나오는 것을 골랐습니다. 같은 이름이 다른 곳에 있으면 놓칠 수 있습니다.
- ARB 키는 `lib/` 에서 키 이름이 한 번도 나오지 않는 것을 골랐습니다.
- 확인하지 못한 것: 네이티브 코드(Kotlin, Swift)가 부르는 채널 이름, 실기기 동작.
