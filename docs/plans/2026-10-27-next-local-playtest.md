# 다음 로컬 플레이테스트 구현 계획

> **For agentic workers:** Use superpowers:subagent-driven-development for isolated task implementation and review. 체크박스는 실제 증거가 있을 때 갱신한다.

**Goal:** R01–R05와 R24–R27의 다음 개발 묶음을 실제 로컬 게임과 Windows 테스트 패키지에 반영한다.

**Architecture:** 기존 BattleState가 명령·시야·보상을 확정한다. 표시층은 같은 판정으로 시야 음영과 유효 경고 영역을 그리고 입력을 명령으로 전달한다. 실행 패키지에는 버전·검증 기록·최소 사용 안내를 함께 둔다.

**Tech Stack:** Godot 4.7.2 Standard, GDScript, Compatibility renderer; Python 표준 라이브러리 빌드 도구.

**Spec:** [남은 개발 및 확정된 방향](../../doc/design/11-remaining-development.md), 기준 commit `85deaf26797d2bc64757d54bd2025d39d09c8a00`.

## Global Constraints

- 초기 영웅 바스·리오·네마와 오프라인 사람 1명+봇 5명 구조를 유지한다.
- 시야는 아군 영웅/살아 있는 구조물 12m, 병력 8m와 벽 차단의 팀 공유다. 셀·핀·회수점은 시야를 제공하지 않는다.
- 포탑 공격 사거리는 9.0→8.5m. 공성 보호 반경 12m, HP·피해·간격은 유지한다.
- 셀 XP는 20/30/40 각 2개, 북서↔남동 40 / 중앙 쌍 30 / 북동↔남서 20. HP180·크레딧10·30초 첫 생성·45초 재생성·14m 공유는 유지한다.
- A→지면 좌클릭으로 공격 이동. 자동 기술 사용 없음. 숨은 적 최신 위치를 추적하지 않는다.
- 기존 이미 발사된 기본 투사체의 내부 추적과 아군에게 알려진 기술 경로는 기존 계약을 유지한다.
- 실제 Windows PC 실행과 사람 플레이를 Linux 자동 실행·렌더 캡처로 대체 완료 처리하지 않는다.
- 사용자 요청으로 개발·기존 저장소 반영은 승인되어 있다. 중간 구현 선택 때문에 재승인을 요구하지 않는다.

## Review Focus

1. 공격 이동 목표와 교전 표적이 분리되고 예약 명령/거절/사망/재시작에서 오래된 목표가 되살아나지 않는다.
2. 안개·시야원 표시가 미니맵/클릭/공격/효과와 일치하며 제공원 겹침·벽 모서리·파괴 때 적 정보를 누출하지 않는다.
3. 원/부채 경고의 벽 차단 기준이 실제 효과 원점·각도·반경과 같고 유효 영역이 사라지지 않는다.
4. 셀의 분수 보상과 재생성 등급 유지, 포탑 경계·보복 감지·봇 여유 거리가 실제 규칙에 맞는다.
5. Windows export의 패키지 누락·엔진/templates 불일치·잘못된 완료 주장을 막고 작은 화면의 새 안내가 입력을 가리지 않는다.

## 작업 경계와 공용 계약

| 소유 | 수정 파일 | 제공 인터페이스 |
|---|---|---|
| 전투 담당 | battle_state.gd, battle_rules.gd, battle_ai.gd, 전투/경기 검사 및 새 test_next_combat.gd | command_attack_move(actor_id:int,target:Vector2)->bool; is_attackable_target(team:int,target_id:int)->bool; cell_tier: String, xp_reward: float |
| 시야 담당 | 새 team_vision_view.gd, arena_view.gd, tactical_map.gd, unit_overlay.gd, 새 test_team_vision.gd | TeamVisionView.configure(state:RefCounted); update_view(camera:Camera3D,team:int,delta:float,hover_enabled:bool); 기존 다른 표시 API 유지 |
| 배포 담당 | tools/package_windows.py, docs/technical/04-windows-build.md, 필요시 export_presets.cfg | 엔진 위치/다운로드 hash; Python packaging CLI와 Windows ZIP/manifest |
| 통합 담당 | battlefield.gd, battle_hud.gd, effects_view.gd, battle_map.gd 또는 새 effect_geometry.gd, UI/형상 검사, check_godot.py, capture helpers, 나머지 문서 | A 입력/안내, 표적 우선순위, 벽 경고 형상, 최종 검증·문서·게시 |

