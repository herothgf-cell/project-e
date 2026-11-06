# 실행 자산 안내

현재 기준은 **V5 수로 전장**이다. 자세한 미술 방향·소스 연결·수정 절차는 [V5 제작 안내](../../../doc/design/25-illustrated-canal.md), 수행된 확인은 [V5 검증 기록](../../../doc/design/verification/2026-11-05-v5-verification.md)을 따른다.

| 경로 | 현재 용도 |
|---|---|
| `heroes/{bas,rio,nema}.glb` | 얼굴·의상 텍스처가 내장된 현재 3D 영웅 |
| `heroes/*-face.webp`, `heroes/*-tunic.webp` | 영웅 3종의 얼굴·의상 편집용 이미지 6개 |
| `heroes/painted.gdshader` | 영웅의 텍스처·색면 표현 |
| `portraits/{bas,rio,nema}.webp` | 현재 영웅 선택 카드 초상화 |
| `portraits/*.svg` | 이전 V3 초상화 자료 |
| `ui/skills/*.svg` | 영웅별 Q/W/E/R 아이콘 12개 |
| `environment/*.glb` | 관측소·문루·회랑·포탑 왕관·수정·식생 등 환경 모델 11개 |
| `environment/canal_flagstones.webp`, `canal_waterbed.webp` | 석재·수로 바닥 |
| `environment/canal_surface.gdshader` | 전장 표면 표현 |

## 편집 주의

[영웅 생성기](../../../tools/build_hero_models.py)는 이 폴더의 얼굴·의상 WebP 6장에서 텍스처를 읽어 17개 노드의 GLB 3개를 만든다. [환경 생성기](../../../tools/art/build_canal_scenery.py)는 수로 구조물과 식생 GLB 11개를 만든다. 두 생성기의 결과는 V5 커밋 `6bd03beb`의 14개 모델과 바이트 단위로 일치했다. [재생성 명령과 검증 기록](../../../doc/design/verification/2026-11-06-v5-model-reproduction.md)

Blender/glTF 편집 시 `hero_rig.gd`가 사용하는 노드 이름·피벗·계층을 보존한다. GLB 안에는 얼굴·의상 이미지의 JPEG 사본이 들어 있으므로 외부 WebP를 수정한 경우 내장 이미지도 갱신하여 다시 내보내야 한다. Godot 가져오기 후 F7 검토실과 실제 경기 카메라에서 모든 동작을 확인한다.

원본 SVG·GLB·WebP·셰이더를 저장소의 기준으로 삼고 엔진의 가져오기 캐시를 원본으로 취급하지 않는다. V5 원화와 텍스처의 제작 기록은 [이미지별 프롬프트](../../../doc/design/assets/fantasy-v5/art-prompts.md), 엔진·한글 글꼴의 라이선스는 [프로젝트 고지](../../../THIRD_PARTY_NOTICES.md)에 있다.

과거 단계의 제작 지침은 [V3 자산 안내](../../../doc/design/22-fantasy-v3-asset-guide.md)와 [V4 자산 안내](../../../doc/design/24-fantasy-v4-asset-guide.md)에 보존한다.
