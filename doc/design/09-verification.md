# 구현 근거와 검증 매트릭스

- **최신 R09 상점·소모품/R10 경제 판단 검증은 [별도 기록](13-consumables-verification.md)**을 따른다. 12묶음3,453개·16프레임·431.8초 자연 봇 경기를 이번 소스의 근거로 구분한다.
- 아래1–7절은 앞선 **R01–R05/R24–R27 회차의 검증과 a11834f 패키지**를 보존한 기록이다. 이전9묶음·27:18 결과를 소모품 구현 이후의 결과로 사용하지 않는다.
- 기록 기준일: **2026-10-27, Asia/Seoul**.
- 대상: `85deaf26797d2bc64757d54bd2025d39d09c8a00` 위에 다음 개발 묶음 R01–R05/R24–R27을 반영한 소스. [구현 계획](../../docs/plans/2026-10-27-next-local-playtest.md)과 [현재 개발 상태](11-remaining-development.md)를 함께 본다.
- 엔진: **Godot 4.7.2 Standard**, 실제 버전 `4.7.2.stable.official.ed1daf0bf`.
- 이전 회차 최종 결과: **임포트, 9개 검사 묶음의2,911개 assertion, 메인 장면90프레임 시작 모두 통과**. 통합 명령 종료0, 실패0, `ERROR:`/`SCRIPT ERROR:` 없음.
- 실제 그래픽 실행: **1280×720의11프레임**, GPU 시야/미니맵 마스크의 비관측→관측→비관측 갱신 확인. 소스·검사·실제 프레임을 독립 검토했다.
- 실제 Windows PC와 사람 플레이는 아직 수행하지 않았다. Windows release export와 전달 ZIP 제작은 완료했고, 실제 PC 확인과 구분해 아래 배포 절에 기록한다.

## 1. 최종 자동 검사

저장소 루트에서 실행했다. 다른 환경에서는 엔진과 XDG 경로를 실제 설치 경로로 바꾼다.

```sh
XDG_DATA_HOME=/workspace/scratch/d3eeca5f7e58/godot-tools/data \
XDG_CONFIG_HOME=/workspace/scratch/d3eeca5f7e58/godot-tools/config \
XDG_CACHE_HOME=/workspace/scratch/d3eeca5f7e58/godot-tools/cache \
python tools/check_godot.py \
  --godot /workspace/scratch/d3eeca5f7e58/godot-tools/Godot_v4.7.2-stable_linux.x86_64
```

| 검사 | 실제 결과 | 주요 확인 범위 |
|---|---|---|
| 버전·임포트 | 통과 | 고정 버전, 스크립트·장면·에셋 |
| test_bas_motion.gd |40 checks,0 failures | 기존 이동·바스E·충돌·자원 |
| test_probe_scene.gd |19 checks,0 failures | 기존 실제 물리 진단 장면 |
| test_battle_rules.gd |115 checks,0 failures | 피해·보호막·제어·기술·성장·명령 |
| test_battle_match.gd |1,923 checks,0 failures | 경로·병력·공성·명령·결정성·810초 봇 진단 |
| test_battle_scene.gd |96 checks,0 failures | 기존 실제 장면·입력·HUD·지속 기술·시야 |
| test_next_combat.gd |152 checks,0 failures | XP20/30/40 공유·재생성, 포탑8.5m·보복·AI, 공격 이동 |
| test_team_vision.gd |499 checks,0 failures | 벽/겹침/제공원 변화, 실제 마스크·표식·클릭 위치·한국어·미니맵 |
| test_next_input.gd |32 checks,0 failures | A 준비/확정/취소/명령 교체, 겹친 표적·잠금, F1 정지/복귀 |
| test_effect_geometry.gd |35 checks,0 failures | 원·부채 벽 차단, 부분 관측·중첩·숨은 구멍·캐시/계산량 경계 |
| 메인 장면90프레임 | 통과 | 실제 project.godot 기본 장면의 시작 |

