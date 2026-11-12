"""Reject compile-only startup stubs; validate loose PEX or every shipped archive variant."""
import argparse,re,subprocess,tempfile,zipfile
from pathlib import Path
ASSEMBLER=Path('E:/Steam/steamapps/common/Skyrim Special Edition/Papyrus Compiler/PapyrusAssembler.exe')
def validate(text,label):
 functions={m.group(1).lower():m.group(2).lower() for m in re.finditer(r'\.function\s+(\w+)\b(.*?)\.endFunction',text,re.S|re.I)}
 for name in ['oninit','onplayerloadgame','maintenance','registerevents']:
  assert name in functions,f'{label}: missing {name}; possible SDK stub'
  code=functions[name].split('.code',1)[-1].split('.endcode',1)[0].strip()
  assert code,f'{label}: empty {name}; possible SDK stub'
 for call in ['varsetup','maidreset','slavereset','maintenance']:
  assert re.search(r'callmethod\s+'+call+r'\b',functions['oninit']),f'{label}: OnInit missing {call}'
 assert re.search(r'callmethod\s+maintenance\b',functions['onplayerloadgame']),f'{label}: load event missing maintenance'
 assert 'mme_scriptsstarted' in functions['maintenance'] and re.search(r'callstatic\s+storageutil\s+setintvalue\b',functions['maintenance']),f'{label}: missing startup flag write'
 assert 'registerformodevent' in functions['registerevents'],f'{label}: missing event registrations'
 # Destructive first-install resets must never be introduced into load maintenance.
 for name in ['onplayerloadgame','maintenance']:
  assert not re.search(r'callmethod\s+(maidreset|slavereset|varsetup)\b',functions[name]),f'{label}: unsafe load reset'
def inspect(data,label,assembler=ASSEMBLER):
 with tempfile.TemporaryDirectory(prefix='MME-Startup-') as directory:
  d=Path(directory);(d/'MilkPlayerLoadGame.pex').write_bytes(data)
  subprocess.run([str(assembler),'MilkPlayerLoadGame','-D','-Q'],cwd=d,check=True,capture_output=True)
  validate((d/'MilkPlayerLoadGame.disassemble.pas').read_text(encoding='utf-8-sig'),label)
def main():
 p=argparse.ArgumentParser();p.add_argument('artifacts',nargs='+');p.add_argument('--reject-stub');a=p.parse_args()
 if a.reject_stub:
  try:inspect(Path(a.reject_stub).read_bytes(),'negative control')
  except AssertionError:print('PASS: compiled SDK stub rejected')
  else:raise AssertionError('Validator accepted the compiled SDK stub')
 for file in a.artifacts:
  path=Path(file)
  if path.suffix.lower()=='.zip':
   with zipfile.ZipFile(path) as z:
    names=[n for n in z.namelist() if n.replace('\\','/').lower().endswith('scripts/milkplayerloadgame.pex')]
    assert len(names)==3,f'Expected standard, P+ and OStim startup artifacts; found {len(names)}'
    for n in names:inspect(z.read(n),n);print('PASS: startup semantics',n)
  else:inspect(path.read_bytes(),str(path));print('PASS: startup semantics',path)
if __name__=='__main__':main()
