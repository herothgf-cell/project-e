# Godot 선택과 Steam 기술 기반

- 상태: Godot 전환 결정과 기술 기준. 2026-10-26 로컬 3라인 전투까지 구현했으며, 독립 실행 Windows 빌드·수동 조작 확인 전에는 M0 전체 완료로 기록하지 않는다.
- 작성·공식 출처 확인: 2026-10-22, Asia/Seoul.
- 범위: Windows PC 제작 환경, 버전 고정, 저장소 관리, Steam 연동 경계.
- 관련: [프로젝트 개요](../00-project-brief.md), [공통 규칙](../01-core-rules.md), [네트워크 설계](02-architecture-and-networking.md), [출시 계획](../release/01-steam-release-plan.md).

## 1. 결론

사용자의 Godot 선택에 따라 **Godot 4 Standard + 타입을 명시한 GDScript + Windows x86_64**로 시작한다.
첫 프로젝트는 `game/project-e/project.godot`이며, 작은 3D 진단 장면은 Compatibility 렌더러로 구성한다.
2026-10-22의 기반 작업은 이동·E 진단이었다. 2026-10-26 실행판은 세 영웅의 기본 공격·패시브·Q/W/E/R과 세 라인·봇·성장·공성·승패로 확장했다. [현재 콘텐츠와 구현 차이](../../doc/design/README.md)를 따른다. 온라인 전송·Steam 연결은 아직 없으며, 바스 E를 모든 영웅의 공통 회피기로 바꾸지 않았다.
세 영웅의 로컬 전투는 구현했고 온라인 예측·보정, Steam 연동은 이후 단계다. 로컬 자동 검증만으로 M1의 온라인 기준이나 M0의 실제 Windows 검증이 끝났다고 판단하지 않는다.
게임의 3v3·3라인·성장·공성 수치는 [공통 규칙](../01-core-rules.md)을 그대로 따른다.

## 2. 선택안과 이유

| 항목 | 출발점 | 결정 이유·검증 조건 |
| --- | --- | --- |
| 엔진 계열 | Godot 4 Standard | 사용자 선택을 반영하고 작은 진단 프로젝트부터 검증 |
| 언어 | 타입을 명시한 GDScript | 규칙과 노드 표현을 나누고 초기 도구 의존성을 제한 |
| 렌더링 | Compatibility | 단순 지형·색상·접지 이동으로 조작과 화면 가독성을 먼저 확인 |
| 첫 플랫폼 | Windows x86_64 | 실제 PC 독립 실행과 Steam 배포 검증에 집중 |
| 첫 입력 | 마우스·키보드 | 우클릭 이동과 Q/W/E/R/D의 확장 경계, 향후 키 재지정 |
| 초기 온라인 | M1에서 `ENetMultiplayerPeer` + RPC | 서버 권위와 직접 연결 진단부터 시작; 예측·보정은 별도 구현 |
| 첫 배포 형태 | 개발용 독립 실행 빌드 | 에디터 밖의 시작·종료·입력·화면부터 확인 |

공식 문서는 Compatibility를 OpenGL 기반 렌더러로 설명하며 Forward+와 Mobile은 별도 기능·하드웨어 조건을 갖는다. [G2]
Compatibility는 초기 작은 회색 상자 장면의 제작 판단이다. 본 제작의 스타일화 3D, 그림자, 스킬 경고·투명 효과 요구가 구체화되면 같은 장면에서 렌더러별 가독성과 CPU/GPU 비용을 측정해 다시 선택한다.
엔진이나 렌더러 이름만으로 60fps, 최소 사양, 온라인 품질을 보장하지 않는다.

## 3. 엔진 후보와 실제 버전 고정

