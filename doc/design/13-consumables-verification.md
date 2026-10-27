# 기지 상점·소모품 구현과 검증

- 기준일: **2026-10-27, Asia/Seoul**.
- 구현 소스: **`e56286a064063bda84ccd9eb309ab8fb80a575a1`**. 기준 `0b1234f8918e0d5bbea2cefbab5f83c4434a9da7`에서 R09와 R10 중 소모품 경제 판단을 구현하고 GitHub `main`에 게시했다. [설계](../../docs/plans/2026-10-27-base-consumables-design.md)와 [구현 계획](../../docs/plans/2026-10-27-base-consumables.md)을 따른다.
- 통합 결과: **임포트, 12개 묶음의 3,453개 assertion, 메인 장면90프레임 시작 통과**. 종료0·실패0, `ERROR:`/`SCRIPT ERROR:` 없음.
- 실제 렌더: Linux Compatibility에서 **720p와1080p, 총16프레임** 저장 및 확인. 선택 화면, 구매·재고·회복·중단·도움말·기지 밖·사망 상태를 확인했다.
- 별도 6봇 자연 경기: **431.8초(약7분12초), 서쪽 승리**, 실제 동쪽 핵 파괴. 사람의 균형이나 목표 경기 시간을 검증한 결과가 아니다.
- 새 Windows release 패키지를 위의 깨끗한 커밋에서 생성했다. 소스73개와 ZIP11개 항목을 대조했고, 소스 폴더 밖에서 exported PCK의 시작·구매·사용·실제 화면3장을 확인했다. **실제 Windows PC 실행·사람 플레이는 미실시**다.

## 1. 구현한 사용자 흐름

**기지에서 P → 구매 → 상점 닫기 → 소모품 칸 선택 → D 사용**으로 연결했다. 기존 G 성장과 B 기지까지 걷기는 유지한다. 상점은 기지 밖과 사망 중에도 설명을 읽을 수 있으나, 구매는 살아 있는 영웅이 자기 기지 안에 있을 때만 승인한다. 상점은 로컬 경기 시간을 멈추며 닫을 때 직전 정지 상태를 복원한다.

| 계약 | 현재 동작 |
|---|---|
| 에너지 병 I01 |40크레딧, 2초간 에너지40. 기본 에너지 회복과 합산 |
| 수리 패치 I02 |50크레딧, 4초간 HP200. 유효 적 영웅 귀속 피해로 남은 회복 중단 |
| 재고·쿨타임 | 두 종류 합산2개, 공유12초. 구매와 사용 모두 현재 상태를 다시 검사 |
| 종류 선택 | 품목별 수량 칸을 클릭해 선택. 클릭만으로 소비하지 않으며 빈 종류도 선택 유지 |
| 사용·실패 | 해당 자원이 조금이라도 부족하면 사용 가능. 최대 자원·빈 재고·공유 대기·사망·종료는 비용 없이 거절 |
| 기존 행동 | D/선택은 이동·공격·조준·시전·예약 명령을 유지. 기절/속박 자체로 소비나 회복을 막지 않음 |
| 피해 중단 | 직접·장치·지속 피해의 실제 영웅 소유자 기준. 보호막 흡수도 유효 피해라면 패치 중단 |
| 중단 제외 | 일반 병력·포탑, 무효/중복/무적 피해, 제어만 적용한 경우. 병력/탑의 최근 처치 기여자로 중단을 추정하지 않음 |
| 사망·부활 | 효과만 종료, 재고·선택 유지. 공유 대기는 사망 중 감소하고 부활로 초기화하지 않음 |
| 봇 | 같은 권한 API로 자기 기지에서 패치1개+병1개를 목표로 구매하고, 자기 체력·에너지·최근 피해로 사용 판단 |

HUD는 조작 영웅의 크레딧·재고·선택·공유 대기·회복 남은 시간을 표시한다. 구매 완료·사용·회복 완료·피해 중단·사망 종료·실패 이유를 한국어로 알린다. 적의 재고나 숨은 적의 소모품 상태는 표시하지 않는다.

