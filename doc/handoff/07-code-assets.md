# 07. 코드·자산 위치와 편집 계약

- 작성일: **2026-11-19, 한국 시간**.
- 기준: `e29c36296abf6d365353401dd0cbee411edc531d`, **V9 / 0.9.0 / Godot 4.7.2 Standard**.
- **현재 코드 확인**은 파일·참조·구조를 읽은 결과다. 이번 인계에서 런타임과 생성기를 실행하지 않았다.

## 1. 먼저 열 파일

| 순서 | 파일 | 읽는 이유 |
|---|---|---|
| 1 | [project.godot](../../game/project-e/project.godot) | 버전·메인 장면·렌더러·입력·물리 설정 |
| 2 | [battlefield.tscn](../../game/project-e/scenes/battlefield.tscn) | 실제 시작 장면과 연결된 스크립트 |
| 3 | [playable_battlefield.gd](../../game/project-e/scripts/presentation/playable_battlefield.gd) | 플레이 구성, 카메라·전술 AI·연출실·음향 |
| 4 | [battlefield.gd](../../game/project-e/scripts/presentation/battlefield.gd) | 입력을 경기 명령으로 변환, UI·경기 시작/재시작 |
| 5 | [battle_state.gd](../../game/project-e/scripts/battle/battle_state.gd) | 로컬 30Hz 상태 진행, 유닛·이벤트·승패 |

시작 장면의 루트는 `playable_battlefield.gd`를 사용하며 이 스크립트는 `battlefield.gd`를 상속한다.
`battlefield.gd`가 `BattleState`를 만들고 `_physics_process()`에서 경기 진행을 호출한다.
카메라·모델·HUD는 표시 계층에서 이 상태를 읽는다. 코드의 `authority`는 현재 **로컬 판정 주체**를 가리킨다.
이 분리가 전용 서버, 원격 입력 또는 네트워크 동기화 구현을 뜻하지 않는다.

## 2. 게임 판정 코드

| 파일 | 현재 책임 | 변경 시 함께 확인할 것 |
|---|---|---|
| [battle_state.gd](../../game/project-e/scripts/battle/battle_state.gd) | 경기 상태·명령·고정 시간·웨이브·공성·승패 | 경기 수명, 실제 명령과 표현의 연결 |
| [battle_rules.gd](../../game/project-e/scripts/battle/battle_rules.gd) | 피해·보호막·제어·성장·보상·사망 | 경계값과 중복 처리 |
| [hero_roster.gd](../../game/project-e/scripts/battle/hero_roster.gd) | 8명 ID·이름·역할·기본 능력치·팀 편성 | 선택 화면·초상·시트·봇 조합 |
| [hero_abilities.gd](../../game/project-e/scripts/battle/hero_abilities.gd) | 공통 기술 메타데이터·기존 3명 기술·형상 | 비용·시간·툴팁·경고·적중 |
| [expanded_abilities.gd](../../game/project-e/scripts/battle/expanded_abilities.gd) | 신규 5명 기술·고유 상태·예약 타격 | 사망·재설정·소모·만료 |
| [battle_consumables.gd](../../game/project-e/scripts/battle/battle_consumables.gd) | 아이템 정의·구매·사용·회복·중단 | 상점·재고·봇·음향 |
| [battle_map.gd](../../game/project-e/scripts/battle/battle_map.gd) | 좌표·충돌·경로·시야·고지 | 화면 변환, 경고와 실제 이동 |
| [battle_ai.gd](../../game/project-e/scripts/battle/battle_ai.gd) | 병력·포탑·기초 영웅 행동 | 대상 선택, 복귀·경제 |
| [tactical_ai.gd](../../game/project-e/scripts/battle/tactical_ai.gd) | 전술 과제·지원·V9 열린 라인 합류 | 진행 중 과제 존중, 최대 2명 배정 |

현행 콘텐츠 값은 위 GDScript의 상수·Dictionary와 판정 코드에 들어 있다.
장기 설계의 `domain/`, `content/`, `simulation/`, `networking/`, `platform/` 표를 현재 폴더 구조로 취급하지 않는다.
관련 기준: [장기 아키텍처 계획](../../docs/technical/02-architecture-and-networking.md), [현재 콘텐츠](../design/content/README.md).

## 3. 표시·입력·검토 계층

