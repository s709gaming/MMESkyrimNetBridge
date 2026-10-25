from pathlib import Path
import sys,json,re,shutil
manifest,variants,output=map(Path,sys.argv[1:]);seen=set();count=0
for folder in json.loads(manifest.read_text(encoding='utf-8-sig')):
 for file in Path(folder).glob('*.psc'):
  if file.name.lower() in seen:continue
  code=re.sub(r';[^\r\n]*','',file.read_text(errors='replace'))
  if re.search(r'\b(?:SexLabFramework|ssl\w+|SexLabUtil|SexlabRegistry|SexLabThread)\b',code,re.I):continue
  if re.match('^(SexLab|ssl)',file.name,re.I) or (variants/file.name).exists():continue
  shutil.copy2(file,output/file.name);seen.add(file.name.lower());count+=1
print('Isolated imports:',count,'files; SexLab framework sources excluded')
