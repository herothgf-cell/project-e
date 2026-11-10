# Project E — 아스트라 수로 전장

Godot 4.7.2 Standard로 만드는 독립 실행형 PC AOS다. **V9 · 0.9.0**은 8명의 판타지 영웅 중 한 명을 선택해 사람 1명과 봇 5명이 싸우는 오프라인 3 대 3 프로토타입이다. 아군 하단·적군 상단의 세로 전장에서 좌·중·우 라인을 따라 성장하고 포탑과 상대 핵을 파괴한다. 기지에서 출발하는 봇은 돌파한 라인에 최대 2명까지 합류한다.

## 게임허브

| 찾는 내용 | 바로가기 |
|---|---|
| 전체 기획과 제작 자료 | [Project E 게임허브](doc/design/README.md) |
| 현재 게임 콘텐츠별 상세 기획 | [경기·맵·전투·AI·성장·경제·로스터·UI·아트·플레이테스트](doc/design/content/README.md) |
| 시티 오브 템페스트 역기획 | [원작 규칙·성장 수치·경제·아이템·전술·출처](doc/design/reverse-design/README.md) |
| 8명 영웅의 기술 수치와 대응 | [캐릭터 시트](doc/design/characters/README.md) |
| 이번 구현과 수행한 검증 | [V9 세로 전장·공성](doc/design/30-v9-vertical-siege.md) · [검증 기록](doc/design/verification/2026-11-10-v9-verification.md) |

## 8명 선택과 전투

| 영웅 | 역할 | 핵심 행동 |
|---|---|---|
| 바스 | 룬 건틀릿 전사 | 진입, 룬 축적과 보호막 |
| 리오 | 별빛 원반 마법사 | 왕복 혜성, 닻과 귀환 경로 |
| 네마 | 숲의 결계술사 | 정령목 설치와 연결 제어 |
| 오린 | 바람의 사수 | 준비형 사격과 강화 기본공격 |
| 테르 | 수정 방패 수호자 | 뒤편 보호와 후퇴 반격 |
| 무아 | 물결의 화가 | 두 구역의 활성 전환과 지원 |
| 세라 | 월영 쌍검사 | 근접 진입, 표식 축적과 소비 |
| 루메 | 잿불 연금술사 | 잔열 강화와 지연 다회 포격 |

패시브 8개와 QWER 32개를 선택 화면, HUD, 실제 전투와 F7 연출실에 연결했다. 신규 5명은 개별 장비와 관절을 갖춘 모델, 실제 모델 렌더 초상, 기술 아이콘과 효과를 사용한다. 신규 능력치와 기술 수치는 V8 실험값이며 역할별 학습과 대응을 시험한다. [영웅별 전체 기술표](doc/design/characters/README.md)

선택한 영웅은 중앙 라인에서 시작한다. 팀당 3명을 자동 편성하며 선택한 신규 영웅에 따라 상대 조합을 달리한다. 기술 체험은 레벨 3과 R 해금 상태로 시작하고, 일반 경기는 레벨 1에서 성장한다. [편성표와 조합 시험](doc/design/content/07-roster-and-drafting.md)

## 실행

1. Godot 4.7.2 Standard에서 `game/project-e/project.godot`를 가져온다.
2. 자산 가져오기가 끝나면 F5로 실행한다.
3. 8명 중 한 명을 선택하고 일반 경기 또는 기술 체험으로 시작한다.
4. F7을 열어 영웅별 동작과 QWER를 재생할 수 있다.

Windows 배포본은 `.exe`와 `.pck`를 같은 폴더에 둔다. 빌드별 다운로드와 실제 실행 결과는 검증 기록에서 확인한다. [V9 빌드·검증](doc/design/verification/2026-11-10-v9-verification.md)

| 입력 | 동작 |
|---|---|
| 우클릭 | 이동 또는 대상 공격 |
| A → 좌클릭 | 공격 이동 |
| Q/W/E/R → 좌클릭 | 스킬 선택과 조준 확정 |
| Esc / S | 조준 취소 / 정지 |
| G / B | 성장 패널 / 기지로 걷기 복귀 |
| P / D | 상점 / 선택한 소모품 사용 |
| F1 | 경기 도움말 |
| F6 / F7 | 전장 보기 / 독립 연출실 |
| Y / Space | 카메라 추적 전환 / 조작 영웅으로 초점 이동 |
| 마우스 휠 / 가운데 버튼 드래그 | 확대·축소 / 카메라 이동 |

경기는 영웅 추적 카메라로 시작한다. 마우스를 화면 내부에서 가장자리로 새로 이동하거나 가운데 버튼으로 드래그하면 자유 시점으로 전환한다. 가장자리 32픽셀에서 속도가 점차 커지며 네 방향에 같은 규칙을 적용한다. [UI·카메라 상세](doc/design/content/08-ui-and-camera.md)

## 성장과 아이템

레벨은 XP로, 영구 능력치와 R은 성장 포인트로, 전투 중 회복 아이템은 골드로 관리한다. 골드는 기지 복귀와 한정된 인벤토리 안에서 이번 교전의 회복량을 선택하게 한다. 수입·소비 계산, 원작과의 수치 비교, 골드가 과도하게 쌓이는 경우의 시험 조건을 별도 기획에 정리했다. [성장](doc/design/content/05-growth.md) · [골드와 아이템](doc/design/content/06-gold-and-items.md)

별샘 영약은 마나 40을 2초 동안, 숲빛 치유약은 체력 200을 4초 동안 회복한다. 치유약은 적 영웅의 유효 피해를 받으면 회복이 중단된다. 두 아이템은 사용 대기시간 12초를 공유한다.

## 제작과 자동 확인

신규 5명 모델과 20개 아이콘을 재생성할 수 있다. 기존 모델과 환경의 제작·재현 방법은 V5 안내에 있다. [V8 자산 재현](doc/design/28-eight-hero-prototype.md#자산-재현) · [V5 모델과 전장](doc/design/25-illustrated-canal.md)

저장소 루트에서 실행한다.

```sh
python tools/check_godot.py --godot /absolute/path/to/godot
python tools/check_art_assets.py
python tools/check_audio_assets.py
python -m unittest discover -s tools/tests -p 'test_package_windows.py'
```

검증 도구는 자산 가져오기, 전투·전장·입력 행동 검사, 시작 장면과 배포 규칙을 확인한다. 실제 배포 PCK의 화면·포인터 검사와 Windows 실행 결과는 같은 버전의 검증 기록에 연결한다. 사람 플레이의 체감·밸런스와 GPU별 성능은 플레이테스트 양식에 따라 관측한다. [V9 검증](doc/design/verification/2026-11-10-v9-verification.md) · [플레이테스트](doc/design/content/10-playtest-and-balance.md)

자연 봇 경기의 공성 시간을 재측정하려면 `tools/measure_siege.gd`를 사용한다. 전투 결정을 바꾸지 않는 관측기로, 실제 핵 파괴 또는 지정한 관측 상한까지 기록한다. 실행 예와 통제 조건은 [V9 검증](doc/design/verification/2026-11-10-v9-verification.md)에 있다.
