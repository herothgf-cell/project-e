# 요소 11. 온라인·Steam의 현재 경계와 장기 계획

- 작성일: **2026-11-19, 한국 시간**.
- 기준: `e29c36296abf6d365353401dd0cbee411edc531d`, **V9 / 0.9.0 / Godot 4.7.2 Standard**.
- 결론: 현재 제품은 **사람 1명 + 봇 5명의 오프라인 3 대 3**이다. 온라인 PvP와 Steam 연동은 장기 계획이다.
- 이번 인계는 저장소 정적 확인이며 네트워크·Steam·새 테스트를 실행하지 않았다.

## 1. 현재 코드에서 확인한 것

| 항목 | 현재 상태 | 근거 |
|---|---|---|
| 로컬 경기 | 현재 코드 확인: 하나의 `BattleState`가 경기 진행 | [battlefield.gd](../../../game/project-e/scripts/presentation/battlefield.gd) |
| 8명 선택 풀·팀당 3명 | 현재 코드 확인 | [hero_roster.gd](../../../game/project-e/scripts/battle/hero_roster.gd) |
| 사람 영웅 1개·나머지 봇 | 현재 코드 확인 | [battle_state.gd](../../../game/project-e/scripts/battle/battle_state.gd), [현재 안내](../../../README.md) |
| 고정 시간 판정 | 현재 코드 확인: 로컬 30Hz | 같은 `battle_state.gd`의 `FIXED_STEP` |
| 네트워크 transport·RPC | 해당 구현을 현재 소스에서 찾지 못함 | 아래 정적 검색 범위 |
| Steam SDK·바인딩·콜백 | 해당 구현과 채택 버전을 찾지 못함 | [프로젝트 폴더](../../../game/project-e/), [고지](../../../THIRD_PARTY_NOTICES.md) |
| 전용 서버 export | 현재 preset에 없음; `dedicated_server=false` | [Windows preset](../../../game/project-e/export_presets.cfg) |
| Steam 없이 실행 | 현재 패키지 안내가 명시 | [package_windows.py](../../../tools/package_windows.py) |

`battle_state.gd`는 스스로 “Local 30 Hz battle authority”라고 설명하고 네트워크 전송을 모델 밖의 책임으로 둔다.
판정과 표시를 나눈 구조, 팀 시야, 봇 인계 가능성, headless 실행만으로 원격 서버 구현이 생기는 것은 아니다.
현재 `controlled_id`는 로컬 조작 영웅을 가리킨다. Steam 사용자 인증·원격 플레이어 소유권으로 해석하지 않는다.

## 2. 코드 미존재 확인의 범위

2026-11-19에 `game/project-e`, `tools`, `.github`를 검색했다.
`Steam`, `GodotSteam`, ENet 계열, `MultiplayerPeer`, `MultiplayerSynchronizer`, `@rpc`, `rpc_id`, `.rpc(`,
`create_server`, `create_client`, `WebSocket`, `WebRTCPeer`의 실행 연결을 찾지 못했다.
검색된 Steam 문구는 패키지 도구가 출력하는 “Steam 계정 불필요”, “Steam 연동 미검증” 안내였다.
현재 트리에서 외부 Steam 애드온·GDExtension·플랫폼 바이너리도 확인되지 않았다.

다음은 새 인수자가 정적 검색을 반복할 때 사용할 예다. 매치 없음의 `rg` 종료 코드 1을 게임 테스트 실패로 읽지 않는다.

```sh
rg -n -i '\bSteam\b|GodotSteam|\bENet[A-Za-z0-9_]*|MultiplayerPeer|MultiplayerSynchronizer|@rpc|rpc_id|\.rpc\(|create_server|create_client|WebSocket|WebRTCPeer' game/project-e/scripts game/project-e/scenes game/project-e/project.godot
```

이 결론은 해당 인계 커밋의 저장소 범위다. 다른 비공개 저장소·외부 계정에 별도 작업이 전혀 없다는 주장으로 확대하지 않는다.
Steamworks 계정 등록·결제·App 생성·스토어 공개·출시에 대한 수행 증거는 현재 저장소에서 확인하지 못했다.
[출시 계획](../../../docs/release/01-steam-release-plan.md)도 이를 미실행 계획으로 표시한다.

## 3. 장기 설계를 읽는 방법

| 문서 | 활용할 내용 | 현행 구현으로 읽으면 안 되는 부분 |
|---|---|---|
| [Godot과 Steam](../../../docs/technical/01-godot-and-steam.md) | 엔진 선택, 플랫폼·전송 책임 구분 | M1 ENet/RPC·M3 이후 바인딩 계획 |
| [아키텍처·네트워크](../../../docs/technical/02-architecture-and-networking.md) | 권위 명령·동기화·예측·보정의 설계 가설 | `networking/`, `platform/`, 원격 세션 구현 |
| [개발 로드맵](../../../docs/02-development-roadmap.md) | M0~M6 의존성과 필요한 증거 | 단계를 이미 완료한 일정표로 해석 |
| [Steam 출시 계획](../../../docs/release/01-steam-release-plan.md) | 출시 준비물·역할·검증 경계 | 실제 등록·심사·게시·출시 완료 |
| [Unity 검토 경로](../../../docs/technical/01-unity-and-steam.md) | Godot으로 전환한 이력 | 현재 엔진이나 Unity 네트워크 구현 근거 |

`docs/`는 초기·장기 계획을 보존한다. `doc/design/`의 현행 콘텐츠·V9 기록과 실제 코드가 현재 플레이 범위를 설명한다.
출시 계획의 “여섯 영웅 후보”, 과거 기술 문서의 “세 영웅”은 당시 범위다. 현재 **8명 선택 풀**과 혼동하지 않는다.
8명 구현과 3 대 3 팀 편성이 있다는 사실은 여섯 사람이 접속할 수 있다는 뜻이 아니다.

