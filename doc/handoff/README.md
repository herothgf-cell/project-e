# Project E 작업 인계 · 처음 읽을 문서

- 정리일: **2026-11-19, 한국 시간**
- 제품: **Project E — 아스트라 수로 전장**. 공개 출시명 확정과는 구분한다.
- 확인한 소스: [main / e29c362](https://github.com/herothgf-cell/project-e/tree/e29c36296abf6d365353401dd0cbee411edc531d), 2026-11-10 병합, **V9 · 0.9.0**.
- 추가 반영한 문서 기준: [055c513](https://github.com/herothgf-cell/project-e/tree/055c5134bf353a2e7c91cba1c23e6564aa1d1229)의 2026-11-19 신규 아트 방향. 이 후속 변경은 문서이며 게임 코드 변경은 아니다.
- 목적: 다른 PC, 개발자 또는 AI가 기존 결정을 잃지 않고 작업을 이어가게 한다.
- 이번 작업: 기존 문서·코드·검증 자료를 읽어 재분류했다. **게임 기능이나 수치를 변경하지 않았으며 게임 테스트를 새로 실행하지 않았다.**

## 1. 현재 프로젝트를 한 문장으로

**세로로 이어진 세 라인에서 빠른 스킬 교전, 경기 중 능력치 투자, 옆 라인 지원과 병력 동반 공성을 거쳐 상대 핵을 파괴하는 독립 PC AOS.**

현재 실행물은 **8명 중 1명을 선택하는 사람 1명 + 봇 5명의 오프라인 3대3 프로토타입**이다. 8명은 선택 가능한 전체 로스터다. 한 경기 8인전이나 온라인 3대3을 뜻하지 않는다. Godot 4.7.2 Standard를 사용한다. [현재 실행 안내](../../README.md)

## 2. 다른 환경에서 가장 빨리 시작하는 순서

| 순서 | 읽거나 할 일 | 얻는 것 |
|---|---|---|
| 1 | [요구와 결정](01-product-and-decisions.md) | 유지할 게임성, 그래픽 방향, 확정 범위 |
| 2 | [현재 상태와 미해결 항목](02-status-and-open-work.md) | 구현·기존 검사·사용자 검토의 차이 |
| 3 | [환경과 빌드](06-environment-build.md) | 소스 확보, Godot 열기, F5, 검증·패키징 |
| 4 | [요소별 기획](#4-요소별-기획-바로가기) | 담당 시스템의 규칙과 수정 지점 |
| 5 | [다음 작업 순서](03-next-actions.md) | 선행 조건과 완료 판정이 있는 작업 목록 |
| 6 | [AI 인계 프롬프트](04-ai-handoff-prompt.md) | 다른 AI에 그대로 전달할 작업 시작 지시 |
| 필요 시 | [문서 지도](05-document-map.md), [코드·에셋 지도](07-code-assets.md) | 상세 수치, 원본 자료, 구현 파일 찾기 |

문서만 받은 경우 실행 소스와 모델은 별도로 확보해야 한다. 소스 저장소는 [herothgf-cell/project-e](https://github.com/herothgf-cell/project-e)다. 인계 당시 상태를 재현하려면 위 고정 커밋을 사용하고, 개발을 이어갈 때는 최신 변경과 비교해 작업 기준 커밋을 새로 기록한다.

## 3. 문서의 상태 표시

| 표시 | 이 문서에서 뜻하는 범위 |
|---|---|
| 현재 코드 확인 | 위 기준 소스에서 로직·설정·자산 연결을 읽어 확인 |
| 기존 검증 기록 | 저장소에 남은 과거 실행·실험·화면 검증 결과 |
| 사용자 요구 | 대화 또는 저장소 결정 기록에서 확인한 목표와 피드백 |
| 후속 제안 | 앞으로의 작업 순서·실험·판정 방법 제안, 구현 완료가 아님 |
| 미확인 | 이번 자료만으로 판단할 수 없거나 아직 실제 검증이 없는 항목 |

현재 코드 확인만으로 품질·재미·균형이 승인되지는 않는다. 과거 검증 결과는 그때의 코드, 환경, 편성에만 적용한다.

## 4. 요소별 기획 바로가기

| 요소 | 인계용 요약 | 기존 상세 정본 |
|---|---|---|
| 경기 흐름·승패 | [01 경기](elements/01-match.md) | [경기 흐름](../design/content/01-match-flow.md) |
| 전장·라인·시야·고지 | [02 전장](elements/02-map-vision.md) | [전장과 시야](../design/content/02-map-and-vision.md) |
| 기본공격·스킬·상태 | [03 전투](elements/03-combat.md) | [전투와 상태](../design/content/03-combat-and-status.md) |
| 미니언·AI·포탑·핵 공성 | [04 병력과 공성](elements/04-minions-ai-siege.md) | [병력과 AI](../design/content/04-units-and-ai.md) |
| XP·레벨·능력치 투자 | [05 성장](elements/05-growth.md) | [성장](../design/content/05-growth.md) |
| 골드·상점·소모품 | [06 경제](elements/06-gold-items.md) | [골드와 아이템](../design/content/06-gold-and-items.md) |
| 8영웅·기술·편성 | [07 캐릭터](elements/07-heroes.md) | [캐릭터 8장](../design/characters/README.md) |
| 조작·HUD·카메라 | [08 UI와 카메라](elements/08-ui-camera.md) | [UI와 카메라](../design/content/08-ui-and-camera.md) |
| 캐릭터·맵 아트·VFX·음향 | [09 아트와 음향](elements/09-art-audio.md) | [미술과 음향](../design/content/09-art-and-audio.md) |
| 밸런스·검증·플레이테스트 | [10 검증](elements/10-balance-tests.md) | [플레이테스트](../design/content/10-playtest-and-balance.md) |
| 온라인·Steam·제품화 | [11 장기 개발](elements/11-online-steam.md) | [기술](../../docs/technical/02-architecture-and-networking.md), [출시](../../docs/release/01-steam-release-plan.md) |

요약에는 목적, 현재 규칙과 주요 수치, 예외, 수정할 소스, 후속 과제와 완료 판정을 넣었다. 8영웅의 전체 수치표와 원작 분석은 기존 문서를 유지해 연결한다.

같은 날 추가된 [D 혼합형 8영웅 아트 디렉션](../design/31-subculture-fantasy-hero-art-direction.md)도 포함했다. 인게임 3~3.5등신과 선택·키아트 6~7등신을 분리하는 **신규 제작 제안**이며 현재 모델에 적용된 상태는 아니다.

## 5. 이전 피드백을 이어받을 때

| 사용자 피드백 | V9에서 확인되는 것 | 이어서 확인할 것 |
|---|---|---|
| “좌우가 아니라 세로였던 것 같다” | 화면과 미니맵은 아군 하단·적군 상단, 좌·중·우 라인 | 사용자가 기억한 동선·시점·공성 입구의 체감 |
| “공성 구간이 너무 길다” | 기지 출발 봇의 열린 라인 합류를 적용한 기존 기록 | 조합별 차이, 핵 피해 공백, 재정비·역전 기회 |
| “미니언 밸런싱” | 현재 수치와 1 HP 유보를 분석, V9 수치 유지 | 잔존 병력, 공성병 체력·도달률·공성 기여 |
| “카메라 움직임이 부자연스럽다” | 추적·해제·가장자리 이동·드래그 로직 및 과거 검사 | 실제 Windows 마우스 조작과 전투 중 가독성 |
| “시안 대비 퀄리티가 낮다” | 모델·텍스처·아이콘·연출과 실제 PCK 캡처 존재 | 얼굴·장비·동작·지형 밀도에 대한 사용자 수용 |

세부 근거와 원작 확인의 한계는 [상태표](02-status-and-open-work.md), [원작 근거 등록부](../design/reverse-design/06-evidence-and-open-questions.md)를 따른다.

## 6. 앞으로 문서를 고치는 방법

현재 동작은 해당 커밋의 소스와 실제 실행으로 판정한다. 목표는 최신 사용자 요구와 채택된 기획으로 판단한다. 두 내용이 다르면 차이를 기록하고 수정 범위를 정한다. 과거 문서의 오래된 값을 현재 규칙으로 되돌리지 않는다.

[문서 지도와 우선순위](05-document-map.md) · [요소 기획 템플릿](templates/feature-spec.md) · [플레이테스트 기록 템플릿](templates/playtest-record.md)

[이번 인계 문서의 확인 범위](08-handoff-verification.md)