| 파일·묶음 | 책임 |
|---|---|
| [battlefield_layout.gd](../../game/project-e/scripts/presentation/battlefield_layout.gd) | 시뮬레이션 좌표와 V9 세로 화면의 변환 |
| [battle_hud.gd](../../game/project-e/scripts/presentation/battle_hud.gd) | 선택 카드·경기 HUD·패널·도움말·소모품 |
| [tactical_map.gd](../../game/project-e/scripts/presentation/tactical_map.gd) | 미니맵 표시와 입력 |
| [hero_rig.gd](../../game/project-e/scripts/presentation/hero_rig.gd) | GLB 8종·재질·노드 관절·코드 생성 동작 |
| [hero_portrait.gd](../../game/project-e/scripts/presentation/hero_portrait.gd) | 기존 3명 WebP와 신규 5명 모델 렌더 초상 |
| [skill_vfx.gd](../../game/project-e/scripts/presentation/skill_vfx.gd), [effects_view.gd](../../game/project-e/scripts/presentation/effects_view.gd) | 실제 기술 형상과 지속 상태의 표시 |
| [team_vision_view.gd](../../game/project-e/scripts/presentation/team_vision_view.gd) | 관측 가능한 팀 시야 표현 |
| [arena_view.gd](../../game/project-e/scripts/presentation/arena_view.gd), [workshop_arena.gd](../../game/project-e/scripts/presentation/workshop_arena.gd) | 전장 표면·건축물·환경 배치 |
| [terrain_relief.gd](../../game/project-e/scripts/presentation/terrain_relief.gd), [support_ramp_view.gd](../../game/project-e/scripts/presentation/support_ramp_view.gd) | 고지·경사로 표시 |
| [review_lab.gd](../../game/project-e/scripts/presentation/review_lab.gd) | F7 독립 영웅·기술·전장 검토 |
| [fantasy_audio.gd](../../game/project-e/scripts/presentation/fantasy_audio.gd) | 조작 영웅의 상태 전환을 관측한 로컬 음향 |

모델 애니메이션·VFX가 피해량이나 적중을 확정하도록 옮기지 않는다. 장식·실제 판정·시야의 계약을 함께 읽는다.
이전 `combat_probe.tscn`, `player.tscn`, `bas_motion.gd`, `probe_player.gd`, `combat_probe.gd`는 초기 진단의 보존 자료다.
실행 흐름을 찾을 때 초기 장면을 현행 메인 장면으로 오인하지 않는다. [장면 목록](../../game/project-e/scenes/)

## 4. 실행 자산과 제작 자료

| 경로 | 현재 확인한 내용 | 편집 원칙 |
|---|---|---|
| [assets/heroes](../../game/project-e/assets/heroes/) | 8명 GLB, 기존 3명의 얼굴·의상 WebP 6개, 셰이더 | 생성기·텍스처·관절 계약을 함께 보존 |
| [assets/portraits](../../game/project-e/assets/portraits/) | 기존 3명의 WebP와 과거 SVG | 신규 5명은 런타임 모델 렌더 초상 |
| [assets/ui/skills](../../game/project-e/assets/ui/skills/) | 8명 QWER의 SVG **32개** | 파일 키·SVG 제목·표시 이름 연결 |
| [assets/ui/items](../../game/project-e/assets/ui/items/) | 별샘 영약·숲빛 치유약 SVG 2개 | 아이템 메타데이터와 함께 확인 |
| [assets/environment](../../game/project-e/assets/environment/) | GLB 11종, 바닥 WebP 2개와 셰이더 | 이동·충돌·시야는 맵 코드에 따름 |
| [assets/audio](../../game/project-e/assets/audio/) | 합성 WAV 5개와 설명 | 16kHz·16-bit PCM·mono 기록 |
| [assets/fonts](../../game/project-e/assets/fonts/) | `ProjectEKorean.woff2`, OFL·설명 | 글꼴과 고지 동시 전달 |
| [doc/design/assets](../design/assets/) | 컨셉·단계별 실제 캡처·영상·manifest | 제작 시안과 실제 실행 증거를 구분 |

[실행 자산 README](../../game/project-e/assets/README.md)는 V5/V7 기준 3명·12아이콘 설명이 남아 있다.
현재 개수와 연결은 V8/V9 코드·폴더를 따른다. 이미 있는 자산을 미구현으로 되돌리는 지시로 해석하지 않는다.

## 5. 모델·아이콘 재생성

아래 명령은 출력 자산을 덮어쓴다. **후속 제안:** 수정 전 작업 브랜치와 필요한 원본 사본을 확보한 뒤 실행한다.

```sh
python tools/build_hero_models.py
python tools/art/build_canal_scenery.py
python tools/build_roster_models_v8.py
python tools/art/build_roster_icons_v8.py
```

