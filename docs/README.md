# 기획 문서 목차

- 버전: v0.1
- 작성일: 2026-10-21, Asia/Seoul
- 상태: 구현 착수 전 검토용 기획. 사용자 확정 요구와 제안값은 각 문서에서 구분한다.

## 읽기 순서와 문서의 책임

| 순서 | 문서 | 이 문서가 결정하는 것 |
|---|---|---|
| 1 | [00 프로젝트 개요](00-project-brief.md) | 목표, 핵심 재미, 고유한 정체성, 초기 제작 범위 |
| 2 | [01 공통 규칙](01-core-rules.md) | 전투·성장·경기·경제의 공통 정의와 초기 수치 |
| 3 | [02 개발 로드맵](02-development-roadmap.md) | 단계, 선행 조건, 산출물, 검증 및 중단/재설계 기준 |
| 4 | [03 콘텐츠 매트릭스](03-content-matrix.md) | 요소별 제작량, 우선순위, 의존 관계, 완료 조건 |
| 5 | [04 플레이테스트](04-playtest-and-balance.md) | 재미·정체성·온라인·성능을 어떻게 검증할지 |
| 6 | [05 결정과 출처](05-decisions-and-sources.md) | 사용자 요구, 작업 가정, 후속 결정, 근거 자료 |

## 콘텐츠

| 문서 | 주요 내용 |
|---|---|
| [세계관과 표현](content/01-world-and-presentation.md) | 공방 연맹, 경기의 이유, 모델·재질·색·소리·연출 기준 |
| [맵과 목표물](content/02-arena-and-objectives.md) | 수로 공방의 동선, 시야, 공성, 지원 경로, 전장 오브젝트 |
| [M01 좌표 배치도](content/arena-m01.svg) | 세 라인·연결로·탑·핵·셀·차단체의 정확한 배치 |
| [미니언과 경제](content/03-minions-and-economy.md) | 웨이브, 파밍, 경험치, 크레딧, 소모품, 보상 사례 |
| [모드와 UI](content/04-modes-onboarding-and-ui.md) | 메뉴부터 경기 결과까지, 튜토리얼, 봇, 접근성 |

## 캐릭터

| ID | 문서 | 제작 단계 |
|---|---|---|
| 공통 | [캐릭터 설계 및 역할표](characters/README.md) | M0부터 적용 |
| C01 | [바스](characters/01-bas.md) | M1 전투 검증부터 |
| C02 | [리오](characters/02-rio.md) | M2 |
| C03 | [네마](characters/03-nema.md) | M2 |
| C04–C06 | [추가 영웅 후보](characters/04-roster-expansion.md) | M3 결과를 보고 M4에서 착수 여부 결정 |

## 기술과 출시

| 문서 | 주요 내용 |
|---|---|
| [Unity와 Steam](technical/01-unity-and-steam.md) | 엔진 선택, LTS/패키지 고정, PC 빌드, 라이선스 확인 |
| [구조와 네트워크](technical/02-architecture-and-networking.md) | 게임 판정, 데이터 구조, 온라인 검증, 클라이언트/서버 경계 |
| [Steam 출시 계획](release/01-steam-release-plan.md) | Playtest, 스토어/빌드 검토, 운영과 공개 매칭 판단 |

## 정본과 수정 규칙

1. 사용자의 확정 요구는 [개요](00-project-brief.md)와 [결정 이력](05-decisions-and-sources.md)에 기록한다.
2. 공통 숫자와 판정은 [공통 규칙](01-core-rules.md)이 정본이다. 캐릭터 문서는 그 영웅의 예외만 추가한다.
3. 맵 좌표·길이는 [맵 문서](content/02-arena-and-objectives.md), 개별 기술은 해당 캐릭터 문서가 상세 정본이다.
4. 모든 초기 수치는 테스트 가설이다. 변경 이유와 관측 결과를 기록하며 동시에 연관 문서를 고친다.
5. 기술 선택은 공식 문서의 확인 날짜를 남긴다. 출시 직전 정책·요금·플랫폼 요구 사항을 다시 확인한다.
6. M0–M6 단계의 완료 여부는 산출물과 실제 검증 결과로 갱신한다. 현재는 문서 작성만 완료되었다.

## 구현 담당자에게

[개요](00-project-brief.md) → [공통 규칙](01-core-rules.md) → [현재 단계](02-development-roadmap.md) → 담당 콘텐츠/캐릭터 문서 → [기술 구조](technical/02-architecture-and-networking.md) 순으로 읽는다. 한 번에 현재 단계의 통과 조건을 만족시키는 범위만 구현한다. 파밍·합류·공성의 재미와 신규 영웅의 고유한 대응법을 둘 다 확인한다.
