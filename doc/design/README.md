# Project E 게임허브

기준은 **V8 · 0.8.0 · 2026-11-09**다. 8명의 판타지 영웅 중 한 명을 선택해 사람 1명과 봇 5명이 3 대 3으로 싸운다. 세 라인의 성장, 측면 셀, 인접 라인 지원, 병력 동반 공성과 핵 파괴가 경기의 흐름을 만든다.

## 바로가기

| 목적 | 문서 |
|---|---|
| 원작 세로형 맵, 미니언 밸런스와 긴 공성의 재검토 | [2026-11-10 영상·코드·실측 검토](29-cot-map-minion-siege-review.md) |
| 현재 게임의 콘텐츠별 상세 기획 | [콘텐츠 10편](content/README.md) |
| 시티 오브 템페스트의 규칙과 설계 해석 | [원작 역기획서](reverse-design/README.md) |
| 8명 영웅의 역할과 정확한 기술 수치 | [캐릭터 시트](characters/README.md) |
| 이번 프로토타입의 구현 범위와 실행 | [V8 8인 프로토타입](28-eight-hero-prototype.md) |
| 수행한 검사와 배포 화면 | [V8 검증 기록](verification/2026-11-09-v8-verification.md) |
| 8명 선택, 신규 모델과 기술의 실행 화면 | [V8 화면 모음](assets/v8/README.md) |
| 설치·조작·자동 확인 명령 | [저장소 시작 안내](../../README.md) |

## 현재 게임 콘텐츠 상세 기획

각 문서는 목적, 플레이 흐름, 실행 수치, 상태와 예외, 화면 피드백, 검증 기준을 함께 담는다. 현재 동작은 연결된 소스와 대조했으며 후속 실험에는 실험 조건과 관찰 항목을 적었다.

| 문서 | 주요 내용 |
|---|---|
| [01 경기 흐름과 승패](content/01-match-flow.md) | 시작, 공성 단계, 사망·부활, 승패와 재시작 |
| [02 전장과 시야](content/02-map-and-vision.md) | M01 좌표, 세 라인, 고지, 셀과 정보 공개 |
| [03 전투와 상태](content/03-combat-and-status.md) | 시전 승인, 피해와 보호막, 제어, 취소와 다회 타격 |
| [04 병력과 AI](content/04-units-and-ai.md) | 웨이브, 막타 유보, 포탑 어그로, 봇 판단 |
| [05 성장](content/05-growth.md) | XP 곡선, 포인트, 투자 증가량과 상한, 원작 비교 |
| [06 골드와 아이템](content/06-gold-and-items.md) | 골드의 역할, 수입과 지출, 두 회복 아이템, 경제 실험 |
| [07 로스터와 편성](content/07-roster-and-drafting.md) | 8명 역할, 시작 능력치, 자동 3인 편성, 조합 시험 |
| [08 UI와 카메라](content/08-ui-and-camera.md) | 선택, HUD, 입력, 추적·가장자리 이동, F7 |
| [09 미술과 음향](content/09-art-and-audio.md) | 실루엣, 모델·아이콘, 경고와 효과, 상태와 소리 |
| [10 플레이테스트와 밸런스](content/10-playtest-and-balance.md) | 영웅별 과제, 경기 기록표, 비교 조건과 조정 기준 |

## 시티 오브 템페스트 역기획

사용자 PDF, 웹 각주, 당시 공략과 시각 자료를 확인했다. 2026-11-10에는 지정 영상의 143개 정지 표본과 2011년 게임 스크린샷을 검토해 상하 진영과 세로 진행축을 보완했다. 출처마다 작성 시점과 확인 범위를 기록했다. 방어 투자 상한처럼 버전이 다른 수치는 근거표에서 비교할 수 있다. 원작의 정확한 XP 곡선·상품 가격·가스 사용처처럼 추가 자료가 필요한 항목도 해당 문서에 남겼다.