[최종 통합 출력](verification/2026-10-27-headless.log) / [실행기](../../tools/check_godot.py). 실행기는 종료 코드와 오류 출력, 예상 완료 문구를 함께 검사한다. 저장한 로그는 행 끝 공백과 마지막 빈 줄만 정리했으며 결과·오류·측정값을 유지했다.

```text
PASS: Godot import, all 9 behavioral suites and main-scene startup
```

2,911은 실제 실행된 assertion 수이며 표본·반복 비교를 포함한다. 서로 다른 기능2,911개나 모든 입력/기하 경우를 검증했다는 뜻은 아니다. 기본 경기 검사의810초 종료는 시간 제한 진단이므로 `winner=-1`이 허용된다. 실제 핵 파괴까지 진행한 검사는 다음 절의 별도 장시간 기록이다.

## 2. 6봇 자연 경기와 이전 기록 비교

`--long-match`는 일반 시작 레벨1·성장2포인트에서 `controlled_id=-1`로 여섯 영웅을 모두 봇이 제어하게 한다. 기본 플레이의 사람1명+봇5명과 다른 조건이다. 핵HP 직접 변경·강제 피해·시간 초과 승패 없이 실제 전투로 핵이 파괴됐다.

| 항목 | 이전2026-10-26 | 새 전투 수치2026-10-27 |
|---|---:|---:|
| 자연 종료 | 동쪽 승리 | 동쪽 승리 |
| 시뮬레이션 시간 |1,211.0초(20:11) |**1,638.2초(27:18)** |
| 파괴된 탑 |11 |12 |
| 영웅 사망 |22 |18 |
| 누적 피해 |671,471.1 |944,723.9 |
| 서쪽/동쪽 핵HP |0 / 약3,884.8 |0 / 약2,312.8 |
| 장시간 경기 검사 |1,922/0 |1,924/0 |

[새 장시간 통합 원문](verification/2026-10-27-long-match.log)은 최초 통합에서2859개 assertion으로 통과했다. 이후 변경은 효과 렌더의 성능, 시야 표식·툴팁과 캡처 준비 상태이며 전투 상태/공통 판정/AI/맵 권한 규칙은 바꾸지 않았다. 그 최종 표시 소스로1절의9개 전체 일반 검사를 다시 실행했다. 장시간 경기를 반복해 수행한 것처럼 기록하지 않는다.

이 한 쌍의 결과만으로 사거리 변경의 효과, 영웅 균형, 사람 경기 길이를 단정하지 않는다. 원래 목표는 **사람6명 정상 경기 중앙값12–18분**이라는 가설이다. 복귀·이동·부활·병력 보호·공성 실패가 소요 시간에 미친 영향과 사람의 선택을 별도로 관찰한다.

이전 기준의5개 묶음2192개 통과와8프레임 기록도 보존한다: [이전 자동 로그](verification/2026-10-26-headless.log), [이전 렌더 로그](verification/2026-10-26-render.log). 이미 수정한 예약 스킬 교체, 네마 지속 연결, 리오 회수점/귀환 경로와 숨은 적 선 효과 회귀도 현재115/96 검사에 남아 있다.

## 3. 새 기능과 독립 검토에서 고친 문제

| 대상 | 실패/문제 재현 | 최종 확인 |
|---|---|---|
| 셀·포탑·공격 이동 | 신규 전투 규칙 검사에서 누락 동작 실패 확인. 공유 시야 공용 API 추가도 별도 실패 확인 | 새 전투152/0, 기존 전투115/0, 경기1923/0 |
| A 입력·선택·도움말 |27개 검사 중10개 실패 | 실제 장면 입력32/0. 겹친 영웅·병력·잠긴 구조물, 패널 차단·정지 상태 복원 |
| 벽 경고 | 기존 원·부채가 벽 뒤를 칠하는16개 검사 중8개 실패 | 벽·관측·겹침·계산량으로 확대해35/0 |
| 시야 제공/음영 | 새 표시가 없던 상태1/1 실패 | 실제 판정과300개 텍셀 표본 비교, 제공원·미니맵·셀·표식 포함499/0 |
| 멈춘 마우스의 미니맵 툴팁 | 이동한 병력을 계속 가리키고 설명이 남음 | 현재 마우스/살아 있는 제공원을 매 표시 주기에 다시 평가 |
| 한국어 시야 설명 | 기본 폰트의 ‘시’ 글리프가 없어 실패 | 포함된 한국어 폰트 연결, 실제 GL 화면 확인 |
| 체력바에 가린 시야원 표식 | 실제 화면의3D고리가 HP/이름과 겹쳐 보이지 않음 | 체력바 왼쪽16px 눈 배지,5px 간격. 줌26/34/42 위치·히트 검사와 실제 화면 |
| 선택 화면의F1 안내 | 경기 전에는 열리지 않는데 ‘F1 안내’라고 표시 | ‘경기 중F1 도움말’로 정확히 표시 |
| 적 원·부채 렌더 정지 | 독립 검토에서 한 경고 생성이219–432ms. [회귀 실패 로그](verification/2026-10-27-effect-red.log) | 아래 성능 수정, 기존 장면96/0와 최종9개 통합 검사 |

