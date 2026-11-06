# V5 복구 작업 검증 — 2026-11-05

이 기록은 `1aabd7d`의 V4 코드에 중단된 V5 모델·운하 전장 작업을 복구한 뒤 **새로 실행한 검사**다. 이전 작업 폴더의 성공 로그를 이번 결과로 재사용하지 않았다. 최신 기능·자산 설명은 [V5 가이드](../25-illustrated-canal.md)를 본다.

## 1. 복구 범위

- 3개 영웅 GLB, 얼굴·의상 WebP 6개, 선택 초상 WebP 3개, 모델 재질 셰이더.
- 운하 환경 GLB 11개, 포장석·수면 텍스처 2개와 환경 셰이더.
- 실제 모델과 지도 연결, 영웅별 기본 공격 자세, 관절 보조 모션, 선택 화면의 F7 버튼 위치.
- 기존 전투 권한 코드인 `scripts/battle/`는 V4 기준과 변경이 없다. 기본 공격·패시브·QWER·상태 이상·시야·성장·공성·봇 판단 규칙을 그대로 사용한다.
- 최종 GLB와 텍스처는 복구했지만, 그 최종판을 그대로 재생성하는 모델 생성 스크립트는 복구하지 못했다. 이전 단계 생성기를 최종판처럼 배포하지 않는다. GLB 편집 규격은 V5 가이드에 기록한다.

## 2. 실행 환경과 명령

- 엔진: `4.7.2.stable.official.ed1daf0bf` / 저장소 `.godot-version`과 일치.
- Linux x86_64, Compatibility, OpenGL / Mesa llvmpipe, Xvfb 1280×720 뷰포트.
- 렌더 캡처의 오디오는 Dummy 드라이버를 사용한다. 음원 파일 검사는 별도로 수행했다.

```sh
python tools/check_godot.py --godot /path/to/Godot_v4.7.2-stable_linux.x86_64
python tools/check_art_assets.py
python tools/check_audio_assets.py
python -m unittest discover -s tools/tests -v

# 그래픽 환경 또는 xvfb-run 안에서 실행한다.
godot --path game/project-e --rendering-method gl_compatibility --audio-driver Dummy \
  --script ../../tools/art/capture_illustrated_pass.gd -- --output=/absolute/path/v5
godot --path game/project-e --rendering-method gl_compatibility --audio-driver Dummy \
  --script tests/capture_integrated_v2.gd -- --output=/absolute/path/skills
```

## 3. 새로 확인한 결과

| 검사 | 결과 | 증거와 범위 |
|---|---|---|
| 기존 Godot 회귀 | **24묶음, 4,506 checks, 실패 0** | [전체 로그](2026-11-05-v5-regression.log). 이동·공격·기술·시야·경제·봇·고지·연출실과 V3/V4 계약 |
| 새 V5 자산·관절 검사 | **80 checks, 실패 0** | [실행 로그](2026-11-05-v5-assets.log). 14 GLB의 유효한 기하, UV·이미지 디코드, 실제 하위 관절 이동, 자세 복원과 판정 상태 불변 |
| 임포트와 메인 장면 | 성공 | 같은 명령에서 임포트와 메인 장면 90프레임 시작 확인 |
| 전체 봇 경기 | 승패 도달 | Battle match 로그에서 431.8초 시뮬레이션에 승자 0. 사람 경기 시간이나 밸런스 판정으로 쓰지 않음 |
| V5 실제 화면 | **9장** | [캡처 로그](2026-11-05-v5-capture.log), [파일·소스 해시](../assets/v5/capture-manifest.json) |
| 12개 기술 실제 연출 | **정지 화면 40장 + 연속 282프레임** | [스킬 캡처 로그](2026-11-05-v5-skills-capture.log). 3명 QWER, 피격·사망·부활, 경사·고지·전체 지도 |
| 원본 SVG 자산 | 19개 통과 | XML·크기 검사. 현재 WebP 초상과는 별도로 보존한 V3 참조 및 스킬 아이콘 |
| 효과음 | PCM WAV 5개 통과 | 파일 형식·샘플 규격 검사. 사람 청취 평가는 수행하지 않음 |
| 패키징 도구 | Python 테스트 9개 통과 | 누락 파일·잘못된 엔진/템플릿·실패한 export·ZIP/해시/라이선스 동봉 처리 |

