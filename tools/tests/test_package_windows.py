"""Packaging boundary tests. A tiny executable double injects export failure modes;
real Godot/template integration is verified separately with the pinned toolchain.
"""
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
import zipfile

SCRIPT = Path(__file__).resolve().parents[1] / 'package_windows.py'


class WindowsPackagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / 'repo'
        project = self.repo / 'game/project-e'
        (project / 'assets/fonts').mkdir(parents=True)
        (self.repo / '.godot-version').write_text('4.7.2\n')
        (self.repo / 'THIRD_PARTY_NOTICES.md').write_text('Third-party notices\n')
        (project / 'assets/fonts/OFL.txt').write_text('Font license\n')
        (project / 'assets/fonts/README.md').write_text('Font notice\n')
        (project / 'project.godot').write_text('[application]\nconfig/name="Test"\n')
        (project / 'export_presets.cfg').write_text(
            '[preset.0]\nname="Windows Desktop"\nplatform="Windows Desktop"\n'
            '[preset.0.options]\ncustom_template/debug=""\ncustom_template/release=""\n'
            'binary_format/embed_pck=false\nbinary_format/architecture="x86_64"\n')
        self.original_preset = (project / 'export_presets.cfg').read_bytes()
        self.engine = self.root / 'godot'
        self.engine.write_text('''#!/usr/bin/env python3
import os, pathlib, struct, sys
mode=os.environ.get('PACKAGE_TEST_MODE', 'success')
if '--version' in sys.argv:
    print('4.6.1.stable.official.test' if mode=='wrong_engine' else '4.7.2.stable.official.ed1daf0bf')
    sys.exit(0)
if '--import' in sys.argv:
    print('ERROR: cannot import resource' if mode=='import_error' else 'Import done')
    sys.exit(0)
if '--export-release' not in sys.argv: sys.exit(4)
if mode=='export_error': print('ERROR: export failed'); sys.exit(0)
if mode=='export_nonzero': sys.exit(7)
output=pathlib.Path(sys.argv[-1]); output.parent.mkdir(parents=True, exist_ok=True)
header=bytearray(512); header[:2]=b'MZ'; struct.pack_into('<I',header,60,128)
header[128:132]=b'PE\\0\\0'; struct.pack_into('<H',header,132,0x8664)
output.write_bytes(header)
if mode!='missing_pack': output.with_suffix('.pck').write_bytes(b'GDPC'+b'\\0'*64)
print('Export done')
''')
        self.engine.chmod(0o755)
        self.templates = self.root / 'Godot_v4.7.2-stable_export_templates.tpz'
        self.make_templates('4.7.2.stable')
        (self.root / 'GODOT-LICENSE.txt').write_text('MIT license\n')
        (self.root / 'GODOT-COPYRIGHT.txt').write_text('Godot components\n')
        self.output = self.root / 'package'

    def make_templates(self, version):
        with zipfile.ZipFile(self.templates, 'w') as archive:
            archive.writestr('templates/version.txt', version)
            archive.writestr('templates/windows_release_x86_64.exe', b'MZtemplate')
            archive.writestr('templates/windows_debug_x86_64.exe', b'MZdebug')

    def invoke(self, mode='success'):
        return subprocess.run(
            [sys.executable, str(SCRIPT), '--godot', str(self.engine),
             '--project-root', str(self.repo), '--output-dir', str(self.output)],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            env={**os.environ, 'PACKAGE_TEST_MODE': mode}, timeout=30)

    def test_success_delivers_real_zip_manifest_and_notices(self):
        # Catches an omitted output, empty bundle, or hashes computed from wrong files.
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stdout)
        manifest = json.loads((self.output / 'manifest.json').read_text())
        self.assertEqual(manifest['engine']['version'], '4.7.2.stable.official.ed1daf0bf')
        self.assertEqual(manifest['verification']['actual_windows_pc'], 'not_run')
        self.assertEqual(manifest['templates']['version'], '4.7.2.stable')
        bundle = self.output / 'ProjectE-windows-x86_64.zip'
        with zipfile.ZipFile(bundle) as archive:
            for name in ['ProjectE.exe', 'ProjectE.pck', 'README-WINDOWS.txt',
                         'THIRD_PARTY_NOTICES.md', 'licenses/GODOT-LICENSE.txt',
                         'licenses/GODOT-COPYRIGHT.txt', 'licenses/FONT-OFL.txt', 'manifest.json']:
                self.assertIn('ProjectE-windows-x86_64/' + name, archive.namelist())
            for entry in manifest['files']:
                data = archive.read('ProjectE-windows-x86_64/' + entry['path'])
                self.assertEqual(hashlib.sha256(data).hexdigest(), entry['sha256'])
                self.assertEqual(len(data), entry['size'])
        self.assertIn(hashlib.sha256(bundle.read_bytes()).hexdigest(),
                      bundle.with_suffix('.zip.sha256').read_text())
        self.assertEqual((self.repo/'game/project-e/export_presets.cfg').read_bytes(), self.original_preset)

    def test_wrong_engine_is_rejected_before_outputs(self):
        result = self.invoke('wrong_engine')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn('Expected official Godot 4.7.2', result.stdout)
        self.assertFalse((self.output/'ProjectE-windows-x86_64.zip').exists())

    def test_mismatched_templates_are_rejected(self):
        self.make_templates('4.7.1.stable')
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn('Template version', result.stdout)

    def test_zero_exit_export_error_is_failure(self):
        result = self.invoke('export_error')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn('export failed', result.stdout)
        self.assertFalse((self.output/'ProjectE-windows-x86_64.zip').exists())

    def test_nonzero_export_exit_is_failure(self):
        result = self.invoke('export_nonzero')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn('exit 7', result.stdout)
        self.assertFalse((self.output/'ProjectE-windows-x86_64.zip').exists())

    def test_missing_pck_cannot_reuse_previous_output(self):
        first = self.invoke()
        self.assertEqual(first.returncode, 0, first.stdout)
        previous = (self.output/'ProjectE-windows-x86_64.zip').read_bytes()
        result = self.invoke('missing_pack')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn('ProjectE.pck', result.stdout)
        self.assertEqual((self.output/'ProjectE-windows-x86_64.zip').read_bytes(), previous)

    def test_import_error_stops_packaging(self):
        result = self.invoke('import_error')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn('cannot import resource', result.stdout)
        self.assertFalse((self.output/'ProjectE-windows-x86_64.zip').exists())

    def test_refuses_to_replace_unrelated_output_directory(self):
        self.output.mkdir()
        (self.output/'keep.txt').write_text('important existing file')
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn('unrelated', result.stdout)
        self.assertEqual((self.output/'keep.txt').read_text(), 'important existing file')

    def test_absent_license_blocks_incomplete_distribution(self):
        (self.root/'GODOT-COPYRIGHT.txt').unlink()
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn('GODOT-COPYRIGHT.txt', result.stdout)


if __name__ == '__main__':
    unittest.main()
