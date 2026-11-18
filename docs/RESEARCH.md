# 기술 조사 결과

확인일: 2026-11-18

이 문서는 `docs/PLAN.md` 와 `docs/SPEC.md` 의 요구사항을 바탕으로, 0단계·1단계 파일럿과 3단계 지도에 필요한 네 가지 기술 항목을 공식 문서와 저장소 기준으로 조사한 결과입니다. 직접 확인하지 못한 동작은 **추측**으로 표시합니다.

---

## 1. 선 위주 지도

### 1.1 타일 제공자 비교

| 항목 | OpenFreeMap | Protomaps (PMTiles) | Stadia Maps (Stamen Toner Lines) |
|---|---|---|---|
| **앱 사용 조건** | 상업·비상업 모두 허용합니다. 단, 오프라인 다운로드는 1회 최대 3,000타일 또는 50MB, 동시 요청 최대 4개, 앱을 식별하는 고유 `User-Agent` 헤더가 필요합니다. 공개 인스턴스는 SLA 없이 best-effort 로 제공합니다. | PMTiles 명세는 CC0, 도구와 라이브러리는 BSD-3-Clause 입니다. 자체 호스팅(S3, R2 등) 시 별도 이용 제한이 없습니다. 지도 데이터(OSM)는 ODbL 이므로 출처 표기가 필요합니다. | Stadia Maps 계정과 프로퍼티 설정이 필요합니다. 상업용 앱이나 광고 포함 앱은 유료 플랜(Starter 월 20달러부터)이 필요합니다. |
| **비상업 무료 범위** | 요청 수·조회 수 하드 캡이 없는 완전 무료입니다. | 자체 호스팅 시 Protomaps 측 요금이 없으며 클라우드 저장소·전송 비용만 듭니다(Cloudflare R2 등은 무료 범위 존재). Protomaps 호스티드 API 도 비상업은 무료입니다. | 개발·평가·학술·비상업 프로젝트에 한해 월 **200,000 크레딧**까지 무료입니다(신용카드 불필요, 초과 시 과금 대신 429 차단). |
| **API 키 필요 여부** | 불필요합니다. 계정과 쿠키도 필요 없습니다. | 자체 호스팅 시 불필요합니다(호스티드 API 사용 시에는 필요). | **필요합니다.** 스타일 URL 등에 `?api_key=...` 또는 도메인 인증을 붙입니다. |
| **벡터 / 래스터 여부** | 벡터 타일(`.mvt`, OpenMapTiles 스키마)과 스타일 JSON 을 제공합니다. | 벡터 타일(PMTiles 단일 아카이브 안에 MVT 포함)입니다. | **벡터와 래스터 모두** 제공합니다. (레거시 Toner Hybrid 래스터는 폐기되었고 레이어 그룹 조합으로 대체합니다.) |
| **다크·라이트·핑크 색 변경** | **가능합니다.** 클라이언트에서 MapLibre 스타일 JSON 의 배경색, 도로·경계선 색, 라벨 색을 직접 바꾸거나 커스텀 스타일 JSON 을 연결하면 됩니다. | **가능합니다.** 벡터 타일과 CC0 기반 기본 테마(`basemaps-flavors`)를 제공하므로 MapLibre 스타일 JSON 으로 자유롭게 색을 바꿀 수 있습니다. | **벡터 스타일은 가능합니다.** Stamen Toner 벡터 타일은 클라이언트 렌더링이므로 색과 레이어를 바꿀 수 있습니다. 반면 래스터 PNG 타일은 흑백·투명 고정이라 색 테마 변경이 어렵습니다. |

출처 및 확인일 (2026-11-18):
- OpenFreeMap 공식 사이트 및 이용약관: https://openfreemap.org/ , https://openfreemap.org/terms/
- OpenFreeMap GitHub 저장소: https://github.com/hyperknot/openfreemap
- Protomaps 공식 문서 및 라이선스: https://docs.protomaps.com/ , https://protomaps.com/
- PMTiles GitHub 저장소: https://github.com/protomaps/PMTiles
- Stadia Maps 요금 및 무료 티어 문서: https://docs.stadiamaps.com/pricing/ , https://stadiamaps.com/pricing/
- Stadia Maps Stamen 스타일 문서: https://docs.stadiamaps.com/map-styles/stamen-toner/
- Stamen 공식 안내: https://stamen.com/stadia-maps-stamen-styles/

