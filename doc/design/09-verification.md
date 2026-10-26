# 구현 근거와 검증 매트릭스

- 기록 기준일: **2026-10-26**.
- 검증 대상: 기준 커밋 `0bda61d316b2b54dfafe8bb8d88e65715b593c60` 위에 세 라인 전장·전투·UI·설계 문서를 통합한 작업 트리. 아래 검사는 최종 검토에서 찾은 두 중요 문제를 수정한 뒤 실행했다.
- 엔진: **Godot 4.7.2 Standard**, 실제 버전 문자열 `4.7.2.stable.official.ed1daf0bf`.
- 통합 결과: **프로젝트 임포트, 5개 검사 묶음의 2,192개 assertion, 기본 장면 시작 모두 통과**. 통합 명령 종료 코드 0, 실패 0, `ERROR:`·`SCRIPT ERROR:` 없음.
- 자동 검사와 실제 렌더 캡처는 사람의 조작감·게임성·6인 네트워크·Windows 배포 검증을 대신하지 않는다.

## 1. 최종 실행 근거

저장소 루트에서 다음 명령을 실행했다. 엔진 경로는 이번 Linux 검증 환경의 경로이며, 다른 PC에서는 설치한 4.7.2 실행 파일로 바꾼다.

```sh
XDG_DATA_HOME=/tmp/project-e-root-final-data \
XDG_CONFIG_HOME=/tmp/project-e-root-final-config \
XDG_CACHE_HOME=/tmp/project-e-root-final-cache \
python tools/check_godot.py \
  --godot /tmp/project-e-godot-tools/Godot_v4.7.2-stable_linux.x86_64 \
  --long-match
```

| 실행 단계 | 실제 결과 | 확인 범위 |
|---|---|---|
| 버전·프로젝트 임포트 | 통과 | 고정 버전 검사, 스크립트·장면·에셋 임포트 |
| `test_bas_motion.gd` | 40 checks, 0 failures | 기존 이동·바스 E·충돌·자원 회귀 |
| `test_probe_scene.gd` | 19 checks, 0 failures | 기존 물리 진단 장면 회귀 |
| `test_battle_rules.gd` | 115 checks, 0 failures | 공격·피해·보호막·명령 검증·영웅 기술·성장 |
| `test_battle_match.gd -- --long` | 1,922 checks, 0 failures | 세 라인 경로·웨이브·공성·종료·봇 자연 경기 |
| `test_battle_scene.gd` | 96 checks, 0 failures | 실제 장면·입력·HUD·시야·지속 기술 형상 |
| 기본 장면 90프레임 시작 | 통과 | `project.godot`의 기본 전장 장면 로딩·실행 |

검사 수는 실행된 assertion 수다. 경로 표본과 반복 상태 비교를 포함하므로 서로 다른 기능이 2,192개라는 뜻은 아니다. 기본 장면 시작은 headless 실행이며, 화면이 그려지는지는 별도의 렌더 캡처로 확인했다.

- [통합 실행 원문 로그](verification/2026-10-26-headless.log)
- [실행기](../../tools/check_godot.py)

실행기는 각 프로세스의 종료 코드, 오류 출력, 예상 완료 문구를 검사한다. 최종 원문에는 다음 문구가 기록됐다.

```text
PASS: Godot import, all five behavioral suites and main-scene startup
```

## 2. 검증 매트릭스

‘통과’는 연결된 자동 검사에서 다룬 입력·상태·표본의 결과다. 모든 기하 경계, 모든 경기 구성, 사람의 실제 조작을 포괄한다는 뜻은 아니다.

