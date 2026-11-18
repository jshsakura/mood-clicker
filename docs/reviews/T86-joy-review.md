# T86 행복해요·설레요 응원 문구 검수

`feat/cheers-joy`의 `13c2d12`를 기준으로 검수했습니다. 아래 수정은 표기된 기본 ID의 표시 변형에도 적용합니다.

## 릴리스 전 우선 수정

1. **HIGH** 설레요의 가속·고함 지시를 바꿉니다. [ko · high · `excited_h296`](../../assets/cheers/ko.json#L22273) `더 크게 질러!`, [en · high · `excited_h223`](../../assets/cheers/en.json#L20447) `Faster! Faster!`, [ja · high · `excited_h294`](../../assets/cheers/ja.json#L22277) `もっと大きく叫べ！`.
2. **HIGH** 심박 수치와 심장 이상을 단정하거나 축하하는 표현을 바꿉니다. [en · high · `excited_h256`](../../assets/cheers/en.json#L20967) `Pulse at 200!`, [ko · complete · `excited_c541`](../../assets/cheers/ko.json#L29973) `심장 멎을 피날레!`, [ja · full · `excited_f523`](../../assets/cheers/ja.json#L27223) `心拍数最高値だ！`.
3. **HIGH** 두 기분의 순위·채점·행복 유지 명령을 바꿉니다. [ko · rare · `excited_r576`](../../assets/cheers/ko.json#L31559) `상위 1% 해금!`, [ja · rare · `excited_r584`](../../assets/cheers/ja.json#L31515) `上位1%解放だ！`, [ko · rare · `happy_r8036`](../../assets/cheers/ko.json#L15995) `누구보다 빛난 미소`, [en · low · `happy_l095`](../../assets/cheers/en.json#L1511) `Keep smiling!`.
4. **MEDIUM** 일본어 어간 잘림과 다른 언어의 잘림을 복원합니다. [ja · high · `happy_h8004`](../../assets/cheers/ja.json#L8217) `好きなメロディ口ずさ`, [ja · full · `excited_f8122`](../../assets/cheers/ja.json#L29527) `明日がもう待ち遠し`, [ko · full · `excited_f8067`](../../assets/cheers/ko.json#L28659) `무엇이든 배울 수 있`, [en · complete · `excited_c8009`](../../assets/cheers/en.json#L27680) `Eager for tomorrow's`.
5. **MEDIUM** 느낌표·이모지 기준을 문서와 검사기에서 일치시키고, 저장 성공처럼 보이는 말과 `+1` 점수 표기를 걷어냅니다.

## HIGH

### 1. 설렘을 느끼는 사람에게 더 빠르고 더 큰 행동을 시킵니다

설레요를 고르고 몇 번 두드리거나 게이지가 중간을 넘으면 다음 문구가 표시 후보가 됩니다. 사용자가 설렘만 기록하려 해도 앱이 두드림의 속도나 흥분을 더 올리라고 지시합니다. 대중교통처럼 소리를 내기 어려운 곳에도 같은 문구가 뜰 수 있습니다.

- 한국어에서 [ko · high · `excited_h266`](../../assets/cheers/ko.json#L21793) `소리 질러!!`, [ko · high · `excited_h296`](../../assets/cheers/ko.json#L22273) `더 크게 질러!`, [ko · high · `excited_h283`](../../assets/cheers/ko.json#L22065) `전력 질주!!`.
- 영어에서 [en · low · `excited_l072`](../../assets/cheers/en.json#L16109) `Faster now!`, [en · high · `excited_h203`](../../assets/cheers/en.json#L20127) `Scream it out!!`, [en · high · `excited_h223`](../../assets/cheers/en.json#L20447) `Faster! Faster!`, [en · high · `excited_h225`](../../assets/cheers/en.json#L20479) `Louder! Louder!`.
- 일본어에서 [ja · low · `excited_l021`](../../assets/cheers/ja.json#L16739) `アクセル踏もう！`, [ja · high · `excited_h294`](../../assets/cheers/ja.json#L22277) `もっと大きく叫べ！`, [ja · high · `excited_h342`](../../assets/cheers/ja.json#L23045) `叫び声上げろ！`, [ja · high · `excited_h335`](../../assets/cheers/ja.json#L22933) `最高潮へ駆けろ！`.

속도 요구와 고함을 빼고 기대를 알아차리거나 지금의 기분을 음미할 장면을 넣습니다. 영어의 `Faster now`, 한국어의 `더 크게 질러`, 일본어의 `もっと大きく叫べ`처럼 단독으로 명령이 되는 변형도 확인합니다. [기분별 근거](../EVIDENCE.md#L157-L158)

### 2. 게이지 단계를 심박수나 이상 증상으로 바꿉니다

사용자가 기분을 선택해 두드리는 동안 앱이 아는 것은 게이지 채움입니다. 다음 문구는 심박수를 재거나 몸을 관찰한 것처럼 들리고, 두근거림을 알아차리는 정도를 넘어 이상 증상까지 피날레로 표현합니다.

- [en · low · `excited_l060`](../../assets/cheers/en.json#L15917) `Pulse rising!`, [en · high · `excited_h256`](../../assets/cheers/en.json#L20967) `Pulse at 200!`, [en · high · `excited_h370`](../../assets/cheers/en.json#L22776) `Heart beating fast!`. 특히 숫자 200은 앱이 측정한 수치처럼 보입니다.
- [ko · full · `excited_f515`](../../assets/cheers/ko.json#L27235) `심장 박동 최고치!`, [ko · complete · `excited_c541`](../../assets/cheers/ko.json#L29973) `심장 멎을 피날레!`, [ja · full · `excited_f523`](../../assets/cheers/ja.json#L27223) `心拍数最高値だ！`. 심장 박동의 최고치와 심장이 멎는 상황까지 축하 표현으로 씁니다.

맥박, 최고 기록, 심장 이상 대신 사용자가 선택한 설렘을 말합니다. 감정 표현인 두근거림을 남길 때는 실제 몸 상태를 판정하는 문장을 피합니다. [단계 결정](../../lib/domain/cheer.dart#L37-L41) · [신체 단정 규칙](../LESSONS.md#L29-L34)

### 3. 기분을 순위·점수로 매기고 행복을 계속하라고 요구합니다

- 설레요에서 무작위 문구가 뽑히면 [ko · rare · `excited_r576`](../../assets/cheers/ko.json#L31559) `상위 1% 해금!`, [ja · rare · `excited_r584`](../../assets/cheers/ja.json#L31515) `上位1%解放だ！`가 상위 1%라고 말합니다. 행복해요의 [ko · rare · `happy_r8036`](../../assets/cheers/ko.json#L15995) `누구보다 빛난 미소`, [ja · rare · `happy_r8036`](../../assets/cheers/ja.json#L15999) `誰よりも輝く笑顔だ`도 다른 사람을 제치고 빛났다고 합니다. 순위와 상대를 없애고 사용자가 좋게 느낀 장면을 씁니다. [비교 원칙](../PRINCIPLES.md#L10) · [무작위 선택](../../lib/domain/cheer_picker.dart#L115-L124)
- 기분이 차오르면 [ko · high · `happy_h374`](../../assets/cheers/ko.json#L7737) `기분 100점!`, [ja · high · `happy_h323`](../../assets/cheers/ja.json#L7097) `気分百点満点！`, [en · full · `happy_f499`](../../assets/cheers/en.json#L10215) `Joy level: max!`, [en · high · `excited_h296`](../../assets/cheers/en.json#L21607) `Gold medal pace!`이 만점이나 메달 언어를 씁니다. [ko · rare · `happy_r528`](../../assets/cheers/ko.json#L15323) `최고 등급 해금!`, [ja · rare · `happy_r517`](../../assets/cheers/ja.json#L15327) `最高ランク解放！`은 등급 해금을 알립니다. 게이지 채움을 기분의 품질이나 사용자의 성과로 읽게 하는 동사를 고칩니다.
- 행복해요를 고른 직후 [en · low · `happy_l095`](../../assets/cheers/en.json#L1511) `Keep smiling!`가 계속 웃으라고 하고, [en · high · `happy_h316`](../../assets/cheers/en.json#L6505) `Best vibes only!`는 좋은 기분만 허용하는 듯합니다. [en · full · `happy_f8002`](../../assets/cheers/en.json#L10932) `Keep today's glow`와 [ko · full · `happy_f8006`](../../assets/cheers/ko.json#L11531) `작은 기쁨 크게 느껴`는 기분을 유지하거나 더 크게 느끼라고 합니다. 좋아하는 부분에 잠깐 주의를 두거나 기분이 바뀌어도 괜찮은 말로 바꿉니다. [기쁨을 음미하는 문구](../EVIDENCE.md#L157)

## MEDIUM

### 4. 표시 변형도 잘린 말을 그대로 반복합니다

기분·단계에 맞는 기본 ID가 뽑히면 어간만 남았거나 목적어 없이 끊긴 문구가 그대로 표시됩니다. 다음은 실제 JSON에서 확인한 예입니다. 일본어의 비격식 권유형이나 명사구는 문맥상 자립하는 경우 유지할 수 있습니다.

- 일본어 행복해요 `high`. [ja · high · `happy_h8004`](../../assets/cheers/ja.json#L8217) `好きなメロディ口ずさ`의 `口ずさ`, [ja · high · `happy_h8064`](../../assets/cheers/ja.json#L9177) `今日の日付覚えてお`의 `覚えてお`, [ja · high · `happy_h8072`](../../assets/cheers/ja.json#L9305) `今日の献立自分で決`의 `決`에서 끝납니다. `full`에도 [ja · full · `happy_f8002`](../../assets/cheers/ja.json#L11467) `今日の気分覚えてお`가 있습니다.
- 일본어 설레요 `low`·`high`. [ja · low · `excited_l8059`](../../assets/cheers/ja.json#L21539) `準備するのも楽し`, [ja · high · `excited_h8047`](../../assets/cheers/ja.json#L26117) `ときめき先頭に立`, [ja · high · `excited_h8051`](../../assets/cheers/ja.json#L26181) `結果より過程楽し`, [ja · high · `excited_h8072`](../../assets/cheers/ja.json#L26517) `周りまで明るくな`. 특히 `立`, `明るくな`에서 멈춘 문장은 다음 글자가 있어야 자연스럽게 읽힙니다.
- 일본어 설레요 `full`·`complete`. [ja · full · `excited_f8122`](../../assets/cheers/ja.json#L29527) `明日がもう待ち遠し`, [ja · complete · `excited_c8001`](../../assets/cheers/ja.json#L30281) `今日の高揚よく楽し`. `待ち遠し`와 `楽し`를 그대로 두고 물결표·이모지만 바꾼 변형도 있습니다. **문법 판단이 필요한 후보** [ja · complete · `happy_c8033`](../../assets/cheers/ja.json#L14525) `好きな曲聴きながら`, [ja · high · `excited_h8062`](../../assets/cheers/ja.json#L26357) `普段と違う選択を`는 각각 `ながら`, 목적격 `を`로 끝납니다. 문장이 단독으로 나오는 화면에서 뒷절을 기대하게 합니다.
- 한국어에서도 [ko · full · `happy_f8118`](../../assets/cheers/ko.json#L13323) `기쁨을 누릴 자격 있`, [ko · full · `excited_f8056`](../../assets/cheers/ko.json#L28483) `기분 좋은 땀방울 같`, [ko · full · `excited_f8067`](../../assets/cheers/ko.json#L28659) `무엇이든 배울 수 있`처럼 `있`, `같`에서 끝납니다. 영어의 [en · complete · `excited_c8009`](../../assets/cheers/en.json#L27680) `Eager for tomorrow's`는 소유격으로 끝나며, [en · rare · `excited_r8009`](../../assets/cheers/en.json#L28935) `Day where laugh beat`는 빠진 말이 있어 무엇이 웃음을 이겼다는 뜻인지 알기 어렵습니다.

변형을 만들기 전에 자립하는 기본 문장으로 다시 쓰고, 맞춤법상 어미뿐 아니라 목적어와 부정까지 남았는지 확인합니다. 잘림이 생긴 작성 방식은 확인하지 못했습니다. [어미와 부정 규칙](../LESSONS.md#L25-L29)

### 5. 느낌표와 이모지 상한이 근거 문서와 검사기에서 달라집니다

근거 문서의 표는 두 기분에 느낌표 하나, 기분별 허용 목록에서 이모지 하나, 느낌표와 이모지 동시 사용 금지를 둡니다. 실제 설정은 두 느낌표를 허용하고 이모지 허용 목록을 적용하지 않습니다. 기존 작성 안내는 검사기 값을 따르도록 되어 있습니다. 예를 들어 [ko · low · `happy_l001`](../../assets/cheers/ko.json#L7) `기분 좋다`의 변형 `기분 좋다!!`와 `기분 좋다 🌼`, [ja · low · `excited_l001`](../../assets/cheers/ja.json#L16419) `ドキドキ！`의 변형 `ドキドキ！ ⚡`가 모두 검사기를 통과합니다. [근거 문서](../EVIDENCE.md#L170-L171) · [행복해요 설정](../../tool/cheers_rules.json#L81-L85) · [설레요 설정](../../tool/cheers_rules.json#L114-L118) · [작성 안내](../../.claude/skills/cheers-write/SKILL.md#L8-L12)

아래 수는 저장소 검사기의 이모지 인식 방법을 적용해, 느낌표 초과·동시 사용·목록 밖 이모지·이모지 두 개 이상 중 하나에 해당하는 표시 문구를 중복 없이 센 값입니다. `3bca247`에서 같은 언어와 기분에 해당 문자열이 없으면 신규로 셌습니다. 현재 기준을 정한 뒤 검사기와 근거 문서를 맞추고, 근거 문서의 표를 유지한다면 위반하는 변형을 함께 수정합니다.

| 언어 | 행복해요 위반 / 표시 수 | 그중 신규 | 설레요 위반 / 표시 수 | 그중 신규 |
|---|---:|---:|---:|---:|
| ko | 1,590 / 4,099 | 980 | 1,498 / 4,091 | 860 |
| en | 1,247 / 3,740 | 510 | 1,235 / 3,638 | 526 |
| ja | 1,587 / 4,100 | 1,004 | 1,528 / 4,080 | 840 |
| 합계 | 4,424 / 11,939 | 2,494 | 4,261 / 11,809 | 2,226 |

### 6. 같은 두드림 상황에서 카메라·외부 행동·저장 성공을 암시합니다

- 두드리는 중 [ko · high · `excited_h8011`](../../assets/cheers/ko.json#L25361) `설렘을 사진으로 남겨`, [en · high · `excited_h8008`](../../assets/cheers/en.json#L23804) `Snap a bright photo`, [ja · low · `excited_l068`](../../assets/cheers/ja.json#L17491) `靴ひも結んで！`, [en · high · `excited_h381`](../../assets/cheers/en.json#L22952) `Stomp your feet!`이 뽑히면 사진을 찍거나 신발 끈을 묶거나 발을 구르는 과제가 됩니다. [en · high · `happy_h8027`](../../assets/cheers/en.json#L9293) `Open window wide`도 지금 창문을 열 수 있는 곳을 전제합니다. 사진이나 창가를 장면으로 떠올리게 쓸 수 있고, 해당 행동을 곧장 요구하는 동사는 바꿉니다. [휴대폰 맥락 규칙](../LESSONS.md#L35)
- [ko · full · `happy_f454`](../../assets/cheers/ko.json#L11099) `행복 저장 완료!`, [en · full · `happy_f477`](../../assets/cheers/en.json#L9875) `Saved this moment!`, [ja · complete · `excited_c8003`](../../assets/cheers/ja.json#L30313) `楽しい記憶保存完了`처럼 저장을 완료했다고 말합니다. 게이지를 채우고 문구를 띄우는 경로는 디스크 쓰기 결과를 기다리지 않습니다. `rare`의 [ko · rare · `happy_r8030`](../../assets/cheers/ko.json#L15899) `오늘의 햇살 저장 완료`은 게이지를 처음 채우기 전도 표시될 수 있습니다. 앱으로 한 일과 기억의 비유가 섞이지 않도록 성공 문구를 바꿉니다. [두드림 처리](../../lib/screens/tap/tap_screen.dart#L269-L287) · [저장 처리](../../lib/app/journal_store.dart#L101-L118)
- `+1`이 들어간 표시 변형이 두 기분에 총 314개 있습니다(ko 110, en 89, ja 115). 예를 들어 [ko · low · `happy_l012`](../../assets/cheers/ko.json#L183) `행복해`의 `행복해 +1`, [en · full · `happy_f499`](../../assets/cheers/en.json#L10215) `Joy level: max!`의 `Joy level: max! +1`, [ja · low · `excited_l021`](../../assets/cheers/ja.json#L16739) `アクセル踏もう！`의 `アクセル踏もう！ +1`은 별도 점수가 올라가는 피드백처럼 보입니다. 변형이 필요하면 말투를 바꾸고 끝에 점수를 붙이는 방식을 걷어냅니다.

### 7. 기분을 바꿔도 같은 의미의 문구가 나옵니다

다음은 원문을 나란히 읽어 확인한 사례입니다. 따뜻한 차나 한숨 돌리기처럼 다른 기분에서도 유효한 장면은 쓸 수 있습니다. 설레요의 기대나 호기심, 행복해요에서 지금 좋게 느껴지는 구체적인 부분을 붙이면 각 기분의 문구가 달라집니다. [기분별 예시](../EVIDENCE.md#L157-L158)

| 언어 | 실제로 뜻이 겹치는 문구 | 고칠 방향 |
|---|---|---|
| ko | [ko · rare · `happy_r8029`](../../assets/cheers/ko.json#L15883) `기분 좋은 바람이 불어` / [ko · low · `excited_l8066`](../../assets/cheers/ko.json#L21679) `기분 좋은 바람 불어`. [ko · high · `happy_h8026`](../../assets/cheers/ko.json#L8569) `마음이 활짝 열렸어` / [ko · high · `excited_h8091`](../../assets/cheers/ko.json#L26641) `마음이 활짝 열렸네`. | 조사와 어미의 차이만 남습니다. 설레요 쪽에 기대되는 대상이나 장면을 넣습니다. |
| ko | [ko · low · `happy_l8085`](../../assets/cheers/ko.json#L4951) `따뜻한 차 한 잔` / [ko · high · `anxious_h167`](../../assets/cheers/ko.json#L36978) `따뜻한 차 한 잔 해`. [ko · low · `excited_l147`](../../assets/cheers/ko.json#L18751) `몸이 반응하네!` / [ko · low · `anxious_l014`](../../assets/cheers/ko.json#L34936) `몸이 먼저 반응하네`. | 차의 감각은 기쁨을 음미하는 쪽으로 살립니다. 몸이 반응했다고 판정하는 설렘 문구는 기대를 나타내는 말로 바꿉니다. |
| en | [en · high · `happy_h385`](../../assets/cheers/en.json#L7609) `Great vibes today!` / [en · low · `excited_l8106`](../../assets/cheers/en.json#L19477) `Great vibe today`. [en · high · `happy_h360`](../../assets/cheers/en.json#L7209) `So thrilled!` / [en · high · `excited_h341`](../../assets/cheers/en.json#L22327) `So thrilled now!`. | 복수형과 `now` 차이만 생깁니다. `thrilled`를 두 기분에서 같은 방식으로 쓰는 묶음을 나눕니다. |
| en | [en · high · `excited_h214`](../../assets/cheers/en.json#L20303) `Heart pounding!` / [en · low · `#66`](../../assets/cheers/en.json#L29595) `Heart is pounding`. [en · complete · `excited_c8065`](../../assets/cheers/en.json#L28396) `Rest well tonight` / [en · complete · `#20`](../../assets/cheers/en.json#L31441) `Rest early tonight`. | 심장이 뛴다는 말은 두 감정에서 똑같이 읽힙니다. 쉬자는 말은 설렘이 남긴 여운을 넣어서 구별합니다. |
| ja | [ja · full · `happy_f416`](../../assets/cheers/ja.json#L10667) `笑顔あふれるよ！` / [ja · low · `excited_l257`](../../assets/cheers/ja.json#L20515) `笑顔あふれる！`. [ja · high · `happy_h305`](../../assets/cheers/ja.json#L6809) `心が踊ってる` / [ja · full · `excited_f8008`](../../assets/cheers/ja.json#L27703) `心が踊っているよ`. | 웃음이 넘친다는 말과 마음이 춤춘다는 말이 중복됩니다. |
| ja | [ja · high · `excited_h8039`](../../assets/cheers/ja.json#L25989) `冷たい水一口飲も` / [ja · high · `#73`](../../assets/cheers/ja.json#L33159) `冷たい水一口飲もう` / [ja · full · `anxious_f036`](../../assets/cheers/ja.json#L37692) `冷たい水一口でも`. [ja · complete · `excited_c8023`](../../assets/cheers/ja.json#L30633) `温かいお茶でひと息` / [ja · full · `#84`](../../assets/cheers/ja.json#L34521) `温かいお茶でひと息つこう`. | 세 기분의 찬물 한 모금, 두 기분의 따뜻한 차가 같은 역할을 합니다. 설렘에서 더 오래 기억하고 싶은 장면과 연결합니다. |

## LOW

### 8. 비슷한 첫말과 같은 뜻의 문구가 단계 안에서 되풀이됩니다

기본 ID당 첫 표시 문구 하나를 세었습니다. 한국어는 띄어쓰기 기준 첫말, 영어는 대소문자를 접은 첫 글자나 첫말, 일본어는 지정 접두사로 셌습니다. 비율은 단계 내 기본 ID의 비중입니다.

| 언어·기분·단계 | 첫말 쏠림 | 사례 |
|---|---|---|
| ko 행복해요 `low` | `기분` 43/335 (12.8%) | [ko · low · `happy_l001`](../../assets/cheers/ko.json#L7) `기분 좋다`, [ko · low · `happy_l023`](../../assets/cheers/ko.json#L359) `기분 맑음`, [ko · low · `happy_l027`](../../assets/cheers/ko.json#L423) `기분 몽글몽글` |
| ko 행복해요 `high` | `기분` 29/305 (9.5%) | [ko · high · `happy_h246`](../../assets/cheers/ko.json#L5689) `기분 최고조!`, [ko · high · `happy_h340`](../../assets/cheers/ko.json#L7193) `오늘 기분 최고!`, [ko · high · `happy_h349`](../../assets/cheers/ko.json#L7337) `기분 최고치!` |
| en 행복해요 `low` | `s` 75/335 (22.4%). 그중 `So`는 10개, `Sweet`는 16개 | [en · low · `happy_l002`](../../assets/cheers/en.json#L23) `So nice!`, [en · low · `happy_l006`](../../assets/cheers/en.json#L87) `Sweet!`, [en · low · `happy_l017`](../../assets/cheers/en.json#L263) `So pleasant!` |
| en 행복해요 `high` | `Happy` 19/305 (6.2%), `So` 18/305 (5.9%) | [en · high · `happy_h297`](../../assets/cheers/en.json#L6209) `Happy heart club!`, [en · high · `happy_h360`](../../assets/cheers/en.json#L7209) `So thrilled!`, [en · high · `happy_h392`](../../assets/cheers/en.json#L7721) `Happy energy!` |
| ja 행복해요 `high` | `今日` 25/305 (8.2%), `心` 21/305 (6.9%) | [ja · high · `happy_h220`](../../assets/cheers/ja.json#L5449) `今日すごすぎ！`, [ja · high · `happy_h232`](../../assets/cheers/ja.json#L5641) `今日は私の日！`, [ja · high · `happy_h250`](../../assets/cheers/ja.json#L5929) `心がいっぱい` |
| ja 설레요 `low` | `わくわく`·`ワクワク` 17/335 (5.1%), `ドキドキ` 10/335 (3.0%) | [ja · low · `excited_l003`](../../assets/cheers/ja.json#L16451) `わくわくする！`, [ja · low · `excited_l191`](../../assets/cheers/ja.json#L19459) `ワクワク開始！`, [ja · low · `excited_l016`](../../assets/cheers/ja.json#L16659) `ドキドキしてきた` |
| ja 설레요 `high` | `楽し` 19/305 (6.2%) | [ja · high · `excited_h366`](../../assets/cheers/ja.json#L23429) `楽しさあふれる！`, [ja · high · `excited_h375`](../../assets/cheers/ja.json#L23573) `楽しすぎて最高！`, [ja · high · `excited_h398`](../../assets/cheers/ja.json#L23941) `楽しく跳ねよう！` |

첫말 수치와 함께 같은 뜻의 묶음을 고칩니다. 예를 들어 한국어 행복해요 `high`의 [ko · high · `happy_h246`](../../assets/cheers/ko.json#L5689) `기분 최고조!`와 [ko · high · `happy_h349`](../../assets/cheers/ko.json#L7337) `기분 최고치!`는 둘 다 정점에 도달했다는 말입니다. 일본어 설레요 `high`의 [ja · high · `excited_h361`](../../assets/cheers/ja.json#L23349) `テンション天まで！`와 [ja · high · `excited_h409`](../../assets/cheers/ja.json#L24117) `テンション天高く！`도 같은 의미의 하늘 비유입니다. 영어는 첫 글자보다 먼저 `smile`, `sweet`, `so`처럼 내용과 말투까지 겹치는 묶음을 다듬습니다. 좋아하는 소리, 온기, 햇빛, 기다리는 약속처럼 장면 자체를 바꾸면 시작도 달라집니다.

## 확인 범위와 재현

| 언어 | 기분 | low | high | full | complete | rare | 기본 합계 |
|---|---|---:|---:|---:|---:|---:|---:|
| ko | happy | 335 | 305 | 205 | 90 | 90 | 1,025 |
| ko | excited | 335 | 305 | 204 | 89 | 90 | 1,023 |
| en | happy | 335 | 305 | 205 | 90 | 90 | 1,025 |
| en | excited | 335 | 303 | 205 | 90 | 87 | 1,020 |
| ja | happy | 335 | 305 | 205 | 90 | 90 | 1,025 |
| ja | excited | 335 | 305 | 201 | 89 | 90 | 1,020 |

- 기본 문장 6,138개는 단계 안에서 `b`당 한 번씩 셌습니다. `b` 없는 단독 문자열도 한 개씩 셌습니다. 표시 문구 23,748개를 집계·검색했고, 위 인용과 뜻이 비슷한 쌍은 원문을 읽어 확인했습니다. 같은 단계 안의 어투와 기분 사이의 의미 반복은 대표 사례를 적었습니다.
- ko·en·ja 표시 문구의 문자를 검색했습니다. ko와 ja가 서로 섞이거나 영어에 한글·가나 문장이 섞인 사례는 확인하지 못했습니다. 고칠 때 일본어의 짧은 명사구와 잘린 동사 어간을 구분합니다.
- `python3 tool/cheers_check.py`와 `python3 tool/l10n_check.py`는 둘 다 통과했습니다. 앱에서 기분을 고른 뒤 두드려 표의 단계에서 해당 ID를 뽑으면 인용한 문자열이 표시 후보가 됩니다. 화면상 사용자 반응은 예상이며, 실기기에서 난수 선택을 반복해 확인하는 검증은 범위에 포함하지 않았습니다. [문구 표시 호출](../../lib/screens/tap/tap_screen.dart#L311-L327)
