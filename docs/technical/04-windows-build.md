# Windows 로컬 테스트 패키지

- 개정: 2026-10-27 UTC.
- 대상: **Godot 4.7.2 Standard / GDScript / Windows x86_64 release**.
- 프로젝트: `game/project-e`; 자동 도구: `tools/package_windows.py`.
- 패키지 생성과 실제 Windows PC의 실행·사람 플레이는 서로 다른 검증이다.

## 1. 고정 도구와 공식 출처

[공식 4.7.2 stable 보관함](https://godotengine.org/download/archive/4.7.2-stable/)에서 **Standard** 엔진과 동일 버전의 **Standard export templates**를 받는다. .NET 패키지를 혼용하지 않는다. 이번 Linux 빌드 호스트에서 실행해 확인한 전체 버전은 다음과 같다.

```text
4.7.2.stable.official.ed1daf0bf
```

공식 다운로드 진입점:

- [Linux x86_64 엔진](https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=linux.x86_64.zip&platform=linux.64)
- [Standard export templates](https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=export_templates.tpz&platform=templates)
- [Windows x86_64 에디터](https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=win64.exe.zip&platform=windows.64)
- [고정 소스의 엔진 MIT 라이선스](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/LICENSE.txt)
- [고정 소스의 엔진 구성 요소 저작권·라이선스](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/COPYRIGHT.txt)

Linux 엔진과 templates 링크는 공식 다운로드 서비스에서 `https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/`의 동일 이름 파일로 연결됐다. 아래 SHA-256은 실제로 받은 파일을 읽어 계산한 값이다. 공개 서명을 별도로 검증했다는 뜻은 아니다.

| 받은 파일 / 추출 파일 | SHA-256 |
|---|---|
| `Godot_v4.7.2-stable_linux.x86_64.zip` | `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4` |
| `Godot_v4.7.2-stable_linux.x86_64` | `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e` |
| `Godot_v4.7.2-stable_export_templates.tpz` | `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` |
| `templates/windows_release_x86_64.exe` | `d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562` |
| `templates/windows_debug_x86_64.exe` | `51498b72b3a237f882ebd7d1787f06a4bc1eaf0572daab93837adcfd3cfdc107` |
| `LICENSE.txt` → `GODOT-LICENSE.txt` | `b0435e3b3e4e55238f05f4b306f30524a1b2e20147810d436eaa554fa6855c80` |
| `COPYRIGHT.txt` → `GODOT-COPYRIGHT.txt` | `cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d` |

TPZ 크기는 1,281,349,702바이트이며 내부 `templates/version.txt`는 **4.7.2.stable**이다. 모든 플랫폼을 포함하는 원본 아카이브에서 패키징에 필요한 Windows x86_64 파일 두 개만 임시 폴더에 추출한다. 사용자 전역 export templates 설정을 수정할 필요가 없다.

현재 작업 환경의 도구 폴더는 `/workspace/scratch/d3eeca5f7e58/godot-tools`이며, 고정 Linux 실행 파일의 전체 경로는 `/workspace/scratch/d3eeca5f7e58/godot-tools/Godot_v4.7.2-stable_linux.x86_64`다. 다른 컴퓨터에서는 실제 경로로 바꾼다.

## 2. 도구 준비

엔진 실행 파일 옆에 다음 파일을 둔다. Windows 빌드 호스트에서는 공식 Windows Standard 에디터 실행 파일을 사용해도 되며, 그 호스트의 엔진 해시는 manifest에 새로 기록된다.

```text
Godot_v4.7.2-stable_linux.x86_64
Godot_v4.7.2-stable_export_templates.tpz
GODOT-LICENSE.txt
GODOT-COPYRIGHT.txt
```

`GODOT-LICENSE.txt`와 `GODOT-COPYRIGHT.txt`는 위의 공식 4.7.2 소스 링크에서 받은 원문이다. 개발 도구로 Python 3.10 이상을 사용한다. Python 외부 패키지는 필요 없다. 패키지 사용자는 Python이나 에디터가 필요 없다.

Linux 준비 예시:

```sh
mkdir -p /absolute/path/project-e-tools
curl --fail --location --output /absolute/path/project-e-tools/Godot_v4.7.2-stable_linux.x86_64.zip 'https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=linux.x86_64.zip&platform=linux.64'
unzip /absolute/path/project-e-tools/Godot_v4.7.2-stable_linux.x86_64.zip -d /absolute/path/project-e-tools
chmod +x /absolute/path/project-e-tools/Godot_v4.7.2-stable_linux.x86_64
curl --fail --location --output /absolute/path/project-e-tools/Godot_v4.7.2-stable_export_templates.tpz 'https://downloads.godotengine.org/?version=4.7.2&flavor=stable&slug=export_templates.tpz&platform=templates'
curl --fail --location --output /absolute/path/project-e-tools/GODOT-LICENSE.txt 'https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/LICENSE.txt'
curl --fail --location --output /absolute/path/project-e-tools/GODOT-COPYRIGHT.txt 'https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/COPYRIGHT.txt'
/absolute/path/project-e-tools/Godot_v4.7.2-stable_linux.x86_64 --version
```

배포 전에 위 표와 다운로드 해시를 비교한다. Linux는 `sha256sum`, PowerShell은 `Get-FileHash -Algorithm SHA256`으로 읽는다. 다운로드가 실패하거나 고정 버전이 없으면 다른 엔진으로 대신 내보내지 않는다.

## 3. 패키지 생성

저장소 루트에서 실행한다.

```sh
python tools/package_windows.py --godot /absolute/path/project-e-tools/Godot_v4.7.2-stable_linux.x86_64
```

현재 작업 환경에서는 다음 명령이다.

```sh
python tools/package_windows.py --godot /workspace/scratch/d3eeca5f7e58/godot-tools/Godot_v4.7.2-stable_linux.x86_64
```

PowerShell 빌드 호스트 예시:

```powershell
$projectEGodotExe = 'C:\Tools\ProjectE\Godot_v4.7.2-stable_win64_console.exe'
python tools/package_windows.py --godot $projectEGodotExe
```

설치를 자동 다운로드하거나 로컬 Godot 설치를 바꾸지 않는다. 아카이브·엔진 notices가 다른 위치에 있으면 명시한다.

```sh
python tools/package_windows.py \
  --godot /absolute/path/godot \
  --templates-archive /absolute/path/Godot_v4.7.2-stable_export_templates.tpz \
  --engine-notices-dir /absolute/path/notices \
  --output-dir /absolute/path/project-e-windows \
  --timeout 300
```

| 옵션 | 기본값 / 동작 |
|---|---|
| `--godot` | 필수. 공식 Standard 엔진 실행 파일 |
| `--templates-archive` | 실행 파일 옆의 `Godot_v<고정 버전>-stable_export_templates.tpz` |
| `--engine-notices-dir` | 실행 파일 옆. 위 이름의 Godot 라이선스 두 파일 필요 |
| `--output-dir` | 저장소의 `build/windows` |
| `--project-root` | 스크립트가 속한 저장소. 별도 체크아웃의 빌드에도 사용 가능 |
| `--timeout` | import/export 각각 300초. 양수만 허용 |

도구는 다음 조건을 모두 확인한 뒤에만 `PASS`와 종료 코드 0을 반환한다.

1. `.godot-version`과 실제 `--version`의 공식 stable 버전이 일치한다. Mono/.NET 및 다른 버전은 허용하지 않는다.
2. TPZ 내부 버전이 `<고정 버전>.stable`이며 필요한 Windows templates가 존재한다.
3. 원본 프로젝트의 `.godot` 캐시를 제외해 별도 복사본을 만들고, 그 복사본의 preset에 임시 template 경로를 지정한다. 원본 preset은 수정하지 않는다.
4. 복사본에서 `--headless --editor --import`, 이어서 `--export-release "Windows Desktop" <출력.exe>`를 실행한다.
5. 명령 종료 코드와 `ERROR:`, `SCRIPT ERROR:` 등의 오류 줄을 검사한다. 오류 문구가 있으면 종료 코드가 0이어도 실패한다.
6. 새로 생성된 EXE의 PE/x86_64 헤더와 PCK의 Godot pack 헤더·최소 크기를 확인한다. 예전 파일을 새 export의 성공으로 재사용하지 않는다.
7. 조작·실행·실제 Windows 확인 안내, 게임 notices, Godot MIT/구성 요소 notices, 폰트 라이선스를 함께 넣는다.
8. 버전·해시·원본 파일 목록을 manifest에 기록하고 ZIP을 다시 열어 CRC와 각 내용의 SHA-256을 검사한다.

완성된 패키지 전체가 검증된 뒤 출력 폴더를 교체한다. 이전에 이 도구가 만든 출력은 새 빌드가 실패할 때 보존된다. 관련 없는 기존 파일이 있는 출력 폴더는 지우지 않고 실패한다. 출력 폴더 안에 개인 파일을 추가했다면 다른 새 `--output-dir`을 지정한다.

제한된 Linux 샌드박스에서는 Godot가 사용자 데이터·설정·캐시 폴더나 에디터의 로컬 TCP 소켓을 만들지 못할 수 있다. `Could not create editor ... directory` 또는 `TCPServer` 오류는 게임 export 성공으로 무시하지 않는다. 이번 검증에서는 승인된 정상 로컬 실행 환경에서 동일 명령을 다시 실행해 확인했다.

## 4. 전달할 파일

기본 출력:

| 파일 | 용도 |
|---|---|
| `build/windows/ProjectE-windows-x86_64.zip` | 사용자에게 전달할 전체 묶음 |
| `build/windows/ProjectE-windows-x86_64.zip.sha256` | ZIP 파일의 SHA-256. ZIP 밖에서 제공해 비교 |
| `build/windows/manifest.json` | 엔진·template·원본 snapshot·파일 해시와 검증 범위 |
| `build/windows/ProjectE.exe` + `ProjectE.pck` | Windows 실행 파일과 실제 게임 데이터 |
| `build/windows/README-WINDOWS.txt` | 에디터 없는 실행·조작·실제 PC 점검·로그 안내 |
| `build/windows/licenses/` | 엔진 MIT/구성 요소 및 폰트 OFL/변경 안내 |
| `build/windows/build-logs/` | 실제 import/export 출력 |

ZIP 안에는 `ProjectE-windows-x86_64/` 폴더 하나가 있다. EXE/PCK와 모든 안내·라이선스를 함께 압축 해제한다. EXE만 보내거나 ZIP 안에서 직접 실행하지 않는다. x86_64 release이며 코드 서명은 하지 않는다. 기본 preset은 별도 PCK를 사용하고, tests 폴더는 export에서 제외한다.

`manifest.json`의 `source.files`는 실제 import/export에 복사한 원본 프로젝트 파일의 경로·크기·해시다. `source.tree_sha256`은 경로 순서대로 `경로 + NUL + 파일SHA256 + LF`를 UTF-8로 이어 해시한 값이다. Git HEAD와 작업 상태도 함께 기록하므로 미커밋 변경이 있는 빌드를 HEAD만으로 오해하지 않는다. `files`는 manifest 자신을 제외한 전달 파일들의 해시다. manifest는 ZIP 안팎 일치를 확인하고, 최종 ZIP은 별도 `.zip.sha256`으로 확인한다. 생성 시각·임시 경로가 들어간 로그 때문에 ZIP 자체의 바이트 단위 재현성을 보장하지 않는다.

## 5. 에디터 없는 실제 Windows PC 점검

이 항목은 **실제 Windows PC에서 사람이 수행하고 별도로 기록해야 한다**. Linux 자동 실행·렌더 캡처나 Linux에서 PCK만 실행한 결과로 완료 처리하지 않는다.

1. PC의 Windows 버전, GPU/드라이버, 디스플레이 배율과 패키지 ZIP 해시를 기록한다. 에디터가 없는 환경에서 전체 압축을 푼 후 `ProjectE.exe`를 실행한다.
2. 바스·리오·네마 이름, 시작 버튼, 경기 HUD·성장 설명의 한국어가 깨지거나 빈 네모로 나오지 않는지 확인한다. 폰트는 패키지에 포함돼 있다.
3. 영웅 선택과 경기 시작, 지면/보이는 적 우클릭, **A→지면 좌클릭 공격 이동**, S 정지, Q/W/E/R 조준·확정과 Esc 취소, G 성장 투자를 확인한다. 사람 1명+봇 5명 구조다.
4. Esc 일시정지 후 Alt-Tab으로 다른 창으로 갔다가 돌아온다. 재개한 뒤 마우스·키보드 입력, 카메라·조준, 창 포커스를 확인한다.
5. 창을 조절하고 100%/150% 디스플레이 배율에서 HUD·미니맵·조작 안내가 겹치거나 잘리는지 확인한다.
6. Esc 메뉴의 **현재 영웅으로 다시 시작**으로 현재 영웅의 경기를 초기화한다. 별도의 **영웅 선택으로** 버튼을 눌러 다른 영웅을 시작한다. 종료 후 EXE를 다시 켜 새 프로세스에서도 같은 절차가 되는지 확인한다.
7. 한 판을 실제로 플레이해 승패와 종료·재시작을 확인한다. 보이지 않는 적 표시, 전장의 구멍, 벽을 통과하는 경고 표시, 공격 이동의 오작동은 위치와 재현 입력을 함께 남긴다.
8. 로그에서 `ERROR`, `SCRIPT ERROR`, 충돌·리소스 누락을 확인하고 문제가 있으면 로그·manifest·화면과 함께 보고한다.

명시적 로그 저장을 권장한다. 압축을 푼 폴더의 PowerShell에서:

```powershell
.\ProjectE.exe --log-file "$env:TEMP\ProjectE-playtest.log"
Get-Content "$env:TEMP\ProjectE-playtest.log"
Get-FileHash .\ProjectE.exe -Algorithm SHA256
Get-FileHash .\ProjectE.pck -Algorithm SHA256
```

기본 사용자 데이터/로그 경로는 `%APPDATA%\Godot\app_userdata\Project E - Canal Works\logs\godot.log`다. `manifest.verification.actual_windows_pc`와 `human_playtest`의 기본 `not_run`은 자동 빌드가 실제 PC 확인을 대신하지 않는다는 표시다. 별도의 실제 PC 검증 기록에 관찰과 확인자를 남긴다.

## 6. 자동 검사와 검증 범위

```sh
python -m unittest discover -s tools/tests -v
python tools/check_godot.py --godot /absolute/path/godot
```

Python 패키징 검사는 외부 Godot 프로세스의 실패 모드를 작은 실행 파일 대역으로 주입하고, **실제 CLI가 만든 디스크 파일·ZIP·manifest·종료 코드**를 확인한다. 대역의 출력물을 진짜 Godot export로 주장하지 않는다. 별도로 공식 엔진과 TPZ로 실제 import/release export를 실행해 EXE/PCK/ZIP을 확인한다. 게임 동작 회귀 검사는 `check_godot.py`가 담당한다.

이번 빌드 호스트에는 Wine/Wine64가 설치돼 있지 않다. Linux Godot로 같은 PCK를 실행할 경우에도 확인 범위는 플랫폼 공통 리소스/스크립트 시작이며 Windows EXE 실행 확인은 아니다. 실제 Windows PC, 사람 플레이, 장시간 GPU 성능, Steam SDK·로비·배포와 온라인 환경은 별도 검증 대상이다.

## 7. 이번에 생성한 테스트 패키지

2026-10-27에 깨끗한 소스 commit `a11834fc0da7ad1aa75292c03661d86b989d00ec`로 실제 Windows release export를 완료했다. ZIP은39,413,375bytes이며 EXE/PCK·한국어 실행 안내·고지·manifest·빌드 로그11개 항목을 포함한다.

ZIP SHA-256: `4bcccb9aac03bc20557d74a4b40e8baf7718ec41e20e05c756b397babc772fb0`.

실제 import/export, ZIP CRC와 파일별 해시, 소스63개 파일 일치를 확인했다. 소스 폴더 밖에서 Linux 엔진으로 exported-PCK90프레임 시작과 실제 GL 선택/경기 화면2장을 확인했다. **Windows PE 파일을 실제 Windows에서 실행한 검사는 미실시**다. [전체 산출물·로그·검증 범위](../../doc/design/09-verification.md#6-windows-패키지-검증), [PC/사람 기록표](../../doc/design/12-local-playtest-record.md)를 따른다.

## 공식 참고 자료

- [Windows export와 EXE/PCK](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)
- [명령줄 import/export 및 log-file](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- [Godot와 외부 구성 요소의 라이선스 포함](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)
- [user://와 플랫폼별 사용자 데이터 경로](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html)
