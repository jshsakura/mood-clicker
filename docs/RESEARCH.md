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

---

## 6. iOS 배포(맥 없음), 탭 효과음(CC0), 캐릭터 애니메이션(Rive vs Lottie)

확인일: 2026-11-18

### 6.1 맥이 없는 상태에서 아이폰에 Flutter 앱 올리기 (TestFlight)

맥이 없어도 **GitHub Actions macOS 러너**에서 `.ipa` 를 빌드해 **TestFlight 내부 테스트**로 사장님 아이폰에 올릴 수 있습니다.

1. **필요한 애플 측 준비물**:
   - **Apple Developer Program 유료 계정** (연 $99): TestFlight 사용에 필수입니다.
   - **App Store Connect API Key** (`.p8` 파일, `Key ID`, `Issuer ID`): App Store Connect 의 `사용자 및 액세스 > 통합` 에서 **App Manager** 이상 권한으로 발급합니다. CI 에서 2단계 인증(2FA) 없이 업로드할 때 씁니다.
   - **Apple Distribution 인증서(`.p12`)** 와 **App Store 프로비저닝 프로파일(`.mobileprovision`)**.
2. **GitHub Actions -> TestFlight 빌드 절차**:
   - `macos-latest` 러너에서 Flutter SDK 를 설정하고 `flutter build ipa --export-options-plist=...` 또는 `fastlane` (`build_app` + `upload_to_testflight`) 으로 아카이브 및 업로드를 수행합니다.
3. **`fastlane match` 필요 여부**:
   - **필수는 아닙니다.** 인증서(`.p12`)와 프로비저닝 프로파일(`.mobileprovision`)을 GitHub Secrets 에 Base64 로 넣어 CI 키체인에 설치하는 수동 방식이나, `xcodebuild -allowProvisioningUpdates` + API Key 조합도 가능합니다.
   - 다만 인증서 만료·재발급과 팀 공유를 생각하면 `fastlane match` 가 편합니다. **맥 없이도** Linux/Windows 에서 `openssl` 로 개인키와 CSR 을 만든 뒤 Apple Developer 포털에서 `.cer` 을 내려받아 `.p12` 로 변환하고, match 전용 비공개 Git 저장소에 직접 올린 뒤 CI 에서 `readonly: true` 로 불러올 수 있습니다.
4. **GitHub Actions macOS 러너 비용**:
   - 공개(public) 저장소는 무료입니다.
   - 비공개(private) 저장소는 표준 Linux(`$0.006/분`) 대비 **약 10배** 요율로 차감됩니다(`macos-latest` 표준 `$0.062/분`, 대형 러너 `$0.102/분`, 작업 시간은 1분 단위로 올림). GitHub Free 플랜은 월 `$12`(Pro/Team 은 월 `$18`) 무료 크레딧을 제공하므로, 파일럿 단계에서 수동 트리거(`workflow_dispatch`)나 태그 푸시 때만 iOS 빌드를 돌리면 무료 크레딧 안에서 충분히 감당할 수 있습니다.
5. **사장님(내부 테스터) 초대 방식**:
   - App Store Connect `사용자 및 액세스` 에 사장님 Apple ID 를 팀원(Account Holder, Admin, App Manager, Developer, Marketing 중 하나)으로 추가하고, TestFlight **내부 테스트(Internal Testing)** 그룹에 배정합니다.
   - 내부 테스터는 앱당 최대 **100명**까지 가능하며, **Beta App Review(외부 심사) 없이** 업로드·처리 직후 TestFlight 앱에서 바로 설치할 수 있습니다(빌드 유효기간 90일).
6. **안드로이드 `.apk` 직접 전달로 충분한가**:
   - 파일럿·사내 확인 단계에서는 `flutter build apk --release`(또는 `--debug`) 로 만든 `.apk` 파일을 메신저나 드라이브로 직접 전달해 설치("출처를 알 수 없는 앱 허용")하는 것으로 충분합니다. Play Console 계정이나 심사 없이 즉시 동작합니다. 버전 관리나 자동 알림이 필요해지면 Firebase App Distribution(무료)을 붙이면 됩니다.