2026-10-22 공식 Windows 다운로드 페이지는 Standard x86_64 **4.7.2**, 공개일 **2026-08-18**을 표시한다. [G1]
현재 기준 버전은 **4.7.2 Standard**로 고정하며 저장소 루트 `.godot-version`에 기록한다. 확보한 공식 Linux 실행 파일의 `--version` 출력은 `4.7.2.stable.official.ed1daf0bf`다.
이 확인은 Linux 실행 파일의 버전 확인이며 Windows 실행·export 성공을 뜻하지 않는다. 같은 4.7.2 export templates와 Windows x86_64 실행 파일로 별도 검증해야 한다.
공식 배포 파일·체크섬·검증 환경은 실행 기록에 남긴다. 이후 페이지 표시와 확보 가능한 배포본이 다르면 차이와 선택 근거를 기록한다.
Standard를 사용하므로 초기 GDScript 프로젝트에는 .NET SDK를 요구하지 않는다. C# 전환이나 커스텀 엔진 빌드는 필요가 입증될 때 별도 결정한다.

| 구성 요소 | 현재 기준 | M0~M1에서 남길 기록 |
| --- | --- | --- |
| Godot 실행 파일 | 4.7.2 Standard, Linux `--version` 확인 | 실제 `--version`, 배포 URL·체크섬, 실행 OS와 선택 이유 |
| Export templates | 엔진과 같은 버전 사용 | 확보한 템플릿 버전, Windows export 결과 |
| GDScript | 명시적 타입을 우선 사용 | 파싱·리소스 로딩 결과와 실행 방법 |
| 렌더러 | 초기 Compatibility | `project.godot` 설정과 실제 그래픽 실행 결과 |
| 입력 | Godot Input Map | 액션명, 마우스 입력, 포커스 복귀·재지정 검증 |
| 네트워크 | M1 ENet/RPC 계획 | 실제 엔진 버전의 연결·지연·재접속 진단 |
| Steam SDK·바인딩 | M3 이후 후보 평가 | SDK·애드온 버전, 라이선스, Windows x86_64·전송 호환성 |

`stable` 문서 URL은 참조용이며 엔진 버전 잠금 수단이 아니다.
엔진이나 애드온 변경은 별도 변경 단위로 수행하고 같은 진단 장면으로 회귀를 비교한다.

## 4. M0 재현과 완료 증거

공식 CLI는 `--version`, `--path`, `--headless`, 에디터 실행과 export 옵션을 제공한다. [G3]
실제 실행 파일 경로를 지정하고 프로젝트 루트에서 실행한다. headless import 성공, 규칙 검사 성공, Windows export 성공, Windows에서의 화면·입력 확인은 서로 다른 증거다.
`--headless` 성공은 GPU 렌더링이나 마우스 조작을 확인하지 않는다. export에는 맞는 export templates와 preset이 필요하다. [G3]

M0 완료 기록에는 다음을 남긴다.

- 실제 엔진 버전과 export templates, 실행 절차, 측정 PC·OS.
- 깨끗한 작업 디렉터리에서 import와 스크립트·리소스 로딩 확인.
- Windows x86_64 진단 export 성공 및 산출물 식별자.
- 실제 Windows에서 시작·종료, 우클릭 이동, 벽 접촉·대시 정지, 화면·포커스 복귀를 수동 확인한 결과.
- 소스·리소스 재열기, Godot 라이선스 고지 및 사용 애드온 확인 담당자.

검증을 수행하지 못한 항목은 미확인으로 남긴다. 작은 scaffold와 오프라인 진단은 M0의 출발점이며 전체 전투나 온라인 완료 증거가 아니다.

## 5. 빌드와 화면 기준

| 항목 | 초기 가설 | 확정 시점 |
| --- | --- | --- |
| 실행 대상 | Windows x86_64, 첫 검증 OS는 Windows 11 x64 | 최소 지원 OS는 M5 실제 시험 후 |
| 화면 | 1920×1080을 첫 측정 기준, 창·전체화면 전환 | M3 UI 검증 |
| 클라이언트 | 60fps 목표 | M5 최소 사양의 실측 결과 |
| 권위 시뮬레이션 | 30Hz 시작안 | M1 지연 시험·M2 부하 시험 |
| 스냅샷 | 30Hz 시작안 | 전송량·보간·손실 시험 |
| 그래픽 품질 | 낮음·기본 두 단계부터 | 교전 가독성을 유지하는 범위 |