### 1.2 Flutter 에서 벡터 스타일을 쓰는 방법

| 패키지 | 최신 버전 | 유지 상태 | iOS | Android | macOS | 비고 |
|---|---|---|---|---|---|---|
| `maplibre_gl` | `0.28.0` | 유지 중입니다. | 지원 (iOS 15.5+) | 지원 (API 24+) | **미지원** | 기존 플러그인 구조이며 Android, iOS, Web 위주입니다. |
| `maplibre` | `0.3.7+1` (프리릴리즈 `0.4.0-pre.2`) | 활발히 개발 중입니다. | 지원 (iOS 15+, Metal) | 지원 (API 24+) | **지원** (macOS 14.3+, Metal) | FFI/JNI 기반의 차세대 공식 MapLibre Flutter 바인딩입니다. 6개 플랫폼을 지원합니다. |
| `flutter_map` + `vector_map_tiles` | `flutter_map` `8.3.2` / `vector_map_tiles` `8.0.0` (프리뷰 `10.0.0-beta`) | `vector_map_tiles` `8.x` 는 주로 `flutter_map` `7.x` 에 맞춰져 있습니다. `10.x` 는 `flutter_gpu` 기반 실험 채널입니다. | 지원 | 지원 | 지원 | 순수 Dart/Flutter 캔버스 렌더링이라 macOS 포함 모든 플랫폼에서 동작하지만, 복잡한 벡터 스타일 성능·호환성은 네이티브 MapLibre 보다 제한적일 수 있습니다. |
| `flutter_map` + `flutter_map_vector_tiles` | `2.11.0` | 유지 중입니다. | 지원 | 지원 | 지원 | `flutter_map` `8.0+` 와 Impeller 환경에 맞춰 새로 작성된 벡터 타일 레이어입니다. |

정리:
- 아이폰·안드로이드 본선과 맥 파일럿을 모두 포함하면 `maplibre` (`0.3.7+1`) 또는 `flutter_map` (`8.3.2`) + `flutter_map_vector_tiles` (`2.11.0`) 조합이 macOS 를 공식 지원합니다.
- `maplibre_gl` (`0.28.0`) 은 안정적이지만 macOS 를 지원하지 않습니다.

출처 및 확인일 (2026-11-18):
- `maplibre_gl`: https://pub.dev/packages/maplibre_gl
- `maplibre`: https://pub.dev/packages/maplibre , https://maplibre.org/flutter-maplibre/
- `flutter_map`: https://pub.dev/packages/flutter_map
- `vector_map_tiles`: https://pub.dev/packages/vector_map_tiles , https://github.com/greensopinion/flutter-vector-map-tiles
- `flutter_map_vector_tiles`: https://pub.dev/packages/flutter_map_vector_tiles

---

## 2. 진동 (Haptics)

### 2.1 Flutter 기본 `HapticFeedback` 으로 되는 것과 안 되는 것

`package:flutter/services.dart` 의 `HapticFeedback` 은 추가 의존성 없이 플랫폼 기본 진동 API 를 호출합니다.

- **되는 것**:
  - 미리 정해진 짧은 촉각 신호 호출: `lightImpact()`, `mediumImpact()`, `heavyImpact()`, `selectionClick()`, `vibrate()`.
  - iOS 의 `UIImpactFeedbackGenerator` / `UISelectionFeedbackGenerator` 계열과 Android 의 `HapticFeedbackConstants` 계열로 연결됩니다.
