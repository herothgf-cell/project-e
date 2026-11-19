# 문서 지도·정본·출처 읽기

정리일 2026-11-19. 코드 기준 V9 main e29c36296abf6d365353401dd0cbee411edc531d.

## 1. 폴더마다 맡은 역할

| 경로 | 역할 | 읽는 시점 |
|---|---|---|
| doc/handoff/ | 인계 시작, 요구·현재 상태·작업 순서·환경 | 새 담당자가 처음 읽기 |
| doc/handoff/elements/ | 요소별 현재 동작 요약과 후속 과제 | 담당 시스템 이해 |
| doc/handoff/templates/ | 새 기획·플레이테스트 작성 양식 | 이후 변경 기록 |
| doc/design/content/ | 현재 콘텐츠 상세 규칙 10편 | 수치·흐름·예외 확인 |
| doc/design/characters/ | 8영웅 개별 패시브·QWER·대응 시트 | 기술 제작·밸런스 |
| doc/design/reverse-design/ | 참고작 역기획 6편과 근거 | 원작과 판단 구조 비교 |
| doc/design/verification/ | 버전별 실행 조건·원자료·한계 | 과거 결과 재현·비교 |
| doc/design/assets/ | 시안, 실제 화면, 영상, 시각 근거 | 품질·배치 검토 |
| doc/design/숫자-제목.md | 초기 상세와 V2~V9 변경 이력 | 왜 바뀌었는지 추적 |
| docs/ | 초기 제품 기획과 장기 기술·출시 로드맵 | 장기 범위와 결정 맥락 |
| game/project-e/ | 실제 Godot 프로젝트 | 현재 동작 판정 |
| tools/ | 자산 제작·검증·공성 계측·패키징 | 재현과 수정 확인 |

이 경로들은 실제 저장소 구조다. 기획 전달 ZIP에는 문서·검증·시각 자료가 포함되고, 게임 코드와 실행 자산은 소스 저장소로 연결될 수 있다. 패키지의 시작 안내에서 포함 범위를 확인한다.

## 2. 충돌을 발견했을 때

### 의도와 실제 동작을 나누기

- **만들려는 것:** 최신 사용자 요구, 이후 채택된 기획·결정.
- **현재 동작:** 기준 커밋의 코드·설정·자산 연결, 해당 빌드의 실제 실행.
- **과거 증거:** 문서에 명시된 커밋·환경·조건에서 얻은 기록.
- **제안:** 채택 여부와 검증이 남은 아이디어.

소스가 요구와 다르다면 “소스가 있으므로 요구가 바뀌었다”고 해석하지 않는다. 문서가 코드와 다르다면 “문서대로 구현되어 있다”고 보고하지 않는다. 차이·영향·다음 작업을 기록한다.

### 현재 정보를 찾는 순서

1. doc/handoff/의 상태와 문서 기준을 확인한다.
2. doc/design/content/와 characters/에서 현재 규칙을 찾는다.
3. 연결된 소스와 V9 변경·검증 자료로 대조한다.
4. 과거 문서가 다르면 버전과 당시 목적을 확인한다.
5. 사용자 요구가 변경됐거나 버그 가능성이 있으면 차이 목록을 남긴다.

초기 docs/의 “정본” 선언은 그 문서 작성 당시 초기 기획에 대한 설명이다. V9 현재 규칙을 판단할 때 그대로 우선하지 않는다.

## 3. 주제별 깊이 읽기

