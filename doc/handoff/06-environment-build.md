# 06. 개발 환경 설치와 실행·빌드 인계

- 작성일: **2026-11-19, 한국 시간**.
- 기준 소스: `main`의 `e29c36296abf6d365353401dd0cbee411edc531d`, **V9 / 0.9.0**.
- 범위: 저장소에서 확인한 설치 조건과 재현 명령. 이번 문서 작업에서 게임·테스트·빌드를 새로 실행하지 않았다.
- **문서 묶음만으로 게임을 실행하거나 빌드할 수 없다.** 아래 명령에는 전체 소스와 실행 자산이 필요하다.

## 1. 현재 환경 기준

| 항목 | 인계 기준 | 상태·근거 |
|---|---|---|
| 엔진 | Godot **4.7.2 Standard** | 현재 코드 확인: [버전 잠금](../../.godot-version) |
| 언어 | GDScript | 현재 코드 확인: [스크립트](../../game/project-e/scripts/) |
| 프로젝트 | `game/project-e/project.godot` | 현재 코드 확인: [설정](../../game/project-e/project.godot) |
| 시작 장면 | `res://scenes/battlefield.tscn` | 현재 코드 확인: 같은 설정의 `run/main_scene` |
| 렌더러 | `gl_compatibility` | 현재 코드 확인: 같은 설정의 `[rendering]` |
| 물리 | GodotPhysics3D, 초당 30 tick | 현재 코드 확인: 같은 설정의 `[physics]` |
| 기본 표시 크기 | 1280×720, `canvas_items` stretch | 현재 코드 확인: 같은 설정의 `[display]` |
| 배포 대상 | Windows x86_64 release, EXE와 별도 PCK | 현재 코드 확인: [export preset](../../game/project-e/export_presets.cfg) |
| 개발 보조 도구 | Python **3.10 이상** | 기존 문서 기준: [Windows 빌드 안내](../../docs/technical/04-windows-build.md) |
| .NET·C# SDK | 현재 프로젝트에 요구하지 않음 | 기존 결정과 실제 GDScript 소스: [기술 기준](../../docs/technical/01-godot-and-steam.md) |

검사·패키징 Python 도구는 표준 라이브러리를 사용한다. 모델을 **재생성**할 때 필요한 NumPy·Pillow는 별도다.
Blender는 현재 게임 실행·export의 필수 도구가 아니며 저장소에 고정 요구 버전이 없다. [자산 인계](07-code-assets.md)
최소 지원 Windows 버전, CPU·GPU·RAM과 목표 PC의 60fps 달성 여부는 **미확인**이다.

## 2. 전체 소스 확보

아래는 인계 문서가 추가된 최신 저장소를 확보하는 예다. Git과 저장소 접근 권한이 필요하다.

```sh
git clone https://github.com/herothgf-cell/project-e.git project-e
cd project-e
git rev-parse HEAD
```

제품 동작의 비교 기준은 `e29c36296abf6d365353401dd0cbee411edc531d`이며 이번 `doc/handoff/`는 그 이후 문서 정리 커밋에 추가된다. 최신 HEAD와 이 제품 기준의 차이를 먼저 확인하고 수정 작업용 브랜치를 만든다.

원본 V9만 별도로 재현하려면 기존 checkout을 유지한 채 다음처럼 별도 작업 디렉터리를 만든다.

```sh
git worktree add --detach ../project-e-v9-reference e29c36296abf6d365353401dd0cbee411edc531d
```

원본 V9 커밋에는 새 `doc/handoff/`가 없다. 이 별도 재현 디렉터리에서는 전달받은 문서 묶음이나 최신 checkout의 인계 문서를 참고한다. 기준 재현을 위한 detached checkout과 이후 기능 개발 브랜치를 구분한다.
ZIP으로 받는 경우에도 `game/`, `tools/`, `.godot-version`, 고지 파일을 포함한 **전체 저장소**를 압축 해제한다.
문서 패키지의 상대 링크가 열리지 않으면 링크 대상 소스·자산이 함께 전달되었는지 먼저 확인한다.
코드 원본을 확보하지 못했다면 문서만으로 모델·전투 로직·PCK를 복원할 수 있다고 약속하지 않는다.

