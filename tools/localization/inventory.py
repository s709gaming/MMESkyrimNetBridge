from common import *
from html.parser import HTMLParser
OUT=ROOT/'tools/localization/strings'
def catalog():
 h=(ROOT/'include/NarrationCatalog.h').read_text(encoding='utf-8')
 return json.loads(''.join(re.findall(r'R"MMECATALOG\((.*?)\)MMECATALOG"',h,re.S)))['entries']
class HTMLText(HTMLParser):
 def __init__(self):super().__init__();self.skip=0;self.text=[]
 def handle_starttag(self,tag,attrs):
  if tag in ('script','style'):self.skip+=1
  if not self.skip:
   self.text.extend(v for k,v in attrs if k in ('placeholder','aria-label','title') and v)
 def handle_endtag(self,tag):
  if tag in ('script','style'):self.skip=max(0,self.skip-1)
 def handle_data(self,text):
  if not self.skip and text.strip():self.text.append(text.strip())
def main():
 strings=set();sources={}
 for p in (ROOT/'Source').rglob('*.psc'):
  if p.name=='MMELocalization.psc':continue
  s=p.read_text(encoding='utf-8-sig');values={decode(s[a:b]) for a,b in display_spans(s)}
  values.update(decode(m[1]) for m in re.finditer(r'MMELocalization.Text\(("(?:\\.|[^"\\])*")\)',s))
  if values:sources[str(p.relative_to(ROOT))]=len(values);strings.update(values)
 # Full authored pools/instructions, preserving every structural key.
 cat=catalog()
 for meta in cat.values():
  strings.update(json_texts(meta['default']))
  for k in ('label','family'):strings.add(meta[k])
  strings.update(v for k,v in meta['presentation'].items() if isinstance(v,str) and k not in ('section',))
  strings.update(meta['presentation'].get('tokenHelp',{}).values())
 view=ROOT/'fomod/choices/maid-roster-ui/Magelight/mmeextensions/views/roster'
 for p in [view/'index.html',view/'dashboard.js']:
  if p.suffix=='.html':
   parser=HTMLText();parser.feed(p.read_text(encoding='utf-8'));strings.update(parser.text)
  for m in STR.finditer(p.read_text(encoding='utf-8')):
   value=decode(m[0])
   if human(value):strings.add(value)
  # JS uses single-quoted literals as well. Treat only phrase-like content.
  for m in re.finditer(r"'(?:\\.|[^'\\\n])*'",p.read_text(encoding='utf-8')):
   value=m[0][1:-1].replace("\\'","'").replace('\\n','\n')
   if human(value):strings.add(value)
 for p in [ROOT/'src/NarrationStore.cpp']:
  for m in STR.finditer(p.read_text(encoding='utf-8')):
   value=decode(m[0])
   if human(value) and len(value)<1000:strings.add(value)
 plugins=[ROOT/'MMEAlert.esp',ROOT/'fomod/choices/maid-roster-ui/MME Extensions - Maid Roster.esp',ROOT/'fomod/choices/milk-leaks/MME Extensions - Milk Leaks.esp',ROOT/'fomod/choices/elsie-compatibility/MME Extensions - Elsie LaVache Fix.esp']
 for p in plugins:
  values=set(plugin_strings(p.read_bytes()));strings.update(values);sources[str(p.relative_to(ROOT))]=len(values)
 # Remaining user-facing status labels / pages and source descriptors.
 strings.update(['General','Milk Drinking','Body ','Arousal ','Armor & Stripping','Armor Effects','Armor Reactions','Traps & Curses','Skyrim.Net','Debug','Troubleshoot','On','Off','Yes','No','Unknown','None','Player','Milk Maids','Milk Maid','Save Changes','Cancel','Continue','Close','Reload Saved','All features','Modified only','Show minor messages','Presets','Milk','Lactacid','Arousal'])
 strings.update(json.loads((ROOT/'tools/localization/manual_ru.json').read_text(encoding='utf-8')))
 strings={s for s in strings if s and re.search('[A-Za-z]',s) and len(s)<8193 and s.strip() not in ('user-title',) and not s.startswith('http') and not any(x in s for x in ['document.','function(','=>','<div','</','operation='])}
 OUT.mkdir(parents=True,exist_ok=True)
 (OUT/'en.json').write_text(json.dumps(sorted(strings),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 (OUT/'inventory.json').write_text(json.dumps(sources,indent=2)+'\n',encoding='utf-8')
 print('Inventoried',len(strings),'strings in',len(sources),'source files; characters',sum(map(len,strings)))
if __name__=='__main__':main()
