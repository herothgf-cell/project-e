# Project E — 수로 공방

**세 라인의 지원 판단, 짧은 스킬 교전, 경기 중 성장을 중심으로 하는 독립 PC용3대3 액션 AOS.** Godot로 개발하며 Steam 출시를 목표로 한다.

현재는 **바스·리오·네마 중 한 명을 조작하고 봇5명과 플레이하는 오프라인 프로토타입**이다. 병력 진격, 영웅 교전, XP 성장, 외곽탑→내곽탑→핵 파괴를 한 판으로 연결한다. 참고작의 게임성 관점은 연구하되 영웅·기술·맵·표현은 독립적으로 설계한다.

## 현재 상태

| 항목 | 내용 |
|---|---|
| 기준일 | **2026-10-29** · R29 경험치 피드백 구현·Godot 4.7.2 자동 검증 완료 |
| 엔진 | Godot4.7.2 Standard + GDScript, Compatibility,30Hz 로컬 권한 |
| 참가자 | 사람1명 + 아군 봇2명 + 상대 봇3명 |
| 전장 | M01 세 라인, 기존 연결로4개, 탑12개·핵2개 |
| 고저차 | 북서/남동40XP 고지2곳, 높이2.4m, 각 라인 복귀 경사+지원 경사 |
| 전투 | 평타, 세 영웅 패시브·Q/W/E/R, 보호막·CC·사망·부활 |
| 성장 | 20/30/40 XP 셀, 레벨·포인트·R 해금, 관측 중 셀 등장·실제 개인 지급·성장 안내·XP 막대 |
| 경제 | P 상점, 에너지 병·수리 패치, D 사용, 봇 구매/사용 |
| 조작·시야 | A 공격 이동, 팀 공유 시야, 전장/미니맵 음영, 시야원 표식 |
| 승패 | 외곽/내곽/핵 잠금, 병력 공성 보호, 핵 파괴·무승부·재시작 |
| 자동 검증 | Godot 4.7.2, **16묶음·3,633개 검사·실패 0**, 메인 장면 시작 PASS |

### R29 경험치 피드백

관측 중인 셀이 생성·재생성되면 짧은 등장 고리와 보상량을 표시한다. 획득 안내는 셀의 총 보상이 아니라 **본인에게 실제 지급된 XP**다. 40 XP를 두 명이 나누면 각각 +20, 세 명이면 내부적으로 40/3을 유지하고 화면만 `≈13.33`으로 표시한다.

레벨업은 도달 레벨·성장 포인트·G 투자와 조건부 R 해금 안내로 연결한다. 최고 레벨에 반영되지 않는 초과 XP는 표시하지 않는다. 숨겨진 셀의 생성 효과는 뒤늦게 시야를 확보해도 재생하지 않으며, 개인 보상 이벤트에 처치 대상의 위치를 담지 않는다. [구현·검증 상세](doc/design/17-xp-feedback-verification.md)

### R30의 새 동선

```text
북서 40XP (-18,24)
  ├─ 라인 복귀 → (-18,18)
  └─ 지원 회전 → (-12,18) → 서북 연결로 (-10,18)

남동 40XP (18,-24)
  ├─ 라인 복귀 → (18,-18)
  └─ 지원 회전 → (12,-18) → 동남 연결로 (10,-18)
```

네 경사는 폭3m이며180도 회전 대칭이다. 타워·XP·영웅·소모품 수치는 이번 작업에서 변경하지 않았다. 상세 규칙과 RED→GREEN 증거는 [R30 검증](doc/design/16-r30-high-ground-flow-verification.md)에 있다.

## 실행하기

### 소스에서 실행

1. **Godot4.7.2 Standard**를 준비한다. .NET 버전은 필요하지 않다.
2. 저장소의 최신 `main`을 받는다.
3. Godot 프로젝트 관리자에서 [game/project-e/project.godot](game/project-e/project.godot)을 Import한다.
4. 프로젝트를 연 뒤 **F5**를 누른다.
5. 바스·리오·네마를 선택한다. 모든 기술부터 확인하려면 **기술 체험**을 켠다.

일반 경기는 레벨1·성장2포인트로 시작한다. G로 투자하고 첫 병력과 함께 전진한다. R은 레벨3부터 성장1포인트로 해금한다. [빠른 시작](docs/technical/03-godot-quickstart.md)

### Windows ZIP 주의

현재 전달된 `ProjectE-windows-x86_64.zip`은 **소모품 단계의 `e56286a` 패키지**다. **R28/R30 고저차·지원 경사와 이번 R29 XP 피드백은 포함하지 않는다.** 최신 기능은 Godot 소스로 실행해야 한다. 이번 작업에서 Windows ZIP을 다시 제작하지 않았으며 실제 Windows PC 확인도 미실시다. [Windows 빌드 기록](docs/technical/04-windows-build.md)

