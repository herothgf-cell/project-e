# 결정 이력·작업 가정·출처

- 버전/작성일: v0.2 / 2026-10-22
- 목적: 사용자 요구, 현재 기획 제안, 후속 검증이 필요한 결정을 구분한다.
- 관련: [개요](00-project-brief.md), [공통 규칙](01-core-rules.md), [로드맵](02-development-roadmap.md), [Godot/Steam](technical/01-godot-and-steam.md)

## 1. 사용자 요구로 고정한 사항

| ID | 요구 | 근거와 반영 |
|---|---|---|
| U01 | 스타크래프트 유즈맵이 아닌 별도 PC 게임 | 독립 Windows 실행을 초기 플랫폼 제안으로 구체화 |
| U02 | Steam 출시 목표 | 온라인 검증과 Steam 준비를 로드맵에 포함 |
| U03 | 참고작에서 느꼈던 핵심 게임성 유지 | 빠른 전투·세 라인·지원·경기 중 성장·공성을 설계의 중심으로 해석 |
| U04 | 그대로 옮긴 게임이라는 인상은 피하기 | 캐릭터 기술·맵 세부 구조·표현을 독립적으로 설계 |
| U05 | 콘텐츠·캐릭터 요소별 기획과 로드맵 | 분야별 문서와 단계별 산출물/검증 기준 작성 |
| U06 | 지정 GitHub 저장소에 문서 작성 | `herothgf-cell/project-e`의 `docs/` 구조 사용 |
| U07 | Godot으로 진행 | “godot 으로 해보자”라는 후속 선택에 따라 현재 엔진을 Godot으로 변경 |

위 요구의 출처는 이번 대화다. 세부 인원, 수치, 세계관, 이름, 캐릭터 기술, 출시 가격까지 사용자 승인으로 확대하지 않는다. v0.1에서는 Unity 질문을 기술 선택 검토로 반영했다. v0.2에서는 사용자의 Godot 선택을 반영한다. GDScript·Compatibility 렌더러·정확한 패치는 구현 기본값 또는 검증 항목이며 별도의 명시적 사용자 요구로 취급하지 않는다.

## 2. 현재 채택한 기획 기준

| ID | 결정 | 이유 | 검증/변경 시점 |
|---|---|---|---|
| D01 | 3v3, 세 라인, 한 플레이어 한 영웅 | 빠른 지원·개인 판단·팀 공성을 작은 인원으로 검증 | M2–M3 |
| D02 | Q/W/E/R와 패시브, 일반기 짧은 주기 | 입력 부담을 제한하면서 기술 교환 빈도 확보 | M1–M3 |
| D03 | 경기 내 포인트 성장, 계정 능력치 우위 없음 | 매 판 선택에 집중하고 외부 성장 격차 제거 | M2–M3 |
| D04 | 크레딧은 초기 소비품 2종에 사용 | 성장 포인트와 구매의 책임을 단순하게 검증 | M3에서 선택 부족 시 재설계 |
| D05 | 밝은 공방/원소 공학 세계, 가칭 수로 공방 | 빠른 전투의 식별성과 독립적 시청각 표현 | M3 표현 검증 |
| D06 | 바스·리오·네마의 서로 다른 기술 판단 | 진입·귀환 궤적·장치 연결의 조작 차이 | M1–M3 |
| D07 | 처음 3영웅/1맵, 출시 후보 6영웅/1맵 | 실제 한 판을 먼저 완성하고 조합 선택을 확장 | M3 이후 추가 영웅 착수 |
| D08 | Godot 4.7.2 Standard 사용 확정; 초기 기본값은 타입을 명시한 GDScript + Compatibility | 사용자의 Godot 선택을 반영하고 작은 시작 프로젝트에서 검증 | M0 동일 버전 export template·Windows 실행 검증 |
| D09 | Windows x86_64·마우스/키보드 우선 | 첫 배포·입력·성능 검증 범위 제한 | 다른 플랫폼은 별도 검증 |
| D10 | 초기 권한 서버 30Hz, 화면 60fps 목표 | 빠른 전투 판정과 측정 가능한 예산 설정 | M1–M2 실측 |
| D11 | 초기 listen server, 전용 서버로 분리 가능한 구조 | 비공개 검증을 시작하면서 공정성/운영 위험 확인 | M4 출시 구조 결정 |
| D12 | 공개 매칭은 실제 수요/지연/운영비를 보고 결정 | 친구 방 성공과 지속 가능한 큐를 구분 | M4–M5 |
| D13 | 기간 약속 없이 M0–M6 통과 기준 운영 | 실제 인원·속도·예산을 아직 확인하지 않음 | M1 이후 일정 추정 |
| D14 | M0 시작 소스는 오프라인 입력·이동·E 단계·자원/쿨타임 진단으로 제한 | 환경과 최소 조작을 먼저 확인하고 전체 전투/온라인과 구분 | Windows export·수동 검증 이후 M1 확대 |
| D15 | v0.1 Unity 권장안을 v0.2 Godot 기준으로 대체 | 사용자 후속 엔진 선택. 게임 규칙·콘텐츠 수·M0–M6 통과 기준은 유지 | 엔진별 실행·export·네트워크 검증 증거 기록 |