출처 및 확인일 (2026-11-18):
- Apple Developer Program 및 TestFlight 내부 테스트 안내: https://developer.apple.com/testflight/
- GitHub Actions 요금 및 macOS 러너 분당 단가: https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions
- Fastlane `match` 공식 문서: https://docs.fastlane.tools/actions/match/
- 맥 없이 OpenSSL 로 Distribution 인증서(`.p12`) 및 `match` 구성 참고: https://simondalvai.org/blog/fastlane-match-without-mac/

### 6.2 탭 효과음 (상업 이용·재배포 가능한 CC0 출처 및 후보)

파일럿 이후 회사에 코드를 넘기는 조건이므로, 상업 이용과 앱 번들 재배포가 자유로운 **CC0 1.0 (퍼블릭 도메인)** 음원을 우선 쓰는 것이 가장 안전합니다. (`docs/SPEC.md` 방침대로 출처와 라이선스는 `THIRD_PARTY_NOTICES` 에 남깁니다.)

| 출처 | 라이선스 | 상업 이용·앱 번들 | 저작자 표기 의무 | 비고 |
|---|---|---|---|---|
| **Kenney.nl** (`Interface Sounds`, `UI Audio`, `Impact Sounds`, `RPG Audio`) | **CC0 1.0** | 가능 | 불필요(권장 사항) | 음질과 톤이 고르게 마스터링되어 있어 UI·타격음 조합에 가장 무난합니다. |
| **Freesound.org** (`CC0` 필터) | 파일별 상이(**CC0**, CC-BY, CC-BY-NC) | CC0 만 조건 없이 가능 | CC0 불필요 / CC-BY **필수** | 반드시 검색 시 CC0 로 필터링하고, 원저작자가 타인의 저작물을 무단 업로드한 음원이 아닌지 확인해야 합니다. CC-BY-NC 는 상업 불가입니다. |

기분별 효과음 후보:
- **행복해요 (높고 맑은 톡)**: Kenney `Interface Sounds` / `UI Audio` 의 `click`, `pop`, `tap` 계열
- **설레요 (방울 소리)**: Kenney `Interface Sounds` 의 `confirmation` / `tone` 계열 또는 Freesound CC0 `bell` / `chime`
- **화나요 (낮은 북소리)**: Kenney `Impact Sounds` / `RPG Audio` 의 `thud` / `impact` 계열 또는 Freesound CC0 `low drum`
- **슬퍼요 (낮은 물방울)**: Freesound CC0 `water drop` / `droplet` (짧은 단일 타격음)
- **불안해요 (짧은 째깍)**: Kenney `Interface Sounds` 의 짧은 `switch` / `tick` 계열 또는 Freesound CC0 `clock tick`

출처 및 확인일 (2026-11-18):
- Kenney 오디오 에셋 (CC0): https://kenney.nl/assets?q=audio
- Freesound 라이선스 안내: https://freesound.org/help/faq/#licenses

### 6.3 캐릭터 애니메이션: Flutter 에서 Rive vs Lottie

`docs/SPEC.md` 의 캐릭터 상태(`가만히`, `반응`, `합장`, `마무리`)와 초당 여러 번 두드리는 연타 상황을 기준으로 비교했습니다.

