# T71 불안 응원 문구 검수

`integrate/poc 2b86f59`의 `assets/cheers/{ko,en,ja}.json`에서 불안 기본 문장 3,254개를 검수했습니다. 원본 JSON에서 각 전체 b ID로 검색할 수 있습니다.

| 언어 | low | high | full | complete | rare | 합계 |
|---|---:|---:|---:|---:|---:|---:|
| 한국어 | 357 | 317 | 215 | 92 | 91 | 1072 |
| 영어 | 345 | 322 | 219 | 91 | 91 | 1068 |
| 일본어 | 352 | 325 | 253 | 91 | 93 | 1114 |

cheers_check.py와 l10n_check.py가 통과했습니다. 감각과 호흡은 선택 가능한 제안이면 남길 수 있습니다. 위험, 증상 변화, 진단, 실시간 보호는 앱이 확인할 수 없습니다.

## 언어 간 차이

- low / ko `anxious_l086`, `anxious_l323` / en `anxious_l188`, `anxious_l293` / ja `anxious_l204`, `anxious_l211`: 한국어는 낯선 신체 감각과 실내 단정, 영어는 어색한 동사와 자막식 축약, 일본어는 조사·서술어 탈락과 동작 수량 표현이 눈에 띕니다.
- high / ko `anxious_h088`, `anxious_h097` / en `anxious_h194`, `anxious_h218` / ja `anxious_h175`, `anxious_h182`, `anxious_h221`, `anxious_h254`: 한국어는 호흡 멈춤·반만 채우기, 영어는 최악의 경우 적기와 잠금 확인, 일본어는 목소리 중계·목을 감싸는 지시·동계의 긍정 해석이 두드러집니다.
- full / ko `anxious_f010`, `anxious_f185` / en `anxious_f023`, `anxious_f205` / ja `anxious_f039`, `anxious_f253`: 세 언어 모두 게이지와 안전·신체 개선을 연결합니다. 영어는 심박, 일본어는 혈류까지 구체적으로 말합니다.
- complete / ko `anxious_c010`, `anxious_c062` / en `anxious_c009`, `anxious_c051`, `anxious_c060`, `anxious_c083` / ja `anxious_c010`, `anxious_c070`, `anxious_c081`: 영어 일부에는 선택성이 있고 한국어 c010은 건너뛸 수 있음을 분명히 합니다. 일본어 c010은 차를 마시지 않아도 된다는 말로 제안의 흐름이 끊깁니다. 세 언어의 상당수는 여전히 추가 과제입니다.
- rare / ko `anxious_r039`, `anxious_r074` / en `anxious_r018`, `anxious_r085` / ja `anxious_r032`, `anxious_r081`: 한국어·일본어는 떠나지 않고 견디기를 칭찬하고, 영어 일부는 차분함을 승리로 표현합니다. 일본어 r081은 상대를 약하다고 부릅니다.
- low / ko `anxious_l276` / en `anxious_l276` / ja `anxious_l276`: 같은 ID의 뜻은 각각 같이 있기, 문이 닫혔다는 단정, 생각이 거품처럼 사라짐입니다. 언어 간 비교 기준은 문장의 역할입니다.
- low / ko `anxious_l001`, `anxious_l086`: 한국어 불안 묶음의 해체·반말과 AGENTS.md:59의 UI 문구 합니다체가 어긋납니다. 불안 문구의 말투가 별도 기준이라면 문서에 반영할 항목입니다.

## 판정 기준

- docs/EVIDENCE.md:29,41-42,121,161,165-174, docs/PRINCIPLES.md:5-12, tool/cheers_rules.json의 공통·불안 규칙을 적용했습니다. 감정을 인정하고, 행동은 선택형으로 한 가지씩 제안하며, 효과와 상황을 보장하지 않습니다.
- 명시적인 타인 순위·비교는 발견하지 못했습니다. en rare anxious_r018과 ja rare anxious_r039는 각각 승리와 호흡 개선을 보상하는 문구로 표시했습니다.
- 우선 검토는 출시 전에 봐야 할 문장입니다. 말투·상황 후보와 같은 계열은 맥락을 재검토할 범위입니다. 같은 뜻에 가까운 사례를 따로 표시했습니다.

## 한국어 (`ko.json`)

### 단계별 대표 문구

- low / `anxious_l086`, `anxious_l087`, `anxious_l323`: '배꼽 아래가 꿈틀하네', '몸이 잔뜩 서 있네', '지금 숨 쉬는 곳은 방'은 낯선 신체 감각과 방이라는 사실을 단정합니다. 편집 우선 사례입니다.
- high / `anxious_h065`, `anxious_h112`, `anxious_h215`: 정수리를 늘리기, 바닥 '차갑기', '떠오른 걸 라벨 붙여'는 명령형이면서 한국어 조사·어휘가 부자연스럽습니다.
- full / `anxious_f010`, `anxious_f183`, `anxious_f185`: '호흡 안정 되찾았어', '문이 닫혀 있고 안전해', '지금 위험한 건 안 보여'는 앱이 확인한 사실처럼 들립니다.
- complete / `anxious_c010`, `anxious_c005`, `anxious_c062`: 선택성을 드러내는 c010과 달리, c005는 박자를 강제하고 c062는 외부 연락에 영향을 줄 수 있는 알림 끄기를 시킵니다.
- rare / `anxious_r015`, `anxious_r039`, `anxious_r074`: '내 편서 나를 기다려'와 '나한테 시간 내 줬어'에서 화자가 흔들립니다. '도망 대신 숨을 골랐어'는 떠나거나 도움을 구하는 선택을 깎아내립니다.

### 뜻이 거의 같은 문구

- low / `anxious_l294` "문은 닫혀 있고 조용해" / `anxious_l356` "문이 닫혀 있어 조용해": 문이 닫혀 조용하다는 동일 문장. 두 줄 모두 환경 단정이라 빼는 쪽.
- low / `anxious_l024` "지금 여기 발이 닿아" / `anxious_l056` "발이 바닥에 닿아 있어": 발이 바닥에 닿아 있다는 같은 관찰.
- low / `anxious_l247` "떠오른 생각은 지나가" / `anxious_l249` "생각 하나가 흘러가네" / `anxious_l252` "생각이 왔다가 가네" / `anxious_l263` "이 생각도 오고 가는 중": 떠오른 생각이 지나가는 장면의 어미 바꿔 쓰기.
- high / `anxious_h002` "어깨를 아래로 내려 봐" / `anxious_h066` "어깨 귀에서 멀어지게": 어깨를 귀에서 멀어지게 내리기.
- high / `anxious_h084` "내쉬는 숨을 더 길게" / `anxious_h091` "한 번 더 길게 내쉬어" / `anxious_h281` "숨을 길게 뱉어 봐": 날숨을 길게 내쉬기.
- high / `anxious_h160` "종이에 한 줄 적어 봐" / `anxious_h172` "메모장 한 줄만 써 봐": 종이·메모장에 한 줄 쓰기.
- full / `anxious_f011` "이 순간 안전하구나" / `anxious_f184` "지금 이 순간은 무사해" / `anxious_f193` "지금은 안전한 자리야": 현재 안전하다고 단정하는 같은 뜻. 세 줄 모두 치료하지 않는 앱의 범위를 넘습니다.
- full / `anxious_f148` "생각이 바람처럼 스쳐" / `anxious_f149` "떠오른 생각이 흘러가" / `anxious_f154` "생각 하나가 떠났어" / `anxious_f157` "생각이 왔다 가네": 생각이 스쳐 지나간다는 같은 역할.
- complete / `anxious_c008` "메모장에 한 줄 적기" / `anxious_c028` "수첩에 한 줄 써 봐" / `anxious_c073` "지금 느낌 한 줄 적기": 메모 도구만 바꾼 한 줄 쓰기.
- complete / `anxious_c054` "컵을 두 손으로 감싸" / `anxious_c087` "찻잔을 두 손에 쥐어": 양손으로 찻잔·컵을 감싸기.
- rare / `anxious_r031` "한 번 쉬어 가기로 했어" / `anxious_r049` "쉬기로 한 선택이야" / `anxious_r066` "쉬어 가 봤구나": 쉬어 가는 일을 했다는 같은 칭찬.
- rare / `anxious_r025` "천천히 해 줘서 고마워" / `anxious_r050` "서두르지 않아 줬어" / `anxious_r065` "이만큼 천천히 왔어": 느리게 진행했다는 칭찬. 화자의 시점만 다릅니다.

### 후보 전체

#### low / 우선 검토 / 4개

안전·외부 압박 부재를 확인 없이 보장합니다.

- low / `anxious_l031` `anxious_l042` `anxious_l043` `anxious_l325`
- low / `anxious_l031`: "지금 이 순간 안전해"
- low / `anxious_l042`: "지금 당장은 괜찮아"
- low / `anxious_l043`: "방은 조용하고 안전해"
- low / `anxious_l325`: "지금은 재촉하는 사람 없어"

#### low / 우선 검토 / 9개

급한 일도 미뤄도 된다는 상황 판단입니다. 긴급도와 일정은 사용자만 압니다.

- low / `anxious_l035` `anxious_l039` `anxious_l041` `anxious_l228` `anxious_l230` `anxious_l235` `anxious_l236` `anxious_l315` `anxious_l326`
- low / `anxious_l035`: "시간 아주 급하진 않아"
- low / `anxious_l039`: "늦으면 조금 늦는 거지"
- low / `anxious_l041`: "아직 안 일어난 일이야"
- low / `anxious_l228`: "오늘 몫은 여기까지여도 돼"

#### low / 우선 검토 / 13개

심장이 빨리 뜀·목 조임·숨이 멎음 등 사용자가 말하지 않은 신호를 선언합니다. 불안의 증상처럼 읽히거나 실제 문제를 놓치게 할 수 있습니다.

- low / `anxious_l015` `anxious_l058`-`anxious_l061` `anxious_l069` `anxious_l076` `anxious_l088`-`anxious_l091` `anxious_l328` `anxious_l333`
- low / `anxious_l015`: "심장이 빨리 뛰는구나"
- low / `anxious_l058`: "가슴이 조금 답답하네"
- low / `anxious_l059`: "배 속이 울렁거리네"
- low / `anxious_l060`: "손바닥이 축축해졌네"

#### low / 우선 검토 / 6개

앱이 곁에 있고 이야기를 듣거나 마음의 크기를 안다고 약속합니다. 도움받을 수 있다는 안내와 실제 듣는 사람을 구분합니다.

- low / `anxious_l273` `anxious_l277` `anxious_l281` `anxious_l292` `anxious_l338` `anxious_l354`
- low / `anxious_l273`: "곁에 있어 줄게"
- low / `anxious_l277`: "말 안 해도 곁에 있을게"
- low / `anxious_l281`: "내가 여기 같이 있어"
- low / `anxious_l292`: "네 얘기 천천히 들을게"

#### low / 말투·상황 후보 / 12개

불안의 원인·신체 의도·감정의 옳고 그름을 앱이 단정합니다. 특히 '예민해져'는 비난, '사실이야'는 생각과 사실을 합치는 말로 들릴 수 있습니다.

- low / `anxious_l010`-`anxious_l012` `anxious_l142`-`anxious_l143` `anxious_l151` `anxious_l153` `anxious_l157` `anxious_l161`-`anxious_l163` `anxious_l167`
- low / `anxious_l010`: "처음이라 더 그래"
- low / `anxious_l011`: "잘하고 싶어서 그래"
- low / `anxious_l012`: "중요한 일이라 그래"
- low / `anxious_l142`: "조금 무서운 게 맞아"

#### low / 말투·상황 후보 / 24개

방·의자·조명·시간·소리·자세가 사실이라는 전제입니다. 선택 가능한 감각 하나로 바꿉니다.

- low / `anxious_l055` `anxious_l170` `anxious_l172` `anxious_l183` `anxious_l187`-`anxious_l188` `anxious_l192` `anxious_l293`-`anxious_l295` `anxious_l299`-`anxious_l300` `anxious_l302`-`anxious_l305` `anxious_l322`-`anxious_l324` `anxious_l342` `anxious_l345` `anxious_l347` `anxious_l356`-`anxious_l357`
- low / `anxious_l055`: "지금 여기 앉아 있어"
- low / `anxious_l170`: "창밖 빛이 보이네"
- low / `anxious_l172`: "의자가 널 받치고 있어"
- low / `anxious_l183`: "냉장고 소리가 들려"

#### low / 말투·상황 후보 / 40개

