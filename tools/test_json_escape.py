"""Execute the repository escaping routines with SKSE Substring semantics."""
import json,re,unittest
from pathlib import Path
from types import SimpleNamespace
ROOT=Path(__file__).resolve().parents[1]
def load():
 source=(ROOT/'Source/Scripts/MMEAlertsSkyrimNet.psc').read_text()
 namespace={'StringUtil':SimpleNamespace(GetLength=len,AsChar=chr,Find=lambda s,t,start:s.find(t,start),Substring=lambda s,start,length=0:s[start:start+length] if length else s[start:])}
 for name,args in [('ReplaceAll','value, token, replacement'),('EscapeJsonString','value')]:
  body=re.search(r'String Function '+name+r'\([^\n]+\n(.*?)EndFunction',source,re.S)[1]
  lines=['def '+name+'('+args+'):'];indent=1
  for raw in body.splitlines():
   line=raw.strip()
   if not line or line.startswith(';'):continue
   if line in ('EndIf','EndWhile'):indent-=1;continue
   line=re.sub(r'^(String|Int) ', '',line)
   if line.startswith(('If ','While ')):
    keyword,expr=line.split(' ',1);lines.append('    '*indent+keyword.lower()+' '+expr+':');indent+=1
   else:lines.append('    '*indent+re.sub(r'^Return ', 'return ',line))
  exec('\n'.join(lines),namespace)
 return namespace
class Escaping(unittest.TestCase):
 def test_real_source_against_json_parser(self):
  escape=load()['EscapeJsonString']
  for text in ['', '\n','\n\nHeading\n\n','""','\\\\','\t\t','\r\n\r\n','? quote " milk \\ end\n']:
   with self.subTest(text=text):self.assertEqual(json.loads('{"text":"'+escape(text)+'"}')['text'],text)
 def test_replacement_edges(self):
  replace=load()['ReplaceAll']
  for text in ['','x','xx','xaxbxx','ax','xa','abc']:
   self.assertEqual(replace(text,'x','YY'),text.replace('x','YY'))
if __name__=='__main__':unittest.main()