모든 피해·쿨타임·경험치·좌표·경기 시간은 새 게임의 초기 가설이다. 원작의 수치를 복원했거나 원작과 같은 플레이 감각을 실측했다는 뜻이 아니다. 변경할 때는 [공통 규칙](01-core-rules.md)과 관련 콘텐츠·영웅·검증 문서를 함께 고친다.

## 3. 후속 결정 목록

| 시점 | 결정할 내용 | 결정에 필요한 증거 |
|---|---|---|
| M0 | 실제 제작 인원·장비·시간·예산 책임 | 사용할 환경과 투입 가능 자원 |
| M0 | 고정한 Godot 4.7.2의 export template·애드온 적용과 Windows 환경 재현 | Linux 실행 버전 `4.7.2.stable.official.ed1daf0bf`; Windows x86_64 export/수동 검증은 대기 |
| M1 | 예측/보정 구현 범위와 네트워크 후보 | 같은 2클라이언트 진단의 결과 비교 |
| M3 | 고유한 정체성과 최초 세 영웅 유지 여부 | 새 조작·상대법에 대한 행동/인터뷰 |
| M3–M4 | 추가 영웅의 실제 제작 순서 | 조합의 빈틈·학습 부담·제작 난도 |
| M4 | 공개 이름·비즈니스 모델·서버 형태/지역 | 제품 이해도·접속·수요·운영비 |
| M4–M5 | 공개 매칭·출시 언어·최소 PC 사양 | 실제 외부 환경의 측정 기록 |
| M5 | 가격·출시일·최종 제공 기능 | 완성 빌드와 운영/배포 준비 증거 |

이 목록은 현재 문서 작성을 멈추기 위한 질문이 아니다. 해당 단계에서 근거를 갖추고 결정할 항목이다. Steam 등록·수수료·공개 작업은 이 문서 작성에 포함하지 않는다.

## 4. 참고작의 사용 범위

참고 대상은 사용자가 확인한 **시티 오브 템페스트**다. 이 문서는 그 게임을 분석해 빠른 기술 교환·지원·성장·공성이라는 재미의 구조를 새 프로젝트의 목표로 정리한 것이다.

원작의 특정 패치, 모든 영웅, 정확한 수치, 맵 배치를 재현하는 사양으로 사용하지 않는다. 오래된 소개·위키·플레이 기억은 버전이 섞일 수 있으므로 새 규칙의 정본으로 삼지 않는다. 최초 세 영웅은 원작 영웅에 대응시키는 표 없이 독립적으로 설계했다.

초기 질문에서 게임성 유지와 독립적인 작품 정체성을 함께 요구했으므로, 동일한 기술/맵의 외형 변경보다 **새로운 결정과 대응법을 가진 영웅**을 우선했다. 장르적 유사성을 전혀 알아보지 못한다는 보장은 하지 않으며 [정체성 검증](04-playtest-and-balance.md)을 통해 확인한다.