가장 먼저 노출되는 단계에서 인정 없이 몸·호흡·시선·행동을 지시합니다. 갈아 끼울 문구는 힘들 때 생략할 수 있는 짧은 제안으로.

- low / `anxious_l027` `anxious_l053`-`anxious_l054` `anxious_l099` `anxious_l110` `anxious_l115` `anxious_l175` `anxious_l179`-`anxious_l182` `anxious_l184`-`anxious_l186` `anxious_l193` `anxious_l196` `anxious_l200`-`anxious_l201` `anxious_l204` `anxious_l208` `anxious_l212` `anxious_l214`-`anxious_l216` `anxious_l218`-`anxious_l221` `anxious_l223` `anxious_l307`-`anxious_l308` `anxious_l320`-`anxious_l321` `anxious_l334`-`anxious_l335` `anxious_l343`-`anxious_l344` `anxious_l348` `anxious_l350` `anxious_l353`
- low / `anxious_l027`: "주변 색 세 가지 찾기"
- low / `anxious_l053`: "지금 내 몸을 먼저 봐"
- low / `anxious_l054`: "숨소리에 귀 기울여 봐"
- low / `anxious_l099`: "들이쉬고 둘 셋 넷"

#### low / 자연스러움 / 25개

번역투 또는 감각·비유가 부자연스럽습니다. '배꼽 아래가 꿈틀하네', '몸이 잔뜩 서 있네', '지금 숨 쉬는 곳은 방'은 대표 사례입니다.

- low / `anxious_l057` `anxious_l070` `anxious_l086`-`anxious_l087` `anxious_l094` `anxious_l102`-`anxious_l103` `anxious_l105` `anxious_l129` `anxious_l133` `anxious_l139` `anxious_l166` `anxious_l194` `anxious_l225` `anxious_l248` `anxious_l253` `anxious_l255` `anxious_l258` `anxious_l268` `anxious_l298` `anxious_l311` `anxious_l314` `anxious_l323` `anxious_l327` `anxious_l330`
- low / `anxious_l057`: "숨은 계속 쉬어지고 있어"
- low / `anxious_l070`: "혀끝에 힘이 들어갔어"
- low / `anxious_l086`: "배꼽 아래가 꿈틀하네"
- low / `anxious_l087`: "몸이 잔뜩 서 있네"

#### low / 같은 계열 / 17개

불안·긴장이 당연하다는 인정의 의미가 겹칩니다. 핵심 문장을 남기고 수식어 교체는 같은 기본 문장으로 셉니다.

- low / `anxious_l001`-`anxious_l004` `anxious_l006`-`anxious_l009` `anxious_l146`-`anxious_l149` `anxious_l154`-`anxious_l156` `anxious_l310` `anxious_l341`
- low / `anxious_l001`: "불안할 만해"
- low / `anxious_l002`: "긴장될 만한 상황이야"
- low / `anxious_l003`: "걱정될 만해"
- low / `anxious_l004`: "마음이 조마조마하지"

#### low / 같은 계열 / 14개

속도를 늦추거나 잠시 쉬어도 된다는 허락을 반복합니다.

- low / `anxious_l034` `anxious_l052` `anxious_l224` `anxious_l226`-`anxious_l227` `anxious_l232`-`anxious_l233` `anxious_l238`-`anxious_l240` `anxious_l244`-`anxious_l246` `anxious_l351`
- low / `anxious_l034`: "잠깐 멈춰도 괜찮아"
- low / `anxious_l052`: "잠깐 쉬었다 해도 돼"
- low / `anxious_l224`: "오늘은 천천히 가도 돼"
- low / `anxious_l226`: "지금은 멈춰 있어도 돼"

#### low / 같은 계열 / 17개

생각이 왔다 가는 관찰을 구름·강물·버스·날씨 교체로 반복합니다.

- low / `anxious_l247` `anxious_l249`-`anxious_l252` `anxious_l254`-`anxious_l256` `anxious_l259`-`anxious_l263` `anxious_l269` `anxious_l271`-`anxious_l272` `anxious_l352`
- low / `anxious_l247`: "떠오른 생각은 지나가"
- low / `anxious_l249`: "생각 하나가 흘러가네"
- low / `anxious_l250`: "생각은 날씨 같아서 바뀌어"
- low / `anxious_l251`: "걱정도 파도처럼 오가"

#### low / 같은 계열 / 17개

도움을 청하거나 이야기를 나눠도 된다는 허락이 겹칩니다.

- low / `anxious_l050`-`anxious_l051` `anxious_l274`-`anxious_l278` `anxious_l283`-`anxious_l285` `anxious_l288` `anxious_l291` `anxious_l317`-`anxious_l321`
- low / `anxious_l050`: "도움 구해도 돼"
- low / `anxious_l051`: "혼자 다 안 져도 돼"
- low / `anxious_l274`: "혼자가 아니야"
- low / `anxious_l275`: "도움을 받아도 괜찮아"

#### low / 같은 계열 / 15개

발 딛기, 앉아 있어도 됨, 닫힌 문과 조용함, 한 줄 적기를 각각 반복합니다.

- low / `anxious_l024` `anxious_l030` `anxious_l056` `anxious_l174` `anxious_l306` | `anxious_l055` `anxious_l245` `anxious_l322` `anxious_l351` | `anxious_l294` `anxious_l356` | `anxious_l202` `anxious_l206` `anxious_l211` `anxious_l349`
- low / `anxious_l024`: "지금 여기 발이 닿아"
- low / `anxious_l030`: "바닥이 나를 받쳐 줘"
- low / `anxious_l056`: "발이 바닥에 닿아 있어"
- low / `anxious_l174`: "발밑 바닥이 단단해"

#### high / 우선 검토 / 4개

안전 단정, 잠금 확인 과제, 위험을 주변에서 확인하지 않도록 하는 듯한 좁은 주의 지시입니다.

- high / `anxious_h254`-`anxious_h255` `anxious_h262`-`anxious_h263`
- high / `anxious_h254`: "지금 이 방은 안전해"
- high / `anxious_h255`: "문이 잠겨 있나 봐"
- high / `anxious_h262`: "여기엔 나와 의자뿐이야"
- high / `anxious_h263`: "지금은 눈앞이 전부야"

#### high / 우선 검토 / 15개

들이쉬는 깊이·박자·숨 멈춤·반만 채우기를 무조건 지시합니다. 신체·호흡 불편을 알 수 없는 앱에서는 빼거나 부담 없는 선택지로.

- high / `anxious_h018` `anxious_h081`-`anxious_h084` `anxious_h088` `anxious_h091` `anxious_h093` `anxious_h097`-`anxious_h100` `anxious_h281`-`anxious_h283`
- high / `anxious_h018`: "배까지 숨 들이쉬기"
- high / `anxious_h081`: "넷 세며 들이쉬어 봐"
- high / `anxious_h082`: "여섯 세며 내쉬어 봐"
- high / `anxious_h083`: "코로 천천히 마셔 봐"

#### high / 말투·상황 후보 / 12개

심박·호흡·온기·근육 이완을 측정한 듯 선언하고 잘 따라오라고 합니다. 두드림 횟수는 이완의 신호가 아닙니다.

- high / `anxious_h038`-`anxious_h041` `anxious_h043` `anxious_h045`-`anxious_h049` `anxious_h087` `anxious_h096`
- high / `anxious_h038`: "호흡이 느려지고 있어"
- high / `anxious_h039`: "심장 소리 잦아들어"
- high / `anxious_h040`: "손끝에 온기 돌고 있어"
- high / `anxious_h041`: "몸이 조금씩 풀려 가"

#### high / 말투·상황 후보 / 189개

몸·주의·행동을 연달아 시키거나 검사하는 어조입니다. 선택형인 문장과 동작 없는 인정도 섞고, 생각을 '일 뿐'이라고 축소하거나 특정인에게 따라오라는 앱 인격은 빼는 방향입니다.

- high / `anxious_h001`-`anxious_h017` `anxious_h023`-`anxious_h025` `anxious_h027`-`anxious_h037` `anxious_h051`-`anxious_h080` `anxious_h105`-`anxious_h131` `anxious_h133`-`anxious_h147` `anxious_h149`-`anxious_h154` `anxious_h155`-`anxious_h173` `anxious_h176`-`anxious_h180` `anxious_h203`-`anxious_h204` `anxious_h209` `anxious_h214` `anxious_h219` `anxious_h223` `anxious_h246` `anxious_h256`-`anxious_h258` `anxious_h264`-`anxious_h275` `anxious_h277`-`anxious_h280` `anxious_h284`-`anxious_h307` `anxious_h312`-`anxious_h317`
- high / `anxious_h001`: "발바닥 바닥에 꾹 대 봐"
- high / `anxious_h002`: "어깨를 아래로 내려 봐"
- high / `anxious_h003`: "꽉 쥔 손바닥 펴 봐"
- high / `anxious_h004`: "턱을 살짝 내려 봐"

#### high / 자연스러움 / 29개

한국어 문장에 목적어·조사가 빠지거나 '정수리를 늘려', '떠오른 걸 라벨 붙여'처럼 낯선 영상·몸 지시가 남습니다.

- high / `anxious_h065`-`anxious_h066` `anxious_h072`-`anxious_h073` `anxious_h083` `anxious_h103` `anxious_h112` `anxious_h118` `anxious_h122` `anxious_h138` `anxious_h142` `anxious_h148`-`anxious_h149` `anxious_h175` `anxious_h188` `anxious_h215` `anxious_h221` `anxious_h223` `anxious_h248` `anxious_h252` `anxious_h268`-`anxious_h270` `anxious_h275` `anxious_h296`-`anxious_h298` `anxious_h309` `anxious_h317`
- high / `anxious_h065`: "정수리를 위로 늘려 봐"
- high / `anxious_h066`: "어깨 귀에서 멀어지게"
- high / `anxious_h072`: "팔꿈치 옆구리에 내려"
- high / `anxious_h073`: "엉덩이 닿은 곳 느껴"

#### high / 같은 계열 / 19개

어깨 내리기·힘 빼기·손 마찰·촉감에 주목하기를 관절이나 물건만 바꿔 반복합니다. h094/h280은 날숨과 관절 힘 빼기 양쪽에 걸립니다.

- high / `anxious_h002` `anxious_h066` `anxious_h094` `anxious_h280` | `anxious_h005` `anxious_h053` `anxious_h067` `anxious_h094` `anxious_h280` `anxious_h296` | `anxious_h007` `anxious_h063` `anxious_h291` | `anxious_h055` `anxious_h075` `anxious_h110`-`anxious_h111` `anxious_h121` `anxious_h125` `anxious_h301` `anxious_h306`
- high / `anxious_h002`: "어깨를 아래로 내려 봐"
- high / `anxious_h066`: "어깨 귀에서 멀어지게"
- high / `anxious_h094`: "내쉬며 어깨 떨어뜨려"
- high / `anxious_h280`: "날숨에 턱을 풀어 봐"

#### high / 같은 계열 / 22개

호흡 박자 세기와 날짜·장소 말하기가 각각 같은 과제입니다.

- high / `anxious_h081`-`anxious_h084` `anxious_h091`-`anxious_h092` `anxious_h098` `anxious_h102` `anxious_h281`-`anxious_h282` | `anxious_h016`-`anxious_h017` `anxious_h256`-`anxious_h258` `anxious_h265`-`anxious_h270` `anxious_h273`
- high / `anxious_h081`: "넷 세며 들이쉬어 봐"
- high / `anxious_h082`: "여섯 세며 내쉬어 봐"
- high / `anxious_h083`: "코로 천천히 마셔 봐"
- high / `anxious_h084`: "내쉬는 숨을 더 길게"

#### high / 같은 계열 / 23개

한 가지 일만 하기, 쉬기, 한 줄 메모하기를 교체 반복합니다.

- high / `anxious_h030`-`anxious_h033` `anxious_h161` `anxious_h180` `anxious_h190` `anxious_h195` `anxious_h203` `anxious_h286` `anxious_h311` | `anxious_h183`-`anxious_h186` `anxious_h192`-`anxious_h193` `anxious_h197`-`anxious_h198` `anxious_h204` | `anxious_h160` `anxious_h172` `anxious_h218`
- high / `anxious_h030`: "오늘 할 것 딱 하나만"
- high / `anxious_h031`: "딱 한 걸음만 생각해"
- high / `anxious_h032`: "지금 할 일 한 가지만"
- high / `anxious_h033`: "나머지는 종이에 적자"

#### high / 같은 계열 / 28개

생각이 지나감을 바라보기와 믿는 사람에게 연결하기가 여러 소품·어미로 반복됩니다.

