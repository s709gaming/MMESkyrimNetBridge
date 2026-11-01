"""Preserve callback logic while adding gated boundary traces."""
from pathlib import Path
import hashlib,json,re,unittest
R=Path(__file__).resolve().parents[1]
class Contracts(unittest.TestCase):
 def test_every_callback_behavior_preserved(self):
  for key,digest in json.loads((R/'tools/prompt-callback-baseline.json').read_text()).items():
   file,name=key.split('|');s=(R/file).read_text()
   body=re.search(r'String Function '+name+r'\([^\n]*\) Global\n(.*?)EndFunction',s,re.S)[1]
   self.assertIn('TracePromptCallback("'+name+'"',body)
   self.assertEqual(body.count('Return '),body.count('Return PromptCallbackReturn(')+body.count('Return MMEAlertsSkyrimNet.PromptCallbackReturn('))
   body=re.sub(r'^.*TracePromptCallback\([^\n]*\n','',body,flags=re.M)
   body=re.sub(r'Return (?:MMEAlertsSkyrimNet\.)?PromptCallbackReturn\("[^"\n]+", \w+, (.*), "[^"\n]+"\)',r'Return \1',body)
   # OStim entry includes its backend label; wrappers preserve all original expressions.
   self.assertEqual(hashlib.sha256(re.sub(r'\s+','',body).encode()).hexdigest(),digest,key)
 def test_logging_gated_and_return_identity(self):
  s=(R/'Source/Scripts/MMEAlertsSkyrimNet.psc').read_text()
  helpers=s.split('; Focused callback boundaries:',1)[1]
  self.assertIn('enablePapyrusTrace',helpers);self.assertIn('enableSkyrimNetPromptDiagnostic',helpers)
  self.assertIn('MMELog.MasterDiagnostic',helpers);self.assertIn('Return value',helpers)
  self.assertNotRegex(helpers,r'Debug.Notification|StorageUtil\.(Set|Unset)|RegisterFor|Utility.Wait|MMELog.Alarm')
  self.assertNotIn('+ value)',helpers)
if __name__=='__main__':unittest.main()
