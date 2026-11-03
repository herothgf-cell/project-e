# Fantasy Semi-Cartoon V3 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox syntax.

**Goal:** 3등신 판타지 캐릭터·게임용 아이콘·배경·HUD를 기존 Godot 3D 경기와 연결한다.

**Architecture:** 게임 권한(`battle/`) 불변. 캐릭터와 전장만 메시/장식, HUD만 2D SVG 자산·테마. UI 리소스는 `assets/ui/` 경로에서 로드한다.

**Tech Stack:** Godot 4.7.2 GDScript, SVG 1.1, GitHub Actions.

**Spec:** [fantasy-v3-art-spec.md](../../../../doc/design/21-fantasy-v3-art-spec.md)

## Global Constraints
- 시티 오브 템페스트 참고 전투의 카메라·3라인·QWER 조작 및 권한 유지
- 바스/리오/네마만 시각 변경; 모든 영웅 관절과 existing 10-clips 보존
- 모든 새 에셋 직접 제작, 상업 사용 가능, 원본 SVG Git 추적
- 길/충돌/고저/시야 및 권한 게임 로직 변경 없음
- Godot 4.7.2 Standard; PC 1280×720 HUD 내 주요 정보 보존

## Review Focus
- 3영웅 비율 일치 및 길이 변형에도 히트박스 반경 0.45m 보존
- SVG 미가져온 초기 실행과 headless import에서 텍스처 에러 없는지
- 영웅 교체 시 QWER 아이콘 12종 모두 갱신되는지
- 게임 HUD 버튼/문구의 대조와 화면 겹침
- 게임 중 숨은 적/효과 시각 정보 누출 없게 장식이 지도 시야 마스크를 이용하는지

### Task 1: 가이드 및 검증
- [ ] 아트 명세, 적용 체크리스트, 자산 목록 작성
- [ ] 새 실루엣/에셋 검사 테스트 작성, 기존 소스에서 실패 조건 확인
- [ ] Godot headless/검증 수행, 결과 문서 기록

### Task 2: 영웅 비율·3D 모델
- [ ] `hero_rig.gd` 머리 크기/몸통 비율 재구성
- [ ] 바스/리오/네마 판타지 팔레트·장비·얼굴 개성 부여
- [ ] 애니메이션 트랙·모델 API와 피격/사망 상태 불변 확인

### Task 3: 맵 아트
- [ ] `workshop_arena.gd`의 지면/석조 색조와 숲·마법 수정 장식 추가
- [ ] `battlefield.tscn` 환경 조명 개선
- [ ] 경로 및 물리/높이/시야 스크립트 비교, 변경 없음 확인

### Task 4: HUD와 재사용 가능한 게임 에셋
- [ ] `assets/portraits/` 바스/리오/네마 원본 SVG 3개
- [ ] `assets/ui/skills/` 3×QWER = 12개 벡터 아이콘
- [ ] `hero_portrait.gd`와 `battle_hud.gd`에 실제 리소스 적용
- [ ] 1280×720, 1920×1080 기본 UI 배치 검토

### Task 5: 시안/릴리스
- [ ] `doc/design/assets/fantasy-v3/` 스타일·맵·HUD SVG 시안 저장
- [ ] 자산 용량·상업 이용권·차후 확대 목록 문서화
- [ ] CI 기반 변경 영향/스크린샷 검사, PR 리뷰 후 main 반영
