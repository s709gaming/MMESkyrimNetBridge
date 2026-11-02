"""Build checked-in Russian data. No network access; identifiers remain English."""
from common import *
from inventory import catalog
import xml.etree.ElementTree as ET
import hashlib

BASE=ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts'
OUT=ROOT/'fomod/choices/russian'
def write(path,obj):
 path.parent.mkdir(parents=True,exist_ok=True)
 path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def main():
 tr=json.loads((ROOT/'tools/localization/strings/ru.json').read_text(encoding='utf-8'))
 tr.update(json.loads((ROOT/'tools/localization/manual_ru.json').read_text(encoding='utf-8')))
 loc='SKSE/Plugins/StorageUtilData/MMEAlerts/Localization'
 write(ROOT/loc/'Active.json',dict(schemaVersion=1,language='en'))
 write(OUT/'core'/loc/'Active.json',dict(schemaVersion=1,language='ru'))
 write(OUT/'core'/loc/'ru.json',dict(schemaVersion=1,strings=tr))
 cat=catalog();defaults={};documents={}
 for id,meta in cat.items():
  value=translated_json(meta['default'],tr);defaults[id]=value
  if meta['default'] is None:continue
  file=meta['file']
  if file not in documents:documents[file]=json.loads((BASE/file).read_text(encoding='utf-8-sig'))
  node=documents[file]
  # Optional tier entries may be absent and inherit their parent normally.
  if meta.get('optionalTier'):continue
  for key in meta['path'][:-1]:node=node[key]
  node[meta['path'][-1]]=value
 for file,document in documents.items():write(OUT/'core'/'SKSE/Plugins/StorageUtilData/MMEAlerts'/file,document)
 write(OUT/'core'/loc/'ru.catalog.json',defaults)
 plugins=[('MMEAlert.esp','core'),('fomod/choices/maid-roster-ui/MME Extensions - Maid Roster.esp','roster'),('fomod/choices/milk-leaks/MME Extensions - Milk Leaks.esp','leaks'),('fomod/choices/elsie-compatibility/MME Extensions - Elsie LaVache Fix.esp','elsie')]
 for path,group in plugins:
  p=ROOT/path;out=OUT/group/p.name;out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(translate_plugin(p.read_bytes(),tr))
 view=Path('Magelight/mmeextensions/views/roster')
 # The observer changes display nodes only, never form values, actor names or edited text.
 runtime=(ROOT/'tools/localization/locale-runtime.js').read_text(encoding='utf-8')
 p=OUT/'roster'/view/'locale.js';p.parent.mkdir(parents=True,exist_ok=True)
 p.write_text('window.MMERussianStrings='+json.dumps(tr,ensure_ascii=False)+';\n'+runtime,encoding='utf-8')
 write(OUT/'BuildManifest.json',dict(language='ru',runtimeValidated=False,machineAssisted=True,files={str(p.relative_to(OUT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.rglob('*')) if p.is_file() and p.name!='BuildManifest.json'}))
 print('Generated Russian option:',len(tr),'translations;',len(documents),'data files;',len(plugins),'plugins')
if __name__=='__main__':main()