- high / `anxious_h026` `anxious_h205` `anxious_h207`-`anxious_h213` `anxious_h216`-`anxious_h217` `anxious_h220` `anxious_h222` `anxious_h225`-`anxious_h228` | `anxious_h229` `anxious_h233`-`anxious_h236` `anxious_h239` `anxious_h242` `anxious_h245` `anxious_h249`-`anxious_h251`
- high / `anxious_h026`: "생각 구름처럼 보내기"
- high / `anxious_h205`: "생각이 지나가게 둬"
- high / `anxious_h207`: "구름 하나 흘려보내"
- high / `anxious_h208`: "생각은 날씨 같아"

#### full / 우선 검토 / 7개

위험이 없다고 보장하거나 실제 긴급 상황에도 서두를 이유가 없다고 선언합니다.

- full / `anxious_f011` `anxious_f028` `anxious_f140` `anxious_f183`-`anxious_f185` `anxious_f193`
- full / `anxious_f011`: "이 순간 안전하구나"
- full / `anxious_f028`: "안전한 방에서 쉬는 중"
- full / `anxious_f140`: "서두를 이유가 없어"
- full / `anxious_f183`: "문이 닫혀 있고 안전해"

#### full / 우선 검토 / 40개

게이지가 찬 사실을 호흡·신체 신호·긴급 상황이 호전됐다는 뜻으로 바꿉니다. 잦아들지 않은 사람도 그대로 있을 수 있다는 문장으로.

- full / `anxious_f002` `anxious_f004` `anxious_f009`-`anxious_f010` `anxious_f016` `anxious_f030`-`anxious_f040` `anxious_f043`-`anxious_f053` `anxious_f056`-`anxious_f057` `anxious_f060` `anxious_f063`-`anxious_f066` `anxious_f204` `anxious_f206` `anxious_f208` `anxious_f211` `anxious_f213` `anxious_f215`
- full / `anxious_f002`: "숨이 고르고 깊어졌어"
- full / `anxious_f004`: "어깨와 턱이 풀렸어"
- full / `anxious_f009`: "몸의 신호 알아차렸어"
- full / `anxious_f010`: "호흡 안정 되찾았어"

#### full / 말투·상황 후보 / 28개

이해·자기 인정이나 집단 행동을 이미 했다고 단정하고, 몇 문장은 견딘 성과나 '예민함'을 채점합니다. 앱이 곁을 지키는 약속도 피합니다.

- full / `anxious_f019`-`anxious_f020` `anxious_f023` `anxious_f075` `anxious_f090`-`anxious_f093` `anxious_f098`-`anxious_f101` `anxious_f124`-`anxious_f128` `anxious_f133` `anxious_f167` `anxious_f169` `anxious_f175` `anxious_f178` `anxious_f195`-`anxious_f199` `anxious_f203`
- full / `anxious_f019`: "지금의 나를 받아들여"
- full / `anxious_f020`: "충분히 잘 머물렀어"
- full / `anxious_f023`: "조급함 놓고 지금 봐"
- full / `anxious_f075`: "조마조마한 마음 인정해"

#### full / 말투·상황 후보 / 26개

사용자가 어디에 있고 무엇을 보거나 만지는지 단정합니다. 지금 알아차린 것이 있는지 열어 두는 문장으로.

- full / `anxious_f041` `anxious_f102`-`anxious_f117` `anxious_f181`-`anxious_f182` `anxious_f188`-`anxious_f192` `anxious_f205` `anxious_f210`
- full / `anxious_f041`: "등이 의자에 닿아 있어"
- full / `anxious_f102`: "창밖에 빛이 들어와"
- full / `anxious_f103`: "방 안에 불이 켜져 있어"
- full / `anxious_f104`: "발밑 바닥이 차가워"

#### full / 자연스러움 / 21개

격·목적어가 빠지거나 관용적이지 않은 표현입니다. '안 해도 괜찮은 여유', '지금은 이 의자 위야'처럼 어색합니다.

- full / `anxious_f003` `anxious_f007` `anxious_f021` `anxious_f024` `anxious_f037` `anxious_f043` `anxious_f048` `anxious_f058` `anxious_f068` `anxious_f076` `anxious_f080` `anxious_f110` `anxious_f120` `anxious_f138` `anxious_f155` `anxious_f171` `anxious_f176` `anxious_f182` `anxious_f188` `anxious_f202` `anxious_f209`
- full / `anxious_f003`: "발바닥 땅을 단단히"
- full / `anxious_f007`: "안 해도 괜찮은 여유"
- full / `anxious_f021`: "고요한 숨결 자리 잡아"
- full / `anxious_f024`: "부드러운 호흡 곁에"

#### full / 같은 계열 / 45개

호흡이 고르게 됨, 불안에 이름 붙이거나 옆에 두기, 불안 인정의 뜻이 각각 반복됩니다.

- full / `anxious_f002` `anxious_f010` `anxious_f021` `anxious_f024` `anxious_f049`-`anxious_f057` `anxious_f061`-`anxious_f066` | `anxious_f067`-`anxious_f084` | `anxious_f085`-`anxious_f088` `anxious_f092` `anxious_f094` `anxious_f096`-`anxious_f097`
- full / `anxious_f002`: "숨이 고르고 깊어졌어"
- full / `anxious_f010`: "호흡 안정 되찾았어"
- full / `anxious_f021`: "고요한 숨결 자리 잡아"
- full / `anxious_f024`: "부드러운 호흡 곁에"

#### full / 같은 계열 / 52개

생각이 지나가는 이미지, 쉬거나 미뤄도 된다는 허락, 도움을 청하는 선택이 반복됩니다.

- full / `anxious_f005` `anxious_f148`-`anxious_f163` | `anxious_f017`-`anxious_f018` `anxious_f123` `anxious_f131` `anxious_f134`-`anxious_f147` | `anxious_f164`-`anxious_f180`
- full / `anxious_f005`: "지나가는 생각 흘려"
- full / `anxious_f148`: "생각이 바람처럼 스쳐"
- full / `anxious_f149`: "떠오른 생각이 흘러가"
- full / `anxious_f150`: "생각은 날씨 같아서 변해"

#### complete / 우선 검토 / 13개

창문/계단/눈 주변 압박, 특정 박자의 호흡, 알림 끄기나 목적을 정하지 않은 전화 버튼과 미루기를 획일적으로 지시합니다. 몸과 환경을 전제하지 않고 생략 가능한 제안으로.

- complete / `anxious_c002` `anxious_c005` `anxious_c018` `anxious_c023` `anxious_c034` `anxious_c051` `anxious_c058`-`anxious_c059` `anxious_c062` `anxious_c065` `anxious_c077` `anxious_c079` `anxious_c084`
- complete / `anxious_c002`: "창문 열고 공기 마셔"
- complete / `anxious_c005`: "넷 들이쉬고 여섯 후"
- complete / `anxious_c018`: "코로 쉬고 입으로 후"
- complete / `anxious_c023`: "창가에 서서 하늘 봐"

#### complete / 말투·상황 후보 / 82개

'안 해도 돼'인 c010에 비해 나머지 상당수가 명령 또는 수행 목록입니다. 완료를 추가 과제로 느끼지 않게 똑같은 동작을 선택형 한 줄로 축약하고 고마움 과제도 필수처럼 만들지 않습니다.

- complete / `anxious_c001` `anxious_c003`-`anxious_c009` `anxious_c011`-`anxious_c017` `anxious_c019`-`anxious_c022` `anxious_c024`-`anxious_c033` `anxious_c035`-`anxious_c061` `anxious_c063`-`anxious_c064` `anxious_c066`-`anxious_c076` `anxious_c078` `anxious_c080`-`anxious_c091`
- complete / `anxious_c001`: "물 한 잔 천천히 마셔"
- complete / `anxious_c003`: "할 일 딱 하나만 골라"
- complete / `anxious_c004`: "손 펴고 5초 가만히"
- complete / `anxious_c005`: "넷 들이쉬고 여섯 후"

#### complete / 자연스러움 / 12개

'공기 마셔', '코로 쉬고 입으로 후', '눈을 따뜻하게 덮어'처럼 뜻이 막연하거나 일상 발화로 어색합니다.

- complete / `anxious_c002` `anxious_c008` `anxious_c018` `anxious_c020` `anxious_c034` `anxious_c053` `anxious_c060` `anxious_c070`-`anxious_c071` `anxious_c075` `anxious_c079` `anxious_c084`
- complete / `anxious_c002`: "창문 열고 공기 마셔"
- complete / `anxious_c008`: "메모장에 한 줄 적기"
- complete / `anxious_c018`: "코로 쉬고 입으로 후"
- complete / `anxious_c020`: "이 자리서 잠깐 눈 감기"

#### complete / 같은 계열 / 30개

물·차와 감각 하나, 한 줄 기록, 관절·손을 움직이는 미세 지시가 많이 반복됩니다.

- complete / `anxious_c001` `anxious_c010` `anxious_c021` `anxious_c025` `anxious_c044` `anxious_c054` `anxious_c070` `anxious_c087` | `anxious_c008` `anxious_c028`-`anxious_c029` `anxious_c072`-`anxious_c074` | `anxious_c004` `anxious_c017` `anxious_c030`-`anxious_c032` `anxious_c041`-`anxious_c043` `anxious_c051`-`anxious_c052` `anxious_c067` `anxious_c071` `anxious_c083`-`anxious_c085` `anxious_c091`
- complete / `anxious_c001`: "물 한 잔 천천히 마셔"
- complete / `anxious_c010`: "차 한 모금, 안 해도 돼"
- complete / `anxious_c021`: "컵에 물을 따라 봐"
- complete / `anxious_c025`: "따뜻한 차를 끓여 봐"

#### complete / 같은 계열 / 18개

호흡/걷기/연락의 같은 선택을 재포장합니다.

- complete / `anxious_c005`-`anxious_c007` `anxious_c013` `anxious_c018` `anxious_c035` `anxious_c058`-`anxious_c059` | `anxious_c009` `anxious_c022` `anxious_c064`-`anxious_c065` `anxious_c086` | `anxious_c039`-`anxious_c040` `anxious_c078`-`anxious_c080`
- complete / `anxious_c005`: "넷 들이쉬고 여섯 후"
- complete / `anxious_c006`: "발바닥 느끼며 쉬어"
- complete / `anxious_c007`: "어깨 내리고 길게 후"
- complete / `anxious_c013`: "두 손 모으고 숨 고르기"

#### rare / 우선 검토 / 8개

안전 확인을 보장하거나 떠나거나 도움을 찾는 대신 계속 앉아 견딘 일을 상으로 삼습니다. 머무르기·회피를 선악으로 나누지 않습니다.

- rare / `anxious_r017` `anxious_r024` `anxious_r039` `anxious_r042` `anxious_r047` `anxious_r057` `anxious_r077` `anxious_r091`
- rare / `anxious_r017`: "안전한 지금 확인했어"
- rare / `anxious_r024`: "불안을 피하지 않았어"
- rare / `anxious_r039`: "도망 대신 숨을 골랐어"
- rare / `anxious_r042`: "조용히 버텨 줬어"

#### rare / 말투·상황 후보 / 57개

호흡·자기 돌봄·몸 관찰을 이미 수행했다고 단정하거나 사용자에게 앱을 위해 숨 쉬고 시간을 냈다고 읽힙니다. 무언가를 해낸 사람만 받는 표창을 피합니다.

- rare / `anxious_r002`-`anxious_r003` `anxious_r006` `anxious_r009` `anxious_r012` `anxious_r014` `anxious_r019`-`anxious_r029` `anxious_r032`-`anxious_r036` `anxious_r040`-`anxious_r045` `anxious_r048` `anxious_r050`-`anxious_r054` `anxious_r056` `anxious_r059`-`anxious_r062` `anxious_r068`-`anxious_r079` `anxious_r082`-`anxious_r085` `anxious_r087`-`anxious_r088`
- rare / `anxious_r002`: "이 순간 지켜 낸 호흡"
- rare / `anxious_r003`: "흔들려도 나를 돌봤어"
- rare / `anxious_r006`: "내 속도 지킨 용기"
- rare / `anxious_r009`: "작은 호흡서 찾은 여유"

#### rare / 자연스러움 / 23개

'내 편서', '작은 호흡서', '나를 서두르지 않았네', '지금 곁을 지켜 줬어'는 조사나 화자 관점이 흔들립니다.