## 5. 공식 자료로 확인한 기술·출시 사실

Steam 자료의 최초 확인일은 2026-10-21이며 Godot 전환 문서의 개정일은 2026-10-22다. 아래는 제품 선택의 근거이며 실제 설치·연동·출시 완료의 증거가 아니다. Godot은 `.godot-version`에 `4.7.2`로 고정하고 Linux 실행 버전 `4.7.2.stable.official.ed1daf0bf`를 확인했다. 이 기록은 Windows 검증을 뜻하지 않는다. 버전과 실제 실행 결과는 [기술 기준](technical/01-godot-and-steam.md)과 [빠른 시작](technical/03-godot-quickstart.md)에 기록한다. 버전·라이선스·요금·심사 조건은 적용 단계에서 다시 확인한다.

| 주제 | 확인 내용 | 공식 자료 |
|---|---|---|
| Steam과 엔진 | Steamworks는 여러 게임 엔진의 연동 경로를 안내한다. Godot 선택과 Steam 배포·API 연동 검증은 별도 작업이다. | [Steamworks API](https://partner.steamgames.com/doc/sdk/api) |
| Godot 라이선스 | MIT 라이선스이며 엔진 사용료·매출 로열티가 없다. 배포 시 라이선스·저작권 고지를 포함하고 별도 자산/애드온 권리를 확인한다. | [Godot License](https://godotengine.org/license/) |
| 언어 | Godot은 GDScript·C# 등 여러 언어를 지원한다. 초기 프로젝트는 Standard 배포판과 타입을 명시한 GDScript를 기본값으로 사용한다. | [Scripting languages](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html) |
| 렌더러 | Compatibility는 Godot 4의 렌더러 선택지다. 초기 선택은 작은 3D 진단의 실행 범위를 위한 것이며 최종 PC 성능을 입증하지 않는다. | [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) |
| 온라인 | Godot의 high-level multiplayer API는 RPC와 전송 연결을 제공한다. 이 게임의 이동 예측·서버 보정·지연 보상은 별도 설계와 2클라이언트 측정이 필요하다. | [High-level multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) |
| 자동 실행·서버 | CLI와 headless 실행 경로로 진단·전용 서버 빌드를 준비할 수 있다. 실제 Windows export와 온라인 성능 검증을 대체하지 않는다. | [Command line](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html), [Dedicated servers](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html) |
| Steam Playtest | 본편에 연결된 별도 App ID로 테스트 참가를 관리하는 무료 기능이다. | [Steam Playtest](https://partner.steamgames.com/doc/features/playtest) |
| 게임 서버 | 게임 서버 호스팅은 개발자/커뮤니티가 운영할 수 있는 별도 대상이다. 로비/Relay 제공을 무료 서버 실행 자원으로 계산하지 않는다. | [Game Servers](https://partner.steamgames.com/doc/features/multiplayer/game_servers) |
| 수수료 | 신규 앱 수수료와 매출 조건에 따른 회수 규정이 있다. 실제 금액·세금·자격은 결제 시 확인한다. | [Steam Direct Fee](https://partner.steamgames.com/doc/gettingstarted/appfee) |
| 심사/공개 | 스토어와 빌드를 검토하며 승인 후 실제 공개 동작을 별도로 실행한다. | [Review Process](https://partner.steamgames.com/doc/store/review_process), [Release Process](https://partner.steamgames.com/doc/store/releasing) |

v0.1의 Unity 6.3 LTS·C#·URP와 NGO/Entities 비교는 당시의 권장안 이력이다. 현재 개발 기준이나 필수 패키지로 사용하지 않는다. 이전 경로 `technical/01-unity-and-steam.md`는 현재 [Godot 기술 문서](technical/01-godot-and-steam.md)로 안내하는 호환 문서로 남긴다. Godot 엔진 자체의 비용과 별개로 서버·유료 애드온·아트·음원·폰트·Steam 등록 비용을 관리한다.

## 6. 공식 자료의 불일치 처리

확인일에 Steam의 [Onboarding](https://partner.steamgames.com/doc/gettingstarted/onboarding)은 수수료 결제 이후 대기기간을 **21일**, [Steam Direct](https://partner.steamgames.com/steamdirect)는 **30일**로 표시한다. 한쪽을 임의로 최신 규칙이라고 단정하지 않는다.

로드맵에는 최소 30일의 여유를 잡고 실제 App 대시보드와 Steam Support에서 적용 조건을 확인한다. 공개 Coming Soon 기간, 심사, 수정·재제출 시간은 별도 조건으로 관리한다. 자세한 순서는 [출시 계획](release/01-steam-release-plan.md)을 따른다.

## 7. 2026-10-22 기반 작업 기록

- 프로젝트 개요와 단일 공통 규칙, 단계별 로드맵, 제작 범위와 검증 계획.
- 세계관/표현, 맵/공성, 병력/경제, 모드/학습/UI 기획.
- 최초 세 영웅의 상세 기술·상대법·예외와 추가 세 영웅의 확장 조건.
- Godot/네트워크/Steam 배포의 기준, 공식 근거와 후속 결정.
- `game/project-e/project.godot`의 M0 기반 소스와 오프라인 입력·이동·E 선딜/돌진/후딜·자원/쿨타임 진단 범위.

M0 시작 소스는 바스 전체 기술·성장·공성·3대3·네트워크 구현 또는 M1 완료가 아니다. 실제 테스트 명령과 결과는 [빠른 시작](technical/03-godot-quickstart.md)을 기준으로 보고한다. Windows 실행 파일의 export/수동 실행, 온라인 지연·손실/성능 실측, Steam 계정·App·스토어·Playtest 생성은 아직 완료하지 않았다. 문서 링크·규칙 일치 확인과 headless 진단만으로 화면·입력·Windows 배포를 검증했다고 기록하지 않는다.

## 8. 2026-10-26 이어서 구현한 범위

사용자는 3라인 전장·기본 공격·나머지 기술·영웅 간 전투, `doc/design` 요소별 문서와 게임/캐릭터 시안을 요청했다. 기존 수치와 세 영웅을 유지해 사람 1명과 봇 5명의 오프라인 3대3, 성장·공성·승패·재시작을 연결한다. 일반 경기와 R 즉시 체험을 구분한다. 현재 제안과 실제 차이는 [새 콘텐츠 문서](../doc/design/README.md), 자동 검사와 실제 렌더링 결과는 [검증 기록](../doc/design/09-verification.md)을 따른다. 온라인·Windows export·Steam·사람 플레이와 균형은 미검증으로 남긴다.

## 9. 변경 기록

| 버전 | 날짜 | 변경 |
|---|---|---|
| v0.1 | 2026-10-21 | 독립 Steam PC 게임으로 최초 기획. 원작의 핵심 재미를 목표로 삼고 신규 영웅·맵·표현을 설계. Unity 6.3 LTS·C#·URP 권장안과 공통 규칙·콘텐츠별 문서·M0–M6·온라인 조기 검증·출시 준비를 정리. |
| v0.2 | 2026-10-22 | 사용자 선택에 따라 Godot 4 Standard로 전환. 타입을 명시한 GDScript·Compatibility를 초기 기본값으로 채택. 기술 문서·빠른 시작·`game/project-e/project.godot` 경로, MIT 고지/비용과 Godot 추적 파일 규칙을 반영. 게임 규칙·콘텐츠 수·마일스톤 통과 기준은 유지. M0 시작 소스와 미완료인 Windows/온라인 검증을 구분. |
| v0.3 프로토타입 | 2026-10-26 | 기존 규칙으로 오프라인 3라인·3영웅·전투·성장·공성·승패 연결. doc/design 요소별 기획과 시안 2장, 실제 실행 검증을 추가. 인터넷/Windows/Steam 통과는 별도 유지. |

다음 개정부터는 실제 변경한 규칙, 바꾼 이유, 사용한 테스트 기록, 영향을 받는 문서를 함께 적는다.