| ID | 콘텐츠/위험 | 확인한 결과 | 현재 상태 |
|---|---|---|---|
| V01 | 기본 공격·피해·보호막 | 방어 후 흡수, 같은 출처 갱신, 공격 간격 | 자동 검사 통과 — 전투 규칙 |
| V02 | 잘못된 명령 | 사망·아군·숨은 적·범위·NaN·잠금 거부, 무소모 | 자동 검사 통과 — 전투 규칙 |
| V03 | 바스 | 부채/띠 경계, 압력, E 충돌·속박 중단, W | 자동 검사 통과 — 전투 규칙·기존 이동 |
| V04 | 리오 | Q 단계별 적중 제한·고정 회수점, E 강화, R 테두리, W 표식·귀환 경로 | 자동 검사 통과 — 전투 규칙·장면 |
| V05 | 네마 | 핀 2개·교체·수명, W/R 취소·소비, E, 지속 연결 폭·정리 | 자동 검사 통과 — 전투 규칙·장면 |
| V06 | 제어·사망 | 속박/기절 구분, CC 예산, 장치 정리, 부활 | 자동 검사 통과 — 전투 규칙 |
| V07 | 성장·경제 | 일반/체험 시작, XP 임계·상한·R·보상, HUD 진행률 | 자동 검사 통과 — 전투 규칙·장면 |
| V08 | 길찾기·맵 | 양 기지→N/C/S 경로와 구간의 보행 가능성, 물/벽 회피, 수로 방향 이동기 | 자동 검사 통과 — 경기. 모든 좁은 모서리나 최단 경로를 보장하지 않음 |
| V09 | 웨이브·공성 | 생성 편성·첫 병력 위치, 내곽·핵 잠금, 병력 보호, 탑 보복·병력 복귀 | 자동 검사 통과 — 경기 |
| V10 | 종료·재시작 | 같은 틱 양 핵 파괴의 무승부, 종료 후 명령 차단, 잔여 상태 제거 | 자동 검사 통과 — 경기·장면 |
| V11 | 봇 장시간 경기 | 일반 시작의 봇 6명이 실제 전투로 핵을 파괴하고 종료 | 20분 11초 자연 종료 확인. 다른 구성과 사람 참여 경기는 미측정 |
| V12 | 장면·UI | 선택·조준·패널 차단·미니맵·재시작, 지속 효과와 시야 경계 | 실제 장면 자동 검사 96개 통과 |
| V13 | 기존 진단 회귀 | 기존 이동·바스 E·물리 진단 장면 유지 | 기존 2개 묶음, 59개 검사 통과 |
| V14 | 실제 프레임 | 전장·한국어 HUD·성장·조준·지속 기술 형상의 실제 렌더 | 8개 프레임 생성 완료. 성능 목표·사람 조작 검증은 아님 |
| V15 | 사람 플레이·밸런스 | 조작감·학습·지원·성장 판단·영웅 균형 | 미검증. 봇 경기 20:11은 기존 12–18분 목표보다 김 |
| V16 | 온라인/배포 | 지연·손실·6인·재접속·Windows/Steam | 미구현 / 미검증 |

현재 남은 표시·입력 차이와 범위 제한은 [기존 설계와 현재 실행판의 차이](10-differences.md)에 기록했다.

## 3. 봇 6명의 자연 경기

`test_battle_match.gd`의 `_test_determinism_and_bots()`는 일반 시작으로 상태를 만든 뒤 `controlled_id = -1`로 설정해 여섯 영웅을 모두 봇이 제어하게 한다. `bots_enabled = true`인 기본 설정을 유지하며, 일반 레벨 1·초기 성장 포인트 2점으로 시작한다. 기본 실행판의 사람 1명+봇 5명과는 제어 조건이 다르다.

| 항목 | 최종 기록 |
|---|---|
| 종료 | **동쪽 팀 승리**, `winner = 1` |
| 시뮬레이션 시간 | **1,211.0초 — 20분 11초** |
| 파괴된 탑 | 11개 |
| 누적 피해 기록 | 671,471.1 |
| 영웅 사망 | 22회 |
| 서쪽 핵 | HP 0.0 |
| 동쪽 핵 | HP 약 3,884.8 |
| 종료 시 상태에 남은 유닛 항목 | 77개. 살아 있는 유닛만 센 수치는 아님 |

이 장시간 경기에서는 영웅·병력·탑·핵의 일반 수치를 유지했고, 핵 HP를 직접 0으로 설정하거나 별도의 강제 피해를 넣거나 시간 초과로 승패를 만들지 않았다. 검사 시간 상한 안에서 실제 전투로 서쪽 핵이 파괴됐다. 별도의 종료 단위 검사는 양 핵의 HP를 직접 설정해 무승부 분기를 확인하지만, 그 준비 상태는 이 자연 경기와 공유하지 않는다.

