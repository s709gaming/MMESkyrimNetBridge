'use strict';
const fs=require('fs'),path=require('path'),vm=require('vm'),assert=require('assert');
const root=path.resolve(__dirname,'..'),folder=path.join(root,'fomod/choices/maid-roster-ui/Magelight/mmeextensions/views/roster');
class Element{
 constructor(tag){this.tagName=tag;this.children=[];this.listeners={};this.attributes={};this.value='';this.checked=false;this.hidden=false;this.disabled=false;this.open=false;this.scrollTop=0;this.clientHeight=400;this.style={};}
 set textContent(text){this.text=String(text);this.children=[];}get textContent(){return (this.text||'')+this.children.map(c=>c.textContent).join('');}
 appendChild(child){this.children.push(child);return child;}setAttribute(name,value){this.attributes[name]=String(value);}
 addEventListener(name,fn){this.listeners[name]=fn;}focus(){document.activeElement=this;}
}
const html=fs.readFileSync(path.join(folder,'index.html'),'utf8'),elements={};
for(const match of html.matchAll(/id="([^"]+)"/g))elements[match[1]]=new Element('div');
elements['lore-panel'].hidden=true;elements['lore-confirm'].hidden=true;elements['editor-import-mode'].value='merge';
const handlers={},document={activeElement:null,getElementById:id=>elements[id],createElement:tag=>new Element(tag),addEventListener:(name,fn)=>handlers[name]=fn};
const catalog=JSON.parse([...fs.readFileSync(path.join(root,'include/NarrationCatalog.h'),'utf8').matchAll(/R"MMECATALOG\((.*?)\)MMECATALOG"/gs)].map(m=>m[1]).join('')).entries;
const meta=Object.entries(catalog).map(([id,row])=>Object.assign({id,customized:false},row));
const bases={};for(const row of meta)bases[row.id]=row.default;
let revision='r1',commits=0,uploadChunks=0,downloadChunks=0,failNextSave=false;const uploads=new Map(),downloads=new Map(),saved={},requests=[];
const enc=o=>Buffer.from(JSON.stringify(o),'utf8').toString('hex'),dec=h=>JSON.parse(Buffer.from(h,'hex').toString('utf8'));
function response(reply,id){const bytes=enc(Object.assign({requestId:id,ok:true},reply));if(bytes.length>8192){downloads.set(id,bytes);return {ok:true,requestId:id,transport:'download',total:Math.ceil(bytes.length/4096)};}return dec(bytes);}
function backend(request){
 const id=request.requestId;requests.push(request.operation);
 if(request.operation==='upload'){
  ++uploadChunks;const prior=uploads.get(id)||'';uploads.set(id,prior+request.data);
  if(request.index+1<request.total)return {ok:true,requestId:id,transport:'ack',index:request.index};
  const decoded=dec(uploads.get(id));uploads.delete(id);return backend(decoded);
 }
 if(request.operation==='download'){
  ++downloadChunks;const bytes=downloads.get(id);return {ok:true,requestId:id,transport:'part',index:request.index,total:Math.ceil(bytes.length/4096),data:bytes.slice(request.index*4096,(request.index+1)*4096)};
 }
 if(request.operation==='catalog')return response({protocolVersion:2,revision,entries:meta.map(m=>({...m,customized:Object.hasOwn(saved,m.id)})),path:'UserData/overrides.json'},id);
 if(request.operation==='presets')return response({presets:[]},id);
 if(request.operation==='capture'||request.operation==='legacy')return response({changes:{'Fullness.nearby_status_summary':'CAPTURED INTERNAL {statuses}','Pools.MilkCravings.craving':['{ActorName} craves captured milk.']}},id);
 if(request.operation==='entry')return response({entryId:request.entryId,revision,value:Object.hasOwn(saved,request.entryId)?saved[request.entryId]:bases[request.entryId],baseValue:bases[request.entryId],customized:Object.hasOwn(saved,request.entryId)},id);
 if(request.operation==='saveBatch'){
  if(failNextSave){failNextSave=false;return {ok:false,kind:'conflict',requestId:id,message:'Changed elsewhere; reload.'};}
  assert.equal(request.revision,revision);for(const [key,value] of Object.entries(request.changes))if(value===null)delete saved[key];else saved[key]=value;
  ++commits;revision='r'+(commits+1);return response({revision},id);
 }
 throw Error('Unexpected fake server operation: '+request.operation);
}
// Supply actual geometry for the resize interaction in the DOM harness.
elements['editor-save'].parentElement={parentElement:{offsetHeight:100}};
elements['editor-divider'].offsetHeight=16;
elements['lore-panel'].clientHeight=600;
elements['lore-panel'].getBoundingClientRect=()=>({height:600});
elements['editor-controls'].getBoundingClientRect=()=>({height:parseFloat(elements['editor-controls'].style.height)||280});
elements['editor-divider'].setPointerCapture=()=>{};
document.body={classList:{add:()=>{},remove:()=>{}}};
const navigation=new Map();
const window={localStorage:{getItem:key=>navigation.get(key)||null,setItem:(key,value)=>navigation.set(key,value),removeItem:key=>navigation.delete(key)},mmeLoreRequest:payload=>{const [session,bytes]=payload.split('|');assert(/^[0-9]+$/.test(session));assert(bytes.length<=10000,'bounded frame');setImmediate(()=>window.setLoreEditor(enc(backend(dec(bytes)))));},mmeRosterClose:()=>{window.closed=true;}};
vm.runInNewContext(fs.readFileSync(path.join(folder,'dashboard.js'),'utf8'),{window,document,Promise,Map,Set,Array,Object,JSON,Number,Error,String,encodeURIComponent,decodeURIComponent,unescape,setTimeout,clearTimeout});
async function settle(){for(let i=0;i<150;i++)await new Promise(setImmediate);}
function descendants(node,tag){return node.children.flatMap(c=>(c.tagName===tag?[c]:[]).concat(descendants(c,tag)));}
async function open(id){const card=elements['editor-list'].children.find(c=>c.attributes['data-entry-id']===id);assert(card,id);card.open=true;card.listeners.toggle();await settle();return card;}
(async()=>{
 const divider=elements['editor-divider'],controls=elements['editor-controls'];
 elements['lore-panel'].hidden=false;
 divider.listeners.pointerdown({button:0,pointerId:1,clientY:300,preventDefault(){}});
 divider.listeners.pointermove({pointerId:1,clientY:-1000});
 assert.equal(controls.style.height,'64px','drag upward expands entry area while retaining controls access');
 divider.listeners.pointermove({pointerId:1,clientY:2000});
 assert.equal(controls.style.height,'384px','drag downward preserves at least 100px for entries');
 divider.listeners.pointercancel();
 divider.listeners.pointermove({pointerId:1,clientY:-1000});
 assert.equal(controls.style.height,'384px','cancel stops dragging');
 divider.listeners.keydown({key:'Home',preventDefault(){}});assert.equal(controls.style.height,'64px');
 divider.listeners.keydown({key:'ArrowDown',preventDefault(){}});assert(parseFloat(controls.style.height)>64);
 assert(navigation.has('mme-editor-split-v1'),'split persists separately from drafts');
 divider.listeners.dblclick();assert.equal(controls.style.height,'','reset restores natural controls height');assert(!navigation.has('mme-editor-split-v1'),'reset clears saved split');
 elements['lore-panel'].hidden=true;

 window.requestEditorClose();assert(window.closed,'close works before first roster payload');window.closed=false;
 let escapePrevented=false;handlers.keydown({key:'Escape',preventDefault:()=>escapePrevented=true});assert(escapePrevented&&window.closed);window.closed=false;
 window.editorSessionChanged('4');elements['lore-tab'].listeners.click();await settle();
 assert.equal(elements['editor-list'].children.length,51);assert(downloadChunks>1,'catalog downloads in chunks');assert(elements['roster-panel'].hidden);
 assert.equal(elements['editor-list'].children[0].attributes['data-entry-id'],'Lore.milkmaid_lore','Milk Maid lore leads');
 assert.equal(elements['editor-list'].children[1].attributes['data-entry-id'],'Lore.milk_lore');
 assert(!elements['editor-list'].children.some(c=>c.attributes['data-entry-id']==='Fullness.nearby_status_summary'),'internal assembly is hidden');

 elements['editor-messages'].listeners.click();assert.equal(elements['editor-list'].children.length,69);
 assert(elements['editor-minor-note'].textContent.includes('17 minor messages hidden'));
 elements['editor-minor'].checked=true;elements['editor-minor'].listeners.change();assert.equal(elements['editor-list'].children.length,86);
 let minor=await open('Pools.FlavorNotifications.custom_living_remove');let minorField=descendants(minor,'textarea')[0];minorField.value='You escape {armorName}.';minorField.listeners.input();
 elements['editor-minor'].checked=false;elements['editor-minor'].listeners.change();assert.equal(elements['editor-list'].children.length,69);
 assert(elements['editor-changes'].textContent.includes('1 unsaved'),'hidden minor draft remains staged');
 elements['editor-minor'].checked=true;elements['editor-minor'].listeners.change();minor=await open('Pools.FlavorNotifications.custom_living_remove');assert.equal(descendants(minor,'textarea')[0].value,'You escape {armorName}.');
 elements['editor-reload'].listeners.click();elements['confirm-accept'].listeners.click();await settle();
 elements['editor-minor'].checked=false;elements['editor-minor'].listeners.change();
 assert(elements['editor-intro'].textContent.includes('without Skyrim.Net'));
 let shared=await open('Pools.MilkCravings.craving');assert(shared.textContent.includes('Also used by Skyrim.Net'));
 const sharedField=descendants(shared,'textarea')[0];sharedField.value='{ActorName} would love some milk.';sharedField.listeners.input();
 elements['editor-skyrimnet'].listeners.click();assert(elements['editor-changes'].textContent.includes('1 unsaved'));
 elements['editor-messages'].listeners.click();shared=await open('Pools.MilkCravings.craving');assert.equal(descendants(shared,'textarea')[0].value,'{ActorName} would love some milk.','section changes keep drafts');
 const sharedReset=descendants(shared,'button').find(b=>b.textContent==='Reset this entry');sharedReset.listeners.click();await settle();
 // The fixture has no override, so discard the staged reset before the existing batch tests.
 elements['editor-reload'].listeners.click();elements['confirm-accept'].listeners.click();await settle();
 elements['editor-group'].value='Thoughts & Cravings';elements['editor-group'].listeners.change();
 assert.equal(JSON.parse(navigation.get('mme-editor-navigation-v1')).section,'messages');
 elements['editor-skyrimnet'].listeners.click();elements['editor-messages'].listeners.click();assert.equal(elements['editor-group'].value,'Thoughts & Cravings','feature selection is retained per section');
 elements['editor-skyrimnet'].listeners.click();
 let card=await open('Lore.milk_lore'),field=descendants(card,'textarea')[0];
 const long='MiLk Ã©â€ºÂª\n'+'x'.repeat(6000);field.value=long;field.listeners.input();assert(!elements['editor-save'].disabled);
 elements['editor-search'].value='Milking.startMessage';elements['editor-search'].listeners.input();
 card=await open('Milking.startMessage');field=descendants(card,'textarea')[0];field.value='{actor} starts milking.';field.listeners.input();
 assert(elements['editor-changes'].textContent.includes('2 unsaved'));
 elements['editor-save'].listeners.click();assert(card.children[1].disabled,'fields are locked while a save is in flight');await settle();assert.equal(commits,1);assert(uploadChunks>1,'large Save uploads in chunks');assert.equal(saved['Lore.milk_lore'],long);assert.equal(saved['Milking.startMessage'],'{actor} starts milking.');
 elements['editor-search'].value='';elements['editor-search'].listeners.input();card=await open('Lore.milkmaid_lore');field=descendants(card,'textarea')[0];field.value='Missing required actor';field.listeners.input();assert(elements['editor-save'].disabled);assert(card.textContent.includes('Keep required placeholder'));
 field.value='{actor} produces milk.';field.listeners.input();assert(!elements['editor-save'].disabled);
 window.requestEditorClose();assert(!elements['lore-confirm'].hidden);assert(!window.closed);elements['confirm-cancel'].listeners.click();
 failNextSave=true;elements['editor-save'].listeners.click();await settle();assert.equal(commits,1);assert(elements['editor-changes'].textContent.includes('1 unsaved'));assert(elements['editor-status'].textContent.includes('Changed elsewhere'));
 window.editorSessionChanged('5');assert(elements['editor-save'].disabled);assert(elements['editor-changes'].textContent.includes('1 unsaved'));
 await settle();assert(!elements['editor-save'].disabled,'visible editor reconciles session without requiring a tab click and preserves drafts');
 const v=window.mmeDashboard.validation;
 for(const row of meta.filter(m=>m.presentation.visible))assert.equal(v(row,row.default),'','visible defaults validate: '+row.id);
 assert.equal(v({family:'AI narration',poolOnly:false,required:['actor'],allowed:['actor']},'{ActorName} speaks.'),'');
 assert(v({family:'AI narration',poolOnly:false,required:['actor'],allowed:['actor']},'{actor} {unknown}').includes('Unsupported'));
 assert(v({family:'AI narration',poolOnly:false,required:[],allowed:[]},'x'.repeat(8193)).includes('8192'));
 assert(v({family:'AI narration',poolOnly:false,required:[],allowed:[]},['']).includes('nonblank'));
 assert(html.includes('overflow-y:scroll')&&html.includes('resize:vertical')&&html.includes('::-webkit-scrollbar-thumb'));
 // Reset spans BOTH player sections even under a filter and keeps internal customizations.
 saved['Fullness.nearby_status_summary']='INTERNAL {statuses}';
 saved['Pools.MilkCravings.craving']=['{ActorName} wants a drink.'];
 saved['Pools.FlavorNotifications.custom_living_remove']=['You escape {armorName}.'];
 elements['editor-reload'].listeners.click();elements['confirm-accept'].listeners.click();await settle();
 assert(!elements['editor-hidden-note'].hidden,'hidden saved customizations are disclosed');
 elements['editor-search'].value='Lore.milkmaid_lore';elements['editor-search'].listeners.input();
 elements['editor-reset-all'].listeners.click();assert(elements['confirm-message'].textContent.includes('BOTH sections'));elements['confirm-accept'].listeners.click();
 elements['editor-save'].listeners.click();await settle();
 assert.equal(saved['Fullness.nearby_status_summary'],'INTERNAL {statuses}','reset preserves hidden override');
 assert(!Object.hasOwn(saved,'Pools.MilkCravings.craving'),'reset includes messages despite AI search filter');
 assert(!Object.hasOwn(saved,'Lore.milk_lore'),'reset includes other AI features');
 assert(!Object.hasOwn(saved,'Pools.FlavorNotifications.custom_living_remove'),'reset includes filtered-out minor entries');
 elements['editor-capture'].listeners.click();await settle();assert(elements['confirm-message'].textContent.includes('1 player-editable'));
 elements['confirm-accept'].listeners.click();elements['editor-save'].listeners.click();await settle();
 assert.equal(saved['Fullness.nearby_status_summary'],'INTERNAL {statuses}','capture cannot overwrite hidden entry');
 assert.deepEqual(saved['Pools.MilkCravings.craving'],['{ActorName} craves captured milk.']);
 elements['editor-messages'].listeners.click();elements['editor-group'].value='Thoughts & Cravings';elements['editor-group'].listeners.change();
 elements['editor-minor'].checked=true;elements['editor-minor'].listeners.change();
 // Recreate the page closure with the same local storage, as a fresh dashboard view would.
 vm.runInNewContext(fs.readFileSync(path.join(folder,'dashboard.js'),'utf8'),{window,document,Promise,Map,Set,Array,Object,JSON,Number,Error,String,encodeURIComponent,decodeURIComponent,unescape,setTimeout,clearTimeout});
 window.editorSessionChanged('9');elements['lore-tab'].listeners.click();await settle();
 assert.equal(elements['editor-messages'].attributes['aria-pressed'],'true','reopened page restores message section');
 assert.equal(elements['editor-group'].value,'Thoughts & Cravings','reopened page restores feature');
 assert(elements['editor-minor'].checked,'reopened page restores minor-message preference');
 console.log('PASS: actual dashboard JS: 51 AI/69 normal/86 expanded message entries, minor filtering/drafts/reset, lore-first order, shared badges, persistence, atomic save and session recovery.');
})().catch(error=>{console.error(error);process.exitCode=1;});
