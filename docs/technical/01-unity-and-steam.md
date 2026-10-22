# Unity 선택과 Steam 기술 기반

- 상태: v0.1 기획 제안, Unity 프로젝트·게임 코드·Steam App 미생성.
- 작성·공식 출처 확인: 2026-10-21, Asia/Seoul.
- 범위: Windows PC 제작 환경, 버전 고정, 저장소 관리, Steam 연동 경계.
- 관련: [프로젝트 개요](../00-project-brief.md), [공통 규칙](../01-core-rules.md), [네트워크 설계](02-architecture-and-networking.md), [출시 계획](../release/01-steam-release-plan.md).

## 1. 결론

Steam에 출시하기 위해 Unity를 반드시 사용할 필요는 없다.
Valve의 공식 Steamworks API 문서는 Unity, Godot, Unreal 등 여러 엔진의 연동 경로를 안내한다. [S1]
이 프로젝트의 출발점으로는 **Unity 6.3 LTS + C# + URP, Windows x64**를 권장한다.
이 선택은 3인 팀 전투, 짧은 지원 동선, 잦은 스킬 사용을 작은 3D 프로토타입으로 검증하기 위한 제작 판단이다.
사용자의 Unity 숙련도, 제작 인원, 예산은 아직 확인되지 않았으므로 학습 속도나 개발 기간을 보장하지 않는다.
먼저 M1에서 한 캐릭터의 조작감과 지연 환경을 검증하고, 이 결과로 본 제작에 들어간다.

## 2. 선택안과 이유

| 항목 | 권장 출발점 | 결정 이유·검증 조건 |
| --- | --- | --- |
| 엔진 계열 | Unity 6.3 LTS | 제작 중 기준 버전을 고정하고 제한된 범위에서 반복 검증 |
| 언어 | C# | 전투 규칙과 Unity 표현 코드를 분리하여 관리 |
| 렌더링 | URP | 밝은 스타일화 3D, 전투 가독성, PC 성능 예산을 함께 검증 |
| 첫 플랫폼 | Windows x64 | 실제 6인 PC 테스트와 Steam 배포 검증에 집중 |
| 첫 입력 | 마우스·키보드 | 클릭 이동, Q/W/E/R/D, 재지정 가능한 입력 |
| 초기 멀티플레이 | NGO + Unity Transport 실험 | 구현 편의보다 지연 시험 통과 여부로 최종 판단 |
| 첫 배포 형태 | 개발용 독립 실행 빌드 | Editor 밖의 실행·입력·성능부터 확인 |

URP는 Unity가 제공하는 렌더 파이프라인이며 PC를 포함한 여러 플랫폼을 대상으로 한다. [U2]
URP를 사용한다는 사실만으로 60fps가 보장되지는 않는다. 스킬 경고, 그림자, 투명 효과의 실제 비용을 측정한다.
HDRP, DOTS 전체 전환, 대규모 주소 기반 에셋 배포는 초기 필수 항목으로 두지 않는다.
고정 카메라·접지 이동·동일한 영웅 충돌 반경을 활용해 첫 전투의 복잡도를 제한한다.

## 3. Unity 6.3 LTS를 권장하는 범위

공식 지원 페이지는 Unity 6.3 LTS 지원을 2027년 12월까지로 안내한다. [U1]
같은 페이지는 새 프로젝트에 Update 계열도 권장하므로, LTS가 모든 신규 프로젝트의 유일한 정답이라는 뜻은 아니다. [U1]
Project E에서는 잦은 엔진 변경보다 한 기준 버전에서 네트워크와 전투를 검증하는 편을 우선한다.
출시 일정이 지원 종료 이후로 늘어나면 M4에서 다음 지원 버전으로의 이전 비용을 다시 판단한다.
이 문서는 특정 패치가 설치되었거나 안정성 시험을 통과했다고 주장하지 않는다.

## 4. M0에서 버전을 고정하는 방법

