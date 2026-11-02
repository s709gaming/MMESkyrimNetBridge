"""Optional shared translation drafting aid. Only checked-in Russian data is used by builds/runtime."""
from common import *
import os
LANGUAGE=os.environ.get("MME_TRANSLATION_LANGUAGE","ru")
import urllib.request,urllib.parse,concurrent.futures,time,html
OUT=ROOT/'tools/localization/strings'
MANUAL=json.loads((ROOT/f'tools/localization/manual_{LANGUAGE}.json').read_text(encoding='utf-8'))
PROTECTED=re.compile(r'\{\{.*?\}\}|\{[^{}]*\}|<[^>]+>|\b(?:MME Extensions|Skyrim\.Net|SkyrimNet|OStim|SexLab|SkyUI|PapyrusUtil|Magelight UI|BodySlide|RaceMenu|XPMSSE|Lactacid)\b|\$\w+',re.S)
def prepare(text):
 saved=[]
 def mask(m):saved.append(m[0]);return f'ZXPH{len(saved)-1:04d}ZX'
 text=PROTECTED.sub(mask,text)
 if LANGUAGE=='ru':text=re.sub(r'\bMilk[ -]?Maids\b','\u0434\u043e\u044f\u0440\u043a\u0438',text,flags=re.I)
 if LANGUAGE=='ru':text=re.sub(r'\bMilk[ -]?Maid\b','\u0434\u043e\u044f\u0440\u043a\u0430',text,flags=re.I)
 return text,saved

def batch(rows):
 masked=[];maps={}
 for i,text in rows:
  value,protected=prepare(text);masked.append(f'ZXROW{i:05d}ZX\n'+value);maps[i]=(text,protected)
 payload='\n'.join(masked)
 url='https://translate.googleapis.com/translate_a/single?'+urllib.parse.urlencode({'client':'gtx','sl':'en','tl':LANGUAGE,'dt':'t','q':payload})
 for attempt in range(4):
  try:
   with urllib.request.urlopen(url,timeout=35) as response:d=json.load(response)
   output=''.join(row[0] for row in d[0] if row and row[0])
   matches=list(re.finditer(r'ZX\s*ROW\s*(\d{5})\s*ZX',output,re.I))
   if len(matches)!=len(rows):raise ValueError('Row markers changed')
   result={}
   for j,m in enumerate(matches):
    i=int(m[1]);text,protected=maps[i];translated=output[m.end():matches[j+1].start() if j+1<len(matches) else len(output)].strip()
    for n,value in enumerate(protected):translated=re.sub(rf'ZX\s*PH\s*{n:04d}\s*ZX',lambda _:value,translated,flags=re.I)
    if 'ZXPH' in translated or not translated:raise ValueError('Placeholder mismatch')
    # Preserve fragment whitespace used around actor names and numeric values.
    translated=re.match(r'^\s*',text)[0]+html.unescape(translated)+re.search(r'\s*$',text)[0]
    if set(re.findall(r'\{[^{}]*\}',text))!=set(re.findall(r'\{[^{}]*\}',translated)):raise ValueError('Tokens changed')
    result[text]=translated
   return result
  except Exception:
   if attempt==3:
    if len(rows)>1:
     middle=len(rows)//2;return batch(rows[:middle])|batch(rows[middle:])
    raise
   time.sleep(attempt+1)
def main():
 texts=json.loads((OUT/'en.json').read_text(encoding='utf-8'));path=OUT/(LANGUAGE+'.json')
 result=json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}
 todo=[(i,t) for i,t in enumerate(texts) if t not in result and t not in MANUAL];batches=[];current=[];size=0
 for row in todo:
  if current and size+len(row[1])>2300:batches.append(current);current=[];size=0
  current.append(row);size+=len(row[1])+20
 if current:batches.append(current)
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
  futures=[ex.submit(batch,b) for b in batches]
  for count,f in enumerate(concurrent.futures.as_completed(futures),1):
   result.update(f.result());path.write_text(json.dumps(result|MANUAL,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
   print('translated batches',count,'/',len(batches),flush=True)
 result.update(MANUAL);path.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 assert set(texts)<=set(result)
 print('PASS:',LANGUAGE,'translations',len(result))
if __name__=='__main__':main()
