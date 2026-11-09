"""Generate the editor/runtime catalog from authored JSON, never installed outputs."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'SKSE/Plugins/StorageUtilData/MMEAlerts'
POOLS=('Thoughts','MilkCravings','ArmorIntroductionStories','DwemerArmorStories',
       'ForcedMilkMaidConversion','ArmorCheckReminders','ArousalEffects',
       'BreastBounceNotifications','DwemerEffectNotifications','Injection',
       'NonMilkmaidDrinkNotifications','TimedArmorNotifications')
def tokens(s):return set(re.findall(r'\{([^{}]+)\}',s))
def label(s):
    friendly={'milk_lore':'General milk and milking-armor lore','milkmaid_lore':'Milk Maid character lore',
              'player_instructions':'Private player self-comment instructions'}
    if s in friendly:return friendly[s]
    s=s.replace('n_p_c','NPC')
    s=re.sub(r'^(narrate_|build_|get_)','',s)
    s=re.sub(r'(?<=[a-z])(?=[A-Z])',' ',s).replace('_',' ')
    return s[0].upper()+s[1:]
def generate():
    schema=json.loads((ROOT/'tools/narration-schema.json').read_text(encoding='utf-8-sig'))
    entries={}
    for feature,routes in schema.items():
        document=json.loads((DATA/'Narration'/f'{feature}.json').read_text(encoding='utf-8-sig'))
        for key,meta in routes.items():
            entries[f'{feature}.{key}']=dict(file=f'Narration/{feature}.json',path=['routes',key,'template'],
                group=feature,label=label(key),family='AI narration',required=meta['tokens'],
                allowed=meta['tokens'],aliases=True,poolOnly=False,default=document['routes'][key]['template'])
    for name in POOLS:
        document=json.loads((DATA/f'{name}.json').read_text(encoding='utf-8-sig'))
        typed='stringList' in document
        for key,value in document.get('stringList',document).items():
            if not isinstance(value,list):continue
            observed=[tokens(s) for s in value]
            entries[f'Pools.{name}.{key}']=dict(file=f'{name}.json',path=(['stringList'] if typed else [])+[key],
                group=name,label=label(key),family='Stories, thoughts & notifications',
                required=sorted(set.intersection(*observed)),allowed=sorted(set.union(*observed)),
                aliases=False,poolOnly=True,default=value)
    assert len(entries)==143 and len([x for x in entries if x.startswith('Pools.')])==57
    for tier in ('low','medium','high','extreme'):
        for outcome in ('lines','milk','arousal','milkAndArousal'):
            notification=outcome=='lines'
            file='Injection' if notification else 'TentacleEffectNarration'
            fallback='Pools.Injection.lines' if notification else 'TentacleArmor.effects_'+outcome
            parent=entries[fallback]
            default=parent['default'] if isinstance(parent['default'],list) else [parent['default']]
            entries[f'Pools.{file}.tiers.{tier}.{outcome}']=dict(
                file=file+'.json',path=['tiers',tier,outcome],group='Tentacle '+tier.title(),
                label=tier.title()+' '+('notification' if notification else outcome+' narration'),
                family='Stories, thoughts & notifications',required=['actor'],allowed=['actor'],
                aliases=not notification,poolOnly=True,default=default,optionalTier=True,fallbackEntry=fallback)
    assert len(entries)==159
    flavor=json.loads((DATA/'FlavorNotifications.json').read_text(encoding='utf-8-sig'))
    flavor={key:value for key,value in flavor.items() if not key.startswith('_')}
    flavor_schema=json.loads((ROOT/'tools/flavor-notification-schema.json').read_text(encoding='utf-8'))
    assert set(flavor)==set(flavor_schema) and len(flavor)==26
    for key,contract in flavor_schema.items():
        value=flavor[key]
        assert isinstance(value,list) and value and all(isinstance(text,str) for text in value)
        for text in value:
            assert set(contract['required'])<=tokens(text)<=set(contract['allowed']), key
        entries['Pools.FlavorNotifications.'+key]=dict(file='FlavorNotifications.json',path=[key],
            group='FlavorNotifications',label=label(key),family='Stories, thoughts & notifications',
            required=contract['required'],allowed=contract['allowed'],aliases=False,poolOnly=True,default=value)
    assert len(entries)==185
    presentation=json.loads((ROOT/'tools/narration-presentation.json').read_text(encoding='utf-8'))
    assert set(presentation['entries'])==set(entries), 'Presentation metadata must cover every catalog ID exactly'
    for entry_id,meta in entries.items():
        display=dict(presentation['entries'][entry_id])
        assert display['section'] in ('skyrimnet','messages','internal')
        assert display['visible']==(display['section']!='internal')
        assert display['section']!='skyrimnet' or meta['aliases'], 'AI section requires the existing actor-alias validation contract'
        assert display['title'] and display['description']
        display['featureOrder']=presentation['featureOrder'].index(display['feature'])
        meta['presentation']=display
        meta['label']=display['title']
    catalog=dict(protocolVersion=2,entries=entries,
        legacy=json.loads((ROOT/'tools/narration-legacy-map.json').read_text(encoding='utf-8-sig')))
    serialized=json.dumps(catalog,ensure_ascii=False,separators=(',',':'))
    assert ')MMECATALOG"' not in serialized
    parts=[serialized[i:i+6000] for i in range(0,len(serialized),6000)]
    (ROOT/'include/NarrationCatalog.h').write_text('// Generated by tools/generate_narration_catalog.py\n#pragma once\n'
        'namespace MME::Narration { inline constexpr const char* kCatalogParts[] = {\n'
        + ',\n'.join('R"MMECATALOG('+part+')MMECATALOG"' for part in parts)+'\n}; }\n',encoding='utf-8')
    print(f'Generated {len(entries)} narration catalog entries (including 16 inherited tentacle tier pools).')
if __name__=='__main__':generate()