## 3. Windows에서 열기와 F5 실행

1. [기존 설치 안내](../../docs/technical/03-godot-quickstart.md)에 기록된 **Godot 4.7.2 Standard / Windows x86_64**를 준비한다.
2. 프로젝트 관리자에서 **Import**를 누르고 `game/project-e/project.godot`를 선택한다.
3. 자산 import가 끝나면 **F5**로 메인 프로젝트를 실행한다.
4. 8명 중 한 명을 고르고 일반 경기 또는 기술 체험을 시작한다.
5. 현재 일반 플레이는 **사람 1명 + 봇 5명, 오프라인 3 대 3**이다. [현재 안내](../../README.md)

Godot 에디터의 F6은 열린 장면 실행이다. 예전 `combat_probe.tscn`을 열어 둔 경우 이전 이동 진단이 실행될 수 있다.
실행 중 게임에서의 F6은 전장 시점 전환이고 F7은 독립 연출실이다. 에디터 단축키와 구분한다.

PowerShell에서 실행 파일의 실제 경로를 지정하면 같은 프로젝트를 열 수 있다.

```powershell
$projectEGodotExe = 'C:\Tools\ProjectE\Godot_v4.7.2-stable_win64_console.exe'
& $projectEGodotExe --version
& $projectEGodotExe --editor --path .\game\project-e
```

일반 CLI 예시는 저장소 루트와 **고정 버전의 `godot`가 PATH에 있는 환경**을 전제로 한다.

```sh
godot --version
godot --headless --path game/project-e --editor --import
godot --editor --path game/project-e
godot --path game/project-e
```

`--headless` import 성공은 그래픽 화면, 마우스 조작, GPU 성능을 확인하지 않는다.

## 4. 재실행할 검사 명령

다음은 **후속 제안: 새 환경에서 실행할 명령**이다. 이번 인계 작성의 실행 결과가 아니다.

```powershell
python tools/check_godot.py --godot $projectEGodotExe
python tools/check_art_assets.py
python tools/check_audio_assets.py
python -m unittest discover -s tools/tests -p 'test_package_windows.py'
```

일반 CLI에서는 첫 명령의 실행 파일 인자만 실제 경로로 바꾼다.

```sh
python tools/check_godot.py --godot /absolute/path/to/godot
python tools/check_godot.py --godot /absolute/path/to/godot --long-match
```

[검사기](../../tools/check_godot.py)는 버전 확인, import, **38개 행동 검사 묶음**, 메인 장면 90프레임 시작을 요청한다.
`--long-match`는 기본 `BattleAI`를 쓰는 `test_battle_match.gd`만 최대 1,860 시뮬레이션 초까지 연장한다. 별도의 `test_tactical_lifecycle.gd`는 이 옵션과 무관하게 최대 2,400초의 전술 AI 경기 수명을 검사한다. V9 공성 비교는 `measure_siege.gd`와 실제 `TacticalAI` 구성으로 별도 수행한다. 모든 조합의 사람 경기 검증이 아니다. [공성 계측 안내](elements/10-balance-tests.md)
종료 코드뿐 아니라 오류 줄과 완료 문구를 확인한다. 새 결과에는 커밋·실제 엔진 버전·실행 환경과 로그를 남긴다.

## 5. Windows export와 전달 ZIP

필요한 외부 파일은 공식 **4.7.2 Standard 엔진**, 같은 버전의 **export templates TPZ**, `GODOT-LICENSE.txt`, `GODOT-COPYRIGHT.txt`다.
정확한 기존 다운로드 경로와 당시 파일 SHA-256은 [Windows 빌드 안내](../../docs/technical/04-windows-build.md)에 보존되어 있다.
고정 버전을 구하지 못하면 다른 엔진으로 묵시적으로 바꾸지 말고 확보 실패와 변경 필요를 기록한다.
패키징 도구는 파일을 자동 다운로드하거나 전역 Godot 설정을 변경하지 않는다.

