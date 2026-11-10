# V9 검증 자료

제품 코드 커밋은 `200df52e018e46b5b7847bfd808c59206dca7a75`다. 자연 경기 JSON은 실행 당시 작업 트리 설명을 `source_revision`에 기록했고, 게시 코드와의 연결은 각 전투 파일의 SHA-256을 대조해 확인했다. [비교와 코드 식별](natural-match-comparison.json) · [해석을 포함한 검증 기록](../2026-11-10-v9-verification.md)

텍스트 로그는 보관할 때 UTF-8 BOM·CRLF·줄끝 공백과 마지막 빈 줄만 정규화했다. 메시지·검사 수치·실패 결과는 바꾸지 않았다. [정규화 전후 해시](log-normalization.json)

## 최종 제품 검증

| 자료 | 내용 |
|---|---|
| [final-regression.log](final-regression.log) | 정확한 Godot 4.7.2, 38개 스위트·6,997개 검사·실패 0, 시작 장면 |
| [packaging-unit-tests.log](packaging-unit-tests.log) | Windows 패키지 도구 9개 Python 검사 |
| [review-summary.md](review-summary.md) | 독립 검토, 실제 지원 임무 중단 재현, 수정과 재승인 |
| [review-task-red.log](review-task-red.log) / [GREEN](review-task-green.log) | 42개 공성 검사 중 8개 실패를 재현한 뒤 모두 통과 |
| [vertical-red.log](vertical-red.log) / [선택 RED](vertical-pick-red.log) / [GREEN](vertical-green.log) | 세로 좌표·입력·안개·구조물 선택 검사 |
| [natural-match-comparison.json](natural-match-comparison.json) | 세 편성의 수정 전후 종료 시간과 최종 공성 지표 |
| [바스 요약](siege-v9-bas-summary.json) / [오린 요약](siege-v9-orin-summary.json) / [테르 요약](siege-v9-tere-summary.json) | 실제 코드 해시, 구조물·영웅·피해·판단·회복 통계 |
| [natural-trace-files.json](natural-trace-files.json) | gzip으로 보존한 전체 사건·5초 상태 표본의 파일명과 SHA-256 |

전체 사건과 표본은 `siege-v9-*-events.jsonl.gz`, `siege-v9-*-samples.jsonl.gz`다. 압축을 풀면 UTF-8 JSON Lines이며 각각의 행은 한 사건 또는 표본이다. 압축 파일과 원본의 해시를 함께 보관했다. 수정 전 두 신규 편성의 비교는 [V8 게시 집계](../2026-11-09-v8-verification.md)를 사용하며, 그 두 편성의 과거 전체 시계열이 있다는 뜻은 아니다.

## 원인 분리 실험

- [controlled-ai-experiments.json](controlled-ai-experiments.json): 핵 우선 접근과 기지 출발 재배치의 다섯 단일 변경 비교.
- [experiments/README.md](experiments/README.md): 실행한 실험 코드·로그·V8 기준 소스 재현 절차.
- [late-siege-experiment.json](late-siege-experiment.json): 12분 이후 공성 병력 빈도를 늘린 별도 단일 변경과 40분 미종료.
- [late-siege-probe.gd](late-siege-probe.gd): 보존용으로 경로 의존성을 제거한 공성 병력 실험 코드. 기준 소스에서 컴파일 확인했으며, 실제 측정한 외부 subclass와의 해시 관계는 JSON에 기록했다.

원인 분리 실험은 V8 기준 소스에만 실행한다. V9 위에서 실행하면 채택한 재배치 정책이 중첩되어 조건이 달라진다. 원작 시티 오브 템페스트의 실제 수치를 측정한 실험이 아니다.

## 초기·리뷰 전 기록

`baseline-regression.log`는 이번 작업의 수정 전 재실행(36개·6,877개 검사), `pre-review-regression.log`는 지원 임무 보완 전 결과다. `siege-red.log`, `siege-defense-red.log`, `siege-green.log`는 초기 26~27개 공성 검사 기록이다. 최종 판단은 위의 42개 검사와 최종 자연 경기 파일을 사용한다. 이전 기록을 최종 검증으로 덮어쓰지 않았다.