봇은 패치를 우선해 없는 종류를 채운다. 기지 안에서는 소모품을 쓰지 않는다. 기지 밖에서는 HP 부족분200 이상이고 마지막 피해 후2초 이상이면 패치, 그 외 에너지 부족분40 이상이면 병을 사용한다. 조작 영웅·사망 영웅·비활성 봇에는 자동 소비를 적용하지 않는다. 지원·핵 방어·라인 전환·난이도는 R10의 남은 범위다.

## 2. 최종 통합 검사

실제 실행 명령:

```sh
XDG_DATA_HOME=/workspace/scratch/d3eeca5f7e58/godot-tools/data \
XDG_CONFIG_HOME=/workspace/scratch/d3eeca5f7e58/godot-tools/config \
XDG_CACHE_HOME=/workspace/scratch/d3eeca5f7e58/godot-tools/cache \
GODOT_SILENCE_ROOT_WARNING=1 \
python tools/check_godot.py \
  --godot /workspace/scratch/d3eeca5f7e58/godot-tools/Godot_v4.7.2-stable_linux.x86_64
```

엔진 실제 버전은 `4.7.2.stable.official.ed1daf0bf`다. [전체 출력](verification/2026-10-27-consumables-headless.log)은 종료0이며 실행기는 오류 줄과 완료 문구를 함께 검사했다.

| 묶음 | 실제 checks | failures |
|---|---:|---:|
| 기존 이동 |40 |0 |
| 기존 실제 물리 장면 |19 |0 |
| 전투·기술 규칙 |115 |0 |
| 경로·병력·봇·한 판 |1,921 |0 |
| 기존 장면·입력·HUD |96 |0 |
| 셀·포탑·A 공격 이동 |152 |0 |
| 팀 시야·표식 |499 |0 |
| A·클릭 우선순위·F1 입력 |32 |0 |
| 벽 경고 형상 |35 |0 |
| 새 소모품 권한 |245 |0 |
| 새 상점·재고·입력 |113 |0 |
| 새 봇 소모품 판단 |186 |0 |
| **합계** |**3,453** |**0** |

```text
PASS: Godot import, all 12 behavioral suites and main-scene startup
```

이 수는 실제 실행된 assertion 수이며 반복 비교를 포함한다. 서로 다른 기능3,453개나 모든 경우의 완전 증명이 아니다. 경기 검사 수는 당시 살아 있는 유닛과 진단 종료 시점에 따른 비교 수를 포함하므로 이전 회차의1,923개와 이번1,921개를 기능 감소로 해석하지 않는다.

새 검사는 실제 경기 상태와 실제 로드한 전장 장면을 사용했다. 구매 버튼·슬롯·사용 버튼의 실제 signal, 게임의 키/전장 입력 처리 함수, 실시간 권한 결과를 검사했으며 OS 수준의 물리 키보드·마우스 전달이나 Windows 창 포커스 검증과는 다르다.

권한 검사는 양 팀 기지 경계, 정확한 가격과 부족한 돈, 중복 재고·합산 한도, 구매 시점 재검사, 자원 최대/일부 부족, 공유 대기, 시간별 회복·초과 회복 버림, 직접/장치/보호막/중복 피해, 사망·부활·재시작·종료를 포함한다. 입력 검사는 메뉴 상호 배제, 조준 정리, 전장/미니맵 관통 차단, 기존 시전·예약 이동 유지, 일시정지 복원, 적 재고 정보 제외를 포함한다. 봇 검사는 실제 `think`를 호출해 돈·재고·회복·거절·행동 유지와 조작 영웅 제외를 확인했다.

## 3. 구현 중 발견하고 고친 경계

**공유 대기가 정확히12초 뒤에도 한 틱 더 잠기는 부동소수점 잔여값**을 재현했다. 실제 `state.step(12.0)`의360틱에서3개 assertion이 실패한 [기대 실패 로그](verification/2026-10-27-consumables-cooldown-red.log)를 남겼다. 남은 값이 `1e-8` 이하이면0으로 정리하며, 이는30Hz 한 틱보다 훨씬 작다. 같은 경로의 최종 검사는 성공했고 즉시 반복 사용은 계속 거절한다.

회복의 마지막 틱은 `min(delta, remaining)`만큼 먼저 지급한 뒤 종료한다. 패치는 기존 타이머 단계에서 회복하고 이후 같은 틱의 공격/투사체/장치 피해가 남은 효과를 끊는다. 이미 지급한 그 틱의 회복을 소급 취소하지 않으며 기존 경기 처리 순서는 바꾸지 않았다.