- **안 되는 것**:
  - **진동 세기(진폭) 수치 조절**과 **날카로움(sharpness)** 조절이 불가능합니다.
  - **커스텀 시간 패턴(파형, 연속 엔벨로프, `.ahap` 파일)** 재생이 불가능합니다.
  - Android 제조사(OEM)별 구현 편차가 큽니다. 기기에 따라 특정 상수가 무시되거나 둔탁한 진동으로 나옵니다.
  - **macOS**: 맥에는 일반 진동 모터가 없으며, `HapticFeedback` 만으로는 트랙패드 포스터치 햅틱(`NSHapticFeedbackManager`) 세밀 제어가 어렵습니다.

출처 및 확인일 (2026-11-18):
- Flutter `HapticFeedback` API 문서: https://api.flutter.dev/flutter/services/HapticFeedback-class.html

### 2.2 세기·패턴 패키지 유지 상태와 iOS Core Haptics 지원

| 패키지 | 최신 버전 | 유지 상태 | 세기·패턴 지원 | iOS Core Haptics | macOS |
|---|---|---|---|---|---|
| `vibration` | `3.2.1` | 유지 중입니다(Dart 3 / 최신 Flutter 호환). | Android 에서 밀리초 배열 패턴과 진폭(amplitude) 조절을 지원합니다. iOS 는 시스템 기본 진동/사운드 fallback 이 중심이라 세밀한 패턴 제어가 어렵습니다. | 미지원(또는 제한적 fallback) | 미지원 |
| `gaimon` | `1.5.1` | 유지 중입니다(AGP/Kotlin, Swift Package Manager 대응). | **지원합니다.** Apple `.ahap` JSON 파일 기반 커스텀 패턴과 기본 프리셋(`light`, `medium`, `heavy`, `rigid`, `soft`, `selection`, `success`, `error`, `warning`)을 제공합니다. | **지원합니다.** (iPhone 8 이상 Taptic Engine / Core Haptics) | 미지원 |
| `core_haptics` 등 | 다양함 | 소규모 유지 | Core Haptics 직접 래핑을 제공합니다. | 지원 | 미지원 |

참고: `vibration` 은 Android 에서 `android.permission.VIBRATE` 권한 선언이 필요합니다.

출처 및 확인일 (2026-11-18):
- `vibration`: https://pub.dev/packages/vibration
- `gaimon`: https://pub.dev/packages/gaimon
- `core_haptics`: https://pub.dev/packages/core_haptics

### 2.3 초당 10회 연타(10Hz)에서 알려진 문제

초당 10회(100ms 간격)로 진동을 즉시 호출하면 물리적 모터(LRA/ERM)의 기동·감쇠 시간과 OS 보호 정책 때문에 문제가 발생합니다.

- **iOS (Core Haptics)**:
  - 메인 스레드에서 매 탭마다 새 `CHHapticPatternPlayer` 를 만들거나 엔진을 껐다 켜면 지연과 이벤트 누락(dropped haptics)이 발생합니다.
  - 해결 방향: `CHHapticEngine` 을 한 번 켜 두고 유지하면서 `resetHandler` / `stoppedHandler` 를 처리해야 하며, 짧은 간격의 연속 입력은 사전 정의 패턴 또는 앱 측 간격 제한(예: `docs/SPEC.md` 초안의 최소 40ms~50ms 쓰로틀)이 필요합니다.
- **Android (`VibrationEffect`)**:
  - 매 100ms 마다 `VibrationEffect.createOneShot()` 을 반복 호출하면 `VibratorService` 바인더 큐가 밀리거나 이전 진동과 겹쳐 명령이 드롭될 수 있습니다.
  - 저가형 기기의 ERM(회전) 모터는 10Hz 단위로 끊어 치지 못해 뭉개진 연속 진동으로 들립니다.
  - 해결 방향: API 30+(Android 11+) 에서 `VibrationEffect.startComposition()` 과 `PRIMITIVE_CLICK` 같은 하드웨어 프리미티브를 쓰면 바인더 오버헤드를 줄일 수 있습니다. 또한 앱 코드에서 최소 간격 쓰로틀링을 두어 뭉개짐을 막아야 합니다.

출처 및 확인일 (2026-11-18):
- Android `VibrationEffect.Composition` 및 Haptics 가이드: https://developer.android.com/develop/ui/views/haptics/custom-haptic-effects
- Apple Core Haptics 공식 문서: https://developer.apple.com/documentation/corehaptics