입력 수집·권위 tick·렌더 프레임을 같은 책임으로 묶지 않는다.
초기 오프라인 진단에서 물리 tick을 30Hz로 두더라도 서버 통신이 구현된 것은 아니다.
애니메이션은 권위 상태를 표현하며 피격을 확정하지 않는다.
최소 GPU·CPU·RAM은 아직 지정하지 않는다. 시험 장비를 기록하고 M5에서 검증한 수치를 게시한다.
Steam Deck, 컨트롤러, macOS, Linux 클라이언트는 이후 평가 대상이며 출시 약속에 넣지 않는다.
Linux 서버 운영 여부는 별도 인프라 선택이다.

## 6. 저장소 관리 원칙

텍스트 장면 `.tscn`, 편집용 리소스 `.tres`, 스크립트 `.gd`, 생성된 스크립트 등의 `.uid` 보조 파일, `project.godot`, 비밀을 포함하지 않는 `export_presets.cfg`를 원본과 함께 버전 관리한다.
TSCN은 장면 트리를 저장하는 텍스트 형식이며 UID로 리소스 참조를 유지한다. [G4]
파일 이동·이름 변경 뒤에는 UID 참조와 장면 로딩을 확인한다. 생성된 `.uid`를 임의 삭제하거나 `.godot/` 캐시와 함께 제외하지 않는다.
`.godot/`의 임포트·에디터 캐시와 로컬 빌드 산출물은 재생성 대상으로 제외한다. 공식 VCS 안내도 `.godot/`를 제외하도록 설명한다. [G5]
원본 에셋과 필요한 임포트 설정 파일은 보존하며, 큰 텍스처·음원은 용량과 배포 권한을 확인한 뒤 Git LFS 여부를 정한다.
파일·폴더명은 `snake_case`를 기준으로 한다. 클래스 이름은 Godot 관례의 `PascalCase`를 사용할 수 있다.
애드온을 도입하면 `addons/`의 소스·필수 바이너리, 정확한 릴리스 또는 커밋, 라이선스·Godot 호환 버전을 기록한다. 엔진 업데이트와 애드온 업데이트를 무심코 함께 수행하지 않는다.
API 키·서버 비밀키·Steam 업로드 자격증명·export 비밀 설정은 저장소나 클라이언트에 넣지 않는다.

## 7. 저장소 경로와 책임

다음 표는 Godot 프로젝트의 기준 경로와 확장 방향이다. 표에 있는 모든 모듈이 이미 구현되었다는 뜻은 아니다.

| 경로 | 책임 |
| --- | --- |
| `docs/` | 승인·검증 상태가 드러나는 기획과 의사결정 |
| `game/project-e/project.godot` | 프로젝트 진입 설정·입력·렌더링·물리 tick |
| `game/project-e/domain/` | 피해·성장·경제·상태 규칙, 장면 트리에 의존하지 않는 `RefCounted` 기반 코드 |
| `game/project-e/simulation/` | tick 진행, 입력 적용, 공간 질의 경계, 권위 상태 |
| `game/project-e/networking/` | 향후 명령·스냅샷·재접속·전송 어댑터 |
| `game/project-e/presentation/` | 카메라·UI·애니메이션·음향·VFX |
| `game/project-e/platform/` | 향후 Steam·설정 저장·플랫폼 추상화 |
| `game/project-e/content/` | 캐릭터·스킬·웨이브·맵의 편집용 `Resource`와 `.tres` |
| `game/project-e/scenes/` | 부트와 조작 진단 장면, 이후 아레나·연습장 |
| `game/project-e/tests/` | 필요한 규칙·명령 검증과 headless 진단 |
| `game/project-e/addons/` | 채택할 때 버전을 고정한 외부 애드온 |
| `tools/` | 반복 가능한 실행·검증 절차, 필요한 범위에서 추가 |

Simulation과 Presentation이 모두 `Node3D`를 사용하더라도 상태 소유권은 분리한다.
편집용 `Resource`를 곧바로 매치 상태로 쓰지 않고 시작 시 검증·복사한 정의로부터 상태를 만든다. 자세한 경계는 [아키텍처](02-architecture-and-networking.md)를 따른다.

## 8. 라이선스와 배포 고지

