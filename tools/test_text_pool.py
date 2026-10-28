"""Pool schema/precedence oracle plus compiled-reader boundaries; live VM is separate."""
from pathlib import Path
import json,re,unittest
ROOT=Path(__file__).resolve().parents[1]
def candidates(data,pool):
    if not isinstance(data,dict):return []
    if pool in data:
        value=data[pool]
        if not isinstance(value,list):return []
    else:
        legacy=data.get('stringList',{})
        value=legacy.get(pool.lower(),[]) if isinstance(legacy,dict) else []
    if not isinstance(value,list):return []
    return [(i,s) for i,s in enumerate(value) if isinstance(s,str) and s.strip()]
class TextPoolTests(unittest.TestCase):
 def test_shipped_file_exposes_old_reader_failure(self):
    d=json.loads((ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts/ForcedMilkMaidConversion.json').read_text(encoding='utf-8'))
    for pool in ['chestCurseStories','conversionMessages']:
        self.assertEqual(len(candidates(d,pool)),5)
        self.assertEqual(len(d.get('stringList',{}).get(pool.lower(),[])),0)
        self.assertEqual([i for i,_ in candidates(d,pool)],list(range(5)))
 def test_canonical_precedence_and_legacy_compatibility(self):
    self.assertEqual(candidates({'stringList':{'pool':['old']}},'pool'),[(0,'old')])
    for explicit in [[],None,{},7,'wrong']:
        self.assertEqual(candidates({'pool':explicit,'stringList':{'pool':['old']}},'pool'),[])
    self.assertEqual(candidates({'pool':['new'],'stringList':{'pool':['old']}},'pool'),[(0,'new')])
 def test_custom_pool_and_invalid_entries(self):
    values=['雪 {actor}',None,4,'',' \n\t','quotes " and braces {}','last']
    self.assertEqual(candidates({'pool':values},'pool'),[(0,values[0]),(5,values[5]),(6,values[6])])
    self.assertEqual(candidates({'pool':[None,4,' ']},'pool'),[])
    for invalid_root in [[],None,2,'text',{'stringList':7}]:self.assertEqual(candidates(invalid_root,'pool'),[])
    with self.assertRaises(json.JSONDecodeError):json.loads('{bad')
 def test_actual_reader_and_callers(self):
    s=(ROOT/'Source/Scripts/MMETextPool.psc').read_text(encoding='utf-8')
    self.assertIn('JsonUtil.PathCount(fileName, poolPath)',s)
    self.assertIn('JsonUtil.GetPathStringValue(fileName, itemPath, "")',s)
    self.assertIn('JsonUtil.IsPathString(fileName, itemPath)',s)
    self.assertIn('JsonUtil.PathMembers(fileName, ".")',s) # present null must not fall back
    self.assertNotRegex(s,r'JsonUtil\.(?:Set\w*|Save|Unload|Load|Clear\w*)\(')
    self.assertIn('Utility.RandomInt(0, validCount - 1)',s)
    self.assertIn('validCount != count',s)
    self.assertIn('MMELog.MasterDiagnostic',s)
    self.assertIn('now - last >= 60.0',s)
    for name,expected in [('MMEMilkCurse',2),('MMENewMilkMaid',1)]:
        text=(ROOT/f'Source/Scripts/{name}.psc').read_text(encoding='utf-8')
        self.assertEqual(text.count('MMETextPool.Pick('),expected)
        self.assertNotRegex(text,r'JsonUtil\.StringList(?:Count|Get)\([^\n]*"(?:chestCurseStories|conversionMessages)"')
    self.assertIn('$scriptNames += "MMETextPool"',(ROOT/'build-package.ps1').read_text(encoding='utf-8-sig'))
if __name__=='__main__':unittest.main()