기존 24묶음을 실행한 뒤 새 V5 검사 1묶음을 직접 실행했다. 합계는 **25묶음, 4,586 checks, 실패 0**이며, `tools/check_godot.py`에도 V5를 등록해 다음 전체 실행과 CI에서 함께 검사하도록 했다.

실제 렌더러로 선택 화면의 한글·초상화, 세 영웅의 얼굴·의상·장비, 전장·경사, 정상 경기 HUD와 미니맵을 확인했다. 추가로 리오·네마 R 발동 화면을 확인했다. 기술 캡처는 실제 전투 명령을 실행하지만, 재현 가능한 검토를 위해 스크립트가 인물 위치와 시간을 설정한다.

**[선택 화면](../assets/v5/selection.webp) · [중앙 교전](../assets/v5/mid-clash.webp) · [전체 전장](../assets/v5/map.webp) · [스킬 검토 영상](../assets/v5/skill-review.mp4)**

## 독립 코드·자산 검토

별도 검토에서 프레젠테이션 변경 9개 파일, V3/V4 테스트 변경, 두 셰이더와 GLB 구조, 기존 시야·삭제 경로를 읽었다. 전투 상태에 대한 쓰기, 미관측 적 표시, 필수 관절 누락, 탑·핵의 고아 객체, 무한히 증가하는 새 캐시, 테스트 조건 약화에 해당하는 구체적인 차단 문제는 발견하지 못했다. 이 검토는 정적 범위이며, 실행 성공의 근거는 위 새 로그다.

## Windows 미리보기 패키지

`ProjectE-v5-20261105-windows-x86_64.zip`을 생성했다. **50,449,041 bytes(약 48.1 MiB)**이며, 전체를 압축 해제한 뒤 `ProjectE.exe`를 실행한다. EXE와 PCK는 같은 폴더에 둔다.

- EXE: 기존 공식 4.7.2 템플릿으로 생성된 V4 CI 실행 파일을 재사용했다. 원본 CI manifest의 템플릿 SHA-256과 대조했다.
- PCK: V5 소스를 새 작업 폴더로 복사해 캐시 없이 임포트하고 Windows Desktop preset으로 새로 내보냈다.
- **배포 PCK 자체**를 Linux의 같은 엔진으로 90프레임 시작하고, OpenGL에서 선택·영웅·전장·교전 9개 화면을 캡처했다. [시작 로그](2026-11-05-v5-pack-startup.log) · [배포 데이터 렌더 로그](2026-11-05-v5-pack-capture.log).
- EXE/PCK 헤더, ZIP 무결성, 들어간 파일별 SHA-256과 라이선스 동봉을 확인했다. [패키지 검증 manifest](2026-11-05-v5-windows-manifest.json).
- 새 V5 검사와 문서가 추가된 뒤에도 배포 snapshot의 실행 코드·리소스가 현재 작업 트리와 일치함을 대조했다. 테스트와 설명 문서는 실행 리소스 일치 비교에서 제외한다.

ZIP SHA-256:

```text
676e289a969e43873a4ebd95c90dc376d14b7e12a8ce27d2645d10d5a0b4fb3f
```

이 패키지에 대해 실제 Windows PC의 그래픽·직접 조작 검증은 수행하지 않았다. 저장소의 `Windows preview` 워크플로는 이후 커밋을 공식 템플릿에서 다시 빌드하고 Windows runner의 headless 시작을 별도로 검사한다.

## 4. 검증의 경계

- 그래픽 로그에는 가상 디스플레이의 VSync 변경 미지원 경고가 있다. 캡처는 오류 없이 완료됐다.
- draw call과 primitive 카운터는 캡처 manifest에 기록한다. 소프트웨어 렌더러에서 얻은 값이므로 사용자 PC의 FPS를 주장하지 않는다. 목표 하드웨어 성능 측정은 후속 작업이다.
- 캐릭터 얼굴·옷 표현은 게임에 연결된 검토판이다. 상용 최종 아트·전체 방향 애니메이션의 완성이나 사람의 타격감 평가를 완료한 것은 아니다.
- 실제 Windows PC의 마우스·키보드, 화면 배율, Alt-Tab, GPU 성능과 사람 한 판 플레이는 별도 확인이 필요하다. 온라인 대전·Steam 계정/로비/배포 연동은 이번 범위에 없다.
- Windows 패키지의 manifest와 워크플로 결과를 함께 확인한다. Linux 소스·배포 PCK 캡처만으로 Windows 그래픽 실행 성공을 표시하지 않는다.