Godot는 MIT 라이선스이며 상업적 배포가 가능하다. 엔진을 게임과 함께 배포할 때 저작권·라이선스 고지를 포함해야 한다. [G6]
게임 콘텐츠의 라이선스는 제작자가 별도로 정할 수 있으며, 엔진의 MIT 라이선스가 외부 아트·음원·폰트·애드온까지 대신 허가하지 않는다. [G6]
배포 크레딧 또는 문서에 Godot 고지를 제공하고, 선택한 빌드에 포함되는 제3자 구성 요소의 고지도 확인한다.
서버·에셋·플러그인 비용은 실제 견적과 필요성을 확인한 뒤 결정하며 이 문서는 구매를 지시하지 않는다.

## 9. Steam 연동의 경계

Steam 배포, 친구 초대·로비, 데이터 전송, 게임 상태 권위, 서버 호스팅은 서로 다른 책임이다.
Valve API 안내는 Godot에 네이티브 Steamworks 지원이 없으며 **GodotSteam은 제3자 솔루션**이라고 명시한다. 목록 등재가 Valve의 보증은 아니다. [S1]
GodotSteam 채택 여부·형태·버전은 아직 결정하지 않았다. Godot Standard와의 호환성, Windows x86_64, Steam SDK 버전, callback 수명, 배포 파일과 라이선스를 확인한 뒤 선택한다.
Steamworks API 호출이 가능하다는 사실과 Godot 고수준 멀티플레이의 전송 계층을 Steam에 연결할 수 있다는 사실을 구분한다.
ENet 직접 연결은 Steam 전송으로 자동 전환되지 않는다. 필요하면 호환 `MultiplayerPeer` 또는 별도 전송 어댑터를 평가하고 RPC·채널·접속 종료·재접속 동작을 다시 검증한다.
Steam 로비는 권위 시뮬레이션을 대신하지 않으며 무료 전용 서버 제공 약속도 아니다. [S2][S3]
연결 구조·재접속·호스트 이탈 정책은 [네트워크 설계](02-architecture-and-networking.md)를 따른다.

## 10. 이후 단계와 보류 결정

- M0: 실제 버전·재현 절차·Windows export와 수동 실행 증거를 남긴다.
- M1 초기: 한 캐릭터의 이동·기본 공격·한 스킬을 두 독립 실행 클라이언트에서 확인한다.
- M1 종료: 바스의 패시브/Q/W/E/R과 성장·R 해금을 구현하고 50/100/150ms RTT의 예측·보정·판정 기준을 확인한다.
- M1 실패: 콘텐츠 생산량을 늘리기 전에 조작·권위·전송 선택을 수정한다.
- M2 진입: 채택한 기술 경로와 남은 제약을 [결정 기록](../05-decisions-and-sources.md)에 반영한다.

| 결정 | 필요한 증거 | 결정 단계 |
| --- | --- | --- |
| 4.7.2의 Windows 실행·templates 확인 | import·Windows export·수동 실행 | M0 |
| 본 제작 렌더러 | 시각 요구·목표 장비의 가독성·프레임 비용 | M1~M3 |
| ENet/RPC 경로 유지 | 지연 시험과 예측·보정 구현·유지 비용 | M1 종료 |
| GodotSteam과 Steam 전송 | SDK·바인딩·전송 호환성·인터넷 접속 시험 | M3~M4 |
| 최종 서버 운영 방식 | 공정성·연결 성공률·지역별 RTT·월 비용 | M4 |
| 공개 지원 플랫폼 | 실제 기기 검증과 운영 부담 | M5 |

## 공식 출처

모두 2026-10-22, Asia/Seoul 확인. 기술 선택·목표는 Project E의 판단이며 공식 제품 성능 보증이 아니다.

- G1: [Godot — Download for Windows](https://godotengine.org/download/windows/).
- G2: [Godot — Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).
- G3: [Godot — Command line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).
- G4: [Godot — TSCN file format](https://docs.godotengine.org/en/stable/engine_details/file_formats/tscn.html).
- G5: [Godot — Version control systems](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html).
- G6: [Godot — License](https://godotengine.org/license/).
- S1: [Steamworks API Overview](https://partner.steamgames.com/doc/sdk/api).
- S2: [Steamworks Multiplayer](https://partner.steamgames.com/doc/features/multiplayer).
- S3: [Steamworks Game Servers](https://partner.steamgames.com/doc/features/multiplayer/game_servers).