- rare / `anxious_r004` `anxious_r009`-`anxious_r010` `anxious_r015` `anxious_r019` `anxious_r026`-`anxious_r027` `anxious_r033` `anxious_r038`-`anxious_r039` `anxious_r057` `anxious_r063` `anxious_r066` `anxious_r070` `anxious_r073`-`anxious_r074` `anxious_r078`-`anxious_r079` `anxious_r082`-`anxious_r085` `anxious_r087`
- rare / `anxious_r004`: "생각서 물러난 지혜"
- rare / `anxious_r009`: "작은 호흡서 찾은 여유"
- rare / `anxious_r010`: "여기 발 디딘 작은 힘"
- rare / `anxious_r015`: "내 편서 나를 기다려"

#### rare / 같은 계열 / 29개

불안과 함께 머무름, 속도 늦춤, 쉬기로 함의 같은 칭찬이 반복됩니다.

- rare / `anxious_r001` `anxious_r030` `anxious_r044`-`anxious_r046` `anxious_r058` `anxious_r067` `anxious_r089`-`anxious_r091` | `anxious_r006` `anxious_r011` `anxious_r018` `anxious_r025`-`anxious_r026` `anxious_r037` `anxious_r050` `anxious_r065` `anxious_r068`-`anxious_r069` `anxious_r081` | `anxious_r013` `anxious_r023` `anxious_r031` `anxious_r049` `anxious_r059` `anxious_r062` `anxious_r066` `anxious_r086`
- rare / `anxious_r001`: "불안 있어도 괜찮은 나"
- rare / `anxious_r030`: "불안 옆에 앉아 줬어"
- rare / `anxious_r044`: "떨림을 그대로 뒀어"
- rare / `anxious_r045`: "말없이 곁을 지켰어"

#### rare / 같은 계열 / 23개

호흡을 돌봄과 스스로를 보살핌을 완료한 듯 반복합니다.

- rare / `anxious_r002` `anxious_r009` `anxious_r012` `anxious_r020` `anxious_r022` `anxious_r035` `anxious_r055` `anxious_r063` `anxious_r070` `anxious_r073` `anxious_r078` `anxious_r084` `anxious_r088` | `anxious_r003` `anxious_r016` `anxious_r034` `anxious_r048` `anxious_r051`-`anxious_r052` `anxious_r064` `anxious_r075`-`anxious_r076` `anxious_r085`
- rare / `anxious_r002`: "이 순간 지켜 낸 호흡"
- rare / `anxious_r009`: "작은 호흡서 찾은 여유"
- rare / `anxious_r012`: "편안한 숨 선물한 시간"
- rare / `anxious_r020`: "평온히 숨 쉰 순간"

## 영어 (`en.json`)

### 단계별 대표 문구

- low / `anxious_l093`, `anxious_l188`, `anxious_l293`: 원인을 판정하는 'This is anxiety'와 구어로 어색한 'Anyone would rattle', 'This breath is today'가 같은 단계에 섞입니다.
- high / `anxious_h194`, `anxious_h218`, `anxious_h130`, `anxious_h150`: 'Write the worst case', 'Check the lock, once'는 영어판에서 두드러지는 불안·확인 과제입니다. 'Taste your mouth'와 'Make your bed corner'는 목적이 불명확합니다.
- full / `anxious_f023`, `anxious_f201`, `anxious_f205`: 심박 판정 문구와 'Knuckles unwhite' 같은 어색한 단어 만들기가 섞입니다.
- complete / `anxious_c009`, `anxious_c051`, `anxious_c060`, `anxious_c083`: 차·연락은 선택형으로 자연스럽게 열어 둡니다. 한편 촛불 켜기, 발코니 나가기는 게임에 적절한 보편 제안이 아닙니다.
- rare / `anxious_r018`, `anxious_r027`, `anxious_r085`: 'Peaceful breath won'은 감정을 성패로 바꿉니다. 뒤 두 표현은 압축 과정에서 말맛이나 문법이 깨졌습니다.

### 뜻이 거의 같은 문구

- low / `anxious_l042` "Room is quiet now" / `anxious_l051` "Quiet room around" / `anxious_l275` "This room is quiet": 조용한 방이라는 같은 추정.
- low / `anxious_l064` "Wrists feel tight" / `anxious_l341` "Wrists feel stiff": 손목이 굳었다는 같은 신체 추정.
- low / `anxious_l229` "Worries come and go" / `anxious_l250` "Thoughts drift by" / `anxious_l254` "Thoughts rise, fade": 생각이 왔다 지나가는 같은 관찰.
- high / `anxious_h010` "Name where you are" / `anxious_h212` "Say where you are" / `anxious_h244` "Name the room": 현재 장소를 말하는 같은 과제.
- high / `anxious_h020` "Let thought drift" / `anxious_h233` "Watch the thought go" / `anxious_h234` "Let it float away" / `anxious_h320` "Watch a thought go" / `anxious_h322` "See thoughts drift": 떠오른 생각이 흘러가게 보기.
- high / `anxious_h003` "Open both palms" / `anxious_h054` "Open your hands": 두 손을 펴기.
- full / `anxious_f124` "Chair holds you up" / `anxious_f160` "The chair holds you" / `anxious_f212` "Rooted in the chair": 의자가 몸을 받쳐 준다는 상황 추정.
- full / `anxious_f001` "Right here, now" / `anxious_f010` "Present this minute" / `anxious_f164` "You are still here": 지금 여기 있다는 재진술.
- full / `anxious_f127` "Worries drift off" / `anxious_f129` "Thoughts come and go" / `anxious_f189` "It will pass by": 걱정이나 생각이 지나간다는 관찰.
- complete / `anxious_c039` "Slow walk, one lap" / `anxious_c053` "Walk one slow lap" / `anxious_c074` "Take a slow stroll": 느리게 걷기. c039/c053은 단어 순서만 거의 바뀝니다.
- complete / `anxious_c001` "One slow water sip" / `anxious_c019` "Warm water sip" / `anxious_c064` "Sip slowly" / `anxious_c091` "Sip, set it down": 물을 천천히 한 모금 마시기.
- rare / `anxious_r043` "You went slowly" / `anxious_r063` "You went slow" / `anxious_r082` "You took it slowly": 천천히 했다는 같은 칭찬.
- rare / `anxious_r028` "You made room for it" / `anxious_r055` "You made space" / `anxious_r067` "You gave it space": 감정에 자리를 내줬다는 같은 칭찬.

### 후보 전체

#### low / 우선 검토 / 7개

안전, 긴급성, 주변 상황을 확인 없이 보장합니다.

- low / `anxious_l016`-`anxious_l018` `anxious_l035` `anxious_l191` `anxious_l292` `anxious_l338`
- low / `anxious_l016`: "Safe in this chair"
- low / `anxious_l017`: "Nothing urgent now"
- low / `anxious_l018`: "This minute is okay"
- low / `anxious_l035`: "Sitting safely here"

#### low / 우선 검토 / 19개

신체 증상과 원인을 앱이 알아챈 듯 선언합니다. 'This is anxiety'도 여기 포함합니다.

- low / `anxious_l005`-`anxious_l006` `anxious_l031`-`anxious_l033` `anxious_l055` `anxious_l063` `anxious_l079`-`anxious_l081` `anxious_l093` `anxious_l115` `anxious_l178` `anxious_l187` `anxious_l189` `anxious_l192` `anxious_l302` `anxious_l307` `anxious_l316`
- low / `anxious_l005`: "Racing heart fits"
- low / `anxious_l006`: "Body on high alert"
- low / `anxious_l031`: "Chest feels fluttery"
- low / `anxious_l032`: "Brain scanning hard"

#### low / 말투·상황 후보 / 90개

첫 단계부터 명령, 낭독, 과제를 제시하거나 생각을 'just'로 축소합니다.

- low / `anxious_l010` `anxious_l012`-`anxious_l015` `anxious_l034` `anxious_l044`-`anxious_l047` `anxious_l086` `anxious_l094`-`anxious_l095` `anxious_l108` `anxious_l128` `anxious_l130`-`anxious_l131` `anxious_l135` `anxious_l142`-`anxious_l144` `anxious_l147` `anxious_l150`-`anxious_l158` `anxious_l160`-`anxious_l170` `anxious_l173` `anxious_l179` `anxious_l197` `anxious_l201`-`anxious_l204` `anxious_l210`-`anxious_l214` `anxious_l216` `anxious_l220`-`anxious_l224` `anxious_l228` `anxious_l232` `anxious_l234` `anxious_l246` `anxious_l248` `anxious_l251`-`anxious_l252` `anxious_l259` `anxious_l262`-`anxious_l263` `anxious_l267`-`anxious_l271` `anxious_l273` `anxious_l304`-`anxious_l305` `anxious_l308` `anxious_l320` `anxious_l322`-`anxious_l328` `anxious_l331`-`anxious_l332` `anxious_l334`
- low / `anxious_l010`: "Notice worry thought"
- low / `anxious_l012`: "Feel feet on floor"
- low / `anxious_l013`: "Feel chair under you"
- low / `anxious_l014`: "Feel back supported"

#### low / 말투·상황 후보 / 77개

자세, 주변 환경, 타인의 존재나 신체 감각을 추측합니다.

- low / `anxious_l042` `anxious_l050`-`anxious_l078` `anxious_l089` `anxious_l136`-`anxious_l141` `anxious_l145` `anxious_l148`-`anxious_l149` `anxious_l195`-`anxious_l200` `anxious_l244`-`anxious_l245` `anxious_l264` `anxious_l275`-`anxious_l276` `anxious_l280` `anxious_l283`-`anxious_l286` `anxious_l291` `anxious_l294`-`anxious_l301` `anxious_l303` `anxious_l317`-`anxious_l319` `anxious_l321` `anxious_l336`-`anxious_l337` `anxious_l340`-`anxious_l341` `anxious_l343`-`anxious_l345`
- low / `anxious_l042`: "Room is quiet now"
- low / `anxious_l050`: "Hands resting flat"
- low / `anxious_l051`: "Quiet room around"
- low / `anxious_l052`: "Jaw is holding tight"

#### low / 자연스러움 / 42개

영어에서 자연스럽게 읽히지 않는 어순과 연결, 자막식 문장 조각입니다.

- low / `anxious_l001` `anxious_l003`-`anxious_l005` `anxious_l010` `anxious_l015` `anxious_l028` `anxious_l037` `anxious_l047` `anxious_l072` `anxious_l075` `anxious_l085`-`anxious_l086` `anxious_l098` `anxious_l122`-`anxious_l123` `anxious_l129` `anxious_l146` `anxious_l172` `anxious_l175` `anxious_l185` `anxious_l188`-`anxious_l189` `anxious_l209` `anxious_l225` `anxious_l235` `anxious_l240` `anxious_l247` `anxious_l277`-`anxious_l282` `anxious_l284` `anxious_l289` `anxious_l293`-`anxious_l295` `anxious_l309` `anxious_l337` `anxious_l339`
- low / `anxious_l001`: "Fair to be anxious"
- low / `anxious_l003`: "Anyone feels jittery"
- low / `anxious_l004`: "Big things feel loud"
- low / `anxious_l005`: "Racing heart fits"

#### low / 같은 계열 / 39개

생각 소음, 지금 이 순간, 신체 지지의 반복 후보입니다.

- low / `anxious_l002` `anxious_l009` `anxious_l028`-`anxious_l029` `anxious_l101` `anxious_l110`-`anxious_l111` `anxious_l185`-`anxious_l186` `anxious_l243` `anxious_l309`-`anxious_l315` | `anxious_l011` `anxious_l019` `anxious_l048` `anxious_l277`-`anxious_l284` `anxious_l289` `anxious_l293` `anxious_l295` | `anxious_l013`-`anxious_l014` `anxious_l035` `anxious_l041` `anxious_l285` `anxious_l338`-`anxious_l339` `anxious_l345`
- low / `anxious_l002`: "Lots on your mind"
- low / `anxious_l009`: "Thoughts are noisy"
- low / `anxious_l028`: "Not knowing is loud"
- low / `anxious_l029`: "Hard not knowing"

#### low / 같은 계열 / 43개

쉬거나 천천히 하기, 걱정이 지나가기의 반복 후보입니다.

- low / `anxious_l205`-`anxious_l208` `anxious_l210`-`anxious_l219` `anxious_l223`-`anxious_l227` `anxious_l249` `anxious_l329`-`anxious_l330` | `anxious_l007`-`anxious_l008` `anxious_l229`-`anxious_l238` `anxious_l250`-`anxious_l252` `anxious_l254`-`anxious_l256` `anxious_l331`-`anxious_l333`
- low / `anxious_l205`: "Slow is allowed"
- low / `anxious_l206`: "Unfinished is okay"
- low / `anxious_l207`: "You can pause here"
- low / `anxious_l208`: "Rest counts too"

