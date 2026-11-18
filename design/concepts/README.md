# 디자인 시안 (Concepts)

확인일: 2026-11-18

이 폴더의 그림은 POC 단계에서 지도 배경, 캐릭터 방향성, 로딩 질감을 검토하기 위한 시안입니다. 모든 시안은 밝은 화이트와 회색 선 위주의 절제된 미니멀 톤으로 제작했으며, 글자와 특정 브랜드·장소 모방 요소를 넣지 않았습니다.

---

## 1. 파일 목록

| 파일 이름 | 용도 | 해상도 / 형식 | 제작 도구 |
|---|---|---|---|
| `map-light.png` | 가상 동네 지도 배경 (라이트, `#F6F6F8`) | `1170x2532` PNG (RGB) | Python + Pillow (2x 슈퍼샘플링 절차적 생성) |
| `map-dark.png` | 가상 동네 지도 배경 (다크, `#121216`, 동일 구도) | `1170x2532` PNG (RGB) | Python + Pillow (2x 슈퍼샘플링 절차적 생성) |
| `char-brush-idle.png` | 캐릭터 시안 A (붓선) · `idle` | `1024x1024` 투명 PNG (RGBA) | `generate_image` + Pillow 배경 투명화 |
| `char-brush-react.png` | 캐릭터 시안 A (붓선) · `react` | `1024x1024` 투명 PNG (RGBA) | `generate_image` (`idle` 참조) + Pillow 배경 투명화 |
| `char-brush-palmsTogether.png` | 캐릭터 시안 A (붓선) · `palmsTogether` | `1024x1024` 투명 PNG (RGBA) | `generate_image` (`idle` 참조) + Pillow 배경 투명화 |
| `char-brush-finish.png` | 캐릭터 시안 A (붓선) · `finish` | `1024x1024` 투명 PNG (RGBA) | `generate_image` (`idle` 참조) + Pillow 배경 투명화 |
| `char-geo-idle.png` | 캐릭터 시안 B (기하 도형) · `idle` | `1024x1024` 투명 PNG (RGBA) | `generate_image` + Pillow 배경 투명화 |
| `char-geo-react.png` | 캐릭터 시안 B (기하 도형) · `react` | `1024x1024` 투명 PNG (RGBA) | `generate_image` (`idle` 참조) + Pillow 배경 투명화 |
| `char-geo-palmsTogether.png` | 캐릭터 시안 B (기하 도형) · `palmsTogether` | `1024x1024` 투명 PNG (RGBA) | `generate_image` (`idle` 참조) + Pillow 배경 투명화 |
| `char-geo-finish.png` | 캐릭터 시안 B (기하 도형) · `finish` | `1024x1024` 투명 PNG (RGBA) | `generate_image` (`idle` 참조) + Pillow 배경 투명화 |
| `loading-texture.png` | 로딩 화면용 은은한 한지/안개 질감 | `1170x2532` PNG (RGB) | `generate_image` + Pillow 리사이즈 |

---

## 2. 도구별 프롬프트 및 제작 방식

### 2.1 지도 배경 (`map-light.png`, `map-dark.png`)
- **방식**: Python + Pillow 로 3단계 굵기(`5.5px`, `2.8px`, `1.3px`)의 도로선, 옅은 강 1개, 옅은 공원 다각형 2곳을 `2340x5064` 로 그린 뒤 LANCZOS 리샘플링으로 `1170x2532` PNG 로 저장했습니다. 건물 블록과 텍스트를 넣지 않았고, 라이트(`#F6F6F8`)와 다크(`#121216`)는 완전히 동일한 좌표를 씁니다.