---

## 3. 저지연 소리

### 3.1 `flutter_soloud` 와 대안의 유지 상태

| 패키지 | 최신 버전 | 유지 상태 | 특징 |
|---|---|---|---|
| `flutter_soloud` | `5.3.0` | **매우 활발히 유지 중입니다.** | C++ SoLoud + `miniaudio` 기반 FFI 엔진입니다. 게임·인터랙티브 앱용 초저지연 재생, 다중 보이스, 내장 DSP 필터를 제공합니다. |
| `audioplayers` | 활발히 유지 중 | 유지 중입니다. | `PlayerMode.lowLatency` 를 지원하지만, 다중 동시 겹침과 실시간 피치 변조는 SoLoud 에 비해 기능이 적습니다. |
| `flame_audio` | 활발히 유지 중 | 유지 중입니다. | Flame 게임 엔진용 SFX 래퍼입니다(단독 사용 가능). |
| `just_audio` | 활발히 유지 중 | 유지 중입니다. | 스트리밍과 긴 음원에 강점이 있으며, 짧은 타격음 10Hz 연타용 사운드 풀 엔진은 아닙니다. |
| `soundpool` | - | **개발 중단(discontinued)** | 더 이상 권장하지 않습니다. |

출처 및 확인일 (2026-11-18):
- `flutter_soloud`: https://pub.dev/packages/flutter_soloud
- `audioplayers`: https://pub.dev/packages/audioplayers
- `flame_audio`: https://pub.dev/packages/flame_audio
- `just_audio`: https://pub.dev/packages/just_audio

### 3.2 짧은 소리 겹쳐 내기(Polyphony)와 음 높이 바꾸기(Pitch Shift)

`flutter_soloud` 는 두 가지 요구사항을 모두 기본으로 지원합니다.

- **짧은 소리 겹쳐 내기**: `SoLoud.instance.loadAsset(...)` 으로 음원을 한 번 메모리에 올린 뒤 `SoLoud.instance.play(sound)` 를 호출할 때마다 별도 보이스(`SoundHandle`)로 동시 재생합니다. 직전 소리를 끊지 않고 자연스럽게 겹칩니다.
- **음 높이 바꾸기**:
  1. 재생 속도 연동 방식: 개별 `SoundHandle` 의 `setRelativePlaySpeed(handle, speed)` 로 재생 속도와 함께 피치를 미세하게 흔들 수 있습니다(짧은 타격음에는 속도 변화가 거의 거슬리지 않고 CPU 부담이 작습니다).
  2. 독립 DSP 필터 방식: 내장 **Pitch Shift** 필터(`FilterType.pitchShiftFilter`)를 활성화하고 `setFilterParameter` 로 세미톤/피치 비율을 조절해 속도 변화 없이 음 높이만 바꿀 수 있습니다.

출처 및 확인일 (2026-11-18):
- `flutter_soloud` 공식 문서 및 pub.dev: https://pub.dev/packages/flutter_soloud , https://docs.page/alnitak/flutter_soloud_docs

### 3.3 아이폰 무음 스위치 존중 방법

`docs/SPEC.md` 요구사항은 **"아이폰 무음 스위치를 켜면 소리를 내지 않는다. 진동은 그대로 낸다."** 입니다.

- iOS `AVAudioSession` 에서 무음 스위치(Ring/Silent switch)를 **존중**하는 카테고리는 `AVAudioSessionCategory.ambient`(다른 앱 음악과 섞이면서 무음 시 소리 안 남) 또는 `soloAmbient` 입니다. 반대로 `playback` 카테고리는 무음 스위치를 **무시**하고 소리를 냅니다.
- `flutter_soloud` 자체는 `miniaudio` 로 오디오를 출력하며 OS 오디오 세션 정책을 직접 세밀하게 제어하려면 **`audio_session`** 패키지와 함께 씁니다.
- `SoLoud.instance.init()` 을 부르기 **전**에 `audio_session` 으로 카테고리를 `AVAudioSessionCategory.ambient` + `mixWithOthers` 로 설정하면, 무음 스위치 켜짐 시 소리가 나지 않고 다른 앱 배경음악도 끊지 않습니다.
- 참고(**추측**): `flutter_soloud` 의 내부 `miniaudio` 기본 초기화만으로도 iOS 에서 `ambient` 와 유사하게 동작할 가능성이 있으나, iOS 버전·다른 플러그인 간 세션 충돌을 막으려면 `audio_session` 으로 `AVAudioSessionCategory.ambient` 를 명시적으로 활성화하는 편이 안전합니다.