실제 UI 검사에서 재고 줄의 최소 높이가 지정 영역을 넘는 문제를 찾아 안쪽 여백을 조정했다. 상점 안내는 **상점을 닫은 뒤 슬롯 선택/D 사용**이라고 명시했고, 영웅 선택 화면의 조작 안내에는 **경기 중**이라는 범위를 유지했다.

## 4. 봇 자연 경기와 해석

```sh
Godot_v4.7.2-stable_linux.x86_64 --headless --path game/project-e \
  --script tests/test_battle_match.gd -- --long
```

[자연 경기 로그](verification/2026-10-27-consumables-long-match.log) / [실행 소스 SHA-256과 종료 코드](verification/2026-10-27-consumables-long-match-source.json). 일반 레벨1·성장2포인트에서 여섯 영웅을 모두 봇으로 제어했다. 실제 핵 파괴까지 진행했으며 핵 HP·강제 피해·승패를 주입하지 않았다. 경기 실행 전후의 전투/AI/맵/기술 소스와 경기 검사 파일의 해시가 같았다.

| 항목 | 이전 소모품 없는 봇 경기 | 이번 소모품 사용 봇 경기 |
|---|---:|---:|
| 종료 |동쪽 승리 |서쪽 승리 |
| 시뮬레이션 시간 |1,638.2초(27:18) |**431.8초(약7:12)** |
| 파괴된 탑 |12 |6 |
| 영웅 사망 |18 |5 |
| 누적 피해 |944,723.9 |201,467.8 |
| 핵 잔여 HP |서0 / 동약2,312.8 |서4,000 / 동0 |
| 남은 유닛 항목 |55 |54 |
| 별도 장시간 검사 |1,924/0 |1,922/0 |