| 비교 항목 | Rive (`rive` `0.14.11`) | Lottie (`lottie` `3.8.1`) |
|---|---|---|
| **런타임·번들 크기** | `rive_native` C++ 네이티브 바이너리를 포함하므로 앱 크기가 플랫폼별 수 MB 늘어납니다. 대신 `.riv` 에셋 파일 자체는 바이너리라 매우 작습니다. | **순수 Dart 구현**이라 네이티브 바이너리 증가가 거의 없습니다. 대신 JSON 에셋이 크면 앱 크기에 반영됩니다(dotLottie 압축으로 완화 가능). |
| **상태 머신 지원** | **매우 강함.** Rive Editor 안에서 `가만히 -> 반응 -> 합장 -> 마무리` 상태 그래프와 트리거·숫자 입력(`채움` 값 연동)을 직접 설계합니다. Flutter 코드에서는 상태 이름·입력값만 바꿉니다. | 전통적으로 타임라인 재생 중심이라 구간(마커) 전환과 블렌딩을 Dart 코드로 직접 제어해야 합니다. (dotLottie/Lottie Creator 에서 기본 상태 머신이 추가되었으나 복합 캐릭터 제어는 Rive 가 더 성숙합니다.) |
| **연타 중 성능** | 실시간 인터랙션용 바이너리 런타임(또는 Rive Renderer)이라 연타 중 트리거 반복 호출과 상태 전환 블렌딩이 부드럽습니다. | 복잡한 벡터 패스나 큰 JSON 은 저사양 안드로이드에서 프레임 드롭이 생길 수 있어 에셋 경량화가 중요합니다. |
| **디자이너 작업 흐름** | **Rive Editor**(웹/데스크톱)에서 그리기·리깅·애니메이션·상태 머신을 한 번에 만듭니다. 내보내기 깨짐이 없으나 디자이너가 새 도구를 익혀야 합니다. | **After Effects**(Bodymovin) 또는 **Lottie Creator** 를 씁니다. 기존 모션 디자이너에게 익숙하지만 AE 기능 일부가 내보내기에서 누락될 수 있습니다. |

정리:
- 캐릭터가 연타(`반응`)와 `채움`(`합장`, `마무리`)에 실시간으로 반응해야 한다면 **Rive** 가 상태 머신과 연타 성능 면에서 유리합니다.
- 디자이너가 After Effects 만 쓰고 상태 전환이 단순한 루프 교체 수준이라면 **Lottie** 도 가능합니다.

출처 및 확인일 (2026-11-18):
- `rive` 패키지 (pub.dev) 및 공식 문서: https://pub.dev/packages/rive , https://rive.app/docs/runtimes/flutter/flutter
- `lottie` 패키지 (pub.dev): https://pub.dev/packages/lottie

---

## 7. 익명 기분 집계 서버, 위치 격자, 스토어 개인정보 요구사항

확인일: 2026-11-18

### 7.1 익명 기분 집계 서버 후보 비교

| 항목 | Supabase | Firebase (Spark 무료 플랜) | Cloudflare Workers + D1 |
|---|---|---|---|
| **무료 범위** | DB 500MB, MAU 50,000, 스토리지 1GB, 대역폭 5GB, API 요청 무제한, 활성 프로젝트 최대 2개. **1주일 비활성 시 프로젝트 자동 일시정지**됩니다. | 인증(익명 포함) MAU 50,000, Firestore 일 5만 읽기 / 2만 쓰기 / 2만 삭제, 1GiB 저장, 월 10GB 전송. (Cloud Functions 는 Blaze 종량제 전환 필요) | Workers 일 10만 요청(호출당 CPU 10ms). D1(SQLite) 단일 DB 최대 500MB(계정 합산 5GB), 일 500만 행 읽기 / 10만 행 쓰기(초과 시 자정 UTC 까지 차단). 일시정지 없음. |
| **익명 인증 방식** | `signInAnonymously()` 기본 제공 (`auth.users` 에 `is_anonymous` 클레임 JWT 발급, RLS 연동 가능). | Firebase Auth 익명 로그인 기본 제공 (Spark 플랜 무료 50,000 MAU 포함). | 기본 인증 서비스 없음. 앱에서 익명 토큰/UUID 를 발급하거나 Worker 에서 자체 JWT 를 서명해 D1 에 저장해야 합니다. |
| **서버 격자 집계 방법** | Postgres RPC / View / SQL 에서 `GROUP BY grid_id HAVING COUNT(DISTINCT user_id) >= 5` 로 1회 쿼리로 `k-익명성` 필터링까지 처리합니다. | Firestore 는 `COUNT(DISTINCT)` 와 `HAVING` 집계가 약해, 격자별 카운터 문서로 증분 쓰기 후 조회 시 `>= 5` 필터링하거나 Cloud Functions(Blaze) 가 필요합니다. | D1(SQLite) 에서 `GROUP BY grid_id HAVING COUNT(DISTINCT user_id) >= 5` SQL 로 바로 집계·필터링합니다. |
| **운영 부담** | 낮음(단, 무료 플랜 7일 미사용 시 자동 일시정지 복구 또는 주기적 핑 필요). | 낮음(다만 SQL 집계가 안 되어 NoSQL 데이터 모델 설계와 Blaze 전환 주의 필요). | 중간(익명 토큰·중복 방지 로직을 Worker 코드로 직접 짜야 하지만, 일시정지가 없고 SQLite 라 단순함). |