#### low / 같은 계열 / 29개

도움 청하기와 신체 긴장의 반복 후보입니다.

- low / `anxious_l026` `anxious_l257`-`anxious_l263` `anxious_l266`-`anxious_l267` `anxious_l270`-`anxious_l274` `anxious_l334`-`anxious_l335` | `anxious_l052`-`anxious_l053` `anxious_l070`-`anxious_l071` `anxious_l077` `anxious_l298` `anxious_l340` | `anxious_l030` `anxious_l054` `anxious_l059` `anxious_l071` `anxious_l126`-`anxious_l127`
- low / `anxious_l026`: "Okay to ask someone"
- low / `anxious_l257`: "Text a friend, maybe"
- low / `anxious_l258`: "Wanting help is okay"
- low / `anxious_l259`: "Say it out loud once"

#### high / 우선 검토 / 11개

안전 단정, 최악의 일 쓰기, 문 잠금 확인, 긴급하지 않다는 판정입니다.

- high / `anxious_h025` `anxious_h168` `anxious_h194` `anxious_h218` `anxious_h228`-`anxious_h229` `anxious_h231` `anxious_h246`-`anxious_h248` `anxious_h252`
- high / `anxious_h025`: "No race happening"
- high / `anxious_h168`: "Nothing to fix now"
- high / `anxious_h194`: "Write the worst case"
- high / `anxious_h218`: "Check the lock, once"

#### high / 우선 검토 / 22개

호흡 효과나 호전 단정, 고정 박자와 맥박 확인 지시입니다.

- high / `anxious_h001` `anxious_h026`-`anxious_h028` `anxious_h038` `anxious_h047`-`anxious_h048` `anxious_h073`-`anxious_h074` `anxious_h078`-`anxious_h086` `anxious_h092` `anxious_h094` `anxious_h106` `anxious_h305`
- high / `anxious_h001`: "Longer exhale helps"
- high / `anxious_h026`: "Breath steadier"
- high / `anxious_h027`: "Hands warming up"
- high / `anxious_h028`: "Heart slowing down"

#### high / 말투·상황 후보 / 255개

명령·환경 의존 과제가 높게 밀집해 있습니다. 선택형으로 고칠 후보입니다.

- high / `anxious_h002`-`anxious_h016` `anxious_h019`-`anxious_h022` `anxious_h037` `anxious_h040`-`anxious_h042` `anxious_h045`-`anxious_h046` `anxious_h051`-`anxious_h072` `anxious_h075`-`anxious_h077` `anxious_h095`-`anxious_h105` `anxious_h107`-`anxious_h167` `anxious_h170`-`anxious_h192` `anxious_h196`-`anxious_h216` `anxious_h223`-`anxious_h226` `anxious_h230` `anxious_h232`-`anxious_h245` `anxious_h250`-`anxious_h251` `anxious_h253`-`anxious_h274` `anxious_h275`-`anxious_h304` `anxious_h306`-`anxious_h321`
- high / `anxious_h002`: "Press feet down"
- high / `anxious_h003`: "Open both palms"
- high / `anxious_h004`: "Lower chin slightly"
- high / `anxious_h005`: "Five things you see"

#### high / 자연스러움 / 37개

구어에 어울리지 않는 동사, 어순, 문장 조각입니다.

- high / `anxious_h011` `anxious_h013` `anxious_h022`-`anxious_h023` `anxious_h035` `anxious_h047`-`anxious_h048` `anxious_h060` `anxious_h064` `anxious_h071` `anxious_h081` `anxious_h083` `anxious_h097` `anxious_h112` `anxious_h116` `anxious_h130` `anxious_h134` `anxious_h150` `anxious_h161`-`anxious_h162` `anxious_h175` `anxious_h182`-`anxious_h183` `anxious_h212` `anxious_h226`-`anxious_h228` `anxious_h245`-`anxious_h246` `anxious_h255`-`anxious_h258` `anxious_h266` `anxious_h304` `anxious_h308` `anxious_h316`
- high / `anxious_h011`: "Name today's day"
- high / `anxious_h013`: "Sip cool water slow"
- high / `anxious_h022`: "Watch like a cloud"
- high / `anxious_h023`: "Next five minutes"

#### high / 같은 계열 / 56개

날숨, 손·발 감각, 작은 일 하나와 휴식이 반복됩니다.

- high / `anxious_h037`-`anxious_h039` `anxious_h047`-`anxious_h048` `anxious_h078`-`anxious_h094` `anxious_h219` `anxious_h225` `anxious_h305`-`anxious_h306` | `anxious_h003` `anxious_h054` `anxious_h070` `anxious_h254` | `anxious_h050` `anxious_h131` `anxious_h264` `anxious_h250` `anxious_h308`-`anxious_h309` | `anxious_h015` `anxious_h023`-`anxious_h024` `anxious_h035` `anxious_h145` `anxious_h157`-`anxious_h171`
- high / `anxious_h037`: "Check breath pace"
- high / `anxious_h038`: "Six on the exhale"
- high / `anxious_h039`: "Pause gently"
- high / `anxious_h047`: "Breathe slow in nose"

#### high / 같은 계열 / 49개

생각을 흘려보내기, 날짜 확인, 사람에게 연락하기가 반복됩니다.

- high / `anxious_h019`-`anxious_h022` `anxious_h181`-`anxious_h190` `anxious_h233`-`anxious_h236` `anxious_h320` `anxious_h322` | `anxious_h010`-`anxious_h011` `anxious_h212`-`anxious_h217` `anxious_h244` `anxious_h251` `anxious_h307` | `anxious_h196`-`anxious_h204` `anxious_h207`-`anxious_h209` `anxious_h238`-`anxious_h243`
- high / `anxious_h019`: "Notice the thought"
- high / `anxious_h020`: "Let thought drift"
- high / `anxious_h021`: "No need to argue"
- high / `anxious_h022`: "Watch like a cloud"

#### full / 우선 검토 / 11개

안전, 호흡이 편해짐, 이용 가능한 도움이나 긴급하지 않음을 보장합니다.

- full / `anxious_f004` `anxious_f019` `anxious_f027` `anxious_f071` `anxious_f086` `anxious_f098` `anxious_f108` `anxious_f110`-`anxious_f111` `anxious_f167` `anxious_f215`
- full / `anxious_f004`: "Safe in this room"
- full / `anxious_f019`: "Safe and supported"
- full / `anxious_f027`: "No clock pressure"
- full / `anxious_f071`: "One email can wait"

#### full / 우선 검토 / 74개

호흡·심박·신체 개선 및 도움이 됐다는 결과를 확인 없이 선언합니다.

- full / `anxious_f005`-`anxious_f006` `anxious_f009` `anxious_f013`-`anxious_f014` `anxious_f017` `anxious_f021`-`anxious_f023` `anxious_f025` `anxious_f029`-`anxious_f044` `anxious_f080`-`anxious_f085` `anxious_f094` `anxious_f100` `anxious_f116`-`anxious_f120` `anxious_f135`-`anxious_f149` `anxious_f153`-`anxious_f159` `anxious_f165` `anxious_f200`-`anxious_f209` `anxious_f213` `anxious_f218`
- full / `anxious_f005`: "Hands warm, loose"
- full / `anxious_f006`: "Shoulders low now"
- full / `anxious_f009`: "Body settling down"
- full / `anxious_f013`: "Noise quieting down"

#### full / 말투·상황 후보 / 58개

자세·이미 한 일·환경을 고정하거나 두려움을 축소합니다.

- full / `anxious_f018` `anxious_f046`-`anxious_f047` `anxious_f052`-`anxious_f055` `anxious_f056`-`anxious_f070` `anxious_f088`-`anxious_f089` `anxious_f092`-`anxious_f097` `anxious_f113`-`anxious_f115` `anxious_f124`-`anxious_f125` `anxious_f132` `anxious_f134` `anxious_f160` `anxious_f169`-`anxious_f176` `anxious_f184`-`anxious_f186` `anxious_f189`-`anxious_f192` `anxious_f199` `anxious_f211`-`anxious_f214`
- full / `anxious_f018`: "With what is real"
- full / `anxious_f046`: "You said it, quietly"
- full / `anxious_f047`: "Uneasy but upright"
- full / `anxious_f052`: "Any body would react"

#### full / 자연스러움 / 33개

동사·관용 표현·조사가 영어 문장으로 자연스럽지 않습니다.

- full / `anxious_f003` `anxious_f021` `anxious_f024` `anxious_f035` `anxious_f040` `anxious_f049` `anxious_f052` `anxious_f072` `anxious_f079` `anxious_f082`-`anxious_f083` `anxious_f087` `anxious_f096` `anxious_f119` `anxious_f140`-`anxious_f145` `anxious_f154`-`anxious_f155` `anxious_f169` `anxious_f184`-`anxious_f185` `anxious_f190` `anxious_f194` `anxious_f200`-`anxious_f202` `anxious_f207` `anxious_f210` `anxious_f214`
- full / `anxious_f003`: "Deep unhurried air"
- full / `anxious_f021`: "Gentle rhythm back"
- full / `anxious_f024`: "Soft into chair"
- full / `anxious_f035`: "Eyelids sit heavier"

#### full / 같은 계열 / 48개

현재, 편해진 호흡, 지나가는 생각의 반복 후보입니다.

- full / `anxious_f001` `anxious_f010` `anxious_f029` `anxious_f126` `anxious_f163`-`anxious_f166` `anxious_f168` `anxious_f182` `anxious_f215`-`anxious_f216` | `anxious_f014` `anxious_f030` `anxious_f042`-`anxious_f044` `anxious_f084`-`anxious_f086` `anxious_f118`-`anxious_f120` `anxious_f144`-`anxious_f149` `anxious_f156` `anxious_f205`-`anxious_f209` | `anxious_f007` `anxious_f099`-`anxious_f103` `anxious_f127`-`anxious_f129` `anxious_f161` `anxious_f189` `anxious_f210`-`anxious_f211`
- full / `anxious_f001`: "Right here, now"
- full / `anxious_f010`: "Present this minute"
- full / `anxious_f029`: "Settled in now"
- full / `anxious_f126`: "A slow minute, yours"

#### full / 같은 계열 / 37개

의자, 쉴 허락, 연락 허락의 반복 후보입니다.

- full / `anxious_f024` `anxious_f034` `anxious_f116` `anxious_f124` `anxious_f160` `anxious_f184` `anxious_f190` `anxious_f199` `anxious_f212` | `anxious_f012` `anxious_f016` `anxious_f028` `anxious_f071`-`anxious_f079` `anxious_f177`-`anxious_f179` | `anxious_f104`-`anxious_f109` `anxious_f130`-`anxious_f133` `anxious_f162` `anxious_f186` `anxious_f188`
- full / `anxious_f024`: "Soft into chair"
- full / `anxious_f034`: "Knees are resting"
- full / `anxious_f116`: "Hips sink into seat"
- full / `anxious_f124`: "Chair holds you up"

#### complete / 우선 검토 / 7개

물리적 환경에 의존하는 동작 또는 고정 호흡 박자를 지시합니다.

- complete / `anxious_c004` `anxious_c044` `anxious_c055` `anxious_c060` `anxious_c062` `anxious_c071` `anxious_c083`
- complete / `anxious_c004`: "Hands open five sec"
- complete / `anxious_c044`: "Breathe out for six"
- complete / `anxious_c055`: "Breathe in 4, out 6"
- complete / `anxious_c060`: "Light a candle"

#### complete / 말투·상황 후보 / 77개

완료 뒤에 또 수행할 과제를 주는 문구입니다. c002·c009·c051·c081은 선택 표현의 대조군입니다.

- complete / `anxious_c003` `anxious_c005`-`anxious_c008` `anxious_c010`-`anxious_c015` `anxious_c017`-`anxious_c018` `anxious_c020`-`anxious_c024` `anxious_c026`-`anxious_c042` `anxious_c045`-`anxious_c050` `anxious_c052`-`anxious_c059` `anxious_c061` `anxious_c063`-`anxious_c070` `anxious_c072`-`anxious_c080` `anxious_c082`-`anxious_c091`
- complete / `anxious_c003`: "Pick one tiny task"
- complete / `anxious_c005`: "Feet down, breathe"
- complete / `anxious_c006`: "Drop shoulders, out"
- complete / `anxious_c007`: "Jot one line, close"