| 질문 | 먼저 읽기 | 상세·근거 |
|---|---|---|
| 게임의 핵심이 무엇인가 | [제품 방향](01-product-and-decisions.md) | [초기 개요](../../docs/00-project-brief.md) |
| 맵이 왜 세로인가 | [전장 요약](elements/02-map-vision.md) | [V8 감사](../design/29-cot-map-minion-siege-review.md), [V9](../design/30-v9-vertical-siege.md) |
| 미니언이 왜 죽이지 않나 | [병력·공성](elements/04-minions-ai-siege.md) | [현재 병력](../design/content/04-units-and-ai.md), [원작 병력](../design/reverse-design/04-units-siege-and-items.md) |
| 골드를 따로 쓰는 이유 | [골드·아이템](elements/06-gold-items.md) | [현재 경제](../design/content/06-gold-and-items.md), [원작 성장·경제](../design/reverse-design/03-growth-and-economy.md) |
| 캐릭터를 어떻게 차별화하나 | [8영웅 요약](elements/07-heroes.md) | [개별 8시트](../design/characters/README.md) |
| 최신 외형 제작안은 무엇인가 | [미술 인계](elements/09-art-audio.md) | [2026-11-19 D 혼합형 아트 바이블](../design/31-subculture-fantasy-hero-art-direction.md), 실제 모델 미반영 |
| 실제 완성도는 어떤가 | [상태와 한계](02-status-and-open-work.md) | [V9 실제 화면](../design/assets/v9/README.md), [V5 시안](../design/assets/fantasy-v5/art-prompts.md) |
| 무엇을 실행해 검증했나 | [검증 요약](elements/10-balance-tests.md) | [V9 검증 원문](../design/verification/2026-11-10-v9-verification.md) |
| 다른 PC에서 어떻게 열고 빌드하나 | [환경·빌드](06-environment-build.md) | [Windows 빌드](../../docs/technical/04-windows-build.md) |
| 어떤 파일을 고치나 | [코드·자산 지도](07-code-assets.md) | 각 요소의 소스 링크 |
| 온라인·Steam은 어디까지인가 | [온라인·제품화](elements/11-online-steam.md) | [장기 기술](../../docs/technical/02-architecture-and-networking.md), [출시](../../docs/release/01-steam-release-plan.md) |

## 4. 이전 자료에서 특히 조심할 내용

| 자료 | 현재 읽는 방법 |
|---|---|
| docs/00-project-brief.md의 3영웅·6영웅 범위 | 초기 제안, 현재 선택 풀은 8명 |
| docs/README.md의 V8·R09·R10 진척 | 과거 목차·개발 기록, 최신 실행 상태는 V9 |
| 초기 가로 맵 SVG·서쪽/동쪽 표현 | 당시 레이아웃/내부 좌표 맥락, 현재 화면은 세로 |
| docs/technical/01-unity-and-steam.md | Godot 전환 이전 이력·안내 |
| V5 아트 생성 프롬프트의 가로 배치 | 과거 컨셉 제작 조건, 현재 V9 전장 방향 사양이 아님 |
| V8 신규 영웅 시트의 방향 표현 | 기술 내용과 화면 방향을 분리해 읽기 |
| 검증 원문의 “이번”, “현재”, “최종” | 해당 문서 날짜·빌드에 한정 |
| 과거 배포 아티팩트 링크 | 보존기한이 있는 산출물, 소스 재빌드 경로와 구분 |

과거 원문은 비교 가능한 기록으로 남긴다. 현재 문서의 오류를 수정하면 변경 이유와 대조 소스를 함께 기록한다.

## 5. 참고작 근거의 범위

참고작 자료는 사용자가 제공한 “시티 오브 템페스트 - 나무위키.pdf”, 당시 공략·웹 자료, 지정 영상과 정지 표본이다. 원본 PDF는 저장소에 포함된 것으로 가정하지 않는다. 전달받은 별도 자료가 없다면 [근거 등록부](../design/reverse-design/06-evidence-and-open-questions.md)의 페이지·출처 정보를 사용하고 확인이 필요한 항목을 표시한다.

지정 영상: https://www.youtube.com/watch?v=B0V1yRqhIc8

저장소의 2026-11-10 기록은 약 10초 간격 143개 정지 표본과 2011년 스크린샷을 대조한 결과다. 현재 문서 정리에서는 그 자료·기록을 확인했으며 영상 전체를 새로 검토하지 않았다. 세로 축을 확인한 근거와 정확한 거리·쿨타임·체력·평균 경기 시간의 실측은 서로 다르다.

## 6. 새 문서 갱신 규칙

파일마다 대상 버전·근거·제안 여부를 적는다. 수치를 바꾸면 관련 콘텐츠, 캐릭터 시트, HUD 설명, 검사 조건을 함께 확인한다. 공성 실험은 실제 AI 주입과 핵별 사건을 남긴다. 외부 자료의 최신 요금·정책·엔진 지원은 적용 시 공식 출처에서 다시 확인한다.
