# 통합 V2 실행판 전달 기록

기준일: 2026-11-03. PR #4는 main에 병합 완료. 통합 소스 `73dc3f06688f58b4a1070553db1108e35248d0de`, 게임 코드 `f2de34106ebd010ee612c13e1216f546f10e61ab`. 이 전달 기록은 문서만 변경한다.

## 재현 및 배포 증거

- [전체 회귀](https://github.com/herothgf-cell/project-e/actions/runs/41590279941): 성공.
- [통합 V2 검사와 실제 12스킬 캡처](https://github.com/herothgf-cell/project-e/actions/runs/41590279790): 성공.
- [기존 플레이 검토판 회귀](https://github.com/herothgf-cell/project-e/actions/runs/41590279976): 성공.
- [Windows release export와 Windows headless 시작](https://github.com/herothgf-cell/project-e/actions/runs/41590279866): 성공.
- [Windows artifact](https://github.com/herothgf-cell/project-e/actions/runs/41590279866/artifacts/13210116188).

전달 ZIP은 CI의 내부 실행 ZIP을 그대로 추출해 `ProjectE-Integrated-V2-Windows.zip`으로 이름만 바꾼 것이다. 실행파일/PCK는 수정하지 않았다.

- 크기: **39,497,058 bytes**.
- SHA-256: `7d91ed8d6798231bbe4279bfce2490b67f2ebf719d186b5683a958b10c95a55d`.
- 패키지 manifest의 소스 revision: PR 검증용 merge snapshot `97321e25dda0d00b2d10feef4d1014a1cffa6672`.
- 소스 manifest의 GDScript/장면 57개가 로컬 전체 검사에 사용한 파일과 SHA-256 일치.
- artifact 외부 ZIP 해시, 내부 ZIP CRC, manifest의 파일별 해시를 재검사해 통과.
- 소스 폴더 밖에서 내보낸 PCK를 Linux Godot에 로드해 통합 연출실 검사329개 + 셀/격리 검사5개 통과.
- 로컬 전체 검사:22묶음/4,522개/실패0. 패키징 Python 검사9개 통과.

## 실행 순서

ZIP을 전부 풀어 `ProjectE.exe` 실행. `ProjectE.pck`는 같은 폴더에 유지한다. 화면의 **F7 통합 연출실**에서 바스/리오/네마, QWER·이동·평타·피격·사망·부활, 언덕 이동, 전체 맵을 확인한다. 0.5×와 재생/정지로 반복 검토한다. 경기로 돌아가면 이전 경기의 일시정지 상태와 입력을 복원한다.

실제 캡처: 정지40장 +15fps 동작282프레임(18.8초). 영상은 무음 시연이며 성능 벤치마크나 사람 플레이 녹화가 아니다. 전체 맵 공개는 연출실에만 적용한다.

## 완료와 미검증의 경계

완료: 캐릭터3명·실제 QWER12시전·30개 동작 클립·고지/경사·시야·관측 사망·검토실·Windows 패키지 연결과 자동 검증. 품질은 모듈형 게임 아트의 1차 통합판이다.

남음: 출시용 조형/텍스처/스키닝, 더 자연스러운 동작, 최종VFX/SFX, 수로/조명/시야 경계 완성도, 사용자 Windows 그래픽·입력·DPI·Alt-Tab·사람 한 판, 온라인/Steam. 이번 Windows runner 검사는 화면 없는 시작 검사이지 사용자 PC 그래픽 성능 검사가 아니다.