#### complete / 자연스러움 / 21개

축약된 지시가 모호하거나 영어다운 연결이 빠졌습니다.

- complete / `anxious_c001` `anxious_c004` `anxious_c006`-`anxious_c007` `anxious_c012`-`anxious_c013` `anxious_c016`-`anxious_c019` `anxious_c028` `anxious_c039` `anxious_c045` `anxious_c047` `anxious_c056` `anxious_c058`-`anxious_c059` `anxious_c064` `anxious_c076` `anxious_c084` `anxious_c089`
- complete / `anxious_c001`: "One slow water sip"
- complete / `anxious_c004`: "Hands open five sec"
- complete / `anxious_c006`: "Drop shoulders, out"
- complete / `anxious_c007`: "Jot one line, close"

#### complete / 같은 계열 / 26개

물·차, 걷기, 휴식, 호흡, 책상 과제가 반복됩니다.

- complete / `anxious_c001` `anxious_c019` `anxious_c022` `anxious_c064` `anxious_c091` | `anxious_c009` `anxious_c035` `anxious_c084` | `anxious_c039` `anxious_c053` `anxious_c074` `anxious_c090` | `anxious_c032` `anxious_c046` `anxious_c063` | `anxious_c021` `anxious_c029` `anxious_c044` `anxious_c055`-`anxious_c056` `anxious_c071` `anxious_c077` | `anxious_c031` `anxious_c079` `anxious_c082` `anxious_c085`
- complete / `anxious_c001`: "One slow water sip"
- complete / `anxious_c019`: "Warm water sip"
- complete / `anxious_c022`: "Drink some water"
- complete / `anxious_c064`: "Sip slowly"

#### rare / 우선 검토 / 8개

안전을 확정하거나 차분함과 버티기를 이겼다는 보상으로 만듭니다.

- rare / `anxious_r009`-`anxious_r010` `anxious_r017`-`anxious_r018` `anxious_r034` `anxious_r049` `anxious_r059` `anxious_r076`
- rare / `anxious_r009`: "Held calm space"
- rare / `anxious_r010`: "Safe in the present"
- rare / `anxious_r017`: "Present and steady"
- rare / `anxious_r018`: "Peaceful breath won"

#### rare / 말투·상황 후보 / 69개

인식·신체 조절·동행을 실제로 관찰한 듯 칭찬합니다.

- rare / `anxious_r002`-`anxious_r005` `anxious_r007`-`anxious_r008` `anxious_r012`-`anxious_r013` `anxious_r019`-`anxious_r047` `anxious_r050`-`anxious_r051` `anxious_r053`-`anxious_r056` `anxious_r058`-`anxious_r060` `anxious_r064`-`anxious_r075` `anxious_r077`-`anxious_r085` `anxious_r087`-`anxious_r088`
- rare / `anxious_r002`: "Met worry gently"
- rare / `anxious_r003`: "Presence over rush"
- rare / `anxious_r004`: "Heard body cues"
- rare / `anxious_r005`: "Gave breathing room"

#### rare / 자연스러움 / 23개

자막식 단어 배열, 대명사와 어미의 부자연스러운 반복입니다.

- rare / `anxious_r007` `anxious_r013` `anxious_r015` `anxious_r018` `anxious_r020`-`anxious_r021` `anxious_r024` `anxious_r027` `anxious_r029` `anxious_r037`-`anxious_r039` `anxious_r045` `anxious_r053` `anxious_r061` `anxious_r064` `anxious_r077` `anxious_r083` `anxious_r085`-`anxious_r086` `anxious_r089`-`anxious_r091`
- rare / `anxious_r007`: "Thoughts unhooked"
- rare / `anxious_r013`: "Trusted one step"
- rare / `anxious_r015`: "Rooted in moment"
- rare / `anxious_r018`: "Peaceful breath won"

#### rare / 같은 계열 / 31개

현재를 붙잡기·속도 늦추기가 반복됩니다.

- rare / `anxious_r001` `anxious_r015` `anxious_r019` `anxious_r022` `anxious_r026` `anxious_r029`-`anxious_r033` `anxious_r039` `anxious_r049` `anxious_r057` `anxious_r062` `anxious_r076`-`anxious_r077` `anxious_r079` `anxious_r091` | `anxious_r003` `anxious_r008` `anxious_r011`-`anxious_r012` `anxious_r036` `anxious_r040` `anxious_r043` `anxious_r046` `anxious_r063` `anxious_r069` `anxious_r075` `anxious_r082` `anxious_r085`
- rare / `anxious_r001`: "Stayed with yourself"
- rare / `anxious_r015`: "Rooted in moment"
- rare / `anxious_r019`: "Calmly stayed here"
- rare / `anxious_r022`: "You stayed with it"

#### rare / 같은 계열 / 23개

자기 돌봄·감각 알아차리기·자리 내주기가 반복됩니다.

- rare / `anxious_r002` `anxious_r016` `anxious_r020` `anxious_r024` `anxious_r037` `anxious_r053` `anxious_r058` `anxious_r070` `anxious_r081` `anxious_r084` `anxious_r090` | `anxious_r004` `anxious_r023` `anxious_r045` `anxious_r047` `anxious_r064` `anxious_r066` `anxious_r068` `anxious_r072`-`anxious_r073` | `anxious_r028` `anxious_r055` `anxious_r067`
- rare / `anxious_r002`: "Met worry gently"
- rare / `anxious_r016`: "Softness and courage"
- rare / `anxious_r020`: "Gentle care kept"
- rare / `anxious_r024`: "You were kind to you"

## 일본어 (`ja.json`)

### 단계별 대표 문구

- low / `anxious_l204`, `anxious_l211`, `anxious_l306`, `anxious_l307`: '目をひとつ閉じてみる？' '指を一本ずつ開いてみ'는 낯설거나 끝이 잘립니다. '見守ってる'는 실제 감시자가 있다는 오해를 낳을 수 있습니다.
- high / `anxious_h175`, `anxious_h182`, `anxious_h238`, `anxious_h254`: 머릿속 목소리 중계·들리는 목소리에 대한 지시, 공기 세기, 두근거림을 삶의 증거라 말하는 표현은 일본어판에서 특히 수정 우선입니다.
- full / `anxious_f010`, `anxious_f039`, `anxious_f040`, `anxious_f253`: 호흡을 단정하는 번역투, 혈류 회복, 견갑골이 등에 떨어진다는 낯선 표현, 위험 부재를 단정하는 문구입니다.
- complete / `anxious_c010`, `anxious_c022`, `anxious_c070`, `anxious_c081`: c010의 생략 허락은 한국어에 비해 어색한 직접 부정입니다. 목표가 없는 관찰, 일정 삭제, 베란다 지시도 눈에 띕니다.
- rare / `anxious_r032`, `anxious_r039`, `anxious_r081`, `anxious_r085`: '逃げずに', 이전보다 깊게 들이쉬었다는 판정, '弱いままで', 앱과 함께 호흡했다는 선언은 압박과 사실 단정을 만듭니다.

### 뜻이 거의 같은 문구

- low / `anxious_l030` "今この瞬間安全だよ" / `anxious_l317` "今は安全な場所だよ" / `anxious_l319` "今この瞬間は無事だよ" / `anxious_l325` "ここには危険がないよ" / `anxious_l345` "今のところ無事だよ": 지금 안전하다는 같은 단정.
- low / `anxious_l294` "ここに一緒にいるよ" / `anxious_l296` "そっと隣に座ってるよ" / `anxious_l297` "黙っててもそばにいるよ" / `anxious_l306` "わたしはここにいるよ": 앱이 지금 곁에 있다는 같은 약속.
- low / `anxious_l234` "一休みしてもいいよ" / `anxious_l255` "休憩を入れていいんだよ" / `anxious_l260` "今は休む番だよ": 한 번 쉬자는 같은 역할.
- high / `anxious_h113` "目に入る青い物を探そう" / `anxious_h114` "赤い物をひとつ見つけよう": 주변 물건 하나 찾기. 파랑·빨강만 바뀝니다.
- high / `anxious_h033` "今日できることひとつだけ" / `anxious_h035` "今やることひとつだけ" / `anxious_h149` "一番小さいことを選ぼう": 할 수 있는 작은 일 하나 고르기.
- high / `anxious_h168` "考えが来たら見送ってみよう" / `anxious_h177` "考えが通り過ぎるのを見よう" / `anxious_h299` "考えが浮かぶのをただ見よう" / `anxious_h303` "思いは来てそのうち去るよ": 생각이 지나가기를 바라보는 같은 선택.
- full / `anxious_f002` "呼吸が整い深くなった" / `anxious_f010` "呼吸が安定戻ってる" / `anxious_f063` "息が自分で整ってきた": 호흡이 안정됐다는 같은 판정.
- full / `anxious_f027` "この場で呼吸してるよ" / `anxious_f031` "今ここで呼吸してる": 이곳에서 숨 쉬고 있다는 같은 관찰.
- full / `anxious_f138` "考えが来ては去っていく" / `anxious_f135` "浮かんだ考えが通り過ぎた" / `anxious_f235` "考えは来て、また去った": 생각이 왔다 사라졌다는 같은 관찰.
- complete / `anxious_c001` "お水ひと口ゆっくり飲もう" / `anxious_c021` "コップ一杯の水を飲もう": 물을 마시는 과제. 양만 한 모금과 한 컵으로 다릅니다.
- complete / `anxious_c016` "時計見ずに1分休もう" / `anxious_c047` "スマホを置いて一分休もう": 1분 쉬기. 시계와 휴대전화를 치우라는 조건만 다릅니다.
- rare / `anxious_r049` "焦りの中でも立ち止まった" / `anxious_r053` "立ち止まるのも選択だった" / `anxious_r075` "ここで待てたのは立派な一歩" / `anxious_r092` "今日も座って待てたね": 멈춰 앉거나 기다렸다는 성과 칭찬의 반복.
- rare / `anxious_r020` "穏やかに息した瞬間" / `anxious_r074` "ゆったり息ができたよね" / `anxious_r079` "ゆっくり吸って吐けた瞬間": 편하게 숨을 들이쉬거나 내쉬었다는 같은 성과 판정.

### 후보 전체

#### low / 우선 검토 / 20개

지금 안전하거나 급할 일이 없다고 보장합니다.

- low / `anxious_l030`-`anxious_l033` `anxious_l037` `anxious_l039`-`anxious_l041` `anxious_l317`-`anxious_l319` `anxious_l321` `anxious_l325` `anxious_l330` `anxious_l332` `anxious_l335`-`anxious_l336` `anxious_l341`-`anxious_l342` `anxious_l345`
- low / `anxious_l030`: "今この瞬間安全だよ"
- low / `anxious_l031`: "部屋に安心しているよ"
- low / `anxious_l032`: "急いで決めなくていい"
- low / `anxious_l033`: "時間そこまで急がない"

#### low / 우선 검토 / 33개

심장·가슴·목·호흡 상태를 관찰한 것처럼 말하고, 감각의 원인을 불안으로 판정합니다.

- low / `anxious_l015` `anxious_l056` `anxious_l058` `anxious_l062` `anxious_l067` `anxious_l073`-`anxious_l079` `anxious_l087`-`anxious_l093` `anxious_l101`-`anxious_l102` `anxious_l105` `anxious_l109`-`anxious_l114` `anxious_l116`-`anxious_l117` `anxious_l125` `anxious_l142` `anxious_l348`
- low / `anxious_l015`: "心臓速く打ってるね"
- low / `anxious_l056`: "息はちゃんと続いてる"
- low / `anxious_l058`: "胸のあたりが狭いね"
- low / `anxious_l062`: "こめかみが脈打ってるね"

#### low / 우선 검토 / 9개

앱이 곁에 있고 직접 보고 듣는 사람처럼 말합니다.

- low / `anxious_l167` `anxious_l292` `anxious_l294` `anxious_l296`-`anxious_l297` `anxious_l302` `anxious_l306`-`anxious_l307` `anxious_l316`
- low / `anxious_l167`: "そのままで受け取るよ"
- low / `anxious_l292`: "聞いてくれる人はいるよ"
- low / `anxious_l294`: "ここに一緒にいるよ"
- low / `anxious_l296`: "そっと隣に座ってるよ"

#### low / 말투·상황 후보 / 41개

원인, 생각의 사실 여부, 미뤄도 될지, 감정 인식에 성공했는지를 단정합니다.

