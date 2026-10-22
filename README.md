# Project E

**빠른 스킬 교전, 경기 중 성장 선택, 세 라인 사이의 지원 판단을 중심으로 하는 독립 PC용 3대3 액션 AOS.** Steam 출시를 목표로 기획한다.

시티 오브 템페스트에서 참고한 재미의 구조를 바탕으로, 영웅의 기술 조합·맵 공방·세계관·시청각 표현은 새롭게 설계한다. 특정 원작 영웅이나 맵을 일대일로 옮기는 프로젝트가 아니다.

## 현재 상태

| 항목 | 상태 |
|---|---|
| 문서 버전 | 기획 v0.1 · 2026-10-21 |
| 확정된 사용자 요구 | 독립 PC 게임, Steam 출시 목표, 참고작의 핵심 게임성 유지, 고유한 작품 정체성 |
| 기술 설계 기준 | Unity 6.3 LTS 계열 + C# + URP, Windows x64 우선 제안 |
| 첫 3대3 검증 범위(M2) | 신규 영웅 3종, 맵 1개, 경기 중 성장, 3대3 공성, 기본 온라인 대전 |
| 출시 후보 범위 | 영웅 6종, 주력 맵 1개, 연습/튜토리얼/봇/비공개 대전; 공개 매칭은 검증 후 결정 |
| 구현 상태 | **기획 문서만 작성됨. Unity 프로젝트·게임 코드·실행 빌드는 아직 없음.** |

문서의 이름, 세계관, 수치, 목표 시간, 제작량은 검증을 위한 제안이다. 구현·성능·밸런스·출시가 완료되었다는 의미가 아니다. Unity 에디터의 정확한 패치는 M0에서 확인하고 고정한다. Steam은 특정 엔진 사용을 요구하지 않으며 Unity 채택 근거는 [기술 선택 문서](docs/technical/01-unity-and-steam.md)에 정리한다.

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
| 엔진·구조·온라인 | [Unity/Steam](docs/technical/01-unity-and-steam.md) · [아키텍처/네트워크](docs/technical/02-architecture-and-networking.md) |
| 검증 | [플레이테스트와 밸런스](docs/04-playtest-and-balance.md) |
| 출시 | [Steam 출시 준비](docs/release/01-steam-release-plan.md) |
| 결정 이력·출처 | [확정 사항, 제안, 후속 결정](docs/05-decisions-and-sources.md) |

## 다음 개발 작업

첫 구현은 [로드맵 M0–M1](docs/02-development-roadmap.md)의 범위로 시작한다. 에디터/패키지 버전을 고정하고, 영웅 1종의 전투와 두 클라이언트의 지연 환경을 검증한다. 이후 실제 3라인·3대3 한 판을 구성한다. 일정은 첫 구현의 실측 속도와 담당 인원을 기준으로 갱신한다.

문서 간 수치 충돌은 [공통 규칙](docs/01-core-rules.md)을 우선한다. 영웅별 예외는 각 영웅 문서에 명시해야 하며, 수정 시 관련 문서와 검증 기준을 함께 갱신한다.
