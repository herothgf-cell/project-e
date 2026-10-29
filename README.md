# Project E — 수로 공방

**세 라인의 지원 판단, 짧은 기술 교전, 경기 중 성장을 중심으로 하는 독립 PC용 3대3 액션 AOS.** Godot 4.7.2 Standard/GDScript로 개발하며 Steam 출시를 목표로 한다. 현재는 사람 한 명과 봇 다섯 명의 로컬 경기다.

## 현재 검토판 — 2026-10-29

[카메라·실제 게임 모델·맵·기술·전술 봇 검증](doc/design/18-playable-visual-slice.md)을 최신 상태 정본으로 본다.

| 영역 | 현재 구현 |
|---|---|
| 전장 | M01 세 라인, 기존 연결로 4개, 타워 12개·핵 2개, 40 XP 고지 2곳과 각 라인/지원 경사 |
| 전투 | 바스·리오·네마의 기본 공격·패시브·QWER, 보호막·CC·사망·부활 |
| 성장·경제 | 20/30/40 XP, 관측 셀 등장·실제 개인 수령·레벨업 안내, 성장 포인트·R, 기지 상점·소모품 |
| 카메라 | 사선 원근 전투/전술/근접 뷰, F6 전환, Y 추적, 자유 이동·영웅 재집중 |
| 게임용 시각 1차 | 세 영웅의 실제 메시·장비·시각 관절 동작, 석재·고지 지지대·장식, 관측된 시전/보호막/투사체 효과 |
| 전술 봇 1차 | 보이는 셀 선택·포기, 인접 지원, 가까운 노출 핵 방어, 자기 라인 복귀, 부활 목표 초기화 |
| 검증 | 기존 16 + 신규 3 = 19묶음, 3,698 checks, 실패 0; 실제 렌더 PNG 102장 |
| 배포 | 최신 Windows EXE/PCK export·ZIP 확인, Windows runner headless 시작 통과 |

**첫 게임용 시각 검토판이며 최종 미술 자산이 아니다.** 원작 영상의 정확한 카메라 수치를 확보하지 못했으므로 현재 카메라는 Project E의 제안값이다. 그래픽·컨셉은 독립 설계한다.

## 실행

### Windows 실행판

[검토판 다운로드 및 검증 출처](doc/design/18-playable-visual-slice.md#6-배포물과-출처)의 최신 artifact를 받는다. artifact ZIP 안의 `ProjectE-windows-x86_64.zip`을 전부 풀고 `ProjectE.exe`를 실행한다. `ProjectE.pck`를 같은 폴더에 둔다.

이번 실행판에는 R28 고저차, R30 지원 경사, R29 XP 피드백과 새 카메라·모델·전술 봇이 포함된다. 이전 `e56286a` 소모품 ZIP은 과거 빌드다. 이번에도 수동 Windows 그래픽·입력·성능 확인까지 끝난 것은 아니다.

### 소스

Godot 4.7.2 Standard에서 [game/project-e/project.godot](game/project-e/project.godot)을 가져온 뒤 F5. 일반 경기는 레벨 1·성장 2포인트, 기술 체험은 레벨 3·R 해금이다. [빠른 시작](docs/technical/03-godot-quickstart.md)

## 조작

| 입력 | 동작 |
|---|---|
| 지면/적 우클릭 | 이동 / 접근 후 기본 공격 |
| A → 지면 좌클릭 | 공격 이동, 교전 후 목적지 복귀 |
| Q/W/E/R → 좌클릭 | 기술 조준·확정 |
| Esc / S | 조준 취소·메뉴 / 정지 |
| G / B | 성장 / 기지로 걸어가기 |
| P / 소모품 칸 / D | 상점 / 품목 선택 / 사용 |
| F1 | 도움말 |
| F6 | 전투 → 전술 → 가까이 시점 |
| Y / Space | 영웅 추적 전환 / 영웅 재집중 |
| 휠 / 가운데 드래그 | 확대·축소 / 자유 카메라 |
| 미니맵 좌클릭/우클릭 | 시점 이동 / 영웅 이동 |

아군 병력과 함께 외곽탑→내곽탑→핵을 공격한다. 셀은 우클릭으로 직접 공격한다. 포탑 공격 범위 8.5m와 시야 12m는 별개다.

## 검증과 문서

- [최신 시각 검토판·전술 봇·Windows 증거](doc/design/18-playable-visual-slice.md)
- [현재 백로그](doc/design/11-remaining-development.md)
- [콘텐츠 문서 목차](doc/design/README.md)
- [M01 지형](doc/design/02-map-m01.md)
- [캐릭터 기획](doc/design/characters/README.md)
- [R29 XP 피드백](doc/design/17-xp-feedback-verification.md)
- [R30 지원 동선](doc/design/16-r30-high-ground-flow-verification.md)
- [사람 플레이 기록표](doc/design/12-local-playtest-record.md)
- [온라인 설계](docs/technical/02-architecture-and-networking.md)
- [Steam 계획](docs/release/01-steam-release-plan.md)

```sh
python tools/check_godot.py --godot /path/to/Godot_v4.7.2-stable
# 추가 세 묶음은 Playable slice CI가 같은 엔진으로 수행한다.
Godot_v4.7.2-stable --headless --path game/project-e --script tests/test_tactical_ai.gd
Godot_v4.7.2-stable --headless --path game/project-e --script tests/test_playable_slice.gd
Godot_v4.7.2-stable --headless --path game/project-e --script tests/test_tactical_lifecycle.gd
```

기존 원시 상태 봇 진단은 431.8초, 새 전술 봇 진단은 1,333.0초에 종료했다. 서로 다른 정책의 단일 자동 경기이므로 사람의 손맛·적정 경기 시간을 입증하지 않는다.

다음: 카메라/아트 방향 검토, 바스 피격·사망·고유 기술 동작·음향, 전장 명암/시야 경계, 입력 피드백과 사람 템포 검증. 빈 라인 전역 배치·핀 대응·온라인·출시용 자산은 후속이다.
