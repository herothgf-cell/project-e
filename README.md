# Project E

**빠른 스킬 교전, 경기 중 성장 선택, 세 라인 사이의 지원 판단을 중심으로 하는 독립 PC용 3대3 액션 AOS.** Steam 출시를 목표로 기획한다.

시티 오브 템페스트에서 참고한 재미의 구조를 바탕으로, 영웅의 기술 조합·맵 공방·세계관·시청각 표현은 새롭게 설계한다. 특정 원작 영웅이나 맵을 일대일로 옮기는 프로젝트가 아니다.

## 현재 상태

| 항목 | 상태 |
|---|---|
| 문서 버전 | Godot 기반 v0.2 · 2026-10-22 |
| 확정된 사용자 요구 | 독립 PC 게임, Steam 출시 목표, 참고작의 핵심 게임성 유지, 고유한 작품 정체성, Godot 사용 |
| 기술 설계 기준 | **Godot 4.7.2 Standard + GDScript**, 초기 Compatibility, Windows x86_64 우선 |
| 첫 3대3 검증 범위(M2) | 신규 영웅 3종, 맵 1개, 경기 중 성장, 3대3 공성, 기본 온라인 대전 |
| 출시 후보 범위 | 영웅 6종, 주력 맵 1개, 연습/튜토리얼/봇/비공개 대전; 공개 매칭은 검증 후 결정 |
| 구현 상태 | **Godot 프로젝트와 오프라인 이동·E 조작 진단 장면 작성. 전체 전투·3대3·온라인은 후속 단계.** |

문서의 이름, 세계관, 수치, 목표 시간, 제작량은 검증을 위한 제안이다. 엔진은 `.godot-version`에 고정했다. Linux headless에서 규칙·장면 검증을 수행했으며 Windows 실행·화면·인터넷 지연 검증은 남아 있다. [기술 선택](docs/technical/01-godot-and-steam.md)과 [실제 검증 기록](docs/technical/03-godot-quickstart.md)을 참조한다.

## 바로 실행하기

1. [Godot 공식 다운로드](https://godotengine.org/download/windows/)에서 **4.7.2 Standard / Windows x86_64**를 준비한다. `.NET` 버전은 필요하지 않다. 최신 기본 다운로드가 달라졌으면 [버전 보관함](https://godotengine.org/download/archive/4.7.2-stable/)에서 4.7.2를 고른다.
2. 저장소를 내려받고 Godot 프로젝트 관리자에서 **Import**를 누른다.
3. [`game/project-e/project.godot`](game/project-e/project.godot)을 선택해 연다.
4. **F6**으로 현재 장면을 실행하거나 **F5**로 프로젝트를 실행한다. 처음 열 때는 F5를 권장한다.

| 입력 | 진단 장면 동작 |
|---|---|
| 마우스 우클릭 | 클릭한 바닥으로 이동 |
| E → 마우스 좌클릭 | 조준 방향으로 바스 E 돌진 |
| Esc | 확정 전 E 조준 취소 |
| S | 일반 이동 정지 |
| F2 | 위치·에너지·쿨다운 초기화 |

중앙 벽은 돌진을 막는다. 벽을 돌아가는 자동 경로 탐색은 아직 없으므로 통로를 직접 클릭한다. E의 영웅 충돌 피해·넉백, Q/W/R·기본 공격·성장·온라인은 아직 구현하지 않았다. 현재 영어 HUD와 도형 캐릭터는 조작 진단용이다.

설치·실행·검증·Windows export의 자세한 순서는 [Godot 빠른 시작](docs/technical/03-godot-quickstart.md)에 있다.

## 처음 읽을 문서

1. [프로젝트 개요와 설계 원칙](docs/00-project-brief.md)
2. [공통 전투·성장·승리 규칙](docs/01-core-rules.md)
3. [개발 로드맵과 단계별 통과 기준](docs/02-development-roadmap.md)
4. [콘텐츠 제작 범위와 의존 관계](docs/03-content-matrix.md)
5. [캐릭터 목록과 설계 기준](docs/characters/README.md)
6. [전체 문서 목차](docs/README.md)

## 상세 기획 바로가기

| 분야 | 문서 |
|---|---|
| 세계관·그래픽·사운드 | [공방 연맹과 표현 방향](docs/content/01-world-and-presentation.md) |
| 맵·시야·공성 | [M01 수로 공방](docs/content/02-arena-and-objectives.md) |
| 병력·경제·오브젝트 | [미니언, 경험치 셀, 소모품](docs/content/03-minions-and-economy.md) |
| 모드·튜토리얼·UI | [사용자 흐름과 학습 설계](docs/content/04-modes-onboarding-and-ui.md) |
| 최초 영웅 | [바스](docs/characters/01-bas.md) · [리오](docs/characters/02-rio.md) · [네마](docs/characters/03-nema.md) |
| 출시 후보 영웅 | [추가 3종의 확장 조건](docs/characters/04-roster-expansion.md) |
| 엔진·구조·온라인 | [Godot/Steam](docs/technical/01-godot-and-steam.md) · [아키텍처/네트워크](docs/technical/02-architecture-and-networking.md) |
| 실행·현재 검증 | [Godot 빠른 시작](docs/technical/03-godot-quickstart.md) · [이번 작업 범위](docs/plans/2026-10-22-godot-foundation.md) |
| 검증 | [플레이테스트와 밸런스](docs/04-playtest-and-balance.md) |
| 출시 | [Steam 출시 준비](docs/release/01-steam-release-plan.md) |
| 결정 이력·출처 | [확정 사항, 제안, 후속 결정](docs/05-decisions-and-sources.md) |

## 다음 개발 작업

다음 작업은 [로드맵 M0–M1](docs/02-development-roadmap.md)의 남은 Windows export·실행 확인과 바스 전투 확장이다. 이어서 영웅 1종과 두 클라이언트의 서버 권위·지연 환경을 검증한 뒤 실제 3라인·3대3 한 판을 구성한다. 일정은 첫 구현의 실측 속도와 담당 인원을 기준으로 갱신한다.

문서 간 수치 충돌은 [공통 규칙](docs/01-core-rules.md)을 우선한다. 영웅별 예외는 각 영웅 문서에 명시해야 하며, 수정 시 관련 문서와 검증 기준을 함께 갱신한다.