**비상업 파일럿 추천: Supabase**
- 이유:
  1. `signInAnonymously()` 와 Postgres RLS 를 바로 쓸 수 있어 익명 인증 구현 비용이 가장 낮습니다.
  2. 격자 집계와 "한 격자 최소 5명(`HAVING COUNT(DISTINCT user_id) >= 5`)" 조건을 Postgres SQL 한 줄(RPC)로 안전하게 강제할 수 있어, 클라이언트에 5명 미만 격자 데이터가 아예 내려가지 않습니다.
  3. 추후 회사에 코드를 넘길 때도 표준 PostgreSQL 스키마와 SQL 로 인수인계하기 쉽습니다. (무료 플랜 7일 비활성 일시정지만 테스트 기간 중 유념하면 됩니다.)

출처 및 확인일 (2026-11-18):
- Supabase 요금 및 익명 로그인 문서: https://supabase.com/pricing , https://supabase.com/docs/guides/auth/auth-anonymous
- Firebase 요금(Spark) 및 익명 인증 문서: https://firebase.google.com/pricing , https://firebase.google.com/docs/auth/flutter/anonymous-auth
- Cloudflare Workers 및 D1 무료 범위 문서: https://developers.cloudflare.com/workers/platform/pricing/ , https://developers.cloudflare.com/d1/platform/pricing/

### 7.2 위치 격자 크기, Flutter 패키지, k-익명성

#### 1) Geohash vs H3 칸 크기 비교

| 격자 체계 | 해상도 / 정밀도 | 실제 칸 크기 (넓이·변 길이) | 특징 |
|---|---|---|---|
| **Geohash** | 정밀도 **5** | 약 **4.9km x 4.9km** (적도 기준, 약 24km²) | 위도가 높아질수록 동서 폭이 좁아지는 직사각형입니다. |
| **Geohash** | 정밀도 **6** | 약 **1.2km x 0.61km** (적도 기준, 약 0.73km²) | 3km² 보다 작아 스토어 정책상 정밀 위치로 분류될 수 있습니다. |
| **Uber H3** | 해상도 **7** | 평균 면적 **약 5.16km²**, 평균 변 길이 **약 1.22km** (인접 중심 거리 약 2.04km) | 정육각형이라 위도 왜곡이 적고 인접 칸 거리가 균일합니다. |
| **Uber H3** | 해상도 **8** | 평균 면적 **약 0.74km²**, 평균 변 길이 **약 0.46km** (인접 중심 거리 약 0.70km) | 3km² 보다 작아 동네 단위보다는 블록 단위에 가깝습니다. |

#### 2) Flutter 패키지 유지 상태
- **`dart_geohash` (`2.1.0`) / `geohash_plus` (`1.1.1`)**: 각각 약 2년·4년 전 이후 업데이트가 멈춘 레거시 상태입니다. Geohash 를 쓴다면 최신 순수 Dart 패키지(`fast_geohash` 등)나 직접 인코더(수십 줄) 구현을 권장합니다.
- **`h3_flutter` (`0.8.0`) / `h3_dart` (`0.8.0`)**: `festelo.net` 이 유지 중이며 FFI/JS 바인딩을 제공합니다(커뮤니티 포크인 `h3_flutter_plus` 등도 존재합니다).

#### 3) k-익명성(한 칸 최소 인원) 실무 사례
- 공간 데이터 k-익명성은 한 격자·구간에 최소 `k` 명의 고유 사용자가 있을 때만 통계를 공개하는 방식입니다.
- 이동·공간 통계 실무(소지역 통계, Strava Metro 등)에서는 **`k = 5`** 를 최소 기준선으로 삼고 구간별 임계치 미만은 숨기거나(suppression) 반올림·차분 프라이버시(Google Mobility 등)를 결합합니다.
- `docs/SPEC.md` 의 초안("최소 5명 미만 비표시")은 실무 기준에 부합하며, `H3 해상도 7`(변 약 1.22km, 면적 약 5.16km²) 은 동네 크기 감각과 아래 스토어 "대략적 위치(3km² 이상)" 기준을 동시에 만족합니다.

