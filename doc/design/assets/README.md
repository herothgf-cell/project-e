# Project E — 콘셉트와 실제 실행 화면

- Created: 2026-10-26 (Asia/Seoul).
- Method: built-in image generation tool, two original images.
- Status: art-direction proposals. These are not captured gameplay, final models, exact map blueprints, or approved UI/icon specifications. Exact map geometry and skill behavior remain defined by the design documents and code.
- `battlefield-concept.png`: proposed environment, materials, camera, and HUD hierarchy. The illustrative ability icons are compositional examples; each hero still has its own canonical four skills.
- `hero-lineup-concept.png`: Bas / Rio / Nema silhouette, clothing, tool and material proposals. Gender, face and clothing details are proposals for review, not previously confirmed user requirements.

## 실제 실행 화면

다음 파일은 생성 시안이 아니라 **Godot 4.7.2 Compatibility에서 렌더링한 현재 프로토타입**이다. 임시 3D 도형과 한국어 UI를 사용한다. 촬영 환경은 Linux 가상 디스플레이와 Mesa llvmpipe이며, 실행 명령·검증 범위는 [검증 기록](../09-verification.md)에 남겼다.

| 파일 | 실제 촬영 상태 |
|---|---|
| [prototype-battlefield.png](prototype-battlefield.png) | 일반 규칙의 봇 경기를 약75초 빠르게 진행한 뒤 촬영. 사람 플레이 기록은 아니다. |
| [prototype-nema-link.png](prototype-nema-link.png) | 기술 체험에서 실제 이동·Q 명령으로 두 핀을 설치. 0.5m 연결 띠가 남아 있는 상태. |
| [prototype-rio-return.png](prototype-rio-return.png) | 기술 체험에서 실제 W·Q 명령 사용. Q가 귀환 단계에 들어간 뒤 고정 회수점을 향하는 경로. |

촬영 스크립트는 `game/project-e/tests/capture_battlefield.gd`이며, 원본 이미지의 합성이나 보정 없이 저장했다. 상황 재현을 위한 명령과 시간 진행을 사용했으며 전투 수치나 피해 판정은 바꾸지 않았다.

## Battlefield prompt

```text
Use case: stylized-concept
Asset type: PC tactical action game art-direction concept, 16:9 landscape, professional game pitch visual.
Primary request: Create an original gameplay-style concept image for PROJECT E, a fast 3v3 three-lane action arena in a sunlit canal workshop city. This is a proposed visual target, not a technical diagram.
Scene: Cream glazed ceramic paving and waterworks, turquoise canals, copper pipes and water wheels, wooden maintenance bridges, restrained plants and terracotta workshop roofs. A compact battlefield with three roughly parallel east-west routes and short diagonal connecting footbridges; the central lane is the combat focus. Ceramics and craft tools define the identity. Functional paths very clear, scenery below visual priority of characters.
Subjects: Three allied guild technicians fighting a few opposing practice constructs and small clockwork worker minions near a copper-and-porcelain defense tower. Bas is a stocky broad adult with asymmetrical huge ivory ceramic pressing gauntlet and copper hinges; Rio is a slim adult with long woven scarf and thin copper-rimmed wooden discs; Nema is a medium-height adult with a folding backpack and two upright ceramic pins linked by a luminous line. These must look like original workshop people, not medieval knights or futuristic soldiers.
Composition: High fixed isometric/top-down gameplay camera. Heroes recognisable at gameplay size, negative space around a clearly marked copper fan attack and thin teal connection line. Show a clean restrained game HUD: top centered team cores and timer '06:42'; bottom-center four square abilities labeled exactly 'Q', 'W', 'E', 'R', health and energy bars; lower-right compact three-lane minimap. Do not crowd picture with UI.
Style: Premium approachable stylized 3D, softly beveled shapes, hand-painted roughness, strong large silhouettes, slightly exaggerated proportions but not baby/chibi, polished small-studio achievable direction, soft ambient occlusion, warm sunlight, no photorealistic texture noise.
Palette: ivory stone, warm copper and terracotta, deep teal water, small saffron cloth accents; teal versus coral team indicators differentiated with circle versus diamond markers.
Text: small discreet top-left 'PROJECT E', subtitle 'CANAL WORKS', top-right small 'VISUAL CONCEPT'. No other prose.
Constraints: Readable telegraphs with clean borders, characters visually above scenery, beautiful cohesive spatial composition, no existing game logos, no copied characters, no dark ruined jungle, no generic neon science fiction, no huge explosion hiding action.
```

## Character prompt