같은 파일을 동시에 수정하지 않는다. 각 담당은 독립 파일만 편집하고 commit/push는 통합 담당이 수행한다. 구현 중 새로운 공용 계약은 메시지와 작업 기록으로 공유한다.

### Task 1: 전투 명령·셀·포탑 (R24/R26/R27 규칙)

- [x] 실제 상태 기반 검사에 20/30/40 공유·등급 재생성, 8.5m 안/밖 및 보복, 공격 이동 교전/복귀/취소/거절/예약 경계를 추가하고 실패를 확인한다.
- [x] 셀별 데이터로 XP를 지급하고 포탑 실제 사거리와 보복 감지를 같은 필드에서 읽는다. 봇 위험 여유는 사거리+기존 여유로 유도한다.
- [x] command_attack_move를 시뮬레이션 명령으로 구현한다. 목적지와 표적을 따로 보존하고 최신 유효 명령만 이전 명령을 교체한다.
- [x] 초기 자동 후보는 적 영웅·병력·공격 가능한 구조물이며 가까운 후보/동률ID. 셀·핀은 직접 지정한다. 검색 반경 8m(자기 중심), 획득 위치에서 추적 최대 8m. 시야 상실 즉시 해제; 같은 표적을 매 틱 재획득해 추적 제한을 우회하지 않는다. 도착 후에는 사거리 안 표적만 공격하고 추격하지 않는다.
- [x] 새 검사 및 기존 전투/경기 검사를 통과시키고 명령 계약·남은 한계를 보고한다.

검증: `godot --headless --path game/project-e --script tests/test_next_combat.gd` 및 기존 전투/경기 검사. Expected: checks, 0 failures; 자연 경기 검증은 통합 시 한 번.

### Task 2: 시야·셀 표시 (R25 및 R24 표시)

- [x] 현재 관측/비관측 지점, 벽 뒤, 제공원 겹침/소멸을 검사하는 실제 상태 기반 표시 검사를 작성하고 실패 확인.
- [x] TeamVisionView가 현재 팀 시야를 전장 지면 음영으로 표시한다. 관측은 정상 밝기, 비관측은 어둡고 낮은 채도; 고정 지형과 길은 읽힌다.
- [x] 미니맵도 같은 판정의 관측 영역을 사용한다. 시야원에 작은 공통 표식/설명, 마우스오버 시 실제 벽 차단을 반영한 범위를 제공한다. 살아 있는 아군만 시야원이다.
- [x] 셀 종류별 형태/크기와 XP 숫자를 표시한다. 물리 반경은 변경하지 않고 숨은 셀의 상태를 노출하지 않는다.
- [x] 실제 렌더에서 명도 경계와 UI 겹침을 확인할 장면을 준비하고 검사 통과를 보고한다.

검증: `godot --headless --path game/project-e --script tests/test_team_vision.gd`; 실제 캡처는 통합 담당. Expected: checks, 0 failures.

### Task 3: 입력·경고·최소 안내 (R01/R02/R04/R27 입력)

- [x] A 준비/확정/Esc/S/우클릭/기술 전환, UI 클릭 차단·사망/결과 경계, 겹친 대상/잠긴 구조물 제외를 실제 장면 검사로 재현한다.
- [x] A 공격 이동과 합법 표적 검증을 연결한다. 직접 클릭 우선순위는 영웅→병력→공격 가능한 구조물→셀→핀, 동순위 화면거리/ID다.
- [x] 원·부채의 유효 영역을 공통 지형 판정으로 잘라 조준과 활성 효과에 사용한다. 벽 앞/뒤/모서리와 차단 없는 원·부채의 검사에서 표시/효과 기준이 일치한다.
- [x] 시야 표시를 장면 생명주기에 연결하고, 선택 화면/경기 도움말에 A, 셀 보상, 시야원/영역, 성장·R·B 걷기 복귀, 탑 잠금/병력 보호를 짧게 안내한다.
- [x] 실제 장면/형상 검사 통과와 시작/교전/어택땅/시야/도움말 렌더를 확인한다.

