# Project E — 아스트라 수로 전장

Godot 4.7.2 Standard로 만드는 독립 실행형 PC AOS다. 현재 실행판은 **사람 1명과 봇 5명이 싸우는 오프라인 3 대 3**이며, 세 라인에서 성장하고 포탑을 밀어 상대 핵을 파괴하는 경기 흐름을 제공한다.

## 현재 기준: V5 수로 전장

2026-11-05에 중단되었던 V5 표현 자산과 연결 코드를 복구했다. 최신 미술 방향은 **3등신의 귀여운 세미카툰 판타지**다. 얼굴과 의상 텍스처가 있는 영웅 3종, 관절별 공격·스킬 동작, 밝은 석재와 청록 수로, 작은 공방 건축물을 실제 게임 장면에 연결했다. 전투 수치와 판정은 기존 전투 상태가 계속 담당한다.

![V5 실제 경기 렌더](doc/design/assets/v5/combat.webp)

위 이미지는 실제 Godot 렌더러에서 스크립트로 배치한 경기 장면이다. 자연스러운 사람 플레이의 기록이나 성능 측정 결과로 사용하지 않는다. [선택 화면](doc/design/assets/v5/selection.webp), [중앙 교전](doc/design/assets/v5/mid-clash.webp), [12개 스킬 검토 영상](doc/design/assets/v5/skill-review.mp4)과 촬영 조건은 [V5 제작·재현 안내](doc/design/25-illustrated-canal.md)에 정리했다.

| 영역 | 현재 구현 |
|---|---|
| 전장 | 3개 라인, 연결 통로 4개, 포탑 12개, 핵 2개, XP 셀 6개, 높이 2.4m 고지 2곳과 진입 경사로 4개 |
| 영웅 | 바스·리오·네마의 기본 공격, 패시브, Q/W/E/R, 레벨 성장과 궁극기 해금 |
| 경기 | 병력 생성·라인 교전·공성·핵 파괴 승리, 사망·부활, 사람 1명과 봇 5명 |
| 경제 | 20/30/40 XP 셀, 공유 보상, 성장 투자, 기지 회복, 상점과 소모품 |
| 봇 | 라인 전투·성장·복귀, 관측한 셀 수집, 아군 지원과 핵 방어, 소모품 구매·사용 |
| 전투 표시 | 시야·고저차·벽 판정에 맞춘 경고와 효과, HUD·미니맵·상태 표시 |
| 캐릭터 표현 | 텍스처가 포함된 GLB 3종, 영웅당 10개 동작 클립, 영웅별 Q/W/E/R 12개 동작과 효과 |
| 음향·검토 | 전투용 WAV 5개, F6 전장 보기와 F7 독립 검토실 |

이 표는 구현 범위를 설명한다. 자동 검증, 실제 렌더 확인, Windows 사용자 PC 플레이는 별도 상태로 관리한다. 최신 결과와 증거는 [2026-11-05 V5 검증 기록](doc/design/verification/2026-11-05-v5-verification.md)을 기준으로 한다. **Windows 사용자 PC의 수동 플레이, 사람 간 온라인 대전, 재접속과 Steam 연동은 완료되지 않았다.**

## 실행

1. Godot 4.7.2 Standard에서 `game/project-e/project.godot`를 가져온다.
2. 최초 자산 가져오기가 끝나면 F5로 실행한다.
3. 바스·리오·네마 중 영웅을 선택해 경기를 시작한다. 개별 동작은 F7 검토실에서 확인한다.

Windows 배포본을 사용하는 경우 `.exe`와 함께 제공된 `.pck`를 같은 폴더에 둔다. 현재 배포·내보내기 검증 범위는 위 V5 검증 기록에서 확인한다.

| 입력 | 동작 |
|---|---|
| 우클릭 | 이동 또는 대상 공격 |
| A → 좌클릭 | 공격 이동 |
| Q/W/E/R → 좌클릭 | 스킬 선택과 조준 확정 |
| Esc / S | 조준 취소 / 정지 |
| G / B | 성장 패널 / 기지로 걷기 복귀 |
| P / D | 상점 / 선택한 소모품 사용 |
| F1 | 경기 도움말 |
| F6 / F7 | 전장 보기 / 독립 검토실 |
| Y / Space | 카메라 추적 전환 / 조작 영웅으로 초점 이동 |
| 마우스 휠 / 가운데 버튼 드래그 | 확대·축소 / 카메라 이동 |

스킬 슬롯·소모품 선택 등 상세 조작은 게임 도움말과 [UI·조작 문서](doc/design/06-ui-and-controls.md)를 따른다. 검토실은 별도 전투 상태를 사용하므로 검토실의 재생이 진행 중인 경기 상태를 바꾸지 않는다.

## 설계와 제작 자료

- [설계 문서 목차](doc/design/README.md): 경기·맵·전투·AI·성장·UI·아트의 요소별 기획
- [V5 수로 전장 제작 안내](doc/design/25-illustrated-canal.md): 자산 목록, 모델 편집 계약, 실제 화면과 재현 명령
- [캐릭터 기획](doc/design/characters/README.md): 바스·리오·네마의 전투 역할과 시각 방향
- [설계와 실행판의 차이](doc/design/10-differences.md), [남은 개발](doc/design/11-remaining-development.md)
- [V4 전투 표현](doc/design/23-fantasy-v4-combat-presentation.md), [V4 자산 안내](doc/design/24-fantasy-v4-asset-guide.md): 이전 단계의 제작 기록

최종 GLB와 WebP는 저장소에 복구되어 있다. 현재 모델과 동일한 결과를 만드는 원본 생성기는 회수하지 못했으며, 이전 생성기로 재생성하면 현재 텍스처·관절 구성을 보존할 수 없다. 모델 수정 방법과 이 한계는 V5 안내에 명시했다.

## 자동 확인

저장소 루트에서 실행한다.

```sh
python tools/check_godot.py --godot /absolute/path/to/godot
python tools/check_art_assets.py
python tools/check_audio_assets.py
python -m unittest discover -s tools/tests -p 'test_package_windows.py'
```

검증 도구는 자산 가져오기, 전투·입력·표현 회귀 검사, 시작 장면 실행 및 배포 관련 규칙을 확인한다. 자동 통과가 사용자 PC의 프레임 성능·재미·사람 경기 밸런스·온라인 연결을 대신하지 않는다. 공개 시안, 역사적 검증 수치, 이번 실행 증거는 [설계 목차](doc/design/README.md)에서 구분한다.