| 구성 요소 | 지금의 상태 | M0 완료 시 남길 기록 |
| --- | --- | --- |
| Unity Editor | 6.3 LTS 계열 권장, 정확한 패치 미정 | 검증한 `6000.3.xf1`의 실제 숫자·릴리스 노트·선택 이유 |
| C# 컴파일러·실행 환경 | Editor에 맞춰 선택 | scripting backend, API compatibility, 빌드 옵션 |
| URP | Editor 호환 버전 선택 예정 | 정확한 패키지 버전과 렌더러 설정 |
| Input System | 사용 후보 | 호환 버전, 입력 액션, 포커스 복귀 검증 |
| NGO / Unity Transport | M1 진단 후보 | 정확한 버전 쌍, 지원 Editor, 알려진 제약 |
| 테스트 패키지 | 필요한 범위만 도입 | 정확한 버전과 실행 방법 |
| Steam SDK·C# 바인딩 | M3 이후 선택 예정 | SDK 버전, 라이선스, 바인딩 커밋·릴리스, 빌드 검증 |

`6000.3.xf1`은 버전 형식의 자리표시자이며 설치 명령이나 실제 고정 버전이 아니다.
M0 담당자는 공식 릴리스 노트에서 후보 패치의 Windows·URP·네트워크 관련 알려진 문제를 확인한다.
빈 진단 프로젝트에서 Editor 실행, Windows 빌드, 실행 종료, 입력, 한 장면 재열기를 확인한다.
이후 `ProjectSettings/ProjectVersion.txt`, `Packages/manifest.json`, `Packages/packages-lock.json`을 함께 기록한다.
설치 경로, 필요한 빌드 모듈, 재현 절차와 사용한 컴퓨터 환경도 남긴다.
패키지 문서의 `latest` URL을 프로젝트의 버전 고정 수단으로 사용하지 않는다.
엔진·패키지 업그레이드는 별도 변경 단위로 수행하고 같은 진단 장면으로 회귀를 비교한다.

## 5. 빌드와 화면 기준

| 항목 | 초기 가설 | 확정 시점 |
| --- | --- | --- |
| 실행 대상 | Windows x64, 첫 검증 OS는 Windows 11 x64 | 최소 지원 OS는 M5 실제 시험 후 |
| 화면 | 1920×1080을 첫 측정 기준, 창·전체화면 전환 | M3 UI 검증 |
| 클라이언트 | 60fps 목표 | M5 최소 사양의 실측 결과 |
| 권위 시뮬레이션 | 30Hz 시작안 | M1 지연 시험·M2 부하 시험 |
| 스냅샷 | 30Hz 시작안 | 전송량·보간·손실 시험 |
| 그래픽 품질 | 낮음·기본 두 단계부터 | 교전 가독성을 유지하는 범위 |

시뮬레이션 tick, 입력 수집, 렌더 프레임을 같은 주기로 묶지 않는다.
캐릭터 애니메이션의 보이는 위치와 서버의 피격 판정은 연결하되 판정의 책임은 서버에 둔다.
최소 GPU·CPU·RAM은 아직 지정하지 않는다. M0에 시험 장비를 기록하고 M5에서 검증한 수치를 게시한다.
Steam Deck, 컨트롤러, macOS, Linux 클라이언트는 이후 평가 대상이며 출시 약속에 넣지 않는다.
서버를 Linux로 운영할지는 별도 인프라 선택이다. 클라이언트의 Linux 지원과 혼동하지 않는다.

## 6. 저장소 관리 원칙