출처 및 확인일 (2026-11-18):
- Uber H3 해상도별 면적·변 길이 공식 표: https://h3geo.org/docs/core-library/restable/
- `h3_flutter` / `h3_dart` / `dart_geohash`: https://pub.dev/packages/h3_flutter , https://pub.dev/packages/h3_dart , https://pub.dev/packages/dart_geohash
- Google Research 공간 집계 및 차분 프라이버시: https://research.google/blog/
- 공간 역학·모빌리티 k-익명성 참고: https://www.gov.uk/government/publications/strava-metro-privacy-and-data-governance (Strava Metro 집계·임계치 사례)

### 7.3 위치 기반 앱의 스토어 요구사항 (App Store / Google Play)

| 항목 | Apple App Store | Google Play |
|---|---|---|
| **권한 및 설명 문구** | `Info.plist` 에 `NSLocationWhenInUseUsageDescription` 필수. 사용자가 왜 위치를 쓰는지 구체적 목적을 적어야 합니다("내 주변 동네 기분을 보여 주기 위해 사용합니다"). 백그라운드 권한은 요청하지 않습니다. | `AndroidManifest.xml` 에 `ACCESS_COARSE_LOCATION` 선언(대략적 위치만으로도 충분하면 `ACCESS_FINE_LOCATION` 제외 가능). |
| **개인정보 처리방침** | App Store Connect 제출 및 앱 내 접근 가능한 Privacy Policy URL 필수. | Play Console 제출 및 앱 내 접근 가능한 개인정보 처리방침 URL 필수. |
| **스토어 개인정보 신고** | **App Privacy (영양 라벨)**: 수집 항목, 사용자 연결 여부(Linked to User), 목적(App Functionality) 신고. | **Data Safety (데이터 보안 양식)**: 수집·공유 여부, 암호화, 삭제 요청 가능 여부 신고. |

**기기에서 격자로 바꿔 보내는 경우의 기재 방법**:
- **정밀 위치 vs 대략적 위치 기준**:
  - Google Play Data Safety 는 **3km² 이상**을 대략적 위치(Approximate location), **3km² 미만**을 정밀 위치(Precise location)로 구분합니다.
  - Apple App Privacy 도 약 3km 반경 수준 이상의 일반화 여부를 기준으로 정밀(Precise)과 대략적(Coarse) 위치를 구분합니다.
- **기재 시 주의할 점**:
  1. 기기에서 GPS 를 읽어 **H3 해상도 7(약 5.16km²) 또는 Geohash 5(약 24km²)** 로 바꾼 뒤 격자 번호만 서버로 보내고 원본 좌표는 즉시 버린다면, 서버로 전송되는 데이터는 **대략적 위치(Coarse / Approximate Location)** 로 기재할 수 있습니다.
  2. 반대로 Geohash 6(약 0.73km²) 이나 H3 해상도 8(약 0.74km²) 은 3km² 미만이므로, 격자로 바꿨더라도 Google Play 기준상 **정밀 위치**로 신고해야 할 수 있습니다.
  3. 서버 접속 로그에 사용자 IP 가 남거나 서드파티 SDK 가 좌표를 수집하면 별도로 위치·기기 정보 수집을 신고해야 하므로, 서드파티 SDK 유무와 서버 IP 로그 보관 여부를 함께 맞춰야 합니다.

출처 및 확인일 (2026-11-18):
- Apple App Privacy Details 공식 안내: https://developer.apple.com/app-store/app-privacy-details/
- Apple `NSLocationWhenInUseUsageDescription`: https://developer.apple.com/documentation/bundleresources/information_property_list/nslocationwheninuseusagedescription
- Google Play Data safety 공식 가이드: https://support.google.com/googleplay/android-developer/answer/10787469
- Android 대략적 위치(`ACCESS_COARSE_LOCATION`) 가이드: https://developer.android.com/develop/sensors-and-location/location/permissions

---

## 8. 기분별 진동 패턴 설계 및 Kenney CC0 효과음 후보

확인일: 2026-11-18