동일 초기 상태를 60초 동안 각각 `0.1초 × 600회`, `1/30초 × 1,800회`로 진행한 뒤 유닛 수·위치·HP가 일치하는지도 검사했다. 이는 검사한 고정 틱 시나리오의 재현 근거이며, 모든 입력 순서나 네트워크 동기화의 증명은 아니다.

**이 결과는 12–18분 경기 길이 가설을 충족하지 못했다.** 사람 참여 경기, 여러 전략·영웅 선택, 재미·승률·난이도는 후속 플레이 테스트에서 측정한다. 봇은 단순한 라인·근처 교전·복귀·성장 판단을 사용하며 협동 전술이나 난이도별 전략까지 구현된 상태는 아니다.

## 4. 최종 검토에서 수정한 회귀

최종 코드 검토에서 발견한 두 중요 문제는 먼저 실패하는 검사를 추가한 뒤 수정했다. 이후 1절의 통합 실행으로 다른 검사와 함께 재확인했다.

| 문제 | 수정 전 재현 | 수정과 최종 결과 |
|---|---|---|
| 기본 공격 중 예약한 스킬이 더 최신 공격 명령 이후에도 실행됨 | 전투 규칙 **115 checks, 4 failures**. 이전 예약 스킬이 에너지·쿨타임을 사용하고 새 공격 의도를 덮음 | 승인된 즉시 공격이 기존 예약을 지움. 거절된 아군 대상 명령은 예약을 유지. **115 checks, 0 failures** |
| 네마 연결·리오 표식/귀환 경로가 지속 표시되지 않고 적 선 효과가 숨은 끝점을 드러냄 | 장면 **96 checks, 13 failures** | 권한 상태의 연결 폭·표식 수명·고정 귀환점을 실제 메시로 표시. 적 선 형상을 시야 구간별로 제한하고 만료·핀 제거·소유자 사망 시 정리. **96 checks, 0 failures** |

앞선 전투 구현 단계에서 확인한 이동기 시전 준비 중 속박, 예약 스킬의 실행 시 재검증, 부채 외곽 모서리 판정, 첫 웨이브 기준 위치, 추격 범위를 넘긴 병력의 라인 복귀도 현재 전투·경기 회귀 검사에 포함한다.

## 5. 실제 렌더 캡처

실행 환경은 **Linux + Xvfb**, Compatibility 렌더러, **OpenGL 4.5 / Mesa 25.2.8 / llvmpipe 소프트웨어 렌더링**이다. 오디오는 `Dummy` 드라이버를 사용했다. 그래픽 디스플레이를 준비한 상태에서 다음 캡처 명령을 실행했다.

```sh
DISPLAY=:95 \
/tmp/project-e-godot-tools/Godot_v4.7.2-stable_linux.x86_64 \
  --path game/project-e \
  --audio-driver Dummy \
  --rendering-method gl_compatibility \
  --rendering-driver opengl3 \
  --script tests/capture_battlefield.gd
```

| 생성 파일 | 실제 내용과 준비 조건 |
|---|---|
| `01-selection.png` | 영웅 선택 화면 |
| `02-start.png` | 바스 일반 경기 시작 직후 |
| `03-growth.png` | 같은 경기의 성장 패널 |
| `04-battle.png` | 여섯 영웅을 봇으로 제어해 75초 진행한 뒤 캡처 |
| `05-aim.png` | 위 상태에서 Q 조준 표시 |
| `06-nema-link.png` | 네마 기술 체험에서 실제 이동·Q 명령으로 만든 두 핀의 지속 연결 |
| `07-rio-mark.png` | 리오 기술 체험에서 실제 W 명령으로 만든 귀환 표식 |
| `08-rio-return.png` | 같은 리오 상태에서 실제 Q 명령으로 만든 귀환 경로 |