최종 독립 검토는 중요한 미해결 결함을 찾지 못했다. 추가로 고정 seed462718, 실제 벽 주변의 원/부채62개 준비 상태와1~2제공원을 조합해 **171,990개 삼각형 내부 표본**을 검사했다. 모든 비퇴화 표본이 권한 팀 시야와 효과 원점의 벽LOS를 만족했다. [검토 표본 로그](verification/2026-10-27-review-geometry.log), [재현 스크립트](verification/2026-10-27-review-geometry.gd). 이는 검사한 표본의 근거이며 연속 공간의 모든 경우를 증명하지 않는다.

## 4. 효과 렌더의 성능 회귀 수정

처음 구현은 적 원·부채를0.18m 조각 수천 개로 나누고 매 프레임 각 삼각형의7지점에서 전체 제공원·벽 검사를 반복했다. 이제 정적인 벽 형상과 결과를 캐시하고, 같은 반경·벽 기하로 만든 살아 있는 아군 시야 다각형과 native 교차 연산을 사용한다. 중첩 영역은 서로 겹치지 않는 볼록 조각으로 나눠 숨은 구멍을 채우거나 투명도가 중복되지 않게 했다.

원점이 숨었어도 보이는 부분은 남긴다. 반대로 제공원 이동/사망/제거는 정확한 위치·집합을 기준으로 캐시를 무효화한다. 지면의1m 음영 샘플이 적 효과 표시를 허용하지 않는다. 곡선은 안쪽 현으로, 교차 경계는 작은 안쪽 여유로 보수적으로 표현하므로 극히 좁은 경계가 덜 그려질 수 있다. 피해·명령 판정을 바꾸지 않는다.

같은 준비 상태에서8회 redraw의 평균이며 첫 생성도 포함한다.

| 준비 상태 | 수정 전 | 수정 후 |
|---|---:|---:|
| 아군 반경2.2m 원 |20.343ms |0.707ms |
| 적 반경2.2m 원 |431.663ms |2.081ms |
| 적 반경6m/70도 부채 |392.106ms |0.703ms |
| 완전히 비관측인 적 부채 |218.511ms |0.034ms |

[고정 준비 상태 로그](verification/2026-10-27-effect-profile.log) / [스크립트](verification/2026-10-27-effect-profile.gd). 캐시가 매번 갱신되는 별도 검사에서는 제공원이0.03m씩 이동하는 부분 관측 부채12회의 평균7.009ms, 시간이 변하는 시전 준비 원12회의 평균3.080ms였다. [동적 로그](verification/2026-10-27-effect-dynamic-profile.log) / [스크립트](verification/2026-10-27-effect-dynamic-profile.gd).

이는 Linux의 분리된CPU 측정이다. 실제 Windows 전체 프레임이나 여러 경고 중첩의60fps를 보장하지 않는다.

## 5. 실제 렌더와 시야 표시

환경: Linux+Xvfb, Compatibility, OpenGL4.5/Mesa25.2.8/llvmpipe(LLVM20.1.2), Dummy 오디오. 그래픽 디스플레이를 준비해 실행했다.