```text
Use case: stylized-concept
Asset type: Original PC game character design presentation sheet, landscape 16:9, three equal clean columns.
Primary request: Design the three playable adult guild technicians of PROJECT E, the same bright ceramic-and-copper canal-workshop world. Cohesive premium stylized 3D character concept art, production useful silhouette/material references. Show one large full-body three-quarter character per column, plus a small back view and two small tool details beneath each. Generous neutral warm ivory background. No scenery.
LEFT, BAS: a broad stocky adult man, warm tan skin, dark hair tied back, short beard, grounded work boots, deep teal work apron over ivory rolled-sleeve shirt. His defining tool is one HUGE asymmetric glazed ivory ceramic pressing gauntlet with exactly two large copper pressure hinges; the other arm is smaller. Low broad triangular silhouette. Chunky and confident, approachable craftsman rather than armored knight. Small detail insets show the two pressure plates and gauntlet mechanism.
CENTER, RIO: a slender agile androgynous adult with short dark swept-back hair, a long saffron woven scarf, off-white tunic, dark indigo fitted work trousers. Two thin COPPER-RIMMED WOODEN DISCS carried at the waist, one held in hand, carved concentric grooves. Long narrow flowing silhouette and light sideways stance. The discs are craft alignment tools, not guns or swords. Insets show disc cross-section and cloth retrieval-knot token.
RIGHT, NEMA: a medium-height adult woman with practical short dark hair and safety goggles on her forehead. Sage-teal utility overalls, ivory sleeves, a compact folding copper-and-wood backpack, ceramic tool pockets, sturdy low boots. Carries two slender white ceramic connection pins, one shown deployed beside her, with a thin teal energy thread between pins. Medium rectangular silhouette defined by backpack and upright tools. Insets show folding pack and pin design.
Style: consistent softly beveled stylized 3D forms with hand-painted material finish, adult proportions gently exaggerated for top-down readability, clean strong shapes, restrained ornamental motifs, warm studio light, readable faces and full hands, lovingly crafted polished game concept sheet. Cloth, copper, glazed ceramic and wood clearly different. Not photorealistic, not toy baby proportions.
Typography: at top 'PROJECT E' and smaller 'CHARACTER CONCEPTS'. Column headings exactly 'BAS', 'RIO', 'NEMA'. Small role labels exactly 'BREAK / GUARD', 'RETURN / REPOSITION', 'LINK / PROTECT'. Small bottom-right 'VISUAL CONCEPT'. No other text.
Constraints: exactly three original hero designs, every full-body figure fits entirely within its column; tools do not overlap neighboring columns, no copied characters or existing game logos, no grimdark armor or generic neon sci-fi, no swords, no sexualized clothing. Preserve common material language but three unmistakably different silhouettes.
```


## 2026-10-27 다음 개발의 실제 렌더

Godot4.7.2 Compatibility, Linux/Xvfb/Mesa llvmpipe에서 `capture_next_features.gd`로 생성했다. 시야 전후와 셀 비교는 재현을 위해 위치·활성 상태를 준비한 자동 장면이며 사람 플레이 기록이 아니다.

| 파일 | 내용 |
|---|---|
| next-guide.png | 1280×720의 F1 안내 |
| next-cell-tiers.png | 실제30초 생성 후 위치를 모은20/30/40 XP 셀 |
| next-vision-before.png / next-vision-overlap.png / next-vision.png | 같은 카메라의 벽 차단→아군 제공원 추가→제거, 눈 표식·시야 범위 |
| next-tower-range.png |12m 시야와8.5m 공격 사거리 |
| next-attack-move.png | A 공격 이동 조준·지면 목적지 |
| next-wall-cone.png / next-wall-circle.png | 유효한 바스 Q/W 조준의 벽 차단 |

자세한 준비 조건·실행 로그·표시 한계는 [검증](../09-verification.md)을 따른다.

이전 소모품 없는 `a11834f` Windows release export의 PCK도 소스 폴더 밖에서 Linux 엔진으로 로딩했다. `windows-pack-startup.png`는 선택 화면, `windows-pack-match.png`는 일반 경기 시작이며 실제 Windows EXE 실행의 증거는 아니다. [exported-PCK 로그](../verification/2026-10-27-windows-pack-graphical.log)를 함께 확인한다.


## 2026-10-27 기지 상점·소모품의 실제 렌더

