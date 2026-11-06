# V5 모델 생성기 재현 검증 — 2026-11-06

영웅과 환경 생성기 2개를 이전 작업본에서 회수했다. 빈 작업 폴더에 두 스크립트와 영웅의 얼굴·의상 WebP 6장만 저장소와 같은 상대 경로로 복사했다. 생성한 GLB 14개의 전체 바이트를 Git 트리 `93d811fffce4709214892e4ecd15e1a0280dcc0d`의 파일과 각각 비교했고 모두 일치했다. 이 트리는 [V5 기준 커밋 6bd03beb](https://github.com/herothgf-cell/project-e/commit/6bd03beb9480e22ec16c20420f62e7680b2906ea)에서 확인할 수 있다. 11월 5일 당시의 실행·렌더·패키지 검증은 [별도 기록](2026-11-05-v5-verification.md)에 있다.

## 재현 환경

Linux x86_64, CPython 3.12.14, NumPy 2.3.5, Pillow 13.0.0, libjpeg-turbo 3.2.0, libwebp 1.6.0. 영웅 생성기는 NumPy와 Pillow를 사용하고, 환경 생성기는 Python 표준 라이브러리를 사용한다. 생성기 2개를 복사한 작업 폴더의 루트에서 실행했다.

```sh
python tools/build_hero_models.py
python tools/art/build_canal_scenery.py
```

## 입력

| 생성기 또는 얼굴·의상 입력 | 바이트 | SHA-256 |
|---|---:|---|
| `build_hero_models.py` | 37,323 | `670a9867ce277544900f70778f775731c2ad9534f8c25bb384321c2ddb2faff1` |
| `build_canal_scenery.py` | 22,410 | `f4419de0d6bf53baf727bf9f3444c1943acb36f927f754c0b216a93dec3d587d` |
| `bas-face.webp` | 50,892 | `1e5c9ca21dc21b7f7dcab0ec4329ee6e9eaae2a0234785823a94c3212fe6876a` |
| `bas-tunic.webp` | 107,580 | `d0e63642095b7078c0681a9bfae8b301d2a195c4a3ce6ab3866bf0f41a806844` |
| `nema-face.webp` | 42,472 | `edb60eb021a1e53b62b3d2fdf23750ad5c29e0e0988e848ff6d908c8111c2e73` |
| `nema-tunic.webp` | 113,384 | `016d1d72dd99263027043777d14bdcb0bc6f1a4a32b22d495021e66d983eb6aa` |
| `rio-face.webp` | 36,186 | `c7fd9b63dd47ff6d0828f603ec0966919e0f9fcaef0533e4a3bec9a0c3034fbb` |
| `rio-tunic.webp` | 105,708 | `74b292f3ce884d61dff34e2bfed8a5a7160f5e3a988537a880c31e4decf76df7` |

영웅 생성기는 각 얼굴·의상을 메시에 맞게 변환해 GLB에 JPEG로 내장한다. 네마는 머리카락의 뒷부분을 후드 안으로 줄이는 계수가 복구된 소스에 포함된다. 원화부터 WebP를 새로 그리는 단계는 이 검증 범위에 포함하지 않았다. [영웅 소스](../../../tools/build_hero_models.py) · [환경 소스](../../../tools/art/build_canal_scenery.py) · [이미지 제작 기록](../assets/fantasy-v5/art-prompts.md)

## 생성 결과

| GLB | 바이트 | SHA-256 |
|---|---:|---|
| `bas.glb` | 678,112 | `f4aa9484f2eee799b8480f235cfa9871df5a7c48229ce215d17537ffb95495e2` |
| `nema.glb` | 617,536 | `8ec760361f1cf3ec4f0c439a7e7e1b2ced757072bc90f6b958ec5554b293840d` |
| `rio.glb` | 687,852 | `836c5393192e0764d1f8ba4c00b734c1d3352184c709caa8306bfdca08cc4990` |
| `amber_fig.glb` | 139,080 | `782513d25fcb9a61e26ebb0e69f9b071ee149c76a761f6881822407bb2b32857` |
| `copper_millwheel.glb` | 73,724 | `8280e4b6b93a9cbd60ddf73101763552d23823e84b2d6f8e0b9030538a4c7b3a` |
| `core_observatory.glb` | 66,456 | `fe11c6b8f053c0e294b7510446425027b5d11497ed15e6b0082a0b7d2929aaa3` |
| `crown_crystal.glb` | 6,488 | `cda8784a89a41ed78c0f6ee6d996ed49c512ce6d36c63aa358ca113be0baafa4` |
| `garden_bank.glb` | 45,664 | `69ffe60c6f12031e5b80956b4a4c0963430994b7c94170d41aecfe4eb992392a` |
| `guild_mosaic.glb` | 18,344 | `cf5d7492acae6929524117dead0888829b9612bce807edbca0210b09c2936f03` |
| `ivy_cloister.glb` | 88,644 | `26432445a7755c1942a335a561a09b4b540457b45cc4252a9b8e898c11bf0f96` |
| `jade_willow.glb` | 139,084 | `e6db6334739dae3b1fb28f586be235033179b09118bb9a8ff6947413eda304f2` |
| `quay_rail.glb` | 10,364 | `60f4bf2860ea2031dbccaa65f8cbfb8a87a001e63463789d9af0a49a197e351e` |
| `sentinel_crown.glb` | 38,072 | `def7f3bb37bf0a0ae9adb82283d44f9913e9d02e94edf4b18534d7961fe9c9da` |
| `terracotta_gatehouse.glb` | 82,988 | `5f5716024df1bd9bec29485020edbd24ce32b2a4711d0843caa85a37afb1df37` |
