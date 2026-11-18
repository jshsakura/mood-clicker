# 맥(macOS) 시작 안내

아무것도 깔리지 않은 새 맥에서 이 앱을 띄우고, 디자인을 고치고, Claude Code 로 이어서 개발하기 위한 순서입니다.
이 문서는 리눅스 환경에서 작성했으므로, **맥에서 직접 실행해 보지 못한 단계에는 `(확인 못 함)` 을 표시했습니다.**

---

## 1. 맥 준비

### 1) Homebrew 설치 (확인 못 함)
터미널을 열고 아래 명령을 붙여 넣습니다.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

설치 마지막에 `Next steps` 로 안내되는 `eval "$(/opt/homebrew/bin/brew shellenv)"` 명령이 나오면 그대로 한 번 실행합니다.

### 2) Git 과 Python 3 확인 (확인 못 함)
```bash
git --version && python3 --version
```

없다면 `brew install git python` 으로 설치합니다.

### 3) Xcode 와 명령줄 도구 설치 (확인 못 함)
1. Mac App Store 에서 **Xcode** 를 설치하고 한 번 열어 약관에 동의합니다.
2. 터미널에서 명령줄 도구 경로를 연결하고 첫 실행 설정을 마칩니다.

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -runFirstLaunch
```

### 4) CocoaPods 설치 (확인 못 함)
iOS 빌드에 필요합니다.

```bash
brew install cocoapods
```

### 5) Android Studio 설치 (확인 못 함)
Android SDK 와 에뮬레이터를 위해 설치합니다.

```bash
brew install --cask android-studio
```

설치 뒤 Android Studio 를 열어 첫 설정 마법사(Standard)를 끝내면 Android SDK 와 Platform-Tools 가 함께 깔립니다.

### 6) Flutter `3.44.0` 설치 (추천: `fvm`, 확인 못 함)
공식 zip 압축 해제 방식과 `fvm` 중 **`fvm` 을 추천**합니다. 이 저장소는 `.github/workflows/ci.yml` 과 도구가 Flutter `3.44.0` 에 맞춰져 있어, 나중에 다른 프로젝트를 받아도 버전이 섞이지 않게 `3.44.0` 을 고정하기 쉽기 때문입니다.

```bash
brew tap leoafarias/fvm && brew install fvm && fvm install 3.44.0 && fvm global 3.44.0
```

`~/.zshrc` 에 `~/.fvm_default/bin` 경로가 빠졌다는 안내가 나오면 안내대로 추가한 뒤 터미널을 다시 엽니다.

### 7) Docker Desktop 필요 여부
**맥에서는 Docker Desktop 을 깔지 않아도 됩니다.**
`tool/fl` 은 로컬에 Flutter `3.44.0` 이 있으면 도커 대신 로컬 `flutter` 를 쓰도록 동작하므로, 위 단계대로 로컬 Flutter `3.44.0` 을 깔아 두면 됩니다.
다만 화면 그림 비교(`tool/shots.sh`)는 골든이 리눅스 도커 이미지로 만들어져 있어 맥에서도 도커를 씁니다. 골든을 맥에서 볼 일이 없으면 Docker Desktop 은 필요 없습니다.

### 8) Android 라이선스 동의 및 상태 점검 (확인 못 함)
```bash
flutter doctor --android-licenses
```

질문이 나오면 `y` 를 입력합니다. 이어서 상태를 확인합니다.

```bash
flutter doctor
```

---

## 2. 저장소 받기와 앱 띄우기

### 9) 저장소 클론
```bash
git clone <저장소 주소> mood-clicker && cd mood-clicker
```

### 10) 저장소 초기 설정
git 훅(`.githooks`)을 켜고 패키지를 받습니다. 끝나면 `Ready. Hooks: .githooks` 가 나옵니다.

```bash
tool/setup.sh
```

### 11) 전체 테스트 실행
맥에서 로컬 Flutter 로 처음 돌릴 때는 골든(화면 그림 비교)을 뺍니다. 골든은 리눅스 도커 이미지 기준이라 맥에서는 같은 화면도 픽셀이 달라 실패합니다.

```bash
python3 -m unittest discover -s tool -p 'test_*.py' && python3 tool/cheers_check.py && tool/fl test --exclude-tags golden
```

전부 통과하면 됩니다. 도커가 있는 컴퓨터(리눅스나 CI)에서는 골든까지 한 번에 `tool/test.sh` 로 돌립니다.

### 12) iOS 시뮬레이터로 앱 띄우기 (확인 못 함)
시뮬레이터를 먼저 연 뒤 실행합니다.

```bash
open -a Simulator
```

```bash
tool/fl run
```

### 13) Android 에뮬레이터로 앱 띄우기 (확인 못 함)
Android Studio 의 **Device Manager** 에서 가상 기기(에뮬레이터)를 하나 실행한 뒤 아래 명령을 돌립니다.

```bash
tool/fl run
```

### 14) 실기기에서 앱 띄우기 (확인 못 함)
- **아이폰 (무료 Apple ID 7일 서명)**:
  1. `open ios/Runner.xcworkspace` 로 Xcode 를 엽니다.
  2. 왼쪽 `Runner > Signing & Capabilities` 에서 **Team** 에 본인 무료 Apple ID 계정을 고르고, **Bundle Identifier** 가 겹치지 않게 고유 이름으로 바꿉니다.
  3. 아이폰을 USB 로 연결하고 잠금을 푼 뒤 `tool/fl run` 으로 올립니다.
  4. 아이폰에서 `설정 > 일반 > VPN 및 기기 관리` 로 들어가 개발자 앱을 **신뢰**합니다. (무료 계정은 서명이 7일마다 만료되므로 7일 뒤 한 번 더 실행하면 됩니다.)
- **안드로이드 (USB 디버깅)**:
  1. 폰의 `설정 > 휴대전화 정보 > 소프트웨어 정보` 에서 **빌드 번호**를 7번 눌러 개발자 옵션을 켭니다.
  2. `설정 > 개발자 옵션 > USB 디버깅` 을 켜고 USB 로 연결한 뒤 `tool/fl run` 을 실행합니다.

---

## 3. 디자인 고치기

색, 간격, 둥글기, 글자, 움직임 시간과 Figma Tokens Studio(무료판 포함) 동기화 흐름은 [docs/DESIGN.md](DESIGN.md) 에 정리되어 있습니다.

### 15) 토큰 수정 뒤 Dart 파일 다시 만들기
`design/tokens/*.json` 을 고친 뒤 생성기를 돌립니다.

```bash
python3 tool/gen_tokens.py
```

### 16) 대비 검사·테스트·분석 확인
글자와 바탕 대비가 기준(4.5) 아래로 떨어지거나 형식이 틀리면 이 단계에서 막아 줍니다.

```bash
tool/fl test --exclude-tags golden && tool/fl analyze
```

### 17) 화면 확인 (확인 못 함)
`tool/fl run` 으로 앱을 띄운 상태에서 화면을 보고, 수정 후에는 실행 창에서 `R` 을 눌러 다시 불러옵니다.

---

## 4. Claude Code 로 이어서 개발하기

### 18) Claude Code 설치 (확인 못 함)
공식 안내대로 Claude Code CLI 를 설치한 뒤 저장소 폴더에서 실행합니다.

```bash
claude
```

### 19) `.claude/settings.json` 플러그인 안내 (확인 못 함)
저장소를 처음 열면 `.claude/settings.json` 에 적힌 `pstack@pstack-claude` 와 `eli5@claude-community` 플러그인을 설치할지 묻는 안내가 뜹니다. 수락하면 리뷰·정리용 플러그인이 함께 켜집니다.

### 20) 이 저장소의 훅, 스킬, 규칙
- **git 훅 (`.githooks/`)**: `commit-msg`, `pre-commit`, `pre-push` 가 커밋 메시지 형식(`<type>: <설명>`), 개인정보(`privacy_scan.py`), AI 티·새 코드 내 한글(`slop_scan.py`), 토큰 스냅샷(`check_snapshot.sh`), 다트 형식·분석을 자동으로 검사합니다. `--no-verify` 로 건너뛰지 않습니다.
- **저장소 스킬**: 검증용 `verify`, 디자인 변경용 `change-design` 스킬이 제공됩니다.
- **개발 규칙 ([AGENTS.md](../AGENTS.md))**: 코드와 주석은 영어로 쓰고(한글은 문서·번역·토큰 데이터에만), `main` 에 바로 push 하지 않고 브랜치를 만들어 PR 로 합칩니다.

---

## 5. GitHub 관리와 배포

### 21) 저장소 소유권 이전 또는 새 저장소로 옮기기
- **소유권 이전**: 기존 소유자가 GitHub 저장소 `Settings > Danger Zone > Transfer ownership` 으로 넘겨주면 이력을 그대로 이어받습니다.
- **새 저장소로 옮기기**: 본인 계정에 새 비공개 저장소를 만든 뒤 아래 명령으로 올립니다.

```bash
git remote set-url origin <새 저장소 주소> && git push -u origin main
```

### 22) GitHub Actions 에서 Android APK 받기
터미널 없이 폰에 깔려면 GitHub 웹 저장소의 **Actions** 탭에서 최신 워크플로 실행을 열고, 아래쪽 **Artifacts** 에서 APK(`.zip` 해제 후 `.apk`)를 폰으로 내려받아 설치합니다.

### 23) iOS TestFlight 배포 준비
무료 Apple ID 는 내 폰에 USB 로 7일간 올릴 때만 쓸 수 있습니다. 다른 사람에게 TestFlight 로 배포하려면 **Apple Developer Program 유료 계정(연 99달러)** 과 **App Store Connect API 키(`.p8`)** 가 필요합니다. 자세한 절차는 `docs/RESEARCH.md` 6절과 11절을 참고합니다.

---

## 6. 자주 나오는 문제 해결 5가지

1. **`pod install` 또는 CocoaPods 오류 (확인 못 함)**
   - 증상: `tool/fl run` 시 iOS 빌드에서 CocoaPods 관련 오류가 납니다.
   - 해결: `cd ios && pod repo update && pod install && cd ..` 를 실행합니다.
2. **Xcode 코드 서명 실패 또는 7일 만료 (확인 못 함)**
   - 증상: `No signing certificate` 나 `Provisioning profile` 오류가 뜹니다.
   - 해결: `open ios/Runner.xcworkspace` 로 열어 **Team** 에 Apple ID 가 선택되어 있는지 확인하고, Bundle Identifier 를 고유한 이름으로 바꾼 뒤 다시 실행합니다.
3. **`Android license status unknown` (확인 못 함)**
   - 증상: `flutter doctor` 나 Android 빌드에서 라이선스 미동의 오류가 납니다.
   - 해결: `flutter doctor --android-licenses` 를 실행해 모두 `y` 로 동의합니다.
4. **커밋 시 `pre-commit` 에서 토큰 불일치나 다트 형식으로 막힘**
   - 증상: `tokens.g.dart` 불일치 또는 `dart format` 실패 메시지가 나옵니다.
   - 해결: `python3 tool/gen_tokens.py` 또는 `tool/format.sh` 를 돌린 뒤 수정된 파일을 다시 `git add` 하고 커밋합니다.
5. **커밋 시 `commit-msg`, `privacy_scan`, `slop_scan` 에 막힘**
   - 증상: 커밋 메시지 형식 오류, 개인정보 감지, 새 `.dart` 코드의 한글·엠대시·`print` 감지로 차단됩니다.
   - 해결: 커밋 첫 줄을 `feat: ...`, `docs: ...` 형식으로 맞추고, 코드의 한글·`print`·실제 이메일/IP 를 제거한 뒤 다시 커밋합니다.