출처 및 확인일 (2026-11-18):
- `audio_session`: https://pub.dev/packages/audio_session
- Apple `AVAudioSession.Category` 공식 문서: https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct
- `flutter_soloud` + `audio_session` 연동 이슈 참고: https://github.com/alnitak/flutter_soloud/issues

---

## 4. Figma Tokens Studio 와 `design/tokens.json` 호환성

### 4.1 Tokens Studio 의 W3C 디자인 토큰 형식(`$type`, `$value`) 지원

- **지원합니다.** Tokens Studio for Figma 는 설정(Settings / Storage Provider 옵션)에서 토큰 형식을 Legacy(`type`, `value`) 와 **W3C DTCG(`$type`, `$value`, `$description`)** 중 하나로 선택해 읽고 내보낼 수 있습니다.
- JSON 파일 직접 Import/Export 와 GitHub/GitLab 동기화 모두 W3C DTCG 형식을 지원합니다.

출처 및 확인일 (2026-11-18):
- Tokens Studio W3C DTCG 형식 문서: https://docs.tokens.studio/manage-tokens/token-format/w3c-dtcg

### 4.2 현재 `design/tokens.json` 구조와의 호환성 판단

현재 `feat/design-tokens` 브랜치의 `design/tokens.json` 초안을 확인한 결과, **그대로는 Tokens Studio 에서 바로 읽어 들이기 어렵고 일부 조정이 필요합니다.**

1. **테마별 `color` 묶음 (`color.dark`, `color.light`, `color.pink`)**:
   - 현재 구조는 단일 JSON 파일 안에 `color.dark.*`, `color.light.*`, `color.pink.*` 로 중첩되어 있습니다.
   - Tokens Studio 는 기본적으로 **토큰 세트(Token Sets)** 단위로 테마를 나눕니다(예: `global`, `dark`, `light`, `pink` 를 최상위 세트 키나 별도 JSON 파일로 분리하고, Pro 기능인 Themes 또는 세트 활성화 순서로 `color.ground` 같은 동일 경로를 덮어씁니다).
   - 단일 파일 안에 `color.dark.ground` 처럼 넣어 두면 Tokens Studio 에서 테마 전환이 아니라 이름이 다른 별개 토큰(`color.dark.ground`, `color.light.ground`)으로 인식합니다.
2. **토큰이 아닌 일반 문자열 필드 (`"brightness": "dark"`)**:
   - `color.dark` 안에 `"brightness": "dark"` 가 `$type`/`$value` 없이 들어 있습니다. Tokens Studio 나 W3C DTCG 파서는 이를 유효한 토큰으로 인식하지 못해 무시하거나 오류를 낼 수 있습니다.
3. **`dimension` 값의 단위 표기 (`"$value": 4`)**:
   - 현재 `space` 와 `radius` 가 단위 없는 숫자(`4`, `24`)로 되어 있습니다. Tokens Studio 와 W3C DTCG 표준에서는 `"4px"` 처럼 단위를 붙이는 것이 원칙입니다(숫자만 넣으면 Tokens Studio UI 에서 `px` 로 암묵 처리되는 경우가 있으나, W3C DTCG 호환을 위해서는 `"4px"` 형태가 안전합니다).