### 8.1 기분별 진동 패턴 설계 (iOS Core Haptics / Android VibrationEffect)

Apple HIG(Playing haptics)에 따라 단발성 타격은 `transient`, 여운이 남는 진동은 `continuous` 로 두고 `intensity`(세기, `0.0~1.0`)와 `sharpness`(날카로움·질감, `0.0~1.0`)를 조합합니다. Android 는 API 30+ 지원 기기에서는 `VibrationEffect.Composition` 프리미티브(`PRIMITIVE_TICK`, `PRIMITIVE_CLICK`, `PRIMITIVE_THUD`)를 우선 쓰고, 일반 진폭 지원 기기(`hasAmplitudeControl() == true`, API 26+)는 `createWaveform(timings, amplitudes, -1)`(진폭 `0~255`)을 사용합니다.

| 반응 / 기분 | 느낌 설명 | iOS Core Haptics (`intensity`, `sharpness`, 타입, 지속/간격) | Android `VibrationEffect` (`timings` ms / `amplitudes` 0~255 또는 Composition 프리미티브) |
|---|---|---|---|
| `tap` · **행복해요** | 가볍고 튀는 톡 | `transient`, `intensity: 0.55`, `sharpness: 0.85` (단발 1회) | 파형: `[0, 15]` / `[0, 140]` · Composition: `PRIMITIVE_TICK(0.65)` |
| `tap` · **설레요** | 짧게 두 번 톡톡 | `transient` 2회, `intensity: 0.45 -> 0.65`, `sharpness: 0.75`, 간격 `45ms` (`t=0ms`, `45ms`) | 파형: `[0, 12, 35, 15]` / `[0, 110, 0, 165]` · Composition: `PRIMITIVE_TICK(0.5)` + 지연 `35ms` + `PRIMITIVE_CLICK(0.7)` |
| `tap` · **화나요** | 무겁고 짧은 쿵 | `transient`, `intensity: 0.95`, `sharpness: 0.25` (낮은 sharpness 로 묵직한 타격) | 파형: `[0, 32]` / `[0, 245]` · Composition: `PRIMITIVE_THUD(0.95)` |
| `tap` · **슬퍼요** | 부드럽고 긴 웅 | `continuous`, `intensity: 0.45`, `sharpness: 0.15`, 지속 `80ms` | 파형: `[0, 30, 50]` / `[0, 110, 65]` (부드러운 감쇠, 연타 시 이전 진동 덮어쓰기) |
| `tap` · **불안해요** | 잘게 떨리는 진동 | `transient` 3회 연속, `intensity: 0.35`, `sharpness: 0.90`, 간격 `22ms` (`t=0, 22, 44ms`) | 파형: `[0, 10, 14, 10, 14, 10]` / `[0, 95, 0, 95, 0, 95]` · Composition: `PRIMITIVE_TICK(0.4)` 3회 (`14ms` 간격) |
| `full` | 채움 끝까지 참 (길고 센 진동) | `continuous` (`intensity: 0.90`, `sharpness: 0.45`, 지속 `220ms`) + 종료 `transient` (`intensity: 1.0`, `sharpness: 0.80`, `t=230ms`) | 파형: `[0, 140, 30, 60]` / `[0, 220, 0, 255]` · Composition: `PRIMITIVE_THUD(0.85)` + `60ms` + `PRIMITIVE_CLICK(1.0)` |
| `select` | 기분 배너 누름 (가벼운 선택) | `transient`, `intensity: 0.45`, `sharpness: 0.65` | 파형: `[0, 12]` / `[0, 115]` · Composition: `PRIMITIVE_CLICK(0.5)` |
| `drop` | 채움 0으로 떨어짐 (아주 약한 진동) | `transient`, `intensity: 0.25`, `sharpness: 0.20` | 파형: `[0, 15]` / `[0, 60]` · Composition: `PRIMITIVE_LOW_TICK` 또는 `PRIMITIVE_TICK(0.25)` |

참고:
- `tap` 연타 시에는 `docs/SPEC.md` 초안대로 최소 `40ms` 간격으로 쓰로틀링합니다. `설레요`(총 47ms~60ms)와 `불안해요`(총 54ms~58ms)는 짧은 연타 시 이전 패턴이 끝나기 전에 새 패턴이 들어올 수 있으므로, 직전 패턴을 취소(cancel)하거나 최소 간격을 기분별 패턴 길이 이상으로 맞춥니다.

