---
name: cheers-write
description: Use when writing, editing, or reviewing mood cheer phrases in assets/cheers/*.json (ko, en, ja).
---

# 응원 문구 작성

기준 문서: [docs/PRINCIPLES.md](../../../docs/PRINCIPLES.md), [docs/EVIDENCE.md](../../../docs/EVIDENCE.md), [tool/cheers_rules.json](../../../tool/cheers_rules.json).

## 기분별 기준

- 모든 기분: 감정을 먼저 인정합니다. 치료·완치·비교·연속 기록 표현은 쓰지 않습니다.
- `happy`, `excited`: 글자 놀이와 이모티콘을 살리되 `tool/cheers_rules.json` 의 금지어와 느낌표 상한을 지킵니다.
- `angry`, `sad`, `anxious`: 느낌표(`!`), 이모지, 카오모지, 웃음(`ㅋㅋ`, `ㅎㅎ`, `haha`, `hehe`)을 쓰지 않습니다.
- `angry`: 분출·공격("쏟아내", "더 세게" 등) 대신 인정, 신체 이완, 느린 호흡을 씁니다.
- `sad`: "힘내", "그래도", "적어도" 대신 인정·허락·함께 있음을 둡니다.
- `anxious`: "걱정 마", "별거 아니" 대신 지금 여기 감각과 호흡을 둡니다.

## 단계

1. `assets/cheers/ko.json`, `en.json`, `ja.json` 세 언어를 같은 원칙으로 함께 작성·수정합니다(직역 금지).
2. 마지막에 검사기를 실행해 통과를 확인합니다.
   ```bash
   python3 tool/cheers_check.py
   python3 tool/l10n_check.py
   ```