### 2.2 캐릭터 시안 A: 붓선 느낌 (`char-brush-*.png`)
- **도구**: Antigravity 내장 `generate_image` (`AspectRatio: "1:1"`, `idle` 생성 후 나머지 3포즈에 `ImagePaths` 로 `idle` 참조 전달) + Python Pillow(가장자리 플러드필 기반 흰 배경 투명화 및 `1024x1024` RGBA 변환).
- **프롬프트 요지**:
  - `idle`: 절제된 먹선/차콜 붓선(`#222228`), 옅은 미색(`#F6F4EE`)과 돌회색(`#D9D6CE`) 채움, 가부좌로 눈을 감고 고요히 앉은 독창적 산사 캐릭터, Rive/Lottie 트레이싱이 쉬운 단순한 선, 글자/배경 없음.
  - `react`: `idle` 과 동일 비례·화풍 유지, 살짝 기운 자세와 부드럽게 뜬 눈, 들어 올린 손, 어깨 옆 옅은 먹물 파동 호.
  - `palmsTogether`: `idle` 과 동일 비례·화풍 유지, 두 손을 가슴 앞에 모은 대칭 합장 자세.
  - `finish`: `idle` 과 동일 비례·화풍 유지, 눈을 감은 편안한 미소와 머리 뒤 갈필 원형 후광.

### 2.3 캐릭터 시안 B: 둥근 기하 도형 (`char-geo-*.png`)
- **도구**: Antigravity 내장 `generate_image` (`AspectRatio: "1:1"`, `idle` 생성 후 나머지 3포즈에 `ImagePaths` 로 `idle` 참조 전달) + Python Pillow(가장자리 플러드필 기반 흰 배경 투명화 및 `1024x1024` RGBA 변환).
- **프롬프트 요지**:
  - `idle`: 차가운 돌회색(`#ECECF0`) 둥근 머리, 부드러운 차콜(`#383840`) 종 모양 몸통, 모래색(`#D4CCC0`) 깃 포인트, 단색 플랫 벡터 스타일, 그라데이션·노이즈·글자 없음.
  - `react`: `idle` 과 동일 비례·색상 유지, 약 7도 기울기와 작은 점 눈, 가슴 높이로 살짝 벌린 손, 옅은 회색(`#D4D4DC`) 동심원 파동 2개.
  - `palmsTogether`: `idle` 과 동일 비례·색상 유지, 대칭으로 모은 합장 자세.
  - `finish`: `idle` 과 동일 비례·색상 유지, 잔잔한 미소 선과 머리 뒤 모래색(`#E6DFD3`) 원형 후광.

### 2.4 로딩 배경 질감 (`loading-texture.png`)
- **도구**: Antigravity 내장 `generate_image` (`AspectRatio: "9:16"`) + Python Pillow(`1170x2532` PNG 변환).
- **프롬프트 요지**: 밝은 오프화이트(`#F6F6F8`) 바탕에 아주 옅은 한지 섬유결과 `#ECECF0`~`#F6F6F8` 사이의 미세한 안개 톤 변화만 있는 완전히 평평한 미니멀 질감, 비네팅·글자·로고·잡티 없음.

---

## 3. 상업 이용 가능 여부 (도구 약관 기준)

1. **`map-light.png`, `map-dark.png` (Python + Pillow 자체 생성)**:
   - 저장소 내 스크립트로 직접 그린 창작물이므로 저작권·상업 이용·회사 이관에 제약이 없습니다.
2. **`char-*.png`, `loading-texture.png` (`generate_image` 생성)**:
   - Google Gemini / Imagen 생성 도구의 약관상 생성 결과물 자체의 상업적 활용은 허용되나(계정/요금제별 최신 Google Generative AI 약관 확인 필요), AI 생성물은 국가별 저작권 등록·배타적 권리 보호가 제한될 수 있습니다.
   - 따라서 이 이미지들은 **디자이너 시안·방향 검토용**으로 쓰고, 실제 출시용 캐릭터와 Rive(`.riv`)/Lottie(`.json`) 에셋은 디자이너가 이 시안을 참고해 벡터로 직접 새로 제작하는 것을 권장합니다.

출처 및 확인일 (2026-11-18):
- Google Terms of Service / Generative AI Additional Terms: https://policies.google.com/terms , https://policies.google.com/terms/generative-ai
