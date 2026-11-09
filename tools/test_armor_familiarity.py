"""Execute actual familiarity source; mock only storage, equipment and game clock."""
from pathlib import Path
from types import SimpleNamespace as NS
import unittest,re
from test_tentacle_tiers import translate,Memory
R=Path(__file__).resolve().parents[1]
SOURCE=(R/'Source/Scripts/MMEArmorFamiliarity.psc').read_text()
class Store(Memory):
 def GetFormValue(self,a,k,default=None):return self.values.get((a,k),default)
 SetFormValue=Memory.SetFloatValue
class Item:
 def __init__(self,name='clothes',mask=4):self.name=name;self.mask=mask
 def GetSlotMask(self):return self.mask
class Actor:
 def __init__(self):self.worn=None
 def GetWornForm(self,_):return self.worn
 def IsDead(self):return False
 def IsDisabled(self):return False
 def Is3DLoaded(self):return True
class Familiarity(unittest.TestCase):
 def setUp(self):
  self.now=10.;self.store=Store();self.actor=Actor();self.item=Item();self.actor.worn=self.item
  self.ns={'Audit':lambda *a:None,'StorageUtil':self.store,'Utility':NS(GetCurrentGameTime=lambda:self.now),'Armor':NS(GetMaskForSlot=lambda _:4),'Math':NS(LogicalAnd=lambda a,b:a&b),'Game':NS(GetPlayer=lambda:self.actor)}
  for name,args in [('IsBodyArmor','item'),('Seed','target'),('Observe','actors'),('OnEquip','target, item'),('OnUnequip','target, item')]:exec(translate(name,args,re.sub(r"(?m)^([ \t]*)Armor (\w+) =",r"\1Actor \2 =",SOURCE.replace("Trace(","Audit("))),self.ns)
 def equip(self,item=None,actor=None):
  actor=actor or self.actor;item=item or self.item;actor.worn=item;return self.ns['OnEquip'](actor,item)
 def remove(self):self.actor.worn=None;self.ns['OnUnequip'](self.actor,self.item)
 def test_first_equip_then_same(self):self.assertFalse(self.equip());self.assertTrue(self.equip())
 def test_seed_current_outfit_quietly(self):self.ns['Seed'](self.actor);self.assertTrue(self.equip())
 def test_continuously_worn_does_not_expire(self):self.equip();self.now+=100;self.assertTrue(self.equip())
 def test_redress_within_eight_hours(self):self.equip();self.remove();self.now+=7.99/24;self.assertTrue(self.equip())
 def test_eight_hours_expire(self):self.equip();self.remove();self.now+=8.01/24;self.assertFalse(self.equip());self.assertTrue(self.equip())
 def test_rewear_cancels_expiry(self):
  self.equip();self.remove();self.now+=1/24;self.assertTrue(self.equip());self.now+=1;self.assertTrue(self.equip())
 def test_duplicate_removal_does_not_restart(self):
  self.equip();self.remove();self.now+=7/24;self.ns['OnUnequip'](self.actor,self.item);self.now+=2/24;self.assertFalse(self.equip())
 def test_different_form_same_name_replaces_memory(self):
  self.equip();self.assertFalse(self.equip(Item()));self.assertFalse(self.equip())
 def test_boots_do_not_replace(self):
  self.equip();self.assertFalse(self.ns['OnEquip'](self.actor,Item('boots',128)));self.assertTrue(self.equip())
 def test_actor_isolation(self):self.equip();other=Actor();self.assertFalse(self.equip(actor=other));self.assertTrue(self.equip())
 def test_stale_unequip_after_redress_ignored(self):
  self.equip();self.ns['OnUnequip'](self.actor,self.item);self.now+=1;self.assertTrue(self.equip())
 def test_stale_other_unequip_ignored(self):
  self.equip();other=Item();self.actor.worn=other;self.ns['OnEquip'](self.actor,other);self.ns['OnUnequip'](self.actor,self.item);self.assertTrue(self.equip(other))
 def test_first_observed_removal_records_outfit(self):
  self.remove();self.now+=1/24;self.assertTrue(self.equip())
 def test_stale_equip_does_not_replace_memory(self):
  self.equip();self.assertTrue(self.ns['OnEquip'](self.actor,Item()));self.assertTrue(self.equip())
 def test_missing_actor_and_clock_rewind(self):
  self.assertFalse(self.ns['OnEquip'](None,self.item));self.equip();self.remove();self.now-=1;self.assertTrue(self.equip())
 def test_integration_preserves_gameplay_and_explicit_traps(self):
  c=(R/'Source/Scripts/MMEAlertsController.psc').read_text();e=c.split('Event OnArmorEquipped(',1)[1].split('EndEvent',1)[0]
  gate=e.index('If familiarEquip && !chestTrapEquip')
  for call in ['HandleCustomArmorEquipped','MMEMilkingEquipmentRefit.HandleArmorEquipped','TryLockRegisteredEquip']:self.assertLess(e.index(call),gate)
  self.assertLess(gate,e.index('TryAutomatic'))
  a=(R/'Source/Scripts/MMEArmorScript.psc').read_text();b=a.split('Function HandleArmorEquipInternal(',1)[1].split('EndFunction',1)[0]
  self.assertLess(b.index('EvaluateArmorStrippingForActor'),b.index('If suppressPresentation'));self.assertLess(b.index('If suppressPresentation'),b.index('PlayArmorEquipMoan'))
  for forbidden in ['RegisterForUpdate','Utility.Wait','SetActorValue','AddSpell']:self.assertNotIn(forbidden,SOURCE)
if __name__=='__main__':unittest.main()