Unity 에셋의 `.meta`에는 GUID와 임포트 설정이 들어가므로 원본과 함께 보존한다. [U3]
에셋 이동·이름 변경은 Unity 안에서 수행하거나 대응하는 `.meta`까지 함께 이동한다.
`.meta`를 삭제해 참조 문제를 해결하려 하지 않고 GUID가 바뀐 원인을 확인한다.
`Asset Serialization = Force Text`를 기준으로 삼아 scene·prefab·설정의 변경을 검토한다. [U4]
텍스처·음원 같은 바이너리가 이 설정으로 텍스트가 되는 것은 아니다.
`Assets`, `Packages`, `ProjectSettings`와 제작에 필요한 소스 에셋을 버전 관리한다.
`Library`, `Temp`, `Obj`, `Logs`, 개인 `UserSettings`, 로컬 빌드 산출물은 재생성 항목으로 제외한다.
큰 원본 아트·음원은 용량을 확인한 뒤 Git LFS 적용 여부를 결정하며, 유료 에셋 배포 권한도 기록한다.
한 scene에 모든 기능을 모으지 않고 진단 장면, 맵 장면, UI prefab의 변경 책임을 나눈다.
API 키·서버 비밀키·Steam 업로드 계정 자격증명을 저장소나 클라이언트에 넣지 않는다.

## 7. 제안하는 저장소 경로

다음은 구현 시작 시의 구조 제안이다. 현재 존재하거나 구현된 경로라는 의미는 아니다.

| 경로 | 책임 |
| --- | --- |
| `docs/` | 승인·검증 상태가 드러나는 기획과 의사결정 |
| `game/ProjectE/Assets/_Project/Domain/` | 피해·성장·경제·상태 규칙, Unity 객체에 의존하지 않는 C# |
| `game/ProjectE/Assets/_Project/Simulation/` | tick 진행, 입력 적용, 공간 질의 경계, 권위 상태 |
| `game/ProjectE/Assets/_Project/Networking/` | 명령·스냅샷·재접속·전송 어댑터 |
| `game/ProjectE/Assets/_Project/Presentation/` | 카메라·UI·애니메이션·음향·VFX |
| `game/ProjectE/Assets/_Project/Platform/` | Steam·설정 저장·플랫폼 추상화 |
| `game/ProjectE/Assets/_Project/Content/` | 편집용 캐릭터·스킬·웨이브·맵 정의 |
| `game/ProjectE/Assets/_Project/Scenes/` | Boot, CombatProbe, ArenaM01, Training 후보 |
| `game/ProjectE/Assets/_Project/Tests/` | 규칙 테스트와 필요한 플레이 모드 시험 |
| `game/ProjectE/Packages/` | 패키지 선언·잠금 |
| `game/ProjectE/ProjectSettings/` | Editor·플랫폼·직렬화 설정 |
| `tools/build/` | 반복 가능한 빌드·검증 절차, 추후 필요 시 작성 |

## 8. 라이선스 확인

2026-10-21 확인한 Unity 약관에서 Personal 기준은 최근 12개월의 `Total Finances`가 US$200,000을 넘지 않는 경우다. [U5]
기준을 초과하면 해당 자격에 맞는 유료 등급이 필요하며, 높은 재무 규모에는 Enterprise 기준이 별도로 적용된다. [U5]
개인·법인·고객을 위한 외주인지에 따라 `Total Finances` 계산 대상이 달라지므로 본인 게임 매출만으로 단정하지 않는다. [U5]
M0에서 제작 주체·수익·투자금·외주 관계를 확인하고 자격 판단의 근거 날짜를 남긴다.
문서에 사용자의 매출이나 라이선스 자격을 추정해 기입하지 않는다.
에디터 구독료, 서버 비용, 에셋 비용은 구매 시점 견적으로 결정하며 이 문서는 결제를 지시하지 않는다.

## 9. Steam 연동의 경계

Steam 배포, 친구 초대·로비, 데이터 전송, 게임 상태 권위, 서버 호스팅을 서로 다른 책임으로 설계한다.
Steam의 Unity 연동 안내에는 제3자 C# 바인딩이 포함된다. 공식 안내에 있다는 이유만으로 채택 버전의 호환성을 보장할 수 없다. [S1]
바인딩 후보는 라이선스, 사용 SDK, Windows x64, callback 수명, 선택한 scripting backend를 직접 확인한다.
NGO용 Steam 전송 어댑터는 별도의 검증 대상이며 기존 Unity Transport와 자동 호환된다고 전제하지 않는다.
Steam 로비는 권위 전투 시뮬레이션을 대신하지 않고 무료 전용 서버 제공 약속도 아니다. [S2][S3]
구체적인 연결 구조·재접속·호스트 이탈 정책은 [네트워크 설계](02-architecture-and-networking.md)를 따른다.

