"""Localization inventory/rewriter. Only explicit display boundaries are rewritten."""
from pathlib import Path
import re,json,struct,zlib
ROOT=Path(__file__).resolve().parents[2]
STR=re.compile(r'"(?:\\.|[^"\\])*"')
LEX=re.compile(r'/;.*?;/|;[^\n]*|"(?:\\.|[^"\\])*"|[A-Za-z_]\w*|[^\s]',re.S)
def decode(s):
 try:return json.loads(s)
 except ValueError:return s[1:-1].replace('\\"','"').replace('\\n','\n').replace('\\t','\t').replace('\\\\','\\')
def literal(s):return json.dumps(s,ensure_ascii=False)
def human(s):
 if re.search(r'\.(?:esp|esm|pex|psc|json|hkx|dll|wav|fuz|seq|txt)\b',s,re.I):return False
 return bool(re.search('[A-Za-z]',s)) and not s.startswith(('$','MMEExtensions.','MME.','MMEAlerts/','/MME','SKSE/')) and not re.fullmatch(r'[\w.\\/:%<>|{}-]+',s)
def calls(source):
 ts=[m for m in LEX.finditer(source) if not m[0].startswith((';','/;'))]
 for i,t in enumerate(ts[:-1]):
  if not re.fullmatch(r'[A-Za-z_]\w*',t[0]) or ts[i+1][0]!='(':continue
  level=1;start=ts[i+1].end();args=[]
  for j in range(i+2,len(ts)):
   val=ts[j][0]
   if val in ('(','['):level+=1
   elif val in (')',']'):
    level-=1
    if level==0:args.append((start,ts[j].start()));break
   elif val==',' and level==1:args.append((start,ts[j].start()));start=ts[j].end()
  else:continue
  yield t[0],args

def direct_strings(source,a,b):
 depth=0
 for m in LEX.finditer(source,a,b):
  t=m[0]
  if t.startswith((';','/;')):continue
  if t in ('(','['):depth+=1
  elif t in (')',']'):depth-=1
  elif t.startswith('"') and depth==0:yield m

def display_spans(source):
 spans=set();vars=set()
 for name,args in calls(source):
  n=name.lower();wanted=[]
  if n in ('notification','messagebox','setinfotext','addheaderoption','showmessage'):wanted=[0]
  elif re.fullmatch(r'add(?:toggle|slider|menu|text|keymap|input|color)option(?:st)?',n):
   wanted=[1] if n.endswith('st') else [0]
   if n in ('addtextoption','addmenuoption'):wanted.append(1)
   if n in ('addslideroption','addslideroptionst'):wanted.append(3 if n.endswith('st') else 2)
  elif n=='settextoptionvalue':wanted=[1]
  elif n=='setmenudialogoptions':wanted=[0]
  for index in wanted:
   if index>=len(args):continue
   a,b=args[index]
   spans.update((m.start(),m.end()) for m in direct_strings(source,a,b) if re.search('[A-Za-z]',decode(m[0])) and not decode(m[0]).startswith('$'))
   expr=STR.sub('',source[a:b]);vars.update(re.findall(r'(?<![.\w])\b\w+\b(?!\s*\()',expr))
 # Follow only string builders in the current script; call arguments/identifiers stay intact.
 function_ranges=[(m.start(),m.end()) for m in re.finditer(r'(?ims)^[ \t]*(?:\w+(?:\[\])?[ \t]+)?(?:Function|Event)\b[^\n]*\n.*?^[ \t]*End(?:Function|Event)\b',source)]
 assignments=list(re.finditer(r'(?m)^\s*(?:String(?:\[\])?\s+)?(\w+)(?:\[[^\]\n]+\])?\s*(?:=|\+=)\s*([^\n]+)',source))
 for _ in range(4):
  for m in assignments:
   if m[1] not in vars or not any(a<=m.start()<b for a,b in function_ranges):continue
   a,b=m.span(2);spans.update((x.start(),x.end()) for x in direct_strings(source,a,b) if human(decode(x[0])))
   vars.update(re.findall(r'(?<![.\w])\b\w+\b(?!\s*\()',STR.sub('',m[2])))
 return sorted((a,b) for a,b in spans if human(decode(source[a:b])) or re.fullmatch(r'[A-Za-z][A-Za-z -]*',decode(source[a:b])))