- low / `anxious_l010`-`anxious_l012` `anxious_l147`-`anxious_l148` `anxious_l154`-`anxious_l158` `anxious_l160` `anxious_l164`-`anxious_l166` `anxious_l168`-`anxious_l170` `anxious_l231` `anxious_l237` `anxious_l239` `anxious_l251` `anxious_l257` `anxious_l265`-`anxious_l266` `anxious_l274`-`anxious_l285` `anxious_l315` `anxious_l339` `anxious_l344` `anxious_l349` `anxious_l351`
- low / `anxious_l010`: "初めてだから余計だね"
- low / `anxious_l011`: "うまくやりたいからだ"
- low / `anxious_l012`: "大事なことだからだね"
- low / `anxious_l147`: "それだけ大事なんだね"

#### low / 말투·상황 후보 / 102개

첫 단계의 수행 과제와 실내·자세·몸 상태 전제입니다.

- low / `anxious_l023`-`anxious_l027` `anxious_l052`-`anxious_l055` `anxious_l057`-`anxious_l086` `anxious_l171`-`anxious_l200` `anxious_l203`-`anxious_l204` `anxious_l207`-`anxious_l211` `anxious_l218`-`anxious_l219` `anxious_l222`-`anxious_l224` `anxious_l227`-`anxious_l230` `anxious_l290` `anxious_l304` `anxious_l311` `anxious_l318` `anxious_l320` `anxious_l322`-`anxious_l324` `anxious_l326`-`anxious_l327` `anxious_l331` `anxious_l333`-`anxious_l334` `anxious_l337`-`anxious_l338` `anxious_l340` `anxious_l350`
- low / `anxious_l023`: "名前ひとつ付けてみよ"
- low / `anxious_l024`: "今ここ足ついてるよ"
- low / `anxious_l025`: "背中あたる所感じよう"
- low / `anxious_l026`: "指先の感触感じよう"

#### low / 자연스러움 / 50개

조사가 빠지거나 동작이 모호해 짧은 일본어 대화로 어색합니다.

- low / `anxious_l004`-`anxious_l006` `anxious_l015`-`anxious_l016` `anxious_l020` `anxious_l022`-`anxious_l025` `anxious_l044`-`anxious_l045` `anxious_l056` `anxious_l058` `anxious_l065` `anxious_l071`-`anxious_l072` `anxious_l090` `anxious_l101` `anxious_l103` `anxious_l109`-`anxious_l111` `anxious_l126`-`anxious_l127` `anxious_l132` `anxious_l152` `anxious_l169`-`anxious_l170` `anxious_l173` `anxious_l189` `anxious_l191` `anxious_l201` `anxious_l204` `anxious_l209`-`anxious_l211` `anxious_l215` `anxious_l220` `anxious_l229` `anxious_l241` `anxious_l261`-`anxious_l264` `anxious_l288` `anxious_l313` `anxious_l328` `anxious_l331` `anxious_l334`
- low / `anxious_l004`: "心そわそわするよね"
- low / `anxious_l005`: "不安が大きく感じるね"
- low / `anxious_l006`: "ドキドキする場だよね"
- low / `anxious_l015`: "心臓速く打ってるね"

#### low / 같은 계열 / 94개

불안 인정과 쉬거나 서두르지 않아도 된다는 말의 반복 후보입니다.

- low / `anxious_l001`-`anxious_l009` `anxious_l013` `anxious_l119`-`anxious_l126` `anxious_l128`-`anxious_l134` `anxious_l137`-`anxious_l143` `anxious_l146`-`anxious_l149` `anxious_l151`-`anxious_l163` `anxious_l169` `anxious_l352` | `anxious_l032`-`anxious_l034` `anxious_l043`-`anxious_l051` `anxious_l230`-`anxious_l260`
- low / `anxious_l001`: "不安になるよね"
- low / `anxious_l002`: "緊張する場面だよね"
- low / `anxious_l003`: "気にかかるよね"
- low / `anxious_l004`: "心そわそわするよね"

#### low / 같은 계열 / 93개

생각이 지나가기, 도움에 손 내밀기, 안전한 실내라는 단정이 반복됩니다.

- low / `anxious_l019`-`anxious_l020` `anxious_l261`-`anxious_l289` | `anxious_l048`-`anxious_l049` `anxious_l290`-`anxious_l315` | `anxious_l030`-`anxious_l031` `anxious_l040`-`anxious_l041` `anxious_l317`-`anxious_l346`
- low / `anxious_l019`: "通り過ぎる気持ちだよ"
- low / `anxious_l020`: "少し通り過ぎる感覚"
- low / `anxious_l261`: "頭の中の声も通り道だ"
- low / `anxious_l262`: "浮かんだ考えは来て去る"

#### low / 같은 계열 / 45개

몸 부위별 긴장과 바닥에서 느낄 감각이 반복됩니다.

- low / `anxious_l017`-`anxious_l018` `anxious_l057`-`anxious_l086` `anxious_l347`-`anxious_l348` | `anxious_l024` `anxious_l029` `anxious_l055` `anxious_l172`-`anxious_l173` `anxious_l191`-`anxious_l192` `anxious_l195` `anxious_l199` `anxious_l331` `anxious_l338`
- low / `anxious_l017`: "肩が上がってるね"
- low / `anxious_l018`: "あごに力入ってるね"
- low / `anxious_l057`: "肩がきゅっと上がってる"
- low / `anxious_l058`: "胸のあたりが狭いね"

#### high / 우선 검토 / 32개

맥박·목·호흡 지시, 안전 판정, 동계를 '살아 있다는 증거'로 긍정하는 표현입니다.

- high / `anxious_h042` `anxious_h048` `anxious_h060` `anxious_h067` `anxious_h071`-`anxious_h073` `anxious_h076` `anxious_h083`-`anxious_h084` `anxious_h086`-`anxious_h088` `anxious_h095` `anxious_h101`-`anxious_h102` `anxious_h107` `anxious_h175` `anxious_h178` `anxious_h182` `anxious_h202` `anxious_h215` `anxious_h221` `anxious_h229` `anxious_h234`-`anxious_h235` `anxious_h239` `anxious_h241`-`anxious_h242` `anxious_h254` `anxious_h319`-`anxious_h320`
- high / `anxious_h042`: "心臓の音が落ち着くね"
- high / `anxious_h048`: "息通りだんだん楽に"
- high / `anxious_h060`: "胸に手をあて鼓動を聞く"
- high / `anxious_h067`: "指先の脈を探してみよう"

#### high / 말투·상황 후보 / 266개

'〜しよう' 과제, 사용자 주변이나 일정 전제, 앱의 의인화가 밀집합니다.

- high / `anxious_h002`-`anxious_h040` `anxious_h043`-`anxious_h051` `anxious_h052`-`anxious_h070` `anxious_h074`-`anxious_h081` `anxious_h085` `anxious_h089`-`anxious_h100` `anxious_h106` `anxious_h109` `anxious_h111`-`anxious_h151` `anxious_h162`-`anxious_h166` `anxious_h169`-`anxious_h170` `anxious_h174`-`anxious_h192` `anxious_h198`-`anxious_h201` `anxious_h203`-`anxious_h214` `anxious_h216`-`anxious_h233` `anxious_h236`-`anxious_h246` `anxious_h249` `anxious_h253` `anxious_h255`-`anxious_h289` `anxious_h292` `anxious_h294`-`anxious_h295` `anxious_h297`-`anxious_h302` `anxious_h304`-`anxious_h311` `anxious_h314`-`anxious_h318` `anxious_h321`-`anxious_h325`
- high / `anxious_h002`: "足裏を床にぐっと"
- high / `anxious_h003`: "肩を下へすとんと"
- high / `anxious_h004`: "握った手のひら開こう"
- high / `anxious_h005`: "あごを少し下げよう"

#### high / 자연스러움 / 62개

부자연스러운 동작, 조사, 문장 조각입니다.

- high / `anxious_h006` `anxious_h008` `anxious_h011` `anxious_h017` `anxious_h021` `anxious_h023` `anxious_h028` `anxious_h036`-`anxious_h038` `anxious_h041` `anxious_h045`-`anxious_h049` `anxious_h057` `anxious_h062`-`anxious_h063` `anxious_h070` `anxious_h078`-`anxious_h079` `anxious_h086` `anxious_h096` `anxious_h098`-`anxious_h100` `anxious_h117`-`anxious_h118` `anxious_h123` `anxious_h128` `anxious_h142` `anxious_h149`-`anxious_h150` `anxious_h164` `anxious_h167` `anxious_h175` `anxious_h184` `anxious_h190` `anxious_h197` `anxious_h217` `anxious_h231` `anxious_h234` `anxious_h238` `anxious_h246` `anxious_h263` `anxious_h266` `anxious_h274` `anxious_h279` `anxious_h289`-`anxious_h290` `anxious_h294` `anxious_h300` `anxious_h302` `anxious_h306`-`anxious_h307` `anxious_h314` `anxious_h320` `anxious_h322`-`anxious_h325`
- high / `anxious_h006`: "眉間ゆるめて目閉じよ"
- high / `anxious_h008`: "手のひらこすり合わせよう"
- high / `anxious_h011`: "窓の外の景色ひとつ見よ"
- high / `anxious_h017`: "今の場所の名前言ってみよ"

#### high / 같은 계열 / 121개

호흡 세기, 몸 부위 움직이기, 주변 감각 과제가 반복됩니다.

- high / `anxious_h001` `anxious_h019`-`anxious_h022` `anxious_h071`-`anxious_h090` `anxious_h234`-`anxious_h241` | `anxious_h002`-`anxious_h008` `anxious_h052`-`anxious_h070` `anxious_h220`-`anxious_h233` | `anxious_h011`-`anxious_h016` `anxious_h112`-`anxious_h134` `anxious_h257`-`anxious_h275`
- high / `anxious_h001`: "吐く息を少し長く"
- high / `anxious_h019`: "おなかまで息吸い込もう"
- high / `anxious_h020`: "鼻からゆっくり吸おう"
- high / `anxious_h021`: "唇すぼめて長くふぅ"

#### high / 같은 계열 / 122개

날짜 말하기, 한 가지 일·휴식, 생각 관찰, 사람 연결이 반복됩니다.

- high / `anxious_h017`-`anxious_h018` `anxious_h134` `anxious_h142` `anxious_h203`-`anxious_h206` `anxious_h322` | `anxious_h033`-`anxious_h036` `anxious_h139`-`anxious_h166` `anxious_h276`-`anxious_h298` | `anxious_h029`-`anxious_h032` `anxious_h167`-`anxious_h184` `anxious_h299`-`anxious_h309` | `anxious_h185`-`anxious_h201` `anxious_h310`-`anxious_h318`
- high / `anxious_h017`: "今の場所の名前言ってみよ"
- high / `anxious_h018`: "今日の曜日思い出そう"
- high / `anxious_h134`: "今の時間を時計で見てみよう"
- high / `anxious_h142`: "メモ帳の最初に今日の日付を"

#### full / 우선 검토 / 14개

안전, 위험 부재, 혈류, 불안이라는 원인, 호흡 수행을 단정합니다.

- full / `anxious_f011` `anxious_f028` `anxious_f039` `anxious_f085` `anxious_f128` `anxious_f159` `anxious_f164` `anxious_f167`-`anxious_f168` `anxious_f184` `anxious_f192` `anxious_f214` `anxious_f225` `anxious_f253`
- full / `anxious_f011`: "この瞬間安全なんだね"
- full / `anxious_f028`: "安全な部屋で休んでる"
- full / `anxious_f039`: "指先に血が戻ってきた"
- full / `anxious_f085`: "体は守ろうとしただけ"

#### full / 우선 검토 / 65개

게이지가 차는 것을 몸과 호흡, 정서가 개선된 것으로 바꿉니다.

- full / `anxious_f002` `anxious_f004` `anxious_f009`-`anxious_f010` `anxious_f016` `anxious_f021` `anxious_f026` `anxious_f030`-`anxious_f048` `anxious_f050`-`anxious_f066` `anxious_f112`-`anxious_f115` `anxious_f119` `anxious_f172`-`anxious_f177` `anxious_f180`-`anxious_f188` `anxious_f201`-`anxious_f202`
- full / `anxious_f002`: "呼吸が整い深くなった"
- full / `anxious_f004`: "肩とあごがゆるんだよ"
- full / `anxious_f009`: "体のサイン気づけたね"
- full / `anxious_f010`: "呼吸が安定戻ってる"

#### full / 말투·상황 후보 / 141개

사용자 장소와 행동을 추정하고 과제나 잘 버티라는 압박을 줍니다.

