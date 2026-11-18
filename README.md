# Unknown (가제)

`Unknown` 은 정식 이름이 정해질 때까지 쓰는 가제입니다. 패키지 이름 `mood_clicker` 와 앱 식별자(`com.example.…`)는 바꾸지 않았습니다.

오늘의 기분을 고르고 연타해서 그 기분이 얼마나 컸는지 남기는 앱의 파일럿입니다.
안드로이드, 아이폰, 맥을 Flutter 하나로 만듭니다.

- 계획: [docs/PLAN.md](docs/PLAN.md)
- 개발 규칙: [AGENTS.md](AGENTS.md)
- 일하는 방법(여러 에이전트 팀, 훅, 스킬): [docs/HARNESS.md](docs/HARNESS.md) · [English](docs/HARNESS.en.md)

## 시작

도커만 있으면 됩니다. Flutter SDK 는 도커 이미지 안에 있습니다.

```bash
tool/setup.sh     # git 훅을 켜고 패키지를 받습니다
tool/fl test
```

아이폰과 맥 빌드는 맥에서 `flutter build ios`, `flutter build macos` 로 하거나 CI 에 맡깁니다.
