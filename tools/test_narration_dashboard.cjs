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
const inventory=JSON.parse(fs.readFileSync(path.join(root,'docs/Narration-Dashboard-Inventory.json'),'utf8'));
const meta=inventory.entries.map(row=>({id:row.id,label:row.id,group:row.id.startsWith('Pools.')?row.id.split('.')[1]:row.id.split('.')[0],family:row.family==='skyrimnet'?'AI narration':'Stories, thoughts & notifications',required:row.requiredTokens||row.tokensObserved,allowed:row.requiredTokens||row.tokensObserved,poolOnly:row.family!=='skyrimnet',customized:false}));
const bases={};for(const row of inventory.entries){let value=JSON.parse(fs.readFileSync(path.join(root,row.file),'utf8'));for(const key of row.path)value=value[key];bases[row.id]=value;}
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
 if(request.operation==='entry')return response({entryId:request.entryId,revision,value:Object.hasOwn(saved,request.entryId)?saved[request.entryId]:bases[request.entryId],baseValue:bases[request.entryId],customized:Object.hasOwn(saved,request.entryId)},id);
 if(request.operation==='saveBatch'){
  if(failNextSave){failNextSave=false;return {ok:false,kind:'conflict',requestId:id,message:'Changed elsewhere; reload.'};}
  assert.equal(request.revision,revision);for(const [key,value] of Object.entries(request.changes))if(value===null)delete saved[key];else saved[key]=value;
  ++commits;revision='r'+(commits+1);return response({revision},id);
 }
 throw Error('Unexpected fake server operation: '+request.operation);
}
const window={mmeLoreRequest:payload=>{const [session,bytes]=payload.split('|');assert(/^[0-9]+$/.test(session));assert(bytes.length<=10000,'bounded frame');setImmediate(()=>window.setLoreEditor(enc(backend(dec(bytes)))));},mmeRosterClose:()=>{window.closed=true;}};
vm.runInNewContext(fs.readFileSync(path.join(folder,'dashboard.js'),'utf8'),{window,document,Promise,Map,Set,Array,Object,JSON,Number,Error,String,encodeURIComponent,decodeURIComponent,unescape,setTimeout,clearTimeout});
async function settle(){for(let i=0;i<150;i++)await new Promise(setImmediate);}
function descendants(node,tag){return node.children.flatMap(c=>(c.tagName===tag?[c]:[]).concat(descendants(c,tag)));}
async function open(id){const card=elements['editor-list'].children.find(c=>c.attributes['data-entry-id']===id);assert(card,id);card.open=true;card.listeners.toggle();await settle();return card;}
(async()=>{
 window.requestEditorClose();assert(window.closed,'close works before first roster payload');window.closed=false;
 let escapePrevented=false;handlers.keydown({key:'Escape',preventDefault:()=>escapePrevented=true});assert(escapePrevented&&window.closed);window.closed=false;
 window.editorSessionChanged('4');elements['lore-tab'].listeners.click();await settle();
 assert.equal(elements['editor-list'].children.length,131);assert(downloadChunks>1,'catalog downloads in chunks');assert(elements['roster-panel'].hidden);
 let card=await open('Lore.milk_lore'),field=descendants(card,'textarea')[0];
 const long='MiLk 雪\n'+'x'.repeat(6000);field.value=long;field.listeners.input();assert(!elements['editor-save'].disabled);
 elements['editor-search'].value='Milking.startMessage';elements['editor-search'].listeners.input();
 card=await open('Milking.startMessage');field=descendants(card,'textarea')[0];field.value='{actor} starts milking.';field.listeners.input();
 assert(elements['editor-changes'].textContent.includes('2 unsaved'));
 elements['editor-save'].listeners.click();assert(card.children[1].disabled,'fields are locked while a save is in flight');await settle();assert.equal(commits,1);assert(uploadChunks>1,'large Save uploads in chunks');assert.equal(saved['Lore.milk_lore'],long);assert.equal(saved['Milking.startMessage'],'{actor} starts milking.');
 elements['editor-search'].value='';elements['editor-search'].listeners.input();card=await open('Lore.milkmaid_lore');field=descendants(card,'textarea')[0];field.value='Missing required actor';field.listeners.input();assert(elements['editor-save'].disabled);assert(card.textContent.includes('Keep required placeholder'));
 field.value='{actor} produces milk.';field.listeners.input();assert(!elements['editor-save'].disabled);
 window.requestEditorClose();assert(!elements['lore-confirm'].hidden);assert(!window.closed);elements['confirm-cancel'].listeners.click();
 failNextSave=true;elements['editor-save'].listeners.click();await settle();assert.equal(commits,1);assert(elements['editor-changes'].textContent.includes('1 unsaved'));assert(elements['editor-status'].textContent.includes('Changed elsewhere'));
 window.editorSessionChanged('5');assert(elements['editor-save'].disabled);assert(elements['editor-changes'].textContent.includes('1 unsaved'));
 elements['lore-tab'].listeners.click();await settle();assert(!elements['editor-save'].disabled,'reopening with an unchanged revision preserves editable drafts');
 const v=window.mmeDashboard.validation;
 assert.equal(v({family:'AI narration',poolOnly:false,required:['actor'],allowed:['actor']},'{ActorName} speaks.'),'');
 assert(v({family:'AI narration',poolOnly:false,required:['actor'],allowed:['actor']},'{actor} {unknown}').includes('Unsupported'));
 assert(v({family:'AI narration',poolOnly:false,required:[],allowed:[]},'x'.repeat(8193)).includes('8192'));
 assert(v({family:'AI narration',poolOnly:false,required:[],allowed:[]},['']).includes('nonblank'));
 assert(html.includes('overflow-y:scroll')&&html.includes('resize:vertical')&&html.includes('::-webkit-scrollbar-thumb'));
 console.log('PASS: actual dashboard JS: 131 entries, lazy fields, independent scrolling, long Unicode/chunked save, atomic multi-entry client transaction, validation, modal close, conflict and session-safe drafts.');
})().catch(error=>{console.error(error);process.exitCode=1;});