## 4. 보존할 온라인 설계 가설

아래는 [장기 아키텍처](../../../docs/technical/02-architecture-and-networking.md)에 있는 **후속 제안**이며 미구현이다.

- 서버가 이동 가능성·피격·피해·성장·재화·승패를 확정하고 클라이언트는 입력 의도를 보낸다.
- 최초 진단은 한 영웅·작은 장면·두 독립 실행 클라이언트의 ENet/RPC 직접 연결로 시작한다.
- 입력 번호·기준 tick·소유권·자원·쿨다운을 검증하고 확정 이벤트는 중복 적용을 막는다.
- 시야별 상태 전송을 설계한다. 숨은 적 데이터를 모두 전송하고 화면만 가리는 방식으로 정보 계약을 대체하지 않는다.
- 입력 이력, 예측, 서버 상태 복원, 미승인 입력 재실행, 타인 상태 보간을 별도 구현·측정한다.
- 고정 tick·동일 seed만으로 모든 PC에서 물리가 완전히 결정적이라고 가정하지 않는다.

| 기존 제안값 | 의미 | 현재 상태 |
|---|---|---|
| 시뮬레이션 30Hz | 온라인 권위 tick의 출발 가설 | 로컬 30Hz만 구현; 서버 측 측정 미확인 |
| 스냅샷 30Hz·렌더 60fps | 전송·표시 목표 | 온라인 성능 실측 아님 |
| RTT 50/100/150ms | 최초 지연 시험 조건 | 시험 미실행 |
| jitter ±20ms·손실 1%/3% | 불안정 연결 시험 조건 | 시험 미실행 |
| 연결 손실 5초·복귀 60초 | 봇 인계와 원사용자 복귀 정책 초안 | 접속·인증·인계 구현 없음 |
| 호스트 이탈 시 세션 중단 | 초기 listen server 정책 초안 | 호스트 세션 자체 미구현 |

당시 계획의 수치를 현재 확정 서비스 규칙이나 성능 보증으로 공개하지 않는다.

## 5. Steam 작업을 분리할 책임

| 책임 | 필요한 구현·결정 | 현재 상태 |
|---|---|---|
| 게임 배포 | 빌드·depot·브랜치·설치/업데이트 검증 | Windows 로컬 ZIP까지만 기존 기록 |
| 플랫폼 기능 | 로그인·친구 초대·로비·오버레이·콜백 수명 | 미구현, SDK/바인딩 버전 미정 |
| 실제 경기 전송 | 연결·채널·손실·종료·재접속 | 미구현, 전송 경로 미정 |
| 판정 권위 | 서버 입력 검증·경기 상태·가시성 | 로컬 판정만 존재 |
| 서버 운영 | 호스팅·지역·비용·로그·장애 대응 | 설계·책임자 미확인 |
| 스토어·출시 | 제품 범위·실제 영상·언어·지원 사양·공개 결정 | 준비 계획만 존재 |

기존 계획은 GodotSteam을 후보로만 다룬다. 채택 형태·버전·Steam SDK·Godot 호환성·배포 파일·라이선스는 결정되지 않았다.
Steam 로비, 실제 전송, 게임의 판정 권위, 서버 호스팅을 하나의 완료 항목으로 묶지 않는다.
ENet 직접 연결의 성공을 Steam 초대·중계·인터넷 연결의 성공으로 자동 승계하지 않는다.
이 문서는 외부 기술·정책을 새로 조회하거나 새 공급자를 선정하지 않았다.

## 6. 출시 문서의 날짜와 미확인 사항

[Steam 출시 계획](../../../docs/release/01-steam-release-plan.md)의 정책·수수료 출처 확인일은 2026-10-21~22다.
그 문서에는 당시 대기기간 안내가 21일/30일로 달랐다는 기록이 있다. 어느 쪽도 이번 인계에서 현행 규정으로 확정하지 않는다.
실제 등록·결제·게시 시점에 담당자가 적용 정책을 다시 확인할 과제이며, 현재 프로토타입 실행의 선행 조건은 아니다.
공개 이름·가격·지역·서버 예산·계약 주체·앱 ID·depot ID·Steam Build ID는 현재 인계에서 확정하지 않는다.
계정 정보·세금·은행 정보·업로드 자격증명을 소스에 채워 넣는 작업도 이번 문서의 범위가 아니다.

## 7. 다음 담당자가 남겨야 할 완료 증거

**후속 제안:** 온라인을 시작한다면 작은 연결 진단 → 서버 명령 검증 → 지연·손실·재접속 → 실제 6인 경기 → Steam 경로 순으로 증거를 쌓는다.
각 단계는 커밋·Godot/바인딩/SDK 버전·서로 다른 PC·실측 RTT·손실·로그·사람 조작 결과를 식별해야 한다.
로컬 회귀 통과, 자연 봇 핵 파괴, Windows headless 기동, Steam 기능, 실제 온라인 완주는 각각 별도로 기록한다.
**기존 검증 기록:** [V9 검증](../../design/verification/2026-11-10-v9-verification.md)은 오프라인 행동·화면·배포·Windows 기동을 다룬다.
**미확인:** 원격 PvP, 인증·로비, 서버 권위 동기화, 예측·보정, 재접속, 인터넷 품질, Steam 설치·초대·출시.
인계받은 개발자나 AI는 위 항목을 완료된 기능으로 소개하거나 기존 자동 검사만으로 완료 처리하지 않는다.