```sh
DISPLAY=:97 LIBGL_ALWAYS_SOFTWARE=1 \
/workspace/scratch/d3eeca5f7e58/godot-tools/Godot_v4.7.2-stable_linux.x86_64 \
  --path game/project-e --rendering-method gl_compatibility \
  --audio-driver Dummy --script tests/capture_next_features.gd
```

실행 종료0,11프레임 저장, GPU 마스크 상태 변화 통과. `ERROR:`/`SCRIPT ERROR:`는 없고 소프트웨어 드라이버의 VSync 변경 미지원 경고만 있었다. [원문 로그](verification/2026-10-27-render.log), [캡처 도우미](../../game/project-e/tests/capture_next_features.gd).

| 프레임 | 실제 준비 상태와 확인 |
|---|---|
|01/02 | 영웅 선택과 기술 체험 시작,1280×720의 버튼/문구 |
|03 | [F1 안내](assets/next-guide.png),2열 설명·닫기 버튼이 화면 안에 들어옴 |
|04 | [20/30/40 XP 셀](assets/next-cell-tiers.png). 실제30.1초 생성 뒤 등급별1개를 모아 배치; 값·반경 변경 없음 |
|05/06/07 | 같은 카메라에서 [벽 뒤 비관측](assets/next-vision-before.png)→[아군 추가로 관측](assets/next-vision-overlap.png)→[제거 후 다시 비관측과 눈 표식](assets/next-vision.png) |
|08 | [포탑 시야/공격](assets/next-tower-range.png): 밝은12m 실선·황색8.5m 점선과 한국어 설명 |
|09 | [A 공격 이동 조준](assets/next-attack-move.png): 준비 상태·목적지 표시 |
|10/11 | 실제로 승인 가능한 [바스Q 부채](assets/next-wall-cone.png), [바스W 원](assets/next-wall-circle.png)의 벽 차단 |

캡처는 실제 battlefield 장면을 로드하고 확인할 위치·소스 상태를 준비한 자동 장면이다. 사람의 조작 관찰이나 일반 경기 기록이 아니다. 시야 전후에는 실제 GPU의 지면/미니맵 텍스처를 읽어 비관측→관측→비관측을 확인했다. Headless dummy 렌더러만으로 GPU 텍스처 업데이트 성공을 주장하지 않았다.

**표시의 현재 한계:** 지면·미니맵 음영은1m 텍셀 중심 샘플이며 임의 지점과 약0.71m 차이가 가능하다. 이동 갱신250ms 간격과0.1m 이하 이동 억제를 사용해 미세 이동의 지연이250ms보다 길 수 있다. 제공원 집합 변화는 즉시 갱신한다. 클릭·모델·HP·셀 숫자는 정확한 현재 시야 판정, 적 경고는 현재 시야 기하의 보수적 영역으로 제한한다. 마우스오버 시야 외곽선은128방향 샘플이다.

68유닛/아군34제공원 준비 상태에서 지면 음영 갱신 중앙값27.8ms·최대36.4ms, 정지60프레임에서 재계산0회를 측정했다. [로그](verification/2026-10-27-vision-profile.log) / [스크립트](verification/2026-10-27-vision-profile.gd).4Hz 제한은 평균 작업을 줄이지만 해당 프레임의CPU 부하를 없애지는 않는다. 실제 PC의 끊김과 병력/경고 중첩은 R18에서 측정한다.

## 6. Windows 패키지 검증

[패키징 CLI](../../tools/package_windows.py)와 [반복 절차](../../docs/technical/04-windows-build.md)를 구현했다. 고정 엔진과 일치하는 공식 templates를 확보했고 별도의 작은 실제 프로젝트에서 release export를 확인했다.

```sh
python -B -m unittest discover -s tools/tests -v
python tools/package_windows.py --godot /actual/path/to/Godot_v4.7.2-stable_linux.x86_64
```

