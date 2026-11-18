# 디자인을 바꾸는 법

디자이너가 코드를 몰라도 앱의 모양을 바꿀 수 있게 만들었습니다. 바꿀 곳은 두 군데뿐입니다.

## 1. 값: `design/tokens.json`

색, 간격, 둥글기, 글자, 움직임 시간이 전부 이 파일 하나에 있습니다.
형식은 W3C 디자인 토큰(`$type`, `$value`)이고, 구성은 Figma 의 Tokens Studio 단일 파일 형식을 따릅니다.
Tokens Studio 무료판은 GitHub 의 파일 하나만 주고받을 수 있어서 한 파일로 합쳤습니다.

| 최상위 키 | 내용 |
|---|---|
| `core` | 테마와 상관없는 값. 간격, 둥글기, 글꼴, 글자, 움직임 |
| `dark` `light` `pink` | 테마 한 벌씩. 같은 이름의 색을 테마마다 다른 값으로 둡니다 |
| `$themes` `$metadata` | Tokens Studio 가 관리합니다. 손으로 고치지 않습니다. 생성기는 `$` 로 시작하는 키를 건너뛰고, `$metadata.tokenSetOrder` 가 있으면 그 순서로 세트를 읽습니다 |

테마의 밝기는 `$extensions.app.brightness` 에 `light` 나 `dark` 로 적으면 그대로 따릅니다.
적지 않으면 `ground` 색의 상대 휘도가 0.5 를 넘는지로 정합니다. Tokens Studio 가 이 항목을 지워도 괜찮습니다.

`core` 안의 묶음은 이렇습니다.

| 묶음 | 내용 |
|---|---|
| `space` | 간격 단계 (4px, 8px, 12px, 16px, 24px, 32px, 48px) |
| `radius` | 카드, 버튼, 알약 모양의 둥글기 |
| `font.family` | 본문 글꼴. Pretendard 입니다 |
| `font.brand` | 앱 이름 글꼴. 쿠킹호일과 같은 Baloo 2 ExtraBold 이고 라틴 문자만 있습니다 |
| `type` | 글자 단계 (display, title, body, label, count, wordmark). 글꼴은 `{font.family}`, `{font.brand}` 참조로 씁니다 |
| `motion` | 눌림, 채움, 화면 전환 시간 |

고친 뒤에는 이렇게 합니다.

```bash
python3 tool/gen_tokens.py   # lib/design/tokens.g.dart 를 다시 만듭니다
tool/fl test                 # 대비 검사까지 돕니다
```

규칙은 생성기가 지켜 줍니다. 어기면 어느 줄이 왜 틀렸는지 알려 줍니다.

- 세트를 하나 더 두면 테마가 하나 늘어납니다. 색을 새로 넣으면 모든 테마에 같은 이름으로 넣어야 합니다.
- 색은 `#RRGGBB` 나 `#RRGGBBAA`, 크기는 `16px` 이나 `16`(숫자만 적으면 px), 줄 높이는 `1.5` 나 `150%`, 시간은 `120ms` 처럼 씁니다.
- 글자 굵기는 100 단위입니다. 지금 들어 있는 Pretendard 는 400 과 700 두 굵기뿐이라, 다른 굵기를 쓰려면 글꼴 파일도 더해야 합니다.

## 글꼴

원본은 `design/fonts/` 에 있고, 앱에는 `python3 tool/subset_fonts.py` 로 만든 가벼운 판(`assets/fonts/`)이 들어갑니다.
한글은 KS X 1001 의 2,350자만 남겨 두 굵기 합쳐 3MB 에서 690KB 로 줄였습니다. 빠진 드문 글자는 기기의 시스템 글꼴로 그려집니다.
굵기를 더하려면 원본 파일을 `design/fonts/` 에 넣고 스크립트를 돌린 뒤 `pubspec.yaml` 에 적습니다.
- 글자와 바탕의 대비가 4.5 아래로 떨어지면 테스트가 실패합니다. 읽기 어려운 조합을 막기 위해서입니다.

`tokens.g.dart` 를 손으로 고치면 커밋 훅과 CI 가 막습니다.

### Tokens Studio 와 GitHub 동기화 (무료판)

Figma 의 Tokens Studio 플러그인에서 한 번만 설정합니다. 메뉴 이름은 플러그인 버전에 따라 조금 다를 수 있습니다.

1. 플러그인의 설정에서 토큰 저장소(Sync)에 GitHub 를 새로 추가합니다.
2. 아래처럼 채웁니다.

   | 칸 | 값 |
   |---|---|
   | Personal Access Token | 이 저장소 하나에만 Contents 읽기·쓰기 권한을 준 GitHub 토큰. 다른 사람에게 알려 주지 않습니다 |
   | Repository | `<소유자>/<저장소>` |
   | Branch | 디자이너용 작업 브랜치. `main` 은 쓰지 않습니다 |
   | File Path | `design/tokens.json` (폴더가 아니라 `.json` 파일 하나입니다) |

3. 설정에서 토큰 형식을 W3C DTCG 로 둡니다.
4. 값을 고친 뒤 Push 하면 그 브랜치에 커밋이 올라갑니다. 개발자가 `python3 tool/gen_tokens.py` 로 `tokens.g.dart` 를 같은 브랜치에 맞춰 올리고, PR 로 합칩니다.
   다른 곳에서 바뀐 값은 Pull 로 받습니다.

## 2. 모양: `lib/design/parts/`

화면 부품이 하나씩 파일로 있습니다. 화면들은 이 부품을 가져다 쓰기만 하므로, 부품 하나를 고치면 그 부품을 쓰는 모든 화면이 함께 바뀝니다.

| 파일 | 부품 |
|---|---|
| `mood_banner.dart` | 기분 고르기의 큰 배너 |
| `fill_gauge.dart` | 두드리기 화면의 차오르는 채움 |
| `character_slot.dart` | 캐릭터 자리. 상태는 idle, react, palmsTogether, finish |

캐릭터 애니메이션(Rive, Lottie)이 오면 `character_slot.dart` 안만 바꿉니다. 상태 이름을 애니메이션의 상태 이름과 맞추면 부르는 쪽은 그대로 둡니다.

## 미리보기

앱을 켜면 지금은 토큰 미리보기 화면이 나옵니다. 위의 단추로 테마를 바꿔 가며 색, 글자, 배너, 채움, 캐릭터 자리를 한 화면에서 봅니다.
화면을 하나씩 만들어 가면 이 화면은 설정 안의 개발자 메뉴로 옮깁니다.

## 지금 값의 출처

다크 테마는 앞서 만든 앱의 팔레트(짙은 바탕, 버터색 포인트 하나)를 그대로 가져왔습니다. 라이트와 핑크는 같은 구조로 만든 초안입니다. 전부 디자이너가 바꿀 자리입니다.