4. **`typography` 값 객체**:
   - 현재 `type.display.$value` 에 `{ "fontSize": 34, "fontWeight": 700, "lineHeight": 1.2 }` 가 들어 있습니다.
   - Tokens Studio 의 `typography` 복합 토큰은 `fontFamily` 를 포함하는 것이 기본이며(9개 속성: `fontFamily`, `fontWeight`, `fontSize`, `lineHeight`, `letterSpacing`, `paragraphIndent`, `paragraphSpacing`, `textDecoration`, `textCase`), `fontSize` 는 `"34px"`, `fontWeight` 는 문자열(`"700"` 또는 `"Bold"`) 또는 참조(`"{font.weight.bold}"`), `lineHeight` 는 `"120%"` 또는 `"1.2"` 형태를 권장합니다. `fontFamily` 가 빠진 `typography` 토큰은 Figma 텍스트 스타일로 적용할 때 누락 경고가 날 수 있습니다.

권장 방향:
- 디자이너가 Tokens Studio 를 직접 쓰게 하려면 `tokens/` 아래에 세트별 파일(`core.json`, `dark.json`, `light.json`, `pink.json`)을 두고, `gen_tokens.py` 또는 Style Dictionary 변환 단계에서 지금의 `design/tokens.json` 처럼 Flutter 코드 생성에 쓰기 좋은 형태로 합치거나 바로 Dart 상수를 생성하는 파이프라인을 추천합니다.

출처 및 확인일 (2026-11-18):
- Tokens Studio Typography 복합 토큰 문서: https://docs.tokens.studio/manage-tokens/token-types/typography
- Tokens Studio Token Sets 및 Themes 문서: https://docs.tokens.studio/manage-tokens/token-sets/ , https://docs.tokens.studio/manage-tokens/themes/

---

## 5. 비슷한 앱과 벤치마킹

확인일: 2026-11-18

우리 앱의 핵심은 세 가지입니다. 첫째, 기분을 고르고 연타한 수로 그 기분의 크기를 남깁니다. 둘째, 달력으로 날짜별 기분을 돌아봅니다. 셋째, 위치 기반 지도로 내 주변 사람들의 오늘 기분을 봅니다. 여기에 산사·명상 앱처럼 캐릭터가 합장하며 마음을 다스리는 콘셉트를 검토하고 있습니다.

### 5.1 기분 기록 앱

#### Daylio (Daylio Journal - Mood Tracker)
- **플랫폼**: iOS, Android
- **핵심 동작 한 줄**: 글쓰기 없이 기분과 활동 아이콘을 한 번씩 눌러 하루를 남기고, 연도별 픽셀 달력과 통계로 돌아봅니다.
- **우리가 배울 점**: 텍스트 입력을 강요하지 않는 2초 컷 기록 흐름, 달력을 색으로 채워 한눈에 흐름을 보게 하는 시각화("Year in Pixels"), 기기 내 로컬 저장 중심의 프라이버시 설계.
- **피할 점**: 활동 태그·목표·습관 추적까지 화면이 복잡해지는 점(우리 앱은 기분과 연타 강도에만 집중합니다).
- **출처**: https://daylio.net/ , Apple App Store / Google Play (`Daylio Journal - Mood Tracker`, 확인일 2026-11-18)

#### How We Feel
- **플랫폼**: iOS, Android
- **핵심 동작 한 줄**: 에너지·유쾌함 사분면에서 144개 이상의 세밀한 감정 단어를 고르고, 그 자리에서 마음을 다스리는 짧은 조절 가이드를 봅니다.
- **우리가 배울 점**: 감정을 고른 뒤 바로 "지금 마음을 다루는 행동"으로 이어지는 구조, 비영리·광고 없는 차분한 톤.
- **피할 점**: 144개 감정 단어 선택은 고르는 데 시간이 걸리고 부담을 줍니다(우리 앱은 4~5개 큰 기분 배너로 즉시 진입합니다).
- **출처**: https://howwefeel.org/ , Apple App Store / Google Play (`How We Feel`, 확인일 2026-11-18)