#### Android 진폭 미지원 기기(`!vibrator.hasAmplitudeControl()`) 대체안
1. **기본 진폭 + 짧은 온오프 `timings` 구분**: 진폭을 바꿀 수 없는 구형·보급형 기기에서는 `0` 이 아닌 진폭이 모두 최대 세기(100%)로 울립니다. `VibrationEffect.createWaveform(timings, -1)`(진폭 배열 없이 시간만 지정) 또는 `VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE)` 로 바꾸고, 기분 차이는 펄스 길이와 횟수로만 구분합니다(예: 행복해요 `[0, 12]`, 설레요 `[0, 10, 40, 12]`, 화나요 `[0, 28]`, 슬퍼요 `[0, 45]`, 불안해요 `[0, 8, 18, 8]`, `drop` 은 생략하거나 `8ms` 1회).
2. **`HapticFeedbackConstants` 대체**: `hasAmplitudeControl()` 이 거짓이거나 ERM 모터라 뭉개짐이 심할 때는 `View.performHapticFeedback()` 의 OS 기본 상수(`CLOCK_TICK` -> 가벼운 톡, `CONTEXT_CLICK` -> 선택, `LONG_PRESS` -> 묵직한 확인)로 내리는 편이 오히려 불쾌한 윙윙거림을 줄입니다.

출처 및 확인일 (2026-11-18):
- Apple HIG Playing haptics: https://developer.apple.com/design/human-interface-guidelines/playing-haptics
- Android Haptics 설계 원칙 및 `VibrationEffect` / `Composition` / `hasAmplitudeControl()`: https://developer.android.com/develop/ui/views/haptics/haptics-principles , https://developer.android.com/develop/ui/views/haptics/custom-haptic-effects

### 8.2 Kenney CC0 오디오 팩 효과음 후보 목록

아래 파일들은 모두 **CC0 1.0** 라이선스로 상업 이용 및 앱 번들 재배포가 가능합니다. (실제 파일 다운로드는 하지 않았으며, 팩 목록에서 용도에 맞는 후보를 골랐습니다.)

| 용도 | 느낌 | 추천 팩 이름 | 후보 파일 이름 | 팩 페이지 URL |
|---|---|---|---|---|
| `tap` · **행복해요** | 높고 맑은 톡 | **Interface Sounds** (또는 UI Audio) | `pluck_001.ogg`, `click_001.ogg` (`UI Audio` 는 `click1.ogg`) | https://kenney.nl/assets/interface-sounds , https://kenney.nl/assets/ui-audio |
| `tap` · **설레요** | 방울 소리 | **Interface Sounds** | `glass_001.ogg`, `confirmation_001.ogg` | https://kenney.nl/assets/interface-sounds |
| `tap` · **화나요** | 낮은 북소리 | **Impact Sounds** | `impactSoft_heavy_000.ogg`, `impactWood_heavy_000.ogg` | https://kenney.nl/assets/impact-sounds |
| `tap` · **슬퍼요** | 낮은 물방울 | **Interface Sounds** | `drop_001.ogg`, `bong_001.ogg` | https://kenney.nl/assets/interface-sounds |
| `tap` · **불안해요** | 짧은 째깍 | **Interface Sounds** | `tick_001.ogg`, `switch_001.ogg` | https://kenney.nl/assets/interface-sounds |
| `full` | 채움 완료 짧은 효과음 | **Interface Sounds** | `confirmation_002.ogg`, `maximize_001.ogg` | https://kenney.nl/assets/interface-sounds |
| `select` | 기분 배너 선택 작은 소리 | **Interface Sounds** | `select_001.ogg`, `switch_002.ogg` | https://kenney.nl/assets/interface-sounds |

출처 및 확인일 (2026-11-18):
- Kenney Interface Sounds: https://kenney.nl/assets/interface-sounds
- Kenney UI Audio: https://kenney.nl/assets/ui-audio
- Kenney Impact Sounds: https://kenney.nl/assets/impact-sounds