첫 명령의 최종 결과는 **9 tests,0 failures**다. [패키징 검사 로그](verification/2026-10-27-packaging-tests.log). 외부 엔진 경계에 실패 응답을 주입해 실제 CLI의 파일·ZIP·manifest·종료 코드를 확인한다. 잘못된 버전/templates, 종료0이어도 오류가 있는 import/export, 빠진PCK, 오래된 산출물 재사용, 고지 누락과 다른 파일이 있는 출력 폴더 덮어쓰기를 거부한다. 실패 시 이전 정상 패키지를 보존한다. 이 대역 검사를 실제 게임 export로 세지 않는다.

**최종 게임 Windows release export 완료.** 소스 commit [a11834f](https://github.com/herothgf-cell/project-e/commit/a11834fc0da7ad1aa75292c03661d86b989d00ec), Git tree `07cbe0f89a14789f04672376824e50083d3783a2`의 깨끗한 작업 트리에서 생성했다. 이 뒤의 배포 검증 문서 갱신은 게임 소스를 바꾸지 않는다.

| 파일 | 실제 크기(bytes) | SHA-256 |
|---|---:|---|
| ProjectE-windows-x86_64.zip |39,413,375 |`4bcccb9aac03bc20557d74a4b40e8baf7718ec41e20e05c756b397babc772fb0` |
| ProjectE.exe |109,268,480 |`d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562` |
| ProjectE.pck |1,328,356 |`7694f1498fc7c4187098ddea16a75fd31e65c86140c36f8022bd9c8d5fb64368` |

실제 import/export는 종료0·오류0이다. EXE의 PE32+ x86-64 형식, PCK 헤더, ZIP11개 항목의CRC, ZIP과 원본의 파일별 일치, manifest와 별도ZIP 체크섬을 확인했다. 게임 소스63개 파일을 다시 해시해 manifest와 비교했으며 소스 snapshot SHA-256은 `2f93037831c72eada8041d0f4d4890a20d953c6fdf692eceec816c4390e3c37c`다.

- [실제 import 로그](verification/2026-10-27-windows-import.log) / [release export 로그](verification/2026-10-27-windows-export.log)
- [빌드 manifest](verification/2026-10-27-windows-manifest.json) / [ZIP 체크섬](verification/2026-10-27-windows-zip.sha256)
- [Linux exported-PCK 시작 로그](verification/2026-10-27-windows-pack-headless.log): 소스 폴더 밖 `/tmp`에서90프레임, 종료0·오류0.
- [exported-PCK 실제 GL 로그](verification/2026-10-27-windows-pack-graphical.log): [선택 화면](assets/windows-pack-startup.png)과 [바스 일반 경기 시작](assets/windows-pack-match.png)2장. 한국어·맵·유닛·HUD·미니맵을 확인했고 종료0·오류0, 기존VSync 경고만 있다.

전달 ZIP에는 EXE/PCK·한국어 실행 안내·Godot/폰트/게임 고지·manifest·빌드 로그를 포함한다. 전체 압축을 풀고 ProjectE.exe를 실행하며 ProjectE.pck를 같은 폴더에 둔다. ZIP/manifest는 export 뒤 수정하지 않았다.

**실제 Windows PC 실행과 사람 플레이는 미실시**다. 이 호스트에는 Wine/Wine64도 없다. Linux로 exported PCK를 로딩하더라도 플랫폼 공통 리소스/스크립트 확인이며 Windows PE 실행과 다르다. Steam과 온라인 테스트도 별도 범위다.

## 7. 실제 사람에게 남은 확인

[R03/R05 기록표](12-local-playtest-record.md)에 참가자·빌드·장비·일반/체험 조건·완주/중단을 기록한다. 세 영웅의 이동·기술·성장·A 명령, 셀 선택, 무엇이 시야를 주고 어디가 보이지 않는지, 포탑 접근·퇴각·공성, 사망/부활·재시작을 실제 입력으로 확인한다. Windows 배율·Alt-Tab·글자·창 크기·로그와 프레임 시간도 같은 빌드로 기록한다.

사람6명의 균형,12–18분 가설, 온라인 지연/손실·재접속, Steam 배포, 최종 아트·음향·접근성은 자동 로컬 검사로 완료 처리하지 않는다.