#### Bearable (Bearable Health & Mood Tracker)
- **플랫폼**: iOS, Android
- **핵심 동작 한 줄**: 기분·수면·증상·약을 한 타임라인에 기록하고 상관관계("Impacts")와 병원 제출용 리포트를 뽑습니다.
- **우리가 배울 점**: "판단이나 조언 없이 기록과 변화만 보여 준다"는 데이터 중심 태도.
- **피할 점**: 의료·증상 관리 앱 특유의 입력 항목 과다와 무거운 대시보드(우리 앱은 연타라는 신체적 해소에 초점을 둡니다).
- **출처**: https://bearable.app/ , Apple App Store / Google Play (`Bearable`, 확인일 2026-11-18)

### 5.2 연타·목탁형 힐링 클리커

#### Muyu: Wooden Fish / Wooden Fish - Electronic MuYu (전자목어 계열)
- **플랫폼**: iOS, Android
- **핵심 동작 한 줄**: 화면의 목탁을 두드릴 때마다 실제 목탁 소리와 진동이 나고 "공덕 +1" 문구가 떠오르며 횟수가 쌓입니다.
- **우리가 배울 점**: 한 번 누를 때마다 즉각 오는 **소리 + 진동 + 시각 반응**의 손맛, 눈을 감고도 리듬을 타게 만드는 단순한 전체 화면 터치.
- **피할 점**: 자동 연타(auto-tap) 모드나 밈 중심의 가벼운 장난감 느낌(우리 앱은 내 기분의 크기를 직접 손으로 두드려 남기는 경험이 핵심입니다).
- **출처**: Apple App Store (`Muyu: Wooden Fish`, `Wooden Fish - Electronic MuYu`), Google Play (`Wooden Fish`, 확인일 2026-11-18)

### 5.3 위치 기반 기분 공유·감정 지도 서비스

#### The Mood Map
- **플랫폼**: iOS
- **핵심 동작 한 줄**: 지역별 익명 감정 데이터를 모아 "감정 날씨"처럼 동네의 전반적인 기분 흐름을 보여 줍니다.
- **우리가 배울 점**: 개인 점(pin)을 드러내지 않고 지역 단위 집계로 보여 주는 방식("감정 날씨" 은유).
- **피할 점**: 지역 집계 단위가 너무 크거나 개인의 감정 해소 경험 없이 구경만 하게 되는 구조.
- **출처**: Apple App Store (`The Mood Map`, 개발자 Xavier Platforms, 확인일 2026-11-18)

#### Moodi Map
- **플랫폼**: iOS
- **핵심 동작 한 줄**: 이모지를 고르고 슬라이더로 강도를 조절하면 3D 지구본 위에 빛나는 점으로 올라가 전 세계 기분 맥박을 봅니다.
- **우리가 배울 점**: 기분 종류에 더해 **강도**를 함께 남기고, 지도에서 시각적으로 바로 읽히게 하는 발상.
- **피할 점**: 슬라이더 조작은 연타의 카타르시스가 없고, 개별 점(dot) 표시는 동네 단위 프라이버시 위험이 있습니다(우리 앱은 1~2km 격자 집계와 최소 인원 임계치로 보호합니다).
- **출처**: Apple App Store (`Moodi Map`, 확인일 2026-11-18)

#### Mood Map (A&K LABS DMCC)
- **플랫폼**: Android
- **핵심 동작 한 줄**: 카페·공원·바 같은 실제 장소에 빨강~초록 기분 스티커를 붙여 현재 장소의 분위기를 공유합니다.
- **우리가 배울 점**: 지도를 텍스트 리뷰 대신 기분 색·아이콘으로 직관화한 점.
- **피할 점**: 사람 기분이 아니라 상업 장소 평점(리뷰)으로 변질되는 점(우리 앱은 장소 평점이 아니라 동네 사람들의 기분 합계만 봅니다).
- **출처**: Google Play (`Mood Map`, 개발자 A&K LABS DMCC, 확인일 2026-11-18)

### 5.4 국내 산사·명상·캐릭터 힐링 앱