이전 수치는 [지난 회차 기록](09-verification.md#2-6봇-자연-경기와-이전-기록-비교)에 근거한다. 이번 기본 통합 검사에서도431.8초의 같은 종료를 확인했다. 새 회복 선택이 이 한 조건의 전투와 공성 흐름에 큰 차이를 만들었으므로, 실제 사람 경기에서는 병/패치 구매 비율·회복 중단·복귀 빈도·라인 체류·구조물 압박을 함께 관찰해야 한다. 이 한 봇 조건의 승리 진영이나 종료 시간을 사람의 영웅 밸런스 또는6인 중앙값12–18분 목표 달성으로 해석하지 않는다. 이번 작업에서 이를 맞추려고 HP·피해·쿨타임을 추가 변경하지 않았다.

## 5. 실제 렌더와 화면 확인

Linux Xvfb, OpenGL4.5, Mesa25.2.8 llvmpipe(LLVM20.1.2), Compatibility, Dummy audio에서 실행했다. [렌더 로그](verification/2026-10-27-consumables-render.log)는 종료0·`16 frames, PASS`이며 `ERROR:`/`SCRIPT ERROR:`가 없다. 이 드라이버에서 지원하지 않는 VSync 변경 경고1개가 있다.

```sh
DISPLAY=:97 LIBGL_ALWAYS_SOFTWARE=1 \
Godot_v4.7.2-stable_linux.x86_64 --path game/project-e \
  --script tests/capture_consumables.gd --audio-driver Dummy \
  -- --output=/absolute/path/to/screenshots
```

재현 도우미는 각 해상도에서 선택, 상점, 재고, 병 회복, 패치 중단, F1, 기지 밖 상점, 사망 중 상점의8장씩 저장한다. **1080p에서는 논리 UI 크기도1920×1080으로 설정**해 넓은 레이아웃을 확인했다. 실제 Windows100/150/200% 배율이나 물리 입력 검사를 수행했다는 뜻은 아니다.

경기 화면은 기술 체험의 바스 L3 상태를 사용한 **기능 확인용 장면**이다. 크레딧210을 배치하고 실제 구매 명령으로 병+패치를 구입해120이 남는지 확인했다. 이것은 일반 경기 시작금100을 변경한 것이 아니다. 병 사용 후 실제0.5초 진행해 공유 대기11.5초·회복1.5초를 확인했다. 패치는 HP 부족 상태에서 사용한 뒤 실제 적 영웅 귀속 피해를 적용해 중단 알림을 확인했다. 사람의 경기 화면이나 자연 경기의 특정 시점으로 표시하지 않는다.

| 대표 보관 화면 | 확인한 내용 |
|---|---|
| [선택720p](assets/consumables-selection-720p.png) | 경기 중 P/D/F1 안내와 새 경기 시작 버튼 |
| [상점720p](assets/consumables-shop-720p.png) · [상점1080p](assets/consumables-shop-1080p.png) | 가격·효과·구매 조건·상점을 닫은 뒤 사용 순서·닫기 버튼 |
| [재고720p](assets/consumables-inventory-720p.png) | 기술 HUD 위의 재고, 수량, 형태로도 구별하는 선택 표시 |
| [회복720p](assets/consumables-recovery-720p.png) | 감소한 재고, 남은 공유 대기와 회복 시간 |
| [패치 중단720p](assets/consumables-interruption-720p.png) | 한국어 중단 알림과 남은 사용 대기 |
| [F1 안내720p](assets/consumables-help-720p.png) | 기존 이동·성장·시야·공성에 P/D 설명 추가 |
| [기지 밖720p](assets/consumables-offbase-720p.png) · [사망720p](assets/consumables-dead-720p.png) | 상점 열람은 가능하고 구매는 이유와 함께 제한 |

## 6. 패키지·독립 검토·남은 실제 확인

### 6.1 새 Windows release 산출물

기존 패키징 도구의9개 경계 검사는 [출력](verification/2026-10-27-consumables-packaging-tests.log)에서 모두 통과했다. 이어 공식4.7.2 엔진과 같은 버전 templates로 실제 Windows x86_64 release를 export했다. 실행 안내에는 P/D, 구매 조건, 가격·회복·합산 한도·공유 대기와 실제 PC 점검 항목을 포함했다.

```sh
python tools/package_windows.py \
  --godot /workspace/scratch/d3eeca5f7e58/godot-tools/Godot_v4.7.2-stable_linux.x86_64 \
  --output-dir /workspace/scratch/d3eeca5f7e58/project-e-next/build/windows-consumables
```

이 명령은 위2절과 같은 XDG 데이터·설정·캐시 경로에서 실행했고 종료0이었다. [소스 게시 영수증](verification/2026-10-27-consumables-source-publication.json)의 원격 Git tree와 로컬 index tree가 같고, export 당시 Git 상태는 깨끗했다. [manifest 원본](verification/2026-10-27-consumables-windows-manifest.json), [실제 import 로그](verification/2026-10-27-consumables-windows-import.log), [실제 export 로그](verification/2026-10-27-consumables-windows-export.log)를 보존했다. 두 엔진 로그에 `ERROR:`/`SCRIPT ERROR:`가 없다.

| 산출물/기준 | 실제 값 |
|---|---|
| 소스 commit | `e56286a064063bda84ccd9eb309ab8fb80a575a1` |
| Git tree | `b49c8c1f396047753ea3d0627d573f6f12b8ea46` |
| manifest 생성 UTC | `2026-10-27T05:52:25.564768+00:00` |
| ZIP | `ProjectE-windows-x86_64.zip`, **39,428,780바이트**, 내부11개 파일 |
| EXE | `ProjectE.exe`,109,268,480바이트, PE x86_64 / PE32+ |
| 게임 데이터 | `ProjectE.pck`,1,343,384바이트, GDPC / Godot4.7.2 |
| 원본 프로젝트 snapshot |73개 파일, 해당 커밋 및 현재 파일과 내용·크기·SHA-256 모두 일치 |
| 소스 snapshot SHA-256 | `c72929cec3509dbc7dc900c6d1f276fe9cffdfd05bde1bcb5469947fc20ae80e` |

ZIP SHA-256은 [체크섬 파일](verification/2026-10-27-consumables-windows.zip.sha256)에 기록했다.

```text
a2d88d42da7623d4ddb71420af2fce2dd7b30a67cac87bca7616fd153a43ae4d
```

PCK SHA-256은 `fe6dd096f7a96487b966538975c2c106f00c988dd21dea0775e138589681e3f7`이다. ZIP의 CRC, 모든 내부 파일 크기·해시, ZIP 안팎 manifest 동일성과 외부 ZIP 체크섬을 확인했다. 게임·Godot MIT/구성 요소·폰트 고지를 포함한다. 전회 `a11834f` / ZIP `4bcccb9a…`의 패키지는 [지난 검증 기록](09-verification.md)에 남아 있으며 이번 산출물과 구별한다.

### 6.2 실제 exported PCK 실행

Linux 엔진의 `--main-pack`으로 **원본 프로젝트 밖의 임시 실행 폴더**에서 새 PCK를 열었다. 이 폴더에는 원본 프로젝트를 복사하지 않았으며 구매/사용 검사용 외부 스크립트만 두었다. 다음 결과는 플랫폼 공통 패키지 리소스와 실행 로직 확인이며 **Windows EXE 실행 결과가 아니다**.

| 실행 | 결과 | 보존 증거 |
|---|---|---|
| headless 메인 장면 |90프레임, 종료0, 오류 없음 | [로그](verification/2026-10-27-consumables-pack-headless-main.log) · [명령/결과](verification/2026-10-27-consumables-pack-headless-main-result.json) |
| headless 소모품 흐름 |10checks,0failures, 종료0 | [로그](verification/2026-10-27-consumables-pack-headless-probe.log) · [명령/결과](verification/2026-10-27-consumables-pack-headless-probe-result.json) |
| 실제 GL 소모품 흐름 |13checks,0failures, 실제3프레임, 종료0 | [로그](verification/2026-10-27-consumables-pack-graphical-probe.log) · [명령/결과](verification/2026-10-27-consumables-pack-graphical-probe-result.json) |

[외부 실행 검사 스크립트](verification/2026-10-27-consumables-pack-probe.gd)는 패키지 안의 실제 전장 장면을 불러와 일반 경기 바스 레벨1·시작금100을 확인한다. P로 상점을 열고 실제 구매 버튼 signal로 두 품목을 사면10크레딧이 남는다. 상점을 닫아 재개하고 기지 밖 위치·에너지50을 배치한 뒤, 실제 슬롯 선택과 D 처리로 병을 사용해0.5초 진행한다. 재고1개 소비, 패치1개 보존, 병 회복과 기본 회복의 합, 공유 대기11.5초를 검사한다. 그래픽 실행의 추가3개 assertion은 PNG 저장 성공을 확인한다.

실제 캡처한 [선택 화면](assets/consumables-pack-selection-720p.png), [시작금100의 상점](assets/consumables-pack-shop-720p.png), [구매 후 병 사용·회복](assets/consumables-pack-recovery-720p.png)을 직접 확인했다. 한국어와 조작 안내·가격·재고·회복 표시가 그려졌다. 이3장은 위5절의 소스 직접 실행16장과 구별하며 자연 경기나 사람 플레이를 촬영한 것으로 해석하지 않는다. GL 로그에는 같은 llvmpipe의 VSync 경고1개만 있고 엔진 오류는 없다.

### 6.3 독립 검토와 남은 실제 확인

권한·UI·봇의 개별 검토와 전체 변경 검토를 모두 마쳤다. [독립 소스 검토 기록](verification/2026-10-27-consumables-reviews.md)의 명세 결과는 PASS, 코드 품질은 PASS/APPROVE이며 남은 실행 가능한 P0–P3 지적은 없다. 이어 별도의 [패키지 검토](verification/2026-10-27-consumables-package-review.md) / [기계 확인 결과](verification/2026-10-27-consumables-package-review.json)도 PASS/APPROVE다. 패키지 검토자는 소스·manifest·ZIP·헤더·로그·안내·고지를 독립 대조했고 프로그램을 다시 실행했다고 주장하지 않았다. 사거리·XP·보상·시야·행동 순서를 추가로 변경하지 않았다.

실제 Windows PC 실행·Alt-Tab·디스플레이 배율·대상 장비 성능과 사람1명+봇5명 경기는 **미실시**다. [플레이 기록표](12-local-playtest-record.md)의 소모품 구매/선택/사용과 회복·중단/복귀 질문을 사용한다. R10 전체 전술, R06 동작·소리, R07 연습장, R08 설정, R12 이후 온라인은 별도 남은 개발이다.
