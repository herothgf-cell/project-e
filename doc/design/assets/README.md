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