| 문서 | 주요 내용 |
|---|---|
| [01 경기와 전장](reverse-design/01-match-and-map.md) | 라인 대치, 측면 성장, 중앙 합류, 언덕과 공성 |
| [02 전투와 조작](reverse-design/02-combat-and-controls.md) | 짧은 재사용, 마나·포션, 광역 공격과 대응 |
| [03 성장과 경제](reverse-design/03-growth-and-economy.md) | 광물, 지표별 체력·이동속도, 투자 효과와 상한 |
| [04 병력·공성·아이템](reverse-design/04-units-siege-and-items.md) | 가스 보상, 마무리 제한, 경험치 목표와 소모품 |
| [05 영웅과 플레이 패턴](reverse-design/05-heroes-and-play-patterns.md) | 대표 영웅의 성향, 투자와 교전, 현재 8명 역할 연결 |
| [06 근거와 확인 과제](reverse-design/06-evidence-and-open-questions.md) | PDF 쪽수, 출처 목록, 버전 충돌과 후속 관찰 양식 |

## 8명 영웅

| 영웅 | 역할 | 핵심 선택 | 상세 시트 |
|---|---|---|---|
| 바스 | 룬 건틀릿 전사 | 짧은 진입과 룬 보호막 | [C01](characters/01-bas.md) |
| 리오 | 별빛 원반 마법사 | 원반 출발·귀환 경로와 닻 | [C02](characters/02-rio.md) |
| 네마 | 숲의 결계술사 | 정령목 두 그루와 연결선 | [C03](characters/03-nema.md) |
| 오린 | 바람의 사수 | 준비형 사격과 다음 기본공격 | [C04](characters/04-orin.md) |
| 테르 | 수정 방패 수호자 | 뒤편 아군 보호와 후퇴 반격 | [C05](characters/05-tere.md) |
| 무아 | 물결의 화가 | 두 구역 중 하나를 활성화 | [C06](characters/06-mua.md) |
| 세라 | 월영 쌍검사 | 접근, 표식 축적과 소비 | [C07](characters/07-sera.md) |
| 루메 | 잿불 연금술사 | 잔열 관리와 지연 다회 포격 | [C08](characters/08-lume.md) |

각 영웅은 패시브 1개와 QWER 4개를 가진다. 선택 풀은 총 8명이며 경기 인원은 팀당 3명이다. 일반 경기에서는 레벨 3부터 성장점 1개로 R을 해금하고, 기술 체험은 레벨 3과 R 해금 상태로 시작한다. 신규 5명의 수치는 V8 플레이테스트용 실험값이다.

## 제작 자료와 이력

| 단계 | 문서 |
|---|---|
| V8 | [8인 프로토타입](28-eight-hero-prototype.md), [검증](verification/2026-11-09-v8-verification.md) |
| V7 | [판타지 스킬·아이템](27-fantasy-skills-v7.md), [검증](verification/2026-11-06-v7-verification.md) |
| V6 | [PDF 적용 근거](26-cot-reference-v6.md), [선택·카메라 검증](verification/2026-11-06-v6-verification.md) |
| V5 | [수로 전장 제작·재현](25-illustrated-canal.md), [모델 재현 기록](verification/2026-11-06-v5-model-reproduction.md), [실제 화면](assets/v5/README.md) |
| V4 | [전투 표현](23-fantasy-v4-combat-presentation.md), [자산 안내](24-fantasy-v4-asset-guide.md) |
| V3 | [판타지 아트 명세](21-fantasy-v3-art-spec.md), [자산 가이드](22-fantasy-v3-asset-guide.md) |
| V2 | [통합 실행판](19-integrated-v2.md), [전달 기록](20-v2-delivery.md) |
| 초기 설계와 구현 | [초기 요소별 기획](01-match-loop.md), [초기 검증](09-verification.md), [장기 기술·출시 계획](../../docs/README.md) |

버전별 기록에는 당시의 구현과 검사 조건을 보존한다. 현재 기능과 수치는 이 허브의 콘텐츠 상세 기획, 영웅 시트, V8 검증 기록을 함께 확인한다. 사람 플레이의 체감·밸런스와 하드웨어별 성능은 해당 빌드의 실제 관측값을 기록한다.