다음9장은 `game/project-e/tests/capture_consumables.gd`가 Godot4.7.2 Compatibility, Linux/Xvfb/Mesa llvmpipe에서 저장한 **실제 기능 확인 프레임**이다.720p/1080p에서8장씩 총16장을 확인했고, 아래는 저장소에 보관한 대표9장이다. 생성 시안이나 사람의 경기 기록이 아니다. [최신 검증의 촬영 조건](../13-consumables-verification.md#5-실제-렌더와-화면-확인)과 [렌더 실행 로그](../verification/2026-10-27-consumables-render.log)를 함께 확인한다.

| 파일 | 실제 촬영 상태 |
|---|---|
| [consumables-selection-720p.png](consumables-selection-720p.png) | 선택 화면의 경기 중 P/D/F1 조작 안내와 시작 버튼 |
| [consumables-shop-720p.png](consumables-shop-720p.png) |1280×720 상점: 두 품목의 가격·효과·구매 조건·닫은 뒤 선택/D 사용 순서 |
| [consumables-shop-1080p.png](consumables-shop-1080p.png) |1920×1080 상점: 논리 UI 크기도 넓혀 품목 카드·안내·닫기 버튼의 배치 확인 |
| [consumables-inventory-720p.png](consumables-inventory-720p.png) | 실제 병/패치 구매 뒤 종류별 수량과 선택 표시; 슬롯 클릭은 선택만 함 |
| [consumables-recovery-720p.png](consumables-recovery-720p.png) | 병을 사용하고0.5초 진행한 상태: 감소한 재고·공유 대기11.5초·회복1.5초 |
| [consumables-interruption-720p.png](consumables-interruption-720p.png) | 실제 적 영웅 귀속 피해로 패치 회복을 끊은 뒤 한국어 중단 알림·공유 대기 |
| [consumables-help-720p.png](consumables-help-720p.png) | F1의 기존 성장·시야·공성 안내와 P 상점→구매→닫기→선택→D 사용 설명 |
| [consumables-offbase-720p.png](consumables-offbase-720p.png) | 자기 기지 밖에서 상점 설명은 열리고 구매는 이유와 함께 제한되는 상태 |
| [consumables-dead-720p.png](consumables-dead-720p.png) | 사망 중 상점 열람과 구매 불가 이유 |

경기 프레임은 기술 체험의 바스L3와 재현용 크레딧210·자원 부족 상태를 준비하고 **실제 구매·사용·시간 진행·피해 명령**으로 만든 테스트 장면이다. 병40+패치50을 실제로 구입해120크레딧이 남는지 확인했다. 일반 경기의 시작금100이나 전투 수치를 바꾼 것이 아니며 자연6봇 경기의 특정 순간을 촬영한 것도 아니다.

**1080p는 창 크기와 논리 UI 크기를 모두1920×1080으로 설정한 레이아웃 검사**다.720p 논리 화면을 단순 확대했다는 의미가 아니며, 실제 Windows100/150/200% DPI 배율·물리 키보드/마우스·Windows EXE 실행 검증으로 대신하지 않는다. 실제 Windows PC와 사람 플레이는 미실시다. 새 Windows export·패키지 검증은 아래 내보낸 PCK 화면과 [최신 검증](../13-consumables-verification.md)의 별도 산출물 기록을 따른다.


## 새 Windows 패키지의 PCK를 소스 밖에서 실행한 화면

다음3장은 소스 commit `e56286a064063bda84ccd9eb309ab8fb80a575a1`에서 실제 Windows release로 내보낸 **ProjectE.pck를 원본 프로젝트 밖에서 Linux Godot의 `--main-pack`으로 연 결과**다. 소스 실행 프레임이나 이전 `a11834f` 패키지 화면과 구별한다. [GL 실행 로그](../verification/2026-10-27-consumables-pack-graphical-probe.log)는13개 검사 실패0·3프레임이며 root가 실제 화면을 확인했다. [probe 소스](../verification/2026-10-27-consumables-pack-probe.gd)와 [실행 환경/결과](../verification/2026-10-27-consumables-pack-graphical-probe-result.json)를 함께 보존했다.

| 파일 | 실제 내보낸 PCK의 촬영 상태 |
|---|---|
| [consumables-pack-selection-720p.png](consumables-pack-selection-720p.png) | 내보낸 메인 장면의 영웅 선택과 경기 중 P/D 조작 안내 |
| [consumables-pack-shop-720p.png](consumables-pack-shop-720p.png) | 일반 바스L1의 구매 전 상점. 시작100크레딧·병/패치 재고0 상태이며 이 촬영 뒤에 실제 구매 수행 |
| [consumables-pack-recovery-720p.png](consumables-pack-recovery-720p.png) | 기지 밖 위치 `(-45,0)`와 에너지50을 배치한 뒤 실제 D 사용·0.5초 진행. 병 재고0/패치1·공유 대기11.5초·회복1.5초 표시 확인 |

상점 프레임 촬영 후 실제 구매로100→10크레딧이 되는지 검사했다. 회복 후 내부 에너지는64와의 차이가0.001 미만인지 probe의 상태 assertion으로 확인했다. 회복 사진의 정수 HUD는63/100이며, 상태 assertion의 근삿값을 사진에64가 표시된 증거로 쓰지 않는다.

출력은1280×720이다. 이는 내보낸 스크립트·리소스·한국어 UI와 소모품 실행 경로의 확인이며 **Windows EXE를 실제 실행한 결과가 아니다**. 실제 Windows PC·물리 입력·DPI·Alt-Tab·사람 플레이는 계속 미실시다. ZIP 해시·소스73개 일치·독립 패키지 검토는 [현재 패키지 안내](../../../docs/technical/04-windows-build.md#7-현재-소모품-테스트-패키지)와 [최신 검증](../13-consumables-verification.md)을 따른다.