캡처 도우미는 실제 `battlefield.tscn`을 로드한다. 기술별 프레임은 일반 기술 규칙을 유지한 채 명령과 시뮬레이션 시간을 지정한 재현 장면이다. 네마 연결과 리오 귀환 캡처는 각각 활성 연결과 실제 귀환 단계가 존재하는지 확인한 뒤 저장하며, 두 형상은 최종 프레임에서도 확인했다. 자동 진행과 정지 프레임 캡처이며 사람이 전투를 플레이한 기록은 아니다. 별도 생성한 콘셉트 이미지도 실행 화면의 근거로 사용하지 않는다.

렌더 명령은 종료 코드 0으로 8개 이미지를 저장했다. `ERROR:`·`SCRIPT ERROR:`는 없었고, 소프트웨어 드라이버가 VSync 모드 변경을 지원하지 않는다는 경고가 한 번 기록됐다. 이 환경의 프레임으로 특정 PC의 60fps 성능이나 Windows 렌더 호환성을 주장하지 않는다.

- [렌더 실행 원문 로그](verification/2026-10-26-render.log)
- [캡처 도우미](../../game/project-e/tests/capture_battlefield.gd)
- [실제 전장 화면](assets/prototype-battlefield.png)
- [네마 지속 연결 화면](assets/prototype-nema-link.png)
- [리오 귀환 경로 화면](assets/prototype-rio-return.png)

## 6. 구현과 검사 위치

| 역할 | 실제 파일 |
|---|---|
| 경기 상태·명령·진행 | [battle_state.gd](../../game/project-e/scripts/battle/battle_state.gd) |
| 공통 전투 판정 | [battle_rules.gd](../../game/project-e/scripts/battle/battle_rules.gd) |
| 세 라인 맵·길찾기 | [battle_map.gd](../../game/project-e/scripts/battle/battle_map.gd) |
| 세 영웅 기술 | [hero_abilities.gd](../../game/project-e/scripts/battle/hero_abilities.gd) |
| 영웅·병력·탑 자동 행동 | [battle_ai.gd](../../game/project-e/scripts/battle/battle_ai.gd) |
| 전장 장면·입력 | [battlefield.tscn](../../game/project-e/scenes/battlefield.tscn), [battlefield.gd](../../game/project-e/scripts/presentation/battlefield.gd) |
| HUD·지속 효과 | [battle_hud.gd](../../game/project-e/scripts/presentation/battle_hud.gd), [effects_view.gd](../../game/project-e/scripts/presentation/effects_view.gd) |
| 전투 규칙 검사 | [test_battle_rules.gd](../../game/project-e/tests/test_battle_rules.gd) |
| 경기·봇 검사 | [test_battle_match.gd](../../game/project-e/tests/test_battle_match.gd) |
| 실제 장면 검사 | [test_battle_scene.gd](../../game/project-e/tests/test_battle_scene.gd) |
| 기존 회귀 검사 | [test_bas_motion.gd](../../game/project-e/tests/test_bas_motion.gd), [test_probe_scene.gd](../../game/project-e/tests/test_probe_scene.gd) |

## 7. 추가 수동 검증의 재현 순서

다음은 **아직 완료하지 않은 사람 플레이 절차**다. 위 자동 검사와 구분해 실제 수행 후 결과를 기록한다.

1. 일반 경기에서 각 영웅을 선택해 이동·기본 공격·Q/W/E, G 투자, R 잠금 이유를 확인한다.
2. 기술 체험에서 각 R을 사용하고 조준·효과·쿨타임·에너지 표시가 읽기 쉬운지 본다.
3. 패널 위 좌/우클릭이 지면 공격으로 전달되지 않는지 실제 마우스로 확인한다.
4. 시야 경계와 벽 뒤에서 적 선택·미니맵·체력·적중 피드백을 살피고, 겹친 대상의 선택 우선순위 차이를 기록한다.
5. 근접 영웅으로 모든 탑에 접근하고, 기지에서 세 라인으로 이동하며, 이동기를 수로/벽 방향으로 사용한다.
6. 사망·부활 뒤 입력과 장치 상태를 확인하고, 핵 종료 후 재시작한다.
7. 사람 1명+봇 5명의 일반 경기를 여러 차례 진행해 경기 시간, 막힘, 성장 선택, 승패와 불편한 조작을 기록한다.

온라인·Steam·Windows 내보내기, 사람 6명의 밸런스, 최종 아트·음향·접근성은 별도 구현·검증 단계다.
