# V5 실제 실행 화면

2026-11-05 복구한 소스에서 Godot 4.7.2 Compatibility로 새로 렌더링했다. 예전 콘셉트 이미지와 달리 이 폴더의 스크린샷은 실제 모델·HUD·셰이더의 게임 화면이다.

- `selection.webp`: 실제 영웅 선택 화면. 카드 안의 그림은 선택용 일러스트 초상화다.
- `bas.webp`, `rio.webp`, `nema.webp`: F7 별도 연출실에서 세 영웅의 실제 GLB 모델을 확대했다.
- `combat.webp`, `mid-clash.webp`, `mid-detail.webp`: 실제 경기 장면과 전투 규칙을 사용하되, 반복 검토를 위해 캡처 스크립트가 영웅·미니언을 배치한다.
- `map.webp`, `lane.webp`: 연출실의 공개 지도와 고지·경사. 정상 경기의 적 시야 공개를 뜻하지 않는다.
- `skill-review.mp4`: QWER 12개와 사망·경사 이동을 15fps, 282프레임으로 기록한 18.8초 검토 영상. 음성·음악은 넣지 않았다.
- `capture-manifest.json`: 스크린샷 해시, 캡처 시점 소스·자산 해시와 렌더러 정보.

재현 스크립트는 [`capture_illustrated_pass.gd`](../../../../tools/art/capture_illustrated_pass.gd)와 [`capture_integrated_v2.gd`](../../../../game/project-e/tests/capture_integrated_v2.gd)다. [전체 검증 기록](../../verification/2026-11-05-v5-verification.md)과 [V5 자산 가이드](../../25-illustrated-canal.md)를 함께 본다.