## 10. 다음 단계의 완료 증거

- M0: 정확한 Editor·패키지 버전, 재현 절차, 라이선스 자격 확인 주체가 기록된다.
- M0: 다른 작업 디렉터리에서 같은 저장소로 Windows 진단 빌드를 만들 수 있다.
- M1 초기 연결 확인: 한 캐릭터의 이동·기본 공격·한 스킬을 두 독립 실행 클라이언트에서 확인한다.
- M1 종료: 바스의 패시브/Q/W/E/R과 성장·R 해금을 구현하고 로드맵의 지연·판정 기준을 확인한다.
- M1: 50/100/150ms RTT의 보정·피격·중복 명령 결과를 수치와 영상으로 기록한다.
- M1 실패 시: 콘텐츠 생산량을 늘리기 전에 조작·권위·네트워크 선택을 수정한다.
- M2 진입 시: 선택한 기술 경로와 남은 제약을 [결정 기록](../05-decisions-and-sources.md)에 반영한다.

## 11. 보류 결정과 의존성

| 결정 | 필요한 증거 | 결정 단계 |
| --- | --- | --- |
| 실제 Unity 패치·패키지 조합 | 빌드·입력·네트워크 진단 | M0~M1 |
| NGO 유지 또는 다른 경로 | 지연 시험과 구현·유지보수 비용 | M1 종료 |
| 최종 서버 운영 방식 | 공정성, 연결 성공률, 지역별 RTT, 월 비용 | M4 |
| 유료 도구·서비스 구매 | 제작 주체와 실제 견적 | 구매 직전 사용자 결정 |
| 공개 지원 플랫폼 | 실제 기기 검증과 운영 부담 | M5 |

## 공식 출처

모두 2026-10-21 확인. 권장안과 시험 기준은 Project E의 제안이며 공식 제품 성능 보증이 아니다.

- U1: [Unity 6 release support](https://unity.com/releases/unity-6/support).
- U2: [Unity 6.3 — Introduction to URP](https://docs.unity3d.com/6000.3/Documentation/Manual/urp/urp-introduction.html).
- U3: [Unity 6.3 — Asset metadata](https://docs.unity3d.com/6000.3/Documentation/Manual/AssetMetadata.html).
- U4: [Unity 6.3 — Editor project settings](https://docs.unity3d.com/6000.3/Documentation/Manual/class-EditorManager.html).
- U5: [Unity Editor Software Terms](https://unity.com/legal/editor-terms-of-service/software), 확인한 문서 갱신일 2026-06-30.
- S1: [Steamworks API Overview](https://partner.steamgames.com/doc/sdk/api).
- S2: [Steamworks Multiplayer](https://partner.steamgames.com/doc/features/multiplayer).
- S3: [Steamworks Game Servers](https://partner.steamgames.com/doc/features/multiplayer/game_servers).

[U1]: https://unity.com/releases/unity-6/support
[U2]: https://docs.unity3d.com/6000.3/Documentation/Manual/urp/urp-introduction.html
[U3]: https://docs.unity3d.com/6000.3/Documentation/Manual/AssetMetadata.html
[U4]: https://docs.unity3d.com/6000.3/Documentation/Manual/class-EditorManager.html
[U5]: https://unity.com/legal/editor-terms-of-service/software
[S1]: https://partner.steamgames.com/doc/sdk/api
[S2]: https://partner.steamgames.com/doc/features/multiplayer
[S3]: https://partner.steamgames.com/doc/features/multiplayer/game_servers
