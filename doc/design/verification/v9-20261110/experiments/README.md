# AI 조건을 분리한 공성 실험

이 폴더는 V9 채택 전에 실행한 **과거 실험용 관찰기**와 로그를 보존한다. 현재 제품의 측정은 저장소 루트의 `tools/measure_siege.gd`를 사용한다.

다섯 스크립트의 전투·맵·수치는 V8 원본을 읽고, 각 스크립트의 `ObservedAI`만 설명된 의사결정 조건을 바꾼다. 원본 관찰기에서 복사된 주석과 `source_commit`은 V8 게임 코드 계보를 나타낸다. 실제 비교 checkout은 `debcd53c6d991ef568761761c38dae2095bc67d6`이며, 직전 `eb022135baf95046e1b1145bec45f5c26bab5b8a`와 게임 소스가 같고 문서만 추가됐다. 정확한 실행 파일 SHA-256, 관찰 조건, 결과와 사건 일치 검증은 [조건별 결과](../controlled-ai-experiments.json)에 있다.

**이 실험 스크립트를 V9 게임 경로에서 실행하면 비교가 무효다.** V9의 기지 출발 재배치가 이미 추가되어 실험 조건이 겹치기 때문이다. 아래처럼 V8 기준 소스를 별도 디렉터리에 풀어 실행한다.

```bash
experiment_repo="$PWD"
experiment_base="$(mktemp -d)"
git archive debcd53c6d991ef568761761c38dae2095bc67d6 game/project-e | tar -x -C "$experiment_base"
/absolute/path/to/Godot_v4.7.2-stable_linux.x86_64 \
  --headless --path "$experiment_base/game/project-e" \
  --script "$experiment_repo/doc/design/verification/v9-20261110/experiments/base-redeploy-two-probe.gd" \
  -- bas base-redeploy-two "$experiment_base/results"
```

| 스크립트 / 실행 이름 | 단독 또는 직전 조건 대비 변경 | 채택 |
|---|---|---|
| `core-mission-probe.gd` / `core-mission` | 지원 병력이 있는 가시 핵을 잡몹·셀보다 먼저 선택 | 아니오 |
| `core-approach-probe.gd` / `core-approach` | 공개된 핵 위치로 시야 확보 전 합류 이동 허용 | 아니오 |
| `core-balanced-probe.gd` / `core-balanced` | 수비 영웅 부재 대신 관측된 국지 인원 열세를 판단 | 아니오 |
| `base-redeploy-probe.gd` / `base-redeploy` | 나머지 원본 AI를 유지하고 기지에서 열린 라인으로 재배치 | 비교 기준 |
| `base-redeploy-two-probe.gd` / `base-redeploy-two` | 재배치 라인에 할당 영웅을 최대 2명으로 제한 | 제품 구현의 기준 |

원본 기본 조합과 마지막 실험의 첫 정책 개입은 426초이며, 그 이전 구조물 피해·파괴·해금·영웅 사망 469개 사건이 완전히 같다. 마지막 실험은 486.6333초에 실제 핵 파괴로 끝났다. 제품은 생명주기 정리·진행 중 행동·방어·기존 임무를 먼저 처리하고, 회복 완료 시에는 기존 후퇴 해제 분기를 유지한다. 이 우선순위 보호는 별도 RED/GREEN 회귀로 검증했으므로 최종 보고에는 제품 코드의 자연 경기 측정 결과를 사용한다.

원시 사건·5초 스냅샷 JSONL은 각 명령에서 다시 생성된다. 저장소에는 약 138 KB의 실행 스크립트·진행 로그·요약을 남겼으며 대형 반복 시계열은 포함하지 않았다. 관찰 상한으로 끝난 실행의 종료 코드 1은 미종료 표본을 뜻하며, 자연 승리 시간으로 해석하지 않는다.
