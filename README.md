# Project E — 수로 공방

세 라인 지원 판단·짧은 기술 교전·성장을 연결하는 Godot 4.7.2 Standard PC AOS. 현재는 **사람 1명 + 봇 5명, 오프라인 3대3**이다.

## 최신 — 통합 V2 (2026-11-03)

**[캐릭터·12개 스킬·애니메이션·맵 고저차·검증 상세](doc/design/19-integrated-v2.md)**

세 영웅의 실제 모델과 QWER 12개, 피격·사망·부활, 기존 고지·경사를 한 실행판에 연결했다. F7 연출실에서 각각 재생한 뒤 하나씩 수정한다. 최종 출시용 아트가 아니라 모듈형 게임 자산의 1차 통합 검토판이다.

| 영역 | 현재 |
|---|---|
| 전장 | 3라인·연결로4개·탑12개·핵2개·XP셀6개·2.4m 고지2곳·경사4개 |
| 전투 | 바스/리오/네마 기본 공격·패시브·QWER·CC·성장·공성·승패 |
| 경제 | XP20/30/40, 실제 개인 XP/레벨업 피드백, 성장/R, 상점/소모품 |
| 봇 | 관측 셀·지원·근거리 핵 방어·라인 복귀·부활 초기화 1차 |
| 카메라 | 사선 원근 전투/전술/근접, 자유 이동과 추적 |
| 연출 | 영웅당 10클립, QWER별 관절 동작, 실제 효과/시야에 맞춘 VFX, 관측 사망 연출 |
| 검토실 | F7, 세 영웅/12스킬/피격/사망/부활/언덕/전체맵/반속/재시연 |
| 로컬 자동 검증 | **22묶음·4,522 checks·실패0**, import/메인 시작, 실제 렌더40장+282프레임 |

## 실행

Godot 4.7.2 Standard에서 `game/project-e/project.godot`을 Import하고 F5. Windows 패키지는 `.exe`와 `.pck`를 같은 폴더에 전부 풀어 `ProjectE.exe` 실행. 최신 패키지 출처는 해당 커밋의 **Windows preview** Actions artifact다. 과거 ZIP에는 V2가 없으므로 구분한다.

먼저 실행 화면의 **F7 통합 연출실**을 열어 확인한다. 일반 경기 또는 기술 체험으로 실제 조작도 가능하다. 기술 체험은 레벨3/R해금으로 시작한다.

| 입력 | 동작 |
|---|---|
| F7 | 통합 연출실 열기/닫기 |
| 지면/적 우클릭 | 이동/기본공격 |
| A → 지면 좌클릭 | 공격 이동 |
| QWER → 좌클릭 | 기술 조준/확정 |
| Esc / S | 취소·메뉴 / 정지 |
| G / B | 성장 / 기지 이동 |
| P / D | 상점 / 선택 소모품 사용 |
| F1 / F6 | 도움말 / 전투·전술·근접 카메라 |
| Y / Space | 영웅 추적 / 재집중 |
| 휠 / 가운데 드래그 | 확대축소 / 자유 카메라 |

연출실의 전체 맵 공개와 재시연 초기화는 별도 경기 상태에만 적용한다. 원래 경기를 진행하거나 자원을 바꾸지 않는다.

## 문서와 검증

- [최신 V2 구현·증거·한계](doc/design/19-integrated-v2.md)
- [남은 개발](doc/design/11-remaining-development.md)
- [설계 목차](doc/design/README.md)
- [M01 지형](doc/design/02-map-m01.md)
- [영웅 기획](doc/design/characters/README.md)
- [이전 시각 검토판](doc/design/18-playable-visual-slice.md)
- [사람 플레이 기록](doc/design/12-local-playtest-record.md)
- [온라인 설계](docs/technical/02-architecture-and-networking.md)

```sh
python tools/check_godot.py --godot /path/to/Godot_v4.7.2-stable
```

`Integrated V2`는 전 검사와 실제 렌더 캡처, `Windows preview`는 release export/ZIP과 Windows headless 시작을 수행한다. 자동 검사는 사용자 PC 그래픽/조작/성능·사람 재미·온라인 품질을 보장하지 않는다. 참고작의 모델·맵·카메라 수치를 복제하거나 영상을 새로 학습했다고 주장하지 않는다.
