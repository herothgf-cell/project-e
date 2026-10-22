# Godot 빠른 시작과 현재 검증 기록

- 개정: 2026-10-22, Asia/Seoul.
- 현재 범위: M0 기반과 오프라인 조작 진단. 전체 M0·M1 완료가 아니다.
- 엔진 기준: **Godot 4.7.2 Standard**, GDScript, Compatibility, GodotPhysics3D, 물리 30Hz.
- 프로젝트: [`game/project-e/project.godot`](../../game/project-e/project.godot).
- 관련: [기술 선택](01-godot-and-steam.md), [온라인 구조](02-architecture-and-networking.md), [이번 작업 계획](../plans/2026-10-22-godot-foundation.md).

## 1. Windows에서 열기

1. [공식 Windows 다운로드](https://godotengine.org/download/windows/)에서 **Godot Engine 4.7.2 / Windows x86_64**를 받는다. GDScript 프로젝트이므로 **Standard**를 사용하며 `.NET`과 별도 C# SDK가 필요하지 않다. 기본 다운로드 버전이 바뀌면 [4.7.2 보관함](https://godotengine.org/download/archive/4.7.2-stable/)에서 같은 버전을 받는다.
2. 압축을 풀고 Godot 실행 파일을 실행한다. 공식 배포본은 압축 해제 후 바로 실행하는 방식이다. [G1]
3. 이 저장소를 `git clone` 또는 GitHub의 **Code → Download ZIP**으로 받는다. ZIP을 사용했다면 전체를 압축 해제한다.
4. Godot 프로젝트 관리자에서 **Import**를 누르고 `game/project-e/project.godot`을 선택한다.
5. 첫 임포트가 끝나면 **F5** 또는 우측 위 프로젝트 실행 버튼을 누른다. `combat_probe.tscn`이 시작된다.

`project.godot` 파일은 편집기를 실행하는 프로그램이 아니라 프로젝트 설정이다. Godot에서 가져와 열어야 한다. `.godot-version`은 개발 기준을 기록하는 파일이며 에디터를 자동 설치하거나 잘못된 버전 실행을 차단하지는 않는다. 아래 검증 도구는 버전 차이를 검사한다.

## 2. 조작과 확인할 장면

| 조작 | 동작 | 첫 확인 |
|---|---|---|
| 우클릭 | 바닥 목적지로 이동 | 5.8m/s, 목적지를 넘어가지 않음 |
| E, 이어서 좌클릭 | 조준을 확정하고 돌진 | 에너지 20 소모, 즉시 5초 쿨다운 시작 |
| Esc | 확정 전 E 조준 취소 | 자원 소모 없음 |
| S | 일반 이동 정지 | 이미 승인된 E의 선딜·돌진·후딜을 취소하지 않음 |
| F2 | 진단 상태 초기화 | 시작 위치·에너지 100·쿨다운 0 |

E는 **0.12초 준비 → 최대 4.2m를 14m/s로 이동 → 0.16초 회복** 순서다. 시작 시 정한 방향을 유지한다. 중앙 벽과 외곽 벽에 캡슐이 닿으면 통과하지 않고 돌진을 종료한다. 같은 위치를 조준하거나 자원이 부족하면 시전을 승인하지 않는다. 에너지는 초당 8 회복한다.

이 장면에서는 벽 자동 우회와 행동 예약이 없다. 벽 반대편으로 우클릭하면 벽 앞에서 멈추므로 통로를 직접 클릭한다. 시전 중 새 이동 명령은 예약하지 않는다. 현재 영어 HUD와 단순 도형은 최종 언어·아트 방향을 확정하지 않는다.

## 3. 구현한 부분과 다음 단계

| 구현한 부분 | 다음 단계 |
|---|---|
| 작은 평면, 벽, 바스 대용 도형, 고정 탑다운 카메라 | 실제 M01 세 라인·시야·타워·공명핵 |
| 클릭 이동, E 조준/선딜/이동/후딜, 벽 정지 | 경로 탐색·행동 예약·영웅 접촉 피해/밀치기·CC |
| 에너지·쿨다운·동작 상태 HUD, 초기화 | 기본 공격·패시브·Q/W/R·성장·튜토리얼 |
| 같은 엔진으로 실행하는 규칙/장면 검사 | 두 클라이언트 ENet 연결, 서버 권위, 예측·보정·50/100/150ms RTT |
| Windows export preset | 같은 버전 templates 확보, Windows export·실행·수동 조작 |

전송·호스트·매칭·Steam 로그인/초대는 아직 구현하지 않았다. 이 장면은 온라인 성능이나 게임 한 판의 재미를 검증한 결과가 아니다.

## 4. 소스 구조

| 파일 | 책임 |
|---|---|
| `scripts/bas_motion.gd` | 명시적 시간으로 이동 의도와 E 단계·에너지·쿨다운 계산 |
| `scripts/probe_player.gd` | `CharacterBody3D`에 이동 의도를 적용하고 실제 벽 충돌 반영 |
| `scripts/combat_probe.gd` | 마우스 지면 투영, 입력·조준·HUD·초기화 |
| `scenes/player.tscn` | 반경 0.45m의 이동 캡슐과 임시 도형 |
| `scenes/combat_probe.tscn` | 진단 지형·카메라·HUD |
| `tests/test_bas_motion.gd` | 이동 거리·시전 승인·단계·비정상 입력·초기화 규칙 검사 |
| `tests/test_probe_scene.gd` | 실제 장면 로딩·입력 바인딩·이동·벽 충돌 검사 |

위 경로는 `game/project-e/` 기준이다. 장기 확장 계층은 [기술 문서](01-godot-and-steam.md)에 있으며, 현재 소규모 진단 코드는 `scripts/`에 모았다.

## 5. 자동 검증 실행

아래 명령은 **저장소 루트**에서 실행한다. `godot`은 실제 4.7.2 실행 파일 경로로 바꿔도 된다. Windows PowerShell에서 공백이 있는 실행 파일 경로는 `& '실제 경로'` 형식으로 호출한다.

```sh
godot --version
godot --headless --path game/project-e --editor --import
godot --headless --path game/project-e --script tests/test_bas_motion.gd
godot --headless --path game/project-e --script tests/test_probe_scene.gd
godot --headless --path game/project-e --quit-after 90
```

Python 3가 있는 개발 환경에서는 위 단계를 한 번에 검사할 수 있다. 플레이에 Python을 요구하지는 않는다.

```sh
python tools/check_godot.py --godot /actual/path/to/godot
```

Windows PowerShell 예시에서 `$godotExe`는 다운로드 후 압축을 푼 실제 위치로 수정한다.

```powershell
$godotExe = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godotExe --headless --path game/project-e --script tests/test_bas_motion.gd
& $godotExe --headless --path game/project-e --script tests/test_probe_scene.gd
```

Godot은 일부 로딩 오류를 출력해도 프로세스 종료 코드가 0일 수 있다. 검증 도구는 종료 코드 외에도 `ERROR:`/`SCRIPT ERROR:`와 각 시험의 완료 문구를 확인한다. headless 검증은 실제 화면·마우스 조작·Windows 호환성 검증을 대신하지 않는다.

## 6. 2026-10-22 실행 기록

| 항목 | 확인 결과 |
|---|---|
| OS / CPU 아키텍처 | Ubuntu 24.04.3 LTS / x86_64 |
| 엔진 실제 출력 | `4.7.2.stable.official.ed1daf0bf` |
| 배포본 | 공식 Linux Standard zip, [공식 다운로드 경로](https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=linux.x86_64.zip&platform=linux.64) |
| 받은 zip의 SHA-256 | `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4` — 받은 파일의 식별값이며 별도 서명 검증을 뜻하지 않음 |
| 에디터 import | 종료 코드 0, 오류 출력 없음 |
| 이동 규칙 | 40개 점검, 실패 0 |
| 실제 장면·충돌 | 19개 점검, 실패 0 |
| 메인 장면 headless 시작 | `--quit-after 90`, 종료 코드 0, 오류 출력 없음 |
| 실제 그래픽 화면·손 조작 | 미확인 |
| Windows templates/export/실행 | 미확인 |
| 인터넷 접속·지연·성능 | 미구현·미측정 |

검증 환경은 Godot 데이터·설정·캐시 경로를 각각 임시 `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`으로 지정했다. 제한된 환경에서 에디터의 로컬 디버그 포트 개방이 차단되어 import는 해당 로컬 동작이 허용되는 실행으로 확인했다. 게임·규칙 검사는 외부 서버에 접속하지 않는다.

## 7. Windows 독립 실행 파일 만들기 — 다음 M0 확인

1. Godot **Editor → Manage Export Templates**에서 에디터와 동일한 **4.7.2 Standard** templates를 설치한다.
2. 저장소 루트에 `build/windows/` 폴더를 만든다.
3. **Project → Export**에서 이미 있는 **Windows Desktop** preset을 고른다. 아키텍처는 `x86_64`다.
4. `build/windows/ProjectE.exe`로 export한다. 현재 preset은 외부 `.pck` 방식이므로 실행 파일과 함께 생성된 `.pck`를 같이 보관한다. [G3]
5. Windows PC에서 에디터 없이 실행하고 화면·우클릭·E·벽·F2·창 포커스 복귀를 확인한다.

CLI export는 다음과 같다. templates와 출력 폴더를 먼저 준비한다.

```sh
godot --headless --path game/project-e --export-debug "Windows Desktop"
```

현재 Windows preset은 개발 검증용이며 코드 서명·Steam SDK를 포함하지 않는다. 이 문서의 명령 제공은 Windows export를 수행했다는 보고가 아니다. 배포에는 [제3자 고지](../../THIRD_PARTY_NOTICES.md)를 함께 포함한다.

## 공식 자료

- G1: [Godot Windows 다운로드](https://godotengine.org/download/windows/).
- G2: [Godot CLI](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).
- G3: [Godot Windows export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html).
