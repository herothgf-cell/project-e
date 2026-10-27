# Godot 빠른 시작과 실행 검증

- 개정: 2026-10-27, Asia/Seoul.
- 현재 범위: **3라인·세 영웅·오프라인 3대3·성장·공성·승패 프로토타입**.
- 엔진: **Godot 4.7.2 Standard**, GDScript, Compatibility, GodotPhysics3D, 30Hz.
- 프로젝트: [game/project-e/project.godot](../../game/project-e/project.godot).
- 기획: [현재 콘텐츠](../../doc/design/README.md) · [구현 차이](../../doc/design/10-differences.md) · [실제 검증 기록](../../doc/design/09-verification.md).

## 1. Windows에서 프로젝트 열기

1. [Godot 공식 4.7.2 보관함](https://godotengine.org/download/archive/4.7.2-stable/)에서 **Standard / Windows x86_64**를 준비한다. .NET이나 C# SDK는 필요하지 않다.
2. 저장소를 clone하거나 GitHub의 **Code → Download ZIP**으로 받아 전체 압축을 푼다.
3. Godot 프로젝트 관리자에서 **Import**를 누르고 **game/project-e/project.godot**을 선택한다.
4. 첫 import가 끝나면 **F5**를 누른다. 이제 메인 장면은 **battlefield.tscn**이며 영웅 선택 화면으로 시작한다.
5. 바스·리오·네마를 선택하고 경기 시작 버튼을 누른다. 아군 두 명과 상대 세 명은 봇이다.

기존 이동 진단 장면이 열려 있는 상태에서 F6을 누르면 예전 진단이 실행된다. **새 전장은 F5**로 시작한다. 프로젝트 파일은 실행 프로그램이 아니라 Godot에서 가져오는 설정 파일이다.

일반 경기는 레벨 1·2포인트로 시작한다. G로 투자하고 20초에 처음 출발하는 병력을 따라간다. R은 레벨 3부터 1포인트로 해금한다. **기술 체험**을 켜면 양 팀 여섯 영웅 모두 레벨 3·R 해금·잔여 3포인트로 시작한다.

## 2. 조작

| 입력 | 동작 |
|---|---|
| 지면 우클릭 | 길을 찾아 목적지로 이동 |
| 보이는 적 우클릭 | 사거리까지 접근한 뒤 기본 공격 |
| A → 지면 좌클릭 | 공격 이동; 교전 후 원래 목적지로 복귀 |
| Q/W/E/R → 좌클릭 | 미리보기를 확인하고 기술 확정 |
| Esc | 조준 취소, 패널 닫기 또는 일시정지 메뉴 |
| S | 이동/공격 명령 정지 |
| G | 성장 투자 패널; 읽는 동안 로컬 시간 정지 |
| F1 | 조작·셀·시야·공성 안내; 닫으면 이전 진행 상태로 복귀 |
| B | 기지로 걸어가기; 순간이동 아님 |
| P | 상점 열기/닫기; 읽는 동안 로컬 정지, 닫으면 직전 상태 복원 |
| I01/I02 슬롯 클릭 | 종류 선택만; 빈 종류도 선택 가능하며 자동 교체하지 않음 |
| D / 사용 버튼 | 선택한 종류 한 개 사용; 합산2개 보유·공유12초 쿨타임 |
| 가운데 버튼 드래그 | 카메라 이동 |
| 휠 / Space | 확대·축소 / 조작 영웅으로 복귀 |
| 미니맵 좌클릭 / 우클릭 | 시점 이동 / 이동 명령 |

바스는 돌파와 엄호, 리오는 왕복 원반과 회수점, 네마는 핀 두 개의 연결을 사용한다. [영웅별 기술](../../doc/design/characters/README.md)과 [입력 상세](../../doc/design/06-ui-and-controls.md)를 참고한다. 기지 부근에서 회복하고, 아군 병력을 동반해 외곽탑→내곽탑→핵을 공격한다.

### 기지에서 구매하고 라인에서 사용하기

기지 상점·소모품은 현재 구현·자동 검증을 완료했다. G 성장/B 걷기 복귀를 유지하며 **P→구매→슬롯 선택→D**로 사용한다. I01 에너지 병은40크레딧/2초 동안 에너지40, I02 수리 패치는50크레딧/4초 동안 HP200이다. 상점은 어디서나 설명을 볼 수 있지만 구매는 경기 중 자기 기지 회복 구역의 살아 있는 영웅만 가능하다. 최근 피해나 사용 쿨타임은 구매 제한이 아니다.

최대 자원·빈 선택·사망·공유 쿨타임에서는 사용하지 않고 한국어 이유를 알린다. D는 이동·공격·시전·예약 명령과 조준을 보존하며 기절/속박 자체로 막지 않는다. 패치는 적 영웅 귀속 유효 피해(장치·지속·보호막 흡수 포함)로 중단하며 환급하지 않는다. 사망 후 남은 재고·선택은 유지하고 사용 쿨타임도 계속 감소한다. 자세한 조건은 [경제](../../doc/design/05-growth-and-economy.md#5-기지-상점과-소모품)를 따른다.

## 3. 현재 소스 구조

아래 경로는 game/project-e 기준이다.

| 경로 | 책임 |
|---|---|
| scripts/battle/battle_state.gd | 고정 시간 경기 상태·명령·공격·생성·공성·승패 |
| scripts/battle/battle_rules.gd | 피해·보호막·CC·성장·보상·사망 |
| scripts/battle/battle_consumables.gd | I01/I02 구매·사용 검사·회복·피해/사망 종료 |
| scripts/battle/hero_abilities.gd | 세 영웅의 기술·기하·시간·장치·원반 |
| scripts/battle/battle_map.gd | M01 좌표·시야·충돌·길찾기 |
| scripts/battle/battle_ai.gd | 병력/탑 자율 행동, 영웅 봇의 전투·복귀·투자 |
| scripts/presentation/ | 입력·카메라·전장 표시·한국어 HUD·표식·미니맵 |
| scenes/battlefield.tscn | 현재 메인 장면 |
| scenes/combat_probe.tscn | 보존한 기존 이동·바스 E 진단 |
| tests/test_battle_*.gd | 전투·한 판·실제 UI 명령 라우팅 검사 |

판정은 로컬 시뮬레이션이다. 표시와 규칙의 분리는 온라인 서버 권위가 이미 구현됐다는 의미가 아니다.

## 4. 자동 검증

저장소 루트에서 실행한다. Python 3는 개발 검증 도구에만 필요하며 게임 실행에는 필요하지 않다.

```sh
python tools/check_godot.py --godot /actual/path/to/godot
python tools/check_godot.py --godot /actual/path/to/godot --long-match
```

기본 명령은 버전/import와 기존9개 묶음에 소모품 권한·실제 입력·봇 판단3개를 더한 **12개 검사 묶음** 및 메인 장면 시작을 확인한다. 이번 실행은 **3,453 assertion 실패0과 메인90프레임 시작을 통과**했다. 별도 장시간 검사는1,922 assertion 실패0,431.8초(약7분12초) 서쪽 핵 파괴 승리였다. 정확한 실행 조건과 이전27:18 동쪽 승리와의 구분은 [최신 검증](../../doc/design/13-consumables-verification.md)을 따른다. **--long-match**는 원래 수치의 봇 경기를 핵 파괴 또는 최대 1,860초까지 연장한다. 경기 검사는 최대 300초의 실제 실행 시간을 허용한다. 장시간 검사와 일반 실행을 혼동하지 않는다.

PowerShell 예시에서 실제 Godot 실행 파일 경로를 지정한다.

```powershell
$godotExe = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
python tools/check_godot.py --godot $godotExe --long-match
```

Python 없이 개별 검사를 실행할 수도 있다.

```sh
godot --headless --path game/project-e --editor --import
godot --headless --path game/project-e --script tests/test_bas_motion.gd
godot --headless --path game/project-e --script tests/test_probe_scene.gd
godot --headless --path game/project-e --script tests/test_battle_rules.gd
godot --headless --path game/project-e --script tests/test_battle_match.gd
godot --headless --path game/project-e --script tests/test_battle_scene.gd
godot --headless --path game/project-e --script tests/test_next_combat.gd
godot --headless --path game/project-e --script tests/test_team_vision.gd
godot --headless --path game/project-e --script tests/test_next_input.gd
godot --headless --path game/project-e --script tests/test_effect_geometry.gd
godot --headless --path game/project-e --script tests/test_consumables.gd
godot --headless --path game/project-e --script tests/test_consumable_input.gd
godot --headless --path game/project-e --script tests/test_consumable_ai.gd
```

소모품 권한 검사는245개, 실제 장면 입력은113개, 봇 구매/사용은186개 assertion을 통과했다. 이 수는 반복·경계 비교를 포함하며 서로 다른 기능 수나 사람의 조작감 검증 수가 아니다.

검증 도구는 종료 코드뿐 아니라 ERROR/SCRIPT ERROR와 완료 문구를 확인한다. 이번 통과 수·자연 종료 시간은 [최신 검증](../../doc/design/13-consumables-verification.md), 이전 실행은 [과거 기록](../../doc/design/09-verification.md)에 모은다.

## 5. 실제 렌더링 확인

그래픽 화면이 있는 환경에서는 다음 보조 스크립트로 선택·시작·성장·봇 경기·조준과 네마/리오의 지속 표식 화면을 저장할 수 있다.

```sh
godot --path game/project-e --script tests/capture_battlefield.gd
```

새 기능의 셀·시야 전후·A 조준·F1 안내·벽 경고는 `tests/capture_next_features.gd`로 캡처하며 출력은 build/screenshots-next다. 기존 도우미 출력은 build/screenshots이다. **--headless에서는 실행하지 않는다.** 경기 화면은 시뮬레이션을 빠르게 진행한 렌더링이며 사람이 조작해 플레이한 기록이 아니다. 자동 검사·프레임 확인·사람 플레이의 범위를 구분한다.

기지 상점·재고/선택·회복 진행·F1 안내는 `tests/capture_consumables.gd`로720p/1080p 실제 프레임을 캡처한다. 수행 조건·출력·최종16프레임 검수 상태는 [최신 검증](../../doc/design/13-consumables-verification.md)을 따른다. 자동 입력 검사 통과와 사람이 직접 플레이한 결과는 구별한다.

## 6. 기존 이동 진단

scenes/combat_probe.tscn을 열고 **F6**을 누르면 이전 진단을 실행한다. 우클릭 이동, E→좌클릭 돌진, S 정지, Esc 취소, F2 초기화다. 작은 진단의 벽 우회 미지원과 영어 HUD는 이 장면의 특성이다. 새로운 전장에는 길찾기와 한국어 HUD가 별도로 있다.

2026-10-22 기반 작업은 동일한 엔진에서 이동 규칙 40개와 실제 진단 장면 19개를 통과했다. 이 과거 기록은 당시 Windows 실행이나 온라인 검증을 포함하지 않았다. 현재 검증 도구는 이 두 묶음을 계속 회귀 검사한다.

## 7. Windows 독립 실행 패키지

기존 전달 패키지는 소모품 추가 전 `a11834f` 소스의 산출물이다. 이번 소모품 소스의 새 export·ZIP 결과는 [최신 검증](../../doc/design/13-consumables-verification.md)에서 별도로 확정한다. 실제 Windows PC 실행과 사람 경기는 여전히 미실시다.

테스트 ZIP을 받았다면 **전체 압축을 풀고 ProjectE.exe를 실행**한다. ProjectE.pck를 같은 폴더에 둔다. 플레이에 Godot 에디터나 Python 설치는 필요하지 않다. 프로젝트 소스 ZIP과 실행 패키지는 서로 다른 파일이다.

개발용으로 직접 빌드하려면 고정된4.7.2 Standard 실행 파일, 같은 버전의 공식 export templates TPZ와 엔진 라이선스 고지를 준비한다. [Windows 빌드 안내](04-windows-build.md)의 옵션에 따라 다음 CLI를 사용한다.

```sh
python tools/package_windows.py --godot /actual/path/to/godot
```

CLI는 버전 확인→별도 소스 사본 import→Windows release export→EXE/PCK 검증→안내/고지/manifest→ZIP·SHA-256 검사를 수행한다. 기본 출력은 build/windows/ProjectE-windows-x86_64.zip이다. 명령의 성공과 실제 Windows PC의 실행은 [검증 기록](../../doc/design/09-verification.md)에 나누어 기록한다.

실제 PC에서는 Godot이 없는 상태로 실행→영웅 선택→일반 경기→재시작→종료, 한국어 글자, 마우스, 창 크기, Alt-Tab 복귀를 확인한다. 사람 플레이는 [기록표](../../doc/design/12-local-playtest-record.md)에 남긴다. 온라인·Steam 연동과 실제 Windows 하드웨어 성능은 이 export 절차의 완료만으로 검증되지 않는다.