| 도구 | 입력·출력과 의존성 |
|---|---|
| [build_hero_models.py](../../tools/build_hero_models.py) | 얼굴·의상 WebP 6개 → 기존 3명 GLB; NumPy·Pillow 사용 |
| [build_canal_scenery.py](../../tools/art/build_canal_scenery.py) | 코드 형상 → 환경 GLB 11개; Python 표준 라이브러리 |
| [build_roster_models_v8.py](../../tools/build_roster_models_v8.py) | 기존 GLB 내장 텍스처와 공용 생성 코드 → 신규 5명 GLB |
| [build_roster_icons_v8.py](../../tools/art/build_roster_icons_v8.py) | 코드 벡터 정의 → 신규 20개 SVG; Python 표준 라이브러리 |

**기존 검증 기록:** V5 재현은 Linux x86_64, CPython **3.12.14**, NumPy **2.3.5**, Pillow **13.0.0**, libjpeg-turbo **3.2.0**, libwebp **1.6.0**에서 14개 GLB가 바이트 단위로 일치했다.
이 버전들은 당시 재현 환경이다. 모든 자산 도구의 범용 최소 버전 또는 현재 환경 재실행 결과로 확대하지 않는다.
근거: [2026-11-06 재현 기록](../design/verification/2026-11-06-v5-model-reproduction.md), [V8 자산 재현](../design/28-eight-hero-prototype.md).

Blender/glTF 편집은 선택 경로다. 고정 Blender 버전, `.blend` 제작 원본과 Python 의존성 잠금 파일은 현재 저장소에서 찾지 못했다.
직접 편집한 GLB는 생성기 재실행으로 덮일 수 있다. 형상 변경을 생성기에 돌려놓거나 별도 원본·편집 절차를 명시한다.
`Head`, `Torso/TeamMark`, `Torso/SwingPanel`, `LeftLeg/Shin`, `RightLeg/RightShin`, `LeftArm/LeftWeapon`, `RightArm/WeaponDetail` 이름·피벗·계층을 보존한다.
WebP를 바꾸면 GLB에 내장된 JPEG도 재생성해야 한다. [상세 편집 계약](../design/25-illustrated-canal.md)

## 6. 추적 파일, 캐시와 검증 도구

- `.gd`, `.tscn`, `.gdshader`, `.uid`, 원본 자산과 `.import` 설정을 함께 관리한다. `.uid`는 캐시와 같이 버리지 않는다.
- `.godot/`, `build/`, `dist/`, `.tools/` 등은 [gitignore](../../.gitignore)에 있는 재생성 대상이다.
- [check_godot.py](../../tools/check_godot.py)는 현재 38묶음과 시작 장면을 검사한다. 옛 문서의 검사 개수를 복사하지 않는다.
- [check_art_assets.py](../../tools/check_art_assets.py), [check_audio_assets.py](../../tools/check_audio_assets.py)는 파일·연결 계약의 자동 검증이다.
- [capture_player_view.gd](../../tools/art/capture_player_view.gd), [capture_vertical_v9.gd](../../tools/art/capture_vertical_v9.gd)는 실제 렌더 캡처·입력 확인용이다.
- [measure_siege.gd](../../tools/measure_siege.gd)는 자연 봇 공성을 관측한다. 명령과 해석 경계는 [V9 검증](../design/verification/2026-11-10-v9-verification.md)에 있다.

**후속 제안:** 변경한 책임의 판정 검사, F7 동작, 실제 경기 카메라, export PCK를 차례로 확인한다.
**미확인:** 자동 검사가 시각적 완성도·자연스러운 모션·사람 플레이 밸런스를 승인해 주지는 않는다.

## 7. 문서 위계와 외부 고지

현행 판단은 코드·설정 → [V9 설명](../design/30-v9-vertical-siege.md)·[콘텐츠 상세](../design/content/README.md) → 날짜가 붙은 검증 기록 순으로 대조한다.
`doc/design/`에는 현재 허브와 단계별 이력이 함께 있고, `docs/`는 초기·장기 계획을 보존한다. 폴더명만으로 모든 문서가 최신인 것은 아니다.
[Unity 검토 경로](../../docs/technical/01-unity-and-steam.md)는 Godot으로 전환되었다는 안내이며 현행 Unity 프로젝트의 증거가 아니다.
[제3자 고지](../../THIRD_PARTY_NOTICES.md)는 Godot MIT와 한글 글꼴 SIL OFL 1.1, 자체 제작·이미지 생성 자산의 출처를 기록한다.
Godot MIT가 Project E 원본 코드·게임 콘텐츠의 라이선스를 정하지 않는다. 저장소에 없는 별도 사용권이나 상업 배포 승인을 추정하지 않는다.
음향·미술 세부 인계는 [09. 미술과 음향](elements/09-art-audio.md), 온라인 경계는 [11. 온라인과 Steam](elements/11-online-steam.md)을 따른다.