#### 하루콩 (Daily Bean)
- **플랫폼**: iOS, Android
- **핵심 동작 한 줄**: 귀여운 콩 캐릭터 이모지와 아이콘 몇 번의 터치로 하루 기분·일상을 기록하고 월별 감정 달력으로 봅니다.
- **우리가 배울 점**: 한눈에 들어오는 둥글고 부담 없는 감정 달력, 짧은 온보딩, 캐릭터가 과한 설명 없이 정서적 친근감을 주는 방식.
- **피할 점**: 일기·스티커 꾸미기 요소가 많아지면 기록이 숙제처럼 느껴질 수 있습니다.
- **출처**: Apple App Store / Google Play (`하루콩`, `Daily Bean`, 블루시그넘, 확인일 2026-11-18)

#### 산사 (가상 산사 체험 앱) 및 템플로 (TEMPLO)
- **플랫폼**: iOS, Android (`산사` 는 iOS App Store 확인, `템플로` 는 iOS·Android)
- **핵심 동작 한 줄**: 가상 법당에서 절을 하거나 염주를 넘기고(산사), 사찰 방문 스탬프·108배·명상을 기록합니다(템플로).
- **우리가 배울 점**: 합장·절·염주 같은 한국적·산사 모티프를 디지털 터치 행위와 연결해 마음을 가라앉히는 리추얼 감각.
- **피할 점**: 특정 종교 색채가 너무 강하면 비종교인 사용자가 거리감을 느낄 수 있습니다(콘셉트 채택 시 특정 종교 교리보다 "고요한 쉼·합장·자연" 톤으로 중립화하는 편이 안전합니다).
- **출처**: Apple App Store (`산사`, `템플로`), Google Play (`템플로(TEMPLO)`, 확인일 2026-11-18)

#### 마보 (Mabo) · 코끼리
- **플랫폼**: iOS, Android
- **핵심 동작 한 줄**: 한국어 음성 가이드 명상·수면 사운드와 기분·상황별 마음챙김 프로그램을 제공합니다.
- **우리가 배울 점**: 한국 사용자 정서에 맞는 차분한 문구 톤과 짧은 5분 단위 세션 감각.
- **피할 점**: 수동적인 오디오 청취 중심이라 사용자가 직접 손으로 감정을 털어 내는 즉각적 상호작용이 약합니다.
- **출처**: https://www.mabopractice.com/ , Apple App Store / Google Play (`마보`, `코끼리`, 확인일 2026-11-18)

---

### 5.5 우리 앱이 다른 점과 벤치마킹 포인트

**우리 앱이 다른 점**:
기존 기분 앱은 "글이나 아이콘 1회 선택"으로 기분을 기록하고, 기존 목탁 클리커는 "기분 분류나 달력·지도 맥락 없이" 횟수만 쌓습니다. 우리 앱은 **기분 선택 -> 손맛 있는 연타로 크기 측정 및 해소 -> 달력 회고 -> 익명 격자 지도 공감**을 하나로 잇는 점이 다릅니다.

**벤치마킹할 포인트 (5개)**:
1. **초간단 진입(Daylio·하루콩)**: 기분 배너를 누르자마자 확인 단계 없이 곧바로 두드리기 화면으로 들어가게 합니다.
2. **타격감의 3박자(전자목어·Wooden Fish)**: 탭마다 저지연 소리(미세 피치 흔들기) + 진동 + 채움 상승이 한 박자로 맞물려 눈을 감고도 몰입할 수 있게 합니다.
3. **판단 없는 달력과 비교(Daylio·Bearable)**: 달력에서는 색·이모지 위주로 한 달 흐름을 보여 주고, 돌아보기에서도 조언 없이 사실 비교만 한 줄로 알려 줍니다.
4. **감정 날씨형 익명 지도(The Mood Map·Moodi Map)**: 개인 점이나 장소 평점 대신 1~2km 동네 격자의 대표 기분과 행복/슬픔 비율만 보여 줍니다.
5. **보편적인 산사 리추얼 감각(산사·마보)**: 캐릭터 힐링 콘셉트를 채택하더라도 특정 종교 색채를 빼고, 합장·자연 배경·고요한 상태 전환으로 "마음을 털어 내는 리추얼" 분위기만 취합니다.
