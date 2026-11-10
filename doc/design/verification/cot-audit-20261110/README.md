# 미니언과 공성 계측 재현

2026-11-10에 V8의 미니언 격리 전투와 여섯 전술 봇 경기를 계측했다. 원본 게임 커밋은 `eb022135baf95046e1b1145bec45f5c26bab5b8a`, 게임 트리는 `60f8258919678e4b5c4f3c554c16727122ba8772`다. 엔진은 공식 Godot `4.7.2.stable.official.ed1daf0bf`를 사용했다. [검토 결과](../../29-cot-map-minion-siege-review.md)

## 포함 파일

| 파일 | 내용 |
|---|---|
| [minion-probe.gd](minion-probe.gd) | 대상별 1 HP 유보, 병력 기능·사거리, 포탑과 웨이브, 잔존, 보상 검사 |
| [minion-probe.log](minion-probe.log) | 최신 원본 프로젝트에서 재실행한 27개 검사와 격리 관측값 |
| [siege-probe.gd](siege-probe.gd) | 원본 판정 함수를 호출하는 관찰기와 만렙 셀 후보 제외 비교 옵션 |
| [baseline.log](baseline.log) | 기본 경기 2,077.33초 자연 종료 |
| [no-max-cell.log](no-max-cell.log) | 비교 경기 2,400.5초 관찰, 승패 미결정 |
| [results.json](results.json) | 두 경기의 구조물별 피해·시간·핵 상태·영웅 후퇴와 판정 집계 |

`siege-probe.gd`의 기본 옵션은 원래 전술 AI를 그대로 호출한다. `no-max-cell` 옵션은 레벨 12 이상일 때 새 셀 후보를 반환하지 않는 조건 하나를 적용한다. 공개한 관찰기는 추가 성장·임무 시작 로그를 포함하며 출력 경로를 세 번째 인자로 받는다. 출력 인자가 생략되면 Godot 사용자 데이터의 `cot-audit` 폴더를 사용한다.

## 실행

저장소 루트에서 아래와 같이 실행한다. `audit_godot`에 공식 4.7.2 실행 파일의 실제 경로를 지정한다.

```bash
audit_godot=/absolute/path/to/Godot_v4.7.2-stable_linux.x86_64
audit_repo="$PWD"
audit_output="$(mktemp -d)"
"$audit_godot" --headless --path "$audit_repo/game/project-e" --editor --import
"$audit_godot" --headless --path "$audit_repo/game/project-e" --script "$audit_repo/doc/design/verification/cot-audit-20261110/minion-probe.gd"
"$audit_godot" --headless --path "$audit_repo/game/project-e" --script "$audit_repo/doc/design/verification/cot-audit-20261110/siege-probe.gd" -- bas baseline "$audit_output"
"$audit_godot" --headless --path "$audit_repo/game/project-e" --script "$audit_repo/doc/design/verification/cot-audit-20261110/siege-probe.gd" -- bas no-max-cell "$audit_output"
```

미니언 검사는 `27 checks, 0 failures`를 출력한다. 경기 관찰기는 자연 승리 시 종료 코드 0, 관찰 상한 도달 시 종료 코드 1을 반환한다. 이번 비교 조건은 승패 미결정으로 코드 1을 반환했다. 명목 상한 2,400초에 0.5초 진행의 부동소수점 경계가 더해져 최종 표본이 2,400.5초가 됐다.

## 측정 의미

- 사건 시각은 실제 피해·해금·파괴 시각이다. 점유 시간은 0.5초 표본을 합산했다.
- 영웅·병력 근접 반경과 공성 지원 반경은 12 m다. 근접 상태가 모든 영웅의 기본 공격 사거리 진입을 뜻하지 않는다.
- 핵 표적 유지 시간과 실제 피해 판정은 별도 집계다. 범위 기술·투사체는 현재 표적 이외의 대상에도 피해를 줄 수 있다.
- 여러 영웅의 후퇴 시간을 합친 값의 단위는 영웅·초다. 동시 후퇴가 포함된다.
- 기본과 비교 경기는 관찰 길이가 다르다. 비교의 실제 승리 시간은 이 기록에 없다.
- 팀 구성은 양 팀 바스·리오·네마이며, 사람 입력은 없다. 다른 조합과 사람 플레이는 추가 검증 대상이다.

모든 구조물에서 출처별 피해의 합과 실제 HP 감소가 일치하는지 확인했다. 두 실행에서 첫 만렙 480.77초 이전 사건 842개가 일치했고, 비교 실행의 만렙 이후 새 셀 시작은 0회였다.
