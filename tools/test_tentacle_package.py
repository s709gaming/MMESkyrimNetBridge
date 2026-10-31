"""Inspect the actual mod-manager archive and its source/build pairs."""
from pathlib import Path
import hashlib
import json
import subprocess
import zipfile

ROOT=Path(__file__).resolve().parents[1]
def digest(data): return hashlib.sha256(data).hexdigest().lower()

def verify():
    with zipfile.ZipFile(ROOT/'dist/MME Extensions.zip') as archive:
        names=archive.namelist()
        assert len(names)==len(set(names)), 'Duplicate archive entries'
        assert 'fomod/ModuleConfig.xml' in names and 'Scripts/MMETentacleTiers.pex' in names
        assert 'docs/Tentacle-Four-Tier-Implementation.md' in names
        for name in names:
            assert not any(part.lower() in ('build','diagnostics','__pycache__','.git') for part in Path(name).parts),name
            assert Path(name).suffix.lower() not in ('.pas','.log','.tmp','.bak','.pyc','.pdb','.obj'),name
            assert Path(name).name.lower() not in ('overrides.json','overrides.previous.json','profile.lock'),name
        pairs={}
        for script in ('MMETentacleTiers','MMETentacleEffects','MMEAlertsController','MMEAlertsMCM','MMEAlertsSkyrimNet','MMEArousalEffects'):
            source=f'Source/Scripts/{script}.psc';compiled=f'Scripts/{script}.pex'
            assert archive.read(source)==(ROOT/source).read_bytes(),source
            assert archive.read(compiled)==(ROOT/compiled).read_bytes(),compiled
            assert (ROOT/compiled).stat().st_mtime >= (ROOT/source).stat().st_mtime,script+' was edited after compilation'
            pairs[script]={'sourceSHA256':digest(archive.read(source)),'compiledSHA256':digest(archive.read(compiled))}
        for name in ('Injection','TentacleEffectNarration'):
            path=f'SKSE/Plugins/StorageUtilData/MMEAlerts/{name}.json'
            current=json.loads(archive.read(path))
            assert set(current.pop('tiers'))=={'low','medium','high','extreme'}
            original=json.loads(subprocess.check_output(['git','show','HEAD:'+path],cwd=ROOT))
            original.pop('tiers',None)
            assert current==original,'Flavor text changed: '+name
        for manifestPath in ('fomod/choices/maid-roster-ui/BuildManifest.json','fomod/choices/ostim-only/BuildManifest.json'):
            manifest=json.loads(archive.read(manifestPath).decode('utf-8-sig'))
            base=manifestPath.rsplit('/',1)[0]
            for pair in manifest['pairs']:
                assert digest(archive.read(f'{base}/Source/Scripts/{pair["script"]}.psc'))==pair['sourceSHA256'].lower()
                assert digest(archive.read(f'{base}/Scripts/{pair["script"]}.pex'))==pair['compiledSHA256'].lower()
            if 'dashboardSHA256' in manifest:
                page=f'{base}/Magelight/mmeextensions/views/roster/dashboard.js'
                assert digest(archive.read(page))==manifest['dashboardSHA256'].lower()
                assert archive.read(page)==(ROOT/page).read_bytes()
        dll='SKSE/Plugins/MMEExtensions.dll'
        assert archive.read(dll)==(ROOT/'build/native-release/package'/dll).read_bytes()
        report={'entries':len(names),'pairs':pairs,'nativeSHA256':digest(archive.read(dll)),
                'runtimeValidated':False,'flavorTextPreserved':True,'archiveSHA256':digest((ROOT/'dist/MME Extensions.zip').read_bytes())}
        out=ROOT/'build/diagnostics/tentacle-package-verification.json'
        out.write_text(json.dumps(report,indent=2)+'\n')
        print(f'PASS: {len(names)} archive entries; source/PEX/native/UI pairs; manifests; unchanged legacy prose; no diagnostics or personal data.')

if __name__=='__main__': verify()
