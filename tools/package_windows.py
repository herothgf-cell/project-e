#!/usr/bin/env python3
"""Export a pinned Godot Standard Windows x86_64 release and a checked ZIP.

No third-party Python dependencies. Downloads are a separate, explicit bootstrap
step: the executable, matching official template archive, and engine notices must
already exist. See docs/technical/04-windows-build.md.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile

BUNDLE_NAME = 'ProjectE-windows-x86_64'
ANSI_ESCAPE = re.compile(r'\x1b\[[0-9;]*m')
GODOT_ERROR = re.compile(r'(?mi)^\s*(?:(?:SCRIPT|USER|FATAL) )?ERROR:|export failed')


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def require_file(path: Path) -> None:
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError(f'Missing or empty required file: {path}')


def run(command: list[str], label: str, log: Path | None = None,
        timeout: int = 300) -> str:
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, errors='replace', timeout=timeout, check=False)
    output = ANSI_ESCAPE.sub('', result.stdout)
    if log:
        log.write_text(output, encoding='utf-8')
    print(output, end='' if output.endswith('\n') else '\n', flush=True)
    if result.returncode or GODOT_ERROR.search(output):
        raise RuntimeError(f'{label} failed (exit {result.returncode})')
    return output.strip()


def verify_windows_files(executable: Path, pack: Path) -> None:
    require_file(executable)
    require_file(pack)
    with executable.open('rb') as stream:
        dos_header = stream.read(64)
        if len(dos_header) != 64 or dos_header[:2] != b'MZ':
            raise RuntimeError('ProjectE.exe is not a Windows PE executable')
        pe_offset = struct.unpack_from('<I', dos_header, 60)[0]
        stream.seek(pe_offset)
        signature_and_machine = stream.read(6)
        if signature_and_machine != b'PE\0\0\x64\x86':
            raise RuntimeError('ProjectE.exe is not a Windows x86_64 PE executable')
    with pack.open('rb') as stream:
        if pack.stat().st_size < 32 or stream.read(4) != b'GDPC':
            raise RuntimeError('ProjectE.pck is not a nonempty Godot pack')


def prepare_templates(archive: Path, destination: Path, version: str) -> dict:
    require_file(archive)
    expected = version + '.stable'
    with zipfile.ZipFile(archive) as templates:
        actual = templates.read('templates/version.txt').decode('utf-8').strip()
        if actual != expected:
            raise RuntimeError(f'Template version {actual!r} does not match {expected!r}')
        destination.mkdir()
        entries = {}
        for name in ('windows_release_x86_64.exe', 'windows_debug_x86_64.exe'):
            target = destination / name
            # Extract only named Windows files; never trust arbitrary ZIP paths.
            with templates.open('templates/' + name) as source, target.open('wb') as output:
                shutil.copyfileobj(source, output)
            require_file(target)
            entries[name] = {'sha256': sha256(target), 'size': target.stat().st_size}
    return {'version': actual, 'archive': archive.name, 'archive_sha256': sha256(archive),
            'official_source': f'https://downloads.godotengine.org/?version={version}'
                               '&flavor=stable&slug=export_templates.tpz&platform=templates',
            'windows_files': entries}


def snapshot_project(source: Path, destination: Path) -> dict:
    entries = []
    for path in sorted(source.rglob('*')):
        relative = path.relative_to(source)
        if '.godot' in relative.parts or '.git' in relative.parts or path.name.endswith('.tmp'):
            continue
        if path.is_symlink():
            raise RuntimeError(f'Source symlinks are not supported: {relative}')
        if not path.is_file():
            continue
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        entries.append({'path': relative.as_posix(), 'sha256': sha256(target),
                        'size': target.stat().st_size})
    # A portable digest over the names and exact contents copied for this export.
    tree = hashlib.sha256()
    for entry in entries:
        tree.update((entry['path'] + '\0' + entry['sha256'] + '\n').encode('utf-8'))
    return {'tree_sha256': tree.hexdigest(), 'files': entries}


def configure_snapshot(preset_path: Path, templates: Path) -> None:
    text = preset_path.read_text(encoding='utf-8')
    if 'name="Windows Desktop"' not in text or 'platform="Windows Desktop"' not in text:
        raise RuntimeError('The Windows Desktop preset is missing')
    if 'binary_format/embed_pck=false' not in text or 'binary_format/architecture="x86_64"' not in text:
        raise RuntimeError('Windows preset must use a separate PCK and x86_64')
    for kind in ('debug', 'release'):
        value = (templates / f'windows_{kind}_x86_64.exe').as_posix()
        text, count = re.subn(rf'(?m)^custom_template/{kind}=.*$',
                              lambda _: f'custom_template/{kind}={json.dumps(value)}', text)
        if count != 1:
            raise RuntimeError(f'Expected exactly one Windows custom_template/{kind} entry')
    preset_path.write_text(text, encoding='utf-8')


def write_readme(path: Path, version: str) -> None:
    path.write_text(f'''Project E — Windows 로컬 테스트 (오프라인 3대3)
엔진: Godot {version} Standard / Windows x86_64 / Compatibility 렌더러.

에디터 없이 실행
ZIP 전체를 폴더에 압축 해제한 뒤 ProjectE.exe를 두 번 클릭한다.
ProjectE.exe와 ProjectE.pck는 같은 폴더에 함께 둔다.
게임 실행에 Godot 에디터, Python, .NET, Steam 계정이나 인터넷 연결은 필요 없다.
이 패키지는 코드 서명을 하지 않은 로컬 테스트 빌드다.

경기와 영웅 선택
바스·리오·네마를 선택하고 경기를 시작한다.
사람 1명이 영웅 1명을 조작하며 나머지 5명은 봇이다.
일반 경기는 레벨 1·성장 2포인트로 시작한다. G로 투자한다.
기술 체험에서는 여섯 영웅 모두 레벨 3·R 해금·잔여 3포인트로 시작한다.
아군 병력과 함께 외곽탑→내곽탑→핵을 공격한다.

조작
지면 우클릭: 이동. 보이는 적 우클릭: 접근 후 기본 공격.
A→지면 좌클릭: 공격 이동. 기술은 자동으로 사용하지 않는다.
Q/W/E/R→좌클릭: 기술 조준과 확정. Esc: 조준 취소.
S: 정지. G: 성장 패널(로컬 경기 일시정지). B: 기지로 걸어가기.
가운데 마우스 버튼 드래그: 카메라 이동. 휠: 확대·축소.
Space: 조작 영웅으로 시점 복귀. 미니맵 좌클릭/우클릭: 시점 이동/이동 명령.
F1: 조작과 전장 안내. Esc: 일시정지 메뉴.
현재 영웅으로 다시 시작: 같은 영웅의 경기를 초기화한다.
별도의 영웅 선택으로 버튼: 선택 화면으로 돌아가 다른 영웅을 고른다.
새 프로세스의 시작을 확인하려면 창을 닫고 EXE를 다시 실행한다.

실제 Windows PC 확인표 — Linux 빌드에서 수행하지 않음
[ ] Godot 에디터가 없는 실제 Windows PC에서 실행하고 OS·GPU·드라이버를 기록한다.
[ ] 영웅 선택·경기 HUD·성장 패널의 한국어에 빈 네모나 깨진 글자가 없는지 확인한다.
[ ] 경기 시작, 이동, 기본 공격, A 공격 이동, 기술 조준·확정·취소를 조작한다.
[ ] 일시정지 후 Alt-Tab으로 나갔다 돌아와 재개하고 마우스·키보드 포커스를 확인한다.
[ ] 창 크기와 디스플레이 배율 100%/150%에서 HUD·미니맵·텍스트를 확인한다.
[ ] 같은 영웅으로 재시작하고, 영웅 선택으로 돌아간 뒤 다른 영웅을 시작한다.
[ ] 창을 닫고 EXE를 다시 켜 실행·영웅 선택·경기 시작을 확인한다.
[ ] 한 판을 직접 플레이해 승패를 확인하고 로그의 오류·충돌을 확인한다.
[ ] 결과와 함께 manifest.json 및 ZIP SHA-256을 기록한다.

로그 확인
압축을 푼 폴더의 PowerShell에서 명시적인 로그 파일을 지정할 수 있다.
  .\\ProjectE.exe --log-file "$env:TEMP\\ProjectE-playtest.log"
  Get-Content "$env:TEMP\\ProjectE-playtest.log"
문제가 있으면 %TEMP%\\ProjectE-playtest.log를 화면·재현 입력과 함께 보관한다.
기본 로그: %APPDATA%\\Godot\\app_userdata\\Project E - Canal Works\\logs\\godot.log
release 빌드에는 별도 콘솔 창이 없으므로 위 log-file 명령으로 기록을 확인한다.

자동 검증 범위
패키지 생성 성공은 빌드 호스트에서 import/export와 파일·해시·ZIP 검사를 통과했다는
뜻이다. 실제 Windows PC 실행, Alt-Tab, 사람 플레이, 성능, 온라인·Steam 연동은
이 자동 빌드로 확인하지 않았다. manifest.json의 검증 범위를 함께 읽는다.

라이선스와 저작권 안내
THIRD_PARTY_NOTICES.md와 licenses/ 폴더를 패키지와 함께 유지한다.
Godot MIT 라이선스, 엔진 외부 구성 요소 안내와 한국어 폰트 OFL이 들어 있다.
Godot MIT 라이선스가 Project E 원본 코드·게임 콘텐츠의 라이선스를 정하지는 않는다.
''', encoding='utf-8')


def git_metadata(root: Path) -> dict:
    result = {}
    for key, arguments in (('revision', ['rev-parse', 'HEAD']),
                           ('status', ['status', '--porcelain'])):
        try:
            command = subprocess.run(['git', '-C', str(root), *arguments],
                                     text=True, stdout=subprocess.PIPE,
                                     stderr=subprocess.DEVNULL, check=False, timeout=10)
            result[key] = command.stdout.strip() if command.returncode == 0 else None
        except (OSError, subprocess.TimeoutExpired):
            result[key] = None
    return result


def build(args: argparse.Namespace) -> Path:
    root = args.project_root.resolve()
    source = root / 'game/project-e'
    executable = Path(args.godot).resolve()
    output = args.output_dir.resolve() if args.output_dir else root / 'build/windows'
    if output == root or output == source or source in output.parents or output in root.parents:
        raise RuntimeError('Output directory must not replace the source project or repository')
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        try:
            previous = json.loads((output / 'manifest.json').read_text(encoding='utf-8'))
            if previous.get('project') != 'Project E' or previous.get('schema_version') != 1:
                raise ValueError('Unrecognized manifest')
            allowed = {entry['path'] for entry in previous['files']}
            allowed.update({'manifest.json', BUNDLE_NAME + '.zip', BUNDLE_NAME + '.zip.sha256'})
            if any(p.relative_to(output).as_posix() not in allowed
                   for p in output.rglob('*') if p.is_file() or p.is_symlink()):
                raise ValueError('Unrecognized files')
        except (OSError, ValueError, KeyError, TypeError):
            raise RuntimeError(f'Refusing to replace an unrelated output directory: {output}')
    require_file(root / '.godot-version')
    expected_version = (root / '.godot-version').read_text(encoding='utf-8').strip()
    require_file(source / 'project.godot')
    require_file(source / 'export_presets.cfg')
    require_file(executable)
    print('Checking pinned official engine', flush=True)
    version = run([str(executable), '--version'], 'Engine version', timeout=30)
    if not re.fullmatch(re.escape(expected_version) + r'\.stable\.official\.[0-9a-f]+', version):
        raise RuntimeError(f'Expected official Godot {expected_version}.stable.official.*, got {version!r}')
    archive = args.templates_archive or executable.parent / f'Godot_v{expected_version}-stable_export_templates.tpz'
    license_dir = args.engine_notices_dir or executable.parent
    notices = {
        'THIRD_PARTY_NOTICES.md': root / 'THIRD_PARTY_NOTICES.md',
        'licenses/GODOT-LICENSE.txt': license_dir / 'GODOT-LICENSE.txt',
        'licenses/GODOT-COPYRIGHT.txt': license_dir / 'GODOT-COPYRIGHT.txt',
        'licenses/FONT-OFL.txt': source / 'assets/fonts/OFL.txt',
        'licenses/FONT-README.md': source / 'assets/fonts/README.md',
    }
    for path in notices.values():
        require_file(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='project-e-windows-', dir=output.parent) as temp:
        work = Path(temp)
        staged = work / 'bundle'
        staged.mkdir()
        logs = staged / 'build-logs'
        logs.mkdir()
        templates = work / 'templates'
        template_info = prepare_templates(archive.resolve(), templates, expected_version)
        snapshot = work / 'project'
        source_info = snapshot_project(source, snapshot)
        configure_snapshot(snapshot / 'export_presets.cfg', templates)
        base = [str(executable), '--headless', '--path', str(snapshot)]
        print('Importing isolated project snapshot', flush=True)
        run(base + ['--editor', '--import'], 'Godot import', logs / 'import.log', args.timeout)
        print('Exporting Windows release', flush=True)
        game_exe = staged / 'ProjectE.exe'
        run(base + ['--export-release', 'Windows Desktop', str(game_exe)],
            'Windows export', logs / 'export.log', args.timeout)
        verify_windows_files(game_exe, staged / 'ProjectE.pck')
        for name, path in notices.items():
            target = staged / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
        write_readme(staged / 'README-WINDOWS.txt', version)
        # Console/debug auxiliaries, if a future preset emits them, are preserved.
        entries = [{'path': p.relative_to(staged).as_posix(), 'size': p.stat().st_size,
                    'sha256': sha256(p)} for p in sorted(staged.rglob('*')) if p.is_file()]
        manifest = {
            'schema_version': 1, 'project': 'Project E',
            'created_utc': datetime.now(timezone.utc).isoformat(),
            'target': 'Windows x86_64', 'export_mode': 'release',
            'engine': {'version': version, 'executable_sha256': sha256(executable),
                       'official_archive': f'https://godotengine.org/download/archive/{expected_version}-stable/'},
            'templates': template_info,
            'engine_notice_sources': {
                name: f'https://raw.githubusercontent.com/godotengine/godot/{expected_version}-stable/{source_name}'
                for name, source_name in [('GODOT-LICENSE.txt', 'LICENSE.txt'),
                                           ('GODOT-COPYRIGHT.txt', 'COPYRIGHT.txt')]},
            'source': {'git': git_metadata(root), **source_info},
            'verification': {'import': 'passed', 'release_export': 'passed',
                             'pe_x86_64_and_pck_headers': 'passed',
                             'actual_windows_pc': 'not_run', 'human_playtest': 'not_run'},
            'files': entries,
        }
        (staged / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
        bundle = staged / (BUNDLE_NAME + '.zip')
        with zipfile.ZipFile(bundle, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as package:
            for path in sorted(staged.rglob('*')):
                if path.is_file() and path != bundle:
                    package.write(path, BUNDLE_NAME + '/' + path.relative_to(staged).as_posix())
        with zipfile.ZipFile(bundle) as package:
            corrupt = package.testzip()
            if corrupt:
                raise RuntimeError(f'ZIP validation failed: {corrupt}')
            for entry in entries:
                packed = package.read(BUNDLE_NAME + '/' + entry['path'])
                if hashlib.sha256(packed).hexdigest() != entry['sha256']:
                    raise RuntimeError(f'ZIP content hash mismatch: {entry["path"]}')
            if package.read(BUNDLE_NAME + '/manifest.json') != (staged / 'manifest.json').read_bytes():
                raise RuntimeError('ZIP manifest differs from the delivered manifest')
        bundle.with_suffix('.zip.sha256').write_text(f'{sha256(bundle)}  {bundle.name}\n', encoding='utf-8')
        # Publish only a complete, validated build. A failed export cannot consume
        # a stale EXE/PCK from an earlier run or replace the previous good bundle.
        backup = work / 'previous-output'
        if output.exists():
            output.rename(backup)
        try:
            staged.rename(output)
        except OSError:
            if backup.exists():
                backup.rename(output)
            raise
    return output / (BUNDLE_NAME + '.zip')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True, help='Pinned official Godot Standard executable')
    parser.add_argument('--project-root', type=Path, default=Path(__file__).resolve().parents[1],
                        help='Repository root (default: this script\'s repository)')
    parser.add_argument('--output-dir', type=Path, help='Output folder (default: build/windows)')
    parser.add_argument('--templates-archive', type=Path,
                        help='Official matching .tpz (default: next to Godot executable)')
    parser.add_argument('--engine-notices-dir', type=Path,
                        help='Folder with GODOT-LICENSE.txt and GODOT-COPYRIGHT.txt (default: next to Godot)')
    parser.add_argument('--timeout', type=int, default=300, help='Import/export timeout in seconds (default: 300)')
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error('--timeout must be positive')
    try:
        package = build(args)
    except (OSError, ValueError, KeyError, RuntimeError, zipfile.BadZipFile,
            subprocess.TimeoutExpired) as error:
        print(f'FAIL: {error}', file=sys.stderr)
        return 1
    print(f'PASS: Windows release export and ZIP verified: {package}')
    print(f'SHA-256: {sha256(package)}')
    print('Actual Windows PC launch and human playtest: NOT RUN')
    return 0


if __name__ == '__main__':
    sys.exit(main())