```powershell
python tools/package_windows.py --godot $projectEGodotExe --templates-archive 'C:\Tools\ProjectE\Godot_v4.7.2-stable_export_templates.tpz' --engine-notices-dir 'C:\Tools\ProjectE' --output-dir build/windows
```

```sh
python tools/package_windows.py \
  --godot /absolute/path/to/godot \
  --templates-archive /absolute/path/to/Godot_v4.7.2-stable_export_templates.tpz \
  --engine-notices-dir /absolute/path/to/notices \
  --output-dir build/windows
```

[패키징 구현](../../tools/package_windows.py)은 별도 소스 사본에서 import한 뒤 `--export-release "Windows Desktop"`를 실행한다.
그 후 PE x86_64·PCK 헤더, 파일·ZIP 해시, 고지, manifest를 확인한다. 원본 export preset은 수정하지 않는다.
기존 출력 디렉터리를 교체할 수 있으므로 이전 전달물을 보존하려면 다른 `--output-dir`를 사용한다.
기본 산출물은 `build/windows/ProjectE-windows-x86_64.zip`, `.zip.sha256`, `manifest.json`과 관련 파일이다.
새 빌드의 생성 시각·manifest·ZIP 해시는 새로 기록한다. 같은 소스 재빌드가 과거 ZIP과 바이트 단위로 같다고 가정하지 않는다.

배포 ZIP을 **전체 압축 해제**하고 `ProjectE.exe`와 `ProjectE.pck`를 같은 폴더에 둔다.
플레이어는 Godot 에디터·Python·.NET·Steam 계정 없이 실행한다. 로그가 필요하면 압축 해제한 폴더에서 다음과 같이 실행한다.

```powershell
.\ProjectE.exe --log-file "$env:TEMP\ProjectE-playtest.log"
Get-Content "$env:TEMP\ProjectE-playtest.log"
```

## 6. 기존 검증 기록과 만료되는 산출물

| 증거 | 저장소에 남은 결과 | 해석 경계 |
|---|---|---|
| 2026-11-10 회귀 | 38묶음·6,997검사 실패 0, 시작 성공 | 당시 소스에 대한 기존 검증 기록 |
| Windows CI | Windows Server 2025, headless 120프레임, 종료 0 | 실제 Windows EXE 기동; 사람 조작은 미실시 |
| 배포 PCK 렌더 | Linux OpenGL에서 화면·포인터와 세로 전장 촬영 | Windows GPU별 성능 증거가 아님 |
| Actions 전달 ZIP | 보존 기한 **2026-11-24**라는 기록 | 2026-11-19 작성 시 과거 기록 인용; 현재 다운로드 가용성은 미확인 |

근거는 [V9 검증 기록](../design/verification/2026-11-10-v9-verification.md), [Windows workflow](../../.github/workflows/windows-preview.yml)다.
과거 배포는 코드 `200df52e018e46b5b7847bfd808c59206dca7a75`와 PR 통합 `8c16d45a58ae1bcc7dc2035b9b72aa6497c1467d`를 식별한다.
이 기록을 현재 인계 커밋에서 새로 테스트한 결과로 바꿔 쓰지 않는다.
Actions 아티팩트가 만료되어도 저장소 소스가 사라졌다는 뜻은 아니다. 전체 소스와 고정 도구를 확보해 위 절차로 **새 빌드**를 만든다.
반대로 문서·로그·스크린샷만 남아 있다면 실행 패키지를 재생성할 수 없다.

## 7. 환경 인수 후 남길 결과

**후속 제안:** 새 환경에서 import → F5 → 자동 검사 → export → 실제 Windows 수동 경기 순서로 각각의 결과를 기록한다.
수동 확인에는 영웅 선택·QWER·상점·죽음/부활·승패·재시작·종료, 한국어 글꼴, 창 크기·DPI·Alt-Tab을 포함한다.
**미확인:** 사람의 한 경기, GPU별 프레임 분포, 사용자 품질 수용, 온라인·Steam. 기존 CI 통과로 대신 완료 처리하지 않는다.
초기 기술 문서의 3영웅·12묶음 검사·절대 scratch 경로는 당시 기록이다. 현행 파일·38묶음 검사기와 이 문서의 경로를 먼저 따른다.
