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
