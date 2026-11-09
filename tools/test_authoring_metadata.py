"""Internal notes must cover the text library without entering runtime text."""
import json,re,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts'
class AuthoringMetadata(unittest.TestCase):
 def setUp(self):
  source=(ROOT/'include/NarrationCatalog.h').read_text(encoding='utf-8')
  self.catalog=json.loads(''.join(re.findall(r'R"MMECATALOG\((.*?)\)MMECATALOG"',source,re.S)))['entries']
 def test_every_entry_has_only_format_and_intent(self):
  self.assertEqual(len(self.catalog),185)
  for id,meta in self.catalog.items():
   with self.subTest(id=id):
    document=json.loads((DATA/meta['file']).read_text(encoding='utf-8-sig'))
    if id.startswith('Pools.'):
     notes=document['_authoring']['entries']['.'.join(meta['path'])]
    else:notes=document['routes'][id.split('.',1)[1]]['_authoring']
    self.assertEqual(set(notes),{'format','intent'})
    self.assertTrue(notes['intent'].strip())
    self.assertTrue(notes['format'].startswith(('Notification.','Narration.','Story.')))
    if notes['format'].startswith('Notification.'):
     self.assertIn('90 characters',notes['format'])
    if meta['presentation']['badge']=='Story Popup':self.assertTrue(notes['format'].startswith('Story.'))
 def test_runtime_catalog_excludes_internal_notes(self):
  def check(value):
   if isinstance(value,dict):
    self.assertNotIn('_authoring',value)
    for child in value.values():check(child)
   elif isinstance(value,list):
    for child in value:check(child)
  check(self.catalog)
 def test_metadata_never_replaces_a_template_or_pool(self):
  for id,meta in self.catalog.items():
   if meta.get('optionalTier'):continue
   value=json.loads((DATA/meta['file']).read_text(encoding='utf-8-sig'))
   for part in meta['path']:value=value[part]
   self.assertEqual(value,meta['default'],id)
if __name__=='__main__':unittest.main()
