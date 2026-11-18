---
name: l10n-add
description: Use when adding or updating UI copy keys in lib/l10n/*.arb and regenerating localization code.
---

# 화면 문구 키 추가

기준 문서: [docs/I18N.md](../../../docs/I18N.md), [AGENTS.md](../../../AGENTS.md).

## 순서

1. 템플릿 `lib/l10n/app_ko.arb` 에 키(`화면_요소`)와 `@키` description 을 추가합니다. 한국어 UI 문구는 합니다체로 씁니다.
2. `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb` 에 같은 키와 `{자리표시자}` 를 맞춥니다(복수형·날짜 형식은 `docs/I18N.md` 참고).
3. 코드 생성을 실행해 `lib/l10n/app_localizations*.g.dart` 를 갱신합니다.
   ```bash
   tool/fl gen-l10n
   ```
4. 검사를 실행해 키 일치, 혼입, 컴파일을 확인합니다.
   ```bash
   python3 tool/l10n_check.py
   tool/fl analyze
   ```