- full / `anxious_f019`-`anxious_f020` `anxious_f023` `anxious_f046`-`anxious_f049` `anxious_f067`-`anxious_f079` `anxious_f082`-`anxious_f088` `anxious_f092`-`anxious_f121` `anxious_f122` `anxious_f128`-`anxious_f132` `anxious_f145`-`anxious_f147` `anxious_f151` `anxious_f154`-`anxious_f159` `anxious_f160`-`anxious_f171` `anxious_f178`-`anxious_f183` `anxious_f193`-`anxious_f205` `anxious_f207`-`anxious_f228` `anxious_f238`-`anxious_f252`
- full / `anxious_f019`: "今の自分そのまま受け止む"
- full / `anxious_f020`: "よく留まってくれたね"
- full / `anxious_f023`: "焦りおいて今を見よう"
- full / `anxious_f046`: "背中が椅子に預けられた"

#### full / 자연스러움 / 51개

신체 은유와 조사 생략, 어색한 구어가 남았습니다.

- full / `anxious_f003` `anxious_f007` `anxious_f010` `anxious_f015`-`anxious_f016` `anxious_f019` `anxious_f021`-`anxious_f022` `anxious_f024` `anxious_f036`-`anxious_f037` `anxious_f040` `anxious_f043`-`anxious_f044` `anxious_f049`-`anxious_f051` `anxious_f053`-`anxious_f054` `anxious_f057`-`anxious_f058` `anxious_f061`-`anxious_f062` `anxious_f068` `anxious_f076`-`anxious_f077` `anxious_f082` `anxious_f089` `anxious_f105` `anxious_f113` `anxious_f136`-`anxious_f137` `anxious_f139`-`anxious_f140` `anxious_f145` `anxious_f147` `anxious_f163` `anxious_f173` `anxious_f176` `anxious_f183` `anxious_f186` `anxious_f194` `anxious_f197` `anxious_f202` `anxious_f220` `anxious_f223` `anxious_f230`-`anxious_f231` `anxious_f236` `anxious_f247` `anxious_f251`
- full / `anxious_f003`: "足裏が床をしっかり踏む"
- full / `anxious_f007`: "やらなくていいゆとり"
- full / `anxious_f010`: "呼吸が安定戻ってる"
- full / `anxious_f015`: "息つける隙間できたよ"

#### full / 같은 계열 / 60개

안정된 호흡, 감정 이름 붙이기, 불안 인정에 반복이 있습니다.

- full / `anxious_f002` `anxious_f010` `anxious_f021` `anxious_f031` `anxious_f050`-`anxious_f065` `anxious_f184`-`anxious_f190` | `anxious_f067`-`anxious_f079` `anxious_f194`-`anxious_f199` | `anxious_f080`-`anxious_f089` `anxious_f203`-`anxious_f206`
- full / `anxious_f002`: "呼吸が整い深くなった"
- full / `anxious_f010`: "呼吸が安定戻ってる"
- full / `anxious_f021`: "静かな呼吸おさまった"
- full / `anxious_f031`: "今ここで呼吸してる"

#### full / 같은 계열 / 88개

생각 비유, 연결, 안전, 휴식에 반복이 있습니다.

- full / `anxious_f133`-`anxious_f144` `anxious_f230`-`anxious_f237` | `anxious_f146`-`anxious_f157` `anxious_f238`-`anxious_f245` | `anxious_f011` `anxious_f028` `anxious_f159`-`anxious_f171` `anxious_f246`-`anxious_f253` | `anxious_f017`-`anxious_f018` `anxious_f110` `anxious_f117` `anxious_f122`-`anxious_f132` `anxious_f220`-`anxious_f229`
- full / `anxious_f133`: "考えは雲みたいに流れる"
- full / `anxious_f134`: "思いが川を流れていく"
- full / `anxious_f135`: "浮かんだ考えが通り過ぎた"
- full / `anxious_f136`: "頭の中の天気が変わった"

#### complete / 우선 검토 / 17개

특정 장소·시간·자세·호흡을 일률적으로 지시합니다.

- complete / `anxious_c002` `anxious_c004`-`anxious_c005` `anxious_c018`-`anxious_c020` `anxious_c038` `anxious_c040` `anxious_c061` `anxious_c064` `anxious_c066` `anxious_c070` `anxious_c072` `anxious_c079` `anxious_c081` `anxious_c083` `anxious_c087`
- complete / `anxious_c002`: "窓開けて外の空気吸おう"
- complete / `anxious_c004`: "手開いて5秒じっとしよ"
- complete / `anxious_c005`: "4秒吸って6秒吐いてみよ"
- complete / `anxious_c018`: "鼻で吸って口で長くふぅ"

#### complete / 말투·상황 후보 / 77개

완료 뒤에도 시키는 과제가 많습니다. 부담 없이 생략할 수 있는 한 줄이 필요합니다.

- complete / `anxious_c001` `anxious_c003` `anxious_c006`-`anxious_c009` `anxious_c011`-`anxious_c017` `anxious_c021`-`anxious_c037` `anxious_c039` `anxious_c041`-`anxious_c060` `anxious_c062`-`anxious_c069` `anxious_c071` `anxious_c073`-`anxious_c078` `anxious_c080` `anxious_c082`-`anxious_c091`
- complete / `anxious_c001`: "お水ひと口ゆっくり飲もう"
- complete / `anxious_c003`: "やることひとつだけ選ぼう"
- complete / `anxious_c006`: "足裏感じながら休もう"
- complete / `anxious_c007`: "肩おろして長くふぅ"

#### complete / 자연스러움 / 23개

목적어와 실제 몸 동작이 어색합니다. c010의 '안 마셔도 된다'는 말도 맥락이 끊깁니다.

- complete / `anxious_c004`-`anxious_c005` `anxious_c007`-`anxious_c010` `anxious_c012` `anxious_c014` `anxious_c018` `anxious_c022`-`anxious_c023` `anxious_c039` `anxious_c042` `anxious_c045` `anxious_c047` `anxious_c051` `anxious_c055` `anxious_c061` `anxious_c064` `anxious_c068` `anxious_c076` `anxious_c081` `anxious_c088`
- complete / `anxious_c004`: "手開いて5秒じっとしよ"
- complete / `anxious_c005`: "4秒吸って6秒吐いてみよ"
- complete / `anxious_c007`: "肩おろして長くふぅ"
- complete / `anxious_c008`: "メモ帳に一行書いて閉じよ"

#### complete / 같은 계열 / 43개

마시기, 창문, 호흡 절차, 신체 움직임이 반복됩니다.

- complete / `anxious_c001` `anxious_c021` `anxious_c054` `anxious_c089` | `anxious_c002` `anxious_c033` `anxious_c061` `anxious_c066` `anxious_c081` | `anxious_c005`-`anxious_c007` `anxious_c013` `anxious_c018` `anxious_c032` `anxious_c060` `anxious_c072` `anxious_c078`-`anxious_c079` `anxious_c087` | `anxious_c023`-`anxious_c026` `anxious_c030`-`anxious_c031` `anxious_c037` `anxious_c041`-`anxious_c046` `anxious_c051`-`anxious_c052` `anxious_c055` `anxious_c059` `anxious_c064`-`anxious_c065` `anxious_c068` `anxious_c082`-`anxious_c083` `anxious_c088`
- complete / `anxious_c001`: "お水ひと口ゆっくり飲もう"
- complete / `anxious_c021`: "コップ一杯の水を飲もう"
- complete / `anxious_c054`: "湯のみを両手で包もう"
- complete / `anxious_c089`: "お茶の香りをかいでみよう"

#### complete / 같은 계열 / 18개

일정 시간 쉬기, 기록하기, 감각 하나 발견하기가 반복됩니다.

- complete / `anxious_c016` `anxious_c020` `anxious_c038` `anxious_c047` `anxious_c067` `anxious_c076` | `anxious_c008` `anxious_c034` `anxious_c057` `anxious_c062` | `anxious_c012` `anxious_c028`-`anxious_c029` `anxious_c043` `anxious_c071` `anxious_c084`-`anxious_c085` `anxious_c090`
- complete / `anxious_c016`: "時計見ずに1分休もう"
- complete / `anxious_c020`: "この場で少し目閉じよう"
- complete / `anxious_c038`: "目を閉じて十数えよう"
- complete / `anxious_c047`: "スマホを置いて一分休もう"

#### rare / 우선 검토 / 18개

안전을 인증하거나, 떠나지 않고 견딘 것을 칭찬하고 사람을 '약하다'고 부릅니다.

- rare / `anxious_r014` `anxious_r017` `anxious_r032`-`anxious_r033` `anxious_r039` `anxious_r041` `anxious_r050`-`anxious_r051` `anxious_r065`-`anxious_r066` `anxious_r073`-`anxious_r075` `anxious_r077` `anxious_r081` `anxious_r085` `anxious_r087` `anxious_r092`
- rare / `anxious_r014`: "思ったより耐えた一日"
- rare / `anxious_r017`: "安全な今を確かめたよ"
- rare / `anxious_r032`: "逃げずに少し待ってみた"
- rare / `anxious_r033`: "ちゃんと一息ついたよね"

#### rare / 말투·상황 후보 / 75개

수행 성공을 알아챈 듯 채점하거나 사용자가 앱을 위해 시간을 냈다고 표현합니다.

- rare / `anxious_r002`-`anxious_r013` `anxious_r015`-`anxious_r016` `anxious_r018`-`anxious_r031` `anxious_r034`-`anxious_r038` `anxious_r040`-`anxious_r049` `anxious_r052`-`anxious_r064` `anxious_r067`-`anxious_r072` `anxious_r076` `anxious_r078`-`anxious_r080` `anxious_r082`-`anxious_r084` `anxious_r086` `anxious_r088`-`anxious_r091` `anxious_r093`
- rare / `anxious_r002`: "この瞬間守った呼吸だよ"
- rare / `anxious_r003`: "揺れても自分いたわった"
- rare / `anxious_r004`: "思考から一歩引いた知恵"
- rare / `anxious_r005`: "体のサインに耳傾けた"

#### rare / 자연스러움 / 34개

화자와 상대, 조사, 신체 비유가 모호합니다.

- rare / `anxious_r001`-`anxious_r002` `anxious_r004`-`anxious_r005` `anxious_r009`-`anxious_r010` `anxious_r012` `anxious_r015`-`anxious_r016` `anxious_r019`-`anxious_r021` `anxious_r028` `anxious_r030` `anxious_r037` `anxious_r040`-`anxious_r041` `anxious_r046` `anxious_r048` `anxious_r054` `anxious_r058` `anxious_r060`-`anxious_r061` `anxious_r063`-`anxious_r064` `anxious_r066` `anxious_r069` `anxious_r072`-`anxious_r073` `anxious_r077` `anxious_r081` `anxious_r088` `anxious_r091`-`anxious_r092`
- rare / `anxious_r001`: "不安といても大丈夫な私"
- rare / `anxious_r002`: "この瞬間守った呼吸だよ"
- rare / `anxious_r004`: "思考から一歩引いた知恵"
- rare / `anxious_r005`: "体のサインに耳傾けた"

#### rare / 같은 계열 / 54개

자기 돌봄, 호흡 성공, 기다리는 성과의 동질적 반복입니다.

- rare / `anxious_r003` `anxious_r011` `anxious_r015`-`anxious_r016` `anxious_r029` `anxious_r040` `anxious_r048` `anxious_r052` `anxious_r062` `anxious_r068` `anxious_r071`-`anxious_r072` `anxious_r078` `anxious_r086` | `anxious_r002` `anxious_r009` `anxious_r012` `anxious_r020` `anxious_r022` `anxious_r025` `anxious_r033` `anxious_r038`-`anxious_r039` `anxious_r047` `anxious_r055` `anxious_r064` `anxious_r067` `anxious_r074` `anxious_r079` `anxious_r084`-`anxious_r085` `anxious_r090` | `anxious_r006`-`anxious_r007` `anxious_r013` `anxious_r018` `anxious_r021` `anxious_r028` `anxious_r030` `anxious_r035`-`anxious_r036` `anxious_r044` `anxious_r049` `anxious_r053` `anxious_r056`-`anxious_r057` `anxious_r059` `anxious_r070` `anxious_r073` `anxious_r075` `anxious_r082` `anxious_r087` `anxious_r092`-`anxious_r093`
- rare / `anxious_r003`: "揺れても自分いたわった"
- rare / `anxious_r011`: "自分責めなかった今日"
- rare / `anxious_r015`: "自分の味方で待ってたね"
- rare / `anxious_r016`: "やさしい目で自分見た日"
