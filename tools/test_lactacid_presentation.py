from pathlib import Path
import re,hashlib,unittest
R=Path(__file__).resolve().parents[1]
S=(R/'Source/MMECompatibilityOverrides/MilkLactacidScr.psc').read_text()
class Contracts(unittest.TestCase):
 def test_original_gameplay_preserved(self):
  body=S.split('; Presentation failure',1)[0]
  body=re.sub(r'    If MilkQ == None \|\| akTarget == None.*?    EndIf\n','',body,flags=re.S)
  body=re.sub(r'^.*MMELog.MasterDiagnostic.*\n','',body,flags=re.M)
  body=body.replace('MMEExtPlayVoiceSafe(MilkQ, akTarget)','MilkQ.SexLab.PickVoice(akTarget).Moan(akTarget, Utility.RandomInt (70, 100), false)').replace('MilkQ.SendModEvent(', 'SendModEvent(')
  self.assertEqual(hashlib.sha256(re.sub(r'\s+','',body).encode()).hexdigest(),'0da2e3556d5f78cfee6ac53d82969c606a0a27344faa64c1b7483dc1c7238070')
 def test_safe_voice_cleanup_and_events(self):
  helper=S.split('Function MMEExtPlayVoiceSafe(',1)[1].split('EndFunction',1)[0]
  self.assertRegex(helper,r'If voice == None\s+MMEExtVoiceFailure[^\n]+\s+Return\s+EndIf')
  self.assertLess(helper.index('If voice == None'),helper.index('voice.Moan('))
  for token in ['StorageUtil.UnsetIntValue','StorageUtil.GetIntValue','MMELog.Alarm(','akTarget.Setunconscious(false)','Game.EnablePlayerControls()']:self.assertIn(token,S)
  for event in ['PlayerOrgasmStart','PlayerOrgasmEnd']:self.assertIn('MilkQ.SendModEvent("'+event+'")',S)
 def test_ostim_has_no_sexlab_calls(self):
  s=(R/'fomod/choices/ostim-only/Source/Scripts/MilkLactacidScr.psc').read_text()
  self.assertNotRegex(s,r'sslBaseVoice|\.SexLab\.')
  self.assertIn('MMEFrameworkBackend.PresentationSkipped(akTarget)',s)
  self.assertEqual(s.count('MilkQ.SendModEvent('),2)
if __name__=='__main__':unittest.main()
