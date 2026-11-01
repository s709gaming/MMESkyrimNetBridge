"""Request coverage and execution of the actual Papyrus text-composition subset."""
from pathlib import Path
import re,json,unittest,sys
from types import SimpleNamespace
ROOT=Path(__file__).resolve().parents[1]
HELPER=(ROOT/'Source/Scripts/MMEDialogueKnowledge.psc').read_text(encoding='utf-8')

def function(name):
 return re.search(r'String Function '+name+r'\([^\n]+\n(.*?)EndFunction',HELPER,re.S)[1]

class Composer:
 def __init__(self,milk='Milk background.',maid='{actor} is a Milk Maid and produces milk.'):
  self.milk,self.maid=milk,maid;self.alarms=[]
 def run(self,name,**values):
  storage=SimpleNamespace(GetIntValue=lambda *a:0,SetIntValue=lambda *a:None)
  text=SimpleNamespace(GetRaw=lambda *a:self.milk,Text=lambda *a:self.maid.replace('{actor}',a[-1]),IsBlank=lambda s:not s.strip())
  strings=SimpleNamespace(Find=lambda s,t:s.lower().find(t.lower()),GetLength=len)
  values.update(MMENarrationText=text,StringUtil=strings,StorageUtil=storage,ForRequest=self.ForRequest)
  active=[True]
  for raw in function(name).splitlines():
   line=raw.strip()
   if not line or line.startswith(';'):continue
   def expr(s):return eval(s.replace('||',' or ').replace('&&',' and '),{'__builtins__':{}},values)
   if line.startswith('If '):active.append(active[-1] and bool(expr(line[3:])));continue
   if line=='EndIf':active.pop();continue
   if not active[-1]:continue
   if line.startswith('MMELog.') or line.startswith('StorageUtil.Set'):continue
   if line.startswith('AlarmOnce('):self.alarms.append('missing lore');continue
   if line.startswith('Return '):return expr(line[7:])
   match=re.fullmatch(r'String (\w+) = (.+)',line);assert match,line
   values[match[1]]=expr(match[2])
  raise AssertionError('No return in '+name)
 def ForRequest(self,speaker,route):return self.run('ForRequest',speaker=speaker,route=route)
 def Append(self,content,speaker):return self.run('Append',content=content,speaker=speaker)

class Contracts(unittest.TestCase):
 def test_actual_composition_neutral_identity_and_fresh_text(self):
  c=Composer();output=c.Append('Lydia drinks milk.','Lydia')
  self.assertTrue(output.startswith('Lydia drinks milk.'))
  self.assertIn('An example Milk Maid is a Milk Maid',output)
  self.assertNotIn('Lydia is a Milk Maid',output)
  self.assertIn('actual identity and current game state remain authoritative',output)
  c.maid='{actor} follows EDITED knowledge.'
  self.assertIn('EDITED knowledge',c.Append('Another event.',None))
 def test_no_duplicate_empty_or_cross_request_state(self):
  c=Composer();first=c.Append('An event.','Hulda')
  self.assertEqual(c.Append(first,'Hulda'),first)
  for text in ['', '   ', '\n']:self.assertEqual(c.Append(text,None),text)
  self.assertEqual(c.ForRequest(None,'automatic'),c.ForRequest('Lydia','known'))
  self.assertNotIn('Hulda',c.ForRequest('Lydia','known'))
 def test_bad_lore_preserves_original_event(self):
  for c in [Composer(milk=''),Composer(maid='')]:
   self.assertEqual(c.Append('Original event.',None),'Original event.')
   self.assertEqual(len(c.alarms),1)
 def test_every_direct_request_uses_its_actual_originator(self):
  count=0
  for filename in ['MMEAlertsSkyrimNet','MMEChestCurseNarration']:
   source=(ROOT/'Source/Scripts'/f'{filename}.psc').read_text(encoding='utf-8')
   calls=re.findall(r'(\w+) = MMEDialogueKnowledge.Append\((\w+), ([^\n]+)\)\s+Int result = SkyrimNetApi.DirectNarration\((\w+), ([^,\n]+), ([^\n]+)\)',source)
   expected=16 if filename=='MMEAlertsSkyrimNet' else 1
   self.assertEqual(len(calls),expected)
   self.assertEqual(source.count('SkyrimNetApi.DirectNarration('),expected)
   for assigned,content,known,submitted,origin,target in calls:
    self.assertEqual(assigned,content);self.assertEqual(content,submitted);self.assertEqual(known,origin)
   count+=len(calls)
  self.assertEqual(count,17)
 def test_all_private_contexts_escape_and_render_knowledge(self):
  count=0
  for filename in ['MMEAlertsSkyrimNet','MMEChestCurseNarration']:
   source=(ROOT/'Source/Scripts'/f'{filename}.psc').read_text(encoding='utf-8')
   lines=[l for l in source.splitlines() if 'String contextJson =' in l]
   self.assertEqual(len(lines),source.count('SkyrimNetApi.SendCustomPromptToLLM('))
   for line in lines:
    self.assertIn('MMEDialogueKnowledge.ForRequest(Game.GetPlayer(), "player self-comment")',line)
    self.assertRegex(line,r'EscapeJsonString\(MMEDialogueKnowledge.ForRequest')
    self.assertIn('milkKnowledge',line)
   count+=len(lines)
  self.assertEqual(count,8)
  template=(ROOT/'SkyrimNetPrompts/mme_wearer_self_comment.prompt').read_text(encoding='utf-8')
  system=template.split('[ system ]')[1].split('[ end system ]')[0]
  self.assertIn('{{ milkKnowledge }}',system);self.assertIn('{{ playerInstructions }}',system)
  sample=Composer(milk='A quote: "milk"; slash \\; Unicode: \u00e9; newline\n').ForRequest('Player','test')
  self.assertEqual(json.loads(json.dumps({'milkKnowledge':sample}))['milkKnowledge'],sample)
 def test_no_new_dependencies_or_gameplay_and_existing_identity(self):
  self.assertNotRegex(HELPER,r'SkyrimNetApi|AssignSlot|setMilk|setLactacid|JsonUtil\.|RegisterFor|Utility.Wait')
  self.assertIn('MMELog.MasterDiagnostic(',HELPER);self.assertIn('MMELog.Alarm(',HELPER)
  self.assertIn('StorageUtil.GetIntValue(None, alarmKey, 0) == 0',HELPER)
  bridge=(ROOT/'Source/Scripts/MMEAlertsSkyrimNet.psc').read_text(encoding='utf-8')
  body=bridge.split('String Function MilkLoreText(',1)[1].split('EndFunction',1)[0]
  self.assertIn('If IsRealMMEMilkmaid(participant)',body)
  self.assertIn('ResolveActorName(participant, "The Milk Maid")',body)
  self.assertIn('$scriptNames += "MMEDialogueKnowledge"',(ROOT/'build-package.ps1').read_text(encoding='utf-8'))

if __name__=='__main__':unittest.main(testRunner=unittest.TextTestRunner(stream=sys.stdout))