검증: 기존 `test_battle_scene.gd`와 새 입력/형상 검사; `capture_battlefield.gd` 또는 후속 capture helper. Expected: 0 failures, 실제 PNG 생성.

### Task 4: Windows 테스트 패키지 (R03)

- [x] 고정 엔진과 일치하는 공식 export templates를 확보하고 다운로드 출처·버전·hash를 기록한다. 불일치 버전으로 완료를 가장하지 않는다.
- [x] Python CLI가 import/export, EXE/PCK 확인, 라이선스/조작 안내, 버전 manifest와 ZIP을 만든다. 실제 산출물 누락과 export 오류는 실패로 종료한다.
- [x] 최종 소스로 Windows release export를 실행하고 실제 파일/ZIP/hash를 확인한다. 가능하면 호환 환경 smoke를 수행하되 실제 Windows PC 확인과 구별한다.
- [x] 사용자 전달 파일과 에디터 없는 실행·Alt-Tab·재시작·폰트·로그 확인 절차를 제공한다.

검증: `python tools/package_windows.py --godot <pinned executable>` (최종 CLI와 옵션은 배포 문서에 기록). Expected: EXE/PCK/ZIP/manifest 생성, export error 없음.

### Task 5: 통합 검증·검토·기록 (R05 준비 포함)

- [x] check_godot.py에 새 검사를 등록하고 전체 검사·메인 장면·6봇 자연 경기를 실행한다.
- [x] 실제 렌더와 신규 입력·시야·경고를 검토하고 명백한 문제를 수정한다.
- [x] 독립 검토에서 규칙·시야 노출·명령 경계·패키지 누락을 확인한다.
- [x] 실제 수행한 증거와 미수행한 Windows PC/사람 플레이를 구분해 개발 목록·요소별 규칙·검증 문서·플레이 기록표를 갱신한다.
- [x] 개발 소스/기획/검증을 GitHub에 반영하고 원격 내용과 commit을 확인한다.

## 결정 기록

- 사용자의 개발 진행 요청과 이미 확정한 시야/포탑 방향을 실행 승인으로 적용한다.
- 계획 위치는 기존 저장소의 `docs/plans` 관례를 사용한다.
- 파일 소유권을 나누어 병렬 진행하며, 각 작업 검토와 전체 통합 검토를 수행한다.
- Windows PC와 실제 사람 입력 관찰은 접근 가능한 환경이 없으면 미검증으로 남기고 재현 가능한 패키지와 기록표까지 완성한다.

## 실행 결과 갱신 — 2026-10-27

- 최종9개 묶음2,911개 assertion와 메인90프레임 통과. 새 전투 수치의 별도6봇 자연 경기1,638.2초 종료.
- 실제 GL11프레임 및 GPU 지면/미니맵 시야 전후 변화 확인. 눈 배지로 체력바에 가린 시야원 고리를 교체했다.
- 독립 검토에서 적 원/부채 렌더219–432ms 회귀를 발견하고 캐시·native 다각형 제한으로 수정했다. 최종 형상35개 및 독립171,990표본 통과.
- 상세 증거: [검증 기록](../../doc/design/09-verification.md). 소스 a11834f를 GitHub main에 반영한 뒤 같은 깨끗한 소스로 Windows release EXE/PCK/ZIP을 만들고 전달 파일을 준비했다. 실제 export·ZIP 무결성과 Linux에서 exported-PCK 시작/2프레임도 확인했다. 실제 Windows PC/사람 플레이는 미실시로 유지한다.