## 조작

| 입력 | 동작 |
|---|---|
| 지면 우클릭 | 이동 |
| 보이는 적 우클릭 | 접근 후 기본 공격 |
| A → 지면 좌클릭 | 공격 이동; 교전 후 원래 목적지로 복귀 |
| Q/W/E/R → 좌클릭 | 조준 후 기술 확정 |
| Esc | 조준 취소 / 패널 닫기 / 일시정지 |
| S | 현재 이동·공격 명령 정지 |
| G | 성장 패널 |
| F1 | 조작·셀·시야·공성 도움말 |
| B | 자기 기지로 걸어가기 |
| P | 기지 상점 열기/닫기 |
| 소모품 칸 클릭 / D | 종류 선택 / 선택한 품목 사용 |
| 가운데 버튼 드래그 / 휠 / Space | 카메라 이동 / 확대·축소 / 영웅 복귀 |
| 미니맵 좌클릭 / 우클릭 | 카메라 이동 / 영웅 이동 |

## 세 영웅

| 영웅 | 핵심 플레이 | 기획 |
|---|---|---|
| 바스 | 압력을 쌓고 돌진·근거리 부채 공격·엄호로 전선을 연다 | [바스](doc/design/characters/01-bas.md) |
| 리오 | 왕복 원반과 회수점을 배치하고 이동으로 공격 경로를 바꾼다 | [리오](doc/design/characters/02-rio.md) |
| 네마 | 두 핀의 연결선으로 진입을 보호하고 구역을 제어한다 | [네마](doc/design/characters/03-nema.md) |

## 검증

R29 최종 게임 코드는 [Godot regression #35](https://github.com/herothgf-cell/project-e/actions/runs/40821728887)에서 통과했다.

- Godot `4.7.2.stable.official.ed1daf0bf`, Linux headless.
- 기존 14묶음 3,531개, 새 XP 피드백 88개, 실제 HUD 막대 14개.
- 전체 **16묶음, 3,633개 검사, 실패 0**.
- 프로젝트 import 및 메인 장면 90프레임 시작 PASS.
- 2/3인 분배·14m 경계·사망·레벨 상한·생성/재생성·시야 재획득·일시정지·재시작 확인.
- 720p/1080p 실제 장면의 컨트롤 경계·겹침·모달 순서를 자동 확인. 렌더 캡처와 사람 가독성 검수는 별도 미실시.

자동6봇 진단은431.8초에 서쪽 팀 승리로 종료됐다. 봇은 아직 XP 셀과 신규 경사를 전략적으로 선택하지 않으므로 이 기록은 R30 게임성 검증이 아니다. 과거 R30 검증은 [16번 문서](doc/design/16-r30-high-ground-flow-verification.md)에 보존한다.

```sh
python tools/check_godot.py --godot /actual/path/to/Godot_v4.7.2-stable
python tools/check_godot.py --godot /actual/path/to/Godot_v4.7.2-stable --long-match
```

## 문서

- [콘텐츠 설계 목차](doc/design/README.md)
- [M01 전장·고저차·지원 경사](doc/design/02-map-m01.md)
- [현재 남은 개발과 순서](doc/design/11-remaining-development.md)
- [시티 오브 템페스트 참고 관점과 독립 구현 방향](doc/design/14-tempest-reference-reprioritization.md)
- [R28 첫 고저차 검증](doc/design/15-high-ground-verification.md)
- [R30 고지 XP–지원로 검증](doc/design/16-r30-high-ground-flow-verification.md)
- [R29 XP 등장·개인 지급·레벨업 검증](doc/design/17-xp-feedback-verification.md)
- [로컬 사람 플레이 기록표](doc/design/12-local-playtest-record.md)
- [온라인 아키텍처](docs/technical/02-architecture-and-networking.md)
- [Steam 출시 계획](docs/release/01-steam-release-plan.md)

## 다음 우선순위

1. **R10 후속:** 봇의 핵/빈 라인 방어, 지원, 셀·핀 대응과 복귀.
2. **R31:** 명령 접수/예약/실패와 공격·시전·피격·CC 최소 표현.
3. **R32:** 사람 경기에서 고지→지원→공성의 합류 시간과 템포 비교.
4. 최신 Windows ZIP·실제 PC 확인과 작은2클라이언트 진단 병행.

R29의 코드·자동 검증은 완료했고, 실제로 생성·공유·성장을 이해하기 쉬운지는 사람 플레이에서 확인한다. 사람의 재미·균형, 실제 Windows 성능, 온라인 품질과 Steam 배포도 후속 검증이다.