def rewrite(source):
 for a,b in reversed(display_spans(source)):source=source[:a]+'MMELocalization.Text('+source[a:b]+')'+source[b:]
 return source

def records(data):
 pos=0
 while pos<len(data):
  sig=data[pos:pos+4];size=struct.unpack_from('<I',data,pos+4)[0]
  if sig==b'GRUP':yield from records(data[pos+24:pos+size]);pos+=size;continue
  h=data[pos:pos+24];body=data[pos+24:pos+24+size]
  if struct.unpack_from('<I',h,8)[0]&0x40000:body=zlib.decompress(body[4:])
  yield sig,h,body;pos+=24+size
 assert pos==len(data)
def fields(body):
 pos=0;extended=None
 while pos<len(body):
  sig=body[pos:pos+4];size=struct.unpack_from('<H',body,pos+4)[0];start=pos;pos+=6
  if sig==b'XXXX':extended=struct.unpack_from('<I',body,pos)[0];pos+=size;continue
  size=extended if extended is not None else size;extended=None
  yield sig,body[pos:pos+size];pos+=size
 assert pos==len(body)
def is_text(sig,field):return field==b'FULL' or (sig==b'INFO' and field in (b'NAM1',b'RNAM')) or (sig==b'MGEF' and field==b'DNAM') or (sig in (b'ARMO',b'SPEL',b'MESG') and field in (b'DESC',b'ITXT'))
def plugin_strings(data):
 for sig,h,body in records(data):
  for f,value in fields(body):
   if is_text(sig,f):
    text=value.rstrip(b'\0').decode('utf-8')
    if text and re.search('[A-Za-z]',text):yield text

def translate_plugin(data,translations):
 pos=0;out=bytearray()
 while pos<len(data):
  sig=data[pos:pos+4];size=struct.unpack_from('<I',data,pos+4)[0];h=bytearray(data[pos:pos+24])
  if sig==b'GRUP':
   body=translate_plugin(data[pos+24:pos+size],translations);struct.pack_into('<I',h,4,len(body)+24);out+=h+body;pos+=size;continue
  raw=data[pos+24:pos+24+size];compressed=bool(struct.unpack_from('<I',h,8)[0]&0x40000);body=zlib.decompress(raw[4:]) if compressed else raw
  changed=False;rebuilt=bytearray()
  for f,value in fields(body):
   new=value
   if is_text(sig,f):
    text=value.rstrip(b'\0').decode('utf-8');translated=translations.get(text,text)
    if translated!=text:new=translated.encode('utf-8')+b'\0';changed=True
   assert len(new)<65536,'Unexpected oversized field'
   rebuilt+=f+struct.pack('<H',len(new))+new
  if changed:
   body=struct.pack('<I',len(rebuilt))+zlib.compress(bytes(rebuilt)) if compressed else bytes(rebuilt)
   struct.pack_into('<I',h,4,len(body));out+=h+body
  else:out+=h+raw
  pos+=24+size
 assert pos==len(data)
 return bytes(out)
def json_texts(value):
 if isinstance(value,str):yield value
 elif isinstance(value,list):
  for x in value:yield from json_texts(x)
 elif isinstance(value,dict):
  for key,x in value.items():
   if key.startswith('_'):continue
   yield from json_texts(x)
def translated_json(value,tr):
 if isinstance(value,str):return tr.get(value,value)
 if isinstance(value,list):return [translated_json(x,tr) for x in value]
 if isinstance(value,dict):return {k:(v if k.startswith('_') else translated_json(v,tr)) for k,v in value.items()}
 return value
