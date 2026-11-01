/* Shared editor model; Magelight is the transport adapter. No gameplay or LLM calls. */
(function(){
'use strict';
const el=id=>document.getElementById(id),clone=value=>JSON.parse(JSON.stringify(value));
const state={session:'',counter:0,pending:null,queue:[],revision:'',documentBytes:0,catalog:[],cache:new Map(),drafts:new Map(),uncertain:false};
let preferences={section:'skyrimnet',features:{},minor:false};
try{const saved=JSON.parse(window.localStorage.getItem('mme-editor-navigation-v1'));if(saved&&['skyrimnet','messages'].includes(saved.section)&&saved.features&&typeof saved.features==='object')preferences=saved;}catch(error){}
const visible=meta=>meta.presentation&&meta.presentation.visible===true;
const presentation=meta=>meta.presentation;
function remember(){try{window.localStorage.setItem('mme-editor-navigation-v1',JSON.stringify(preferences));}catch(error){}}
const listed=meta=>visible(meta)&&(!presentation(meta).minor||preferences.minor);
function orderedEntries(){return state.catalog.filter(listed).sort((a,b)=>presentation(a).featureOrder-presentation(b).featureOrder||presentation(a).order-presentation(b).order||a.id.localeCompare(b.id));}
function updateSections(){
 const ai=preferences.section==='skyrimnet';
 el('editor-skyrimnet').setAttribute('aria-pressed',String(ai));el('editor-messages').setAttribute('aria-pressed',String(!ai));
 el('editor-intro').textContent=ai?'Customize Skyrim.Net reactions, lore and speaking style. Prompts guide generated dialogue; they are not necessarily spoken word for word.':'Edit on-screen messages and story popups. These work without Skyrim.Net. Shared messages can also guide its reactions when enabled.';
 el('editor-message-link').hidden=!ai;
 el('editor-minor-controls').hidden=ai;el('editor-minor').checked=!!preferences.minor;
 const minors=state.catalog.filter(m=>visible(m)&&presentation(m).minor);
 el('editor-minor-note').textContent=preferences.minor?minors.length+' minor messages included.':minors.length+' minor messages hidden ('+minors.filter(m=>m.customized||state.drafts.has(m.id)).length+' customized or unsaved).';
 const select=el('editor-group');select.textContent='';const all=node('option','All features');all.value='';select.appendChild(all);
 const features=Array.from(new Set(orderedEntries().filter(m=>presentation(m).section===preferences.section).map(m=>presentation(m).feature)));
 for(const feature of features){const option=node('option',feature);option.value=feature;select.appendChild(option);}
 const selected=preferences.features[preferences.section];select.value=features.includes(selected)?selected:'';
 el('editor-hidden-note').hidden=!state.catalog.some(m=>!visible(m)&&m.customized);
}
function changeSection(section){preferences.features[preferences.section]=el('editor-group').value;preferences.section=section;remember();updateSections();el('editor-list').scrollTop=0;renderList();}
const friendly=text=>text.replace(/([a-z])([A-Z])/g,'$1 $2').replace(/_/g,' ');
const status=message=>{el('editor-status').textContent=message;};
const encode=text=>unescape(encodeURIComponent(text)).split('').map(c=>c.charCodeAt(0).toString(16).padStart(2,'0')).join('');
const decode=hex=>{if(typeof hex!=='string'||hex.length%2||!/^[0-9a-f]*$/.test(hex))throw Error('Invalid encoded response');return decodeURIComponent(hex.replace(/../g,p=>'%'+p));};
function node(tag,text,kind){const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(kind)n.className=kind;return n;}
function button(text,action){const n=node('button',text);n.type='button';n.addEventListener('click',action);return n;}
let confirmAction=null,confirmOrigin=null;
function cancelConfirm(){confirmAction=null;el('lore-confirm').hidden=true;if(confirmOrigin&&confirmOrigin.focus)confirmOrigin.focus();confirmOrigin=null;}
function ask(message,action){confirmOrigin=document.activeElement;confirmAction=action;el('confirm-message').textContent=message;el('lore-confirm').hidden=false;if(el('confirm-cancel').focus)el('confirm-cancel').focus();}
el('confirm-cancel').addEventListener('click',cancelConfirm);
el('confirm-accept').addEventListener('click',()=>{const action=confirmAction;cancelConfirm();if(action)action();});
function finish(error,reply){
 const job=state.pending;if(!job)return;clearTimeout(job.timer);state.pending=null;
 if(error){state.uncertain=true;job.reject(error);}else if(!reply.ok){job.reject(Error(reply.message||'Request failed; drafts retained.'));}else job.resolve(reply);
 updateFooter();pump();
}
function sendFrame(frame){
 const job=state.pending;
 try{if(typeof window.mmeLoreRequest!=='function')throw Error('Editor controls are unavailable. Reopen the dashboard.');
  window.mmeLoreRequest(state.session+'|'+encode(JSON.stringify(frame)));
 }catch(error){finish(error);}
 if(job&&state.pending===job)updateFooter();
}
function pump(){
 if(state.pending||!state.queue.length||!state.session)return;
 const job=state.queue.shift();state.pending=job;
 job.timer=setTimeout(()=>finish(Error('Request timed out. Reload Saved to check the outcome before retrying.')),30000);
 const payload=encode(JSON.stringify(job.request));
 if(payload.length>8192){job.parts=[];for(let i=0;i<payload.length;i+=4096)job.parts.push(payload.slice(i,i+4096));job.uploadIndex=0;sendUpload();}
 else sendFrame(job.request);
}
function sendUpload(){const j=state.pending;sendFrame({operation:'upload',requestId:j.request.requestId,index:j.uploadIndex,total:j.parts.length,data:j.parts[j.uploadIndex]});}
function rpc(operation,extra){return new Promise((resolve,reject)=>{
 if(!state.session){reject(Error('Waiting for the dashboard session. Reopen the tab after the roster loads.'));return;}
 const request=Object.assign({operation,requestId:String(++state.counter)},extra||{});
 if(encode(JSON.stringify(request)).length>655360){reject(Error('Transaction exceeds the transport limit. Save fewer or shorter entries.'));return;}
 state.queue.push({request,resolve,reject,session:state.session});pump();updateFooter();
});}
window.setLoreEditor=function(encoded){
 const j=state.pending;if(!j||j.session!==state.session)return;
 try{const reply=JSON.parse(decode(encoded));if(reply.requestId&&reply.requestId!==j.request.requestId)return;
  if(reply.transport==='ack'){
   if(reply.index!==j.uploadIndex)throw Error('Upload acknowledgement mismatch. Reload before retrying.');
   ++j.uploadIndex;sendUpload();return;
  }
  if(reply.transport==='download'){
   if(!Number.isInteger(reply.total)||reply.total<1||reply.total>320)throw Error('Invalid response size');
   j.download=[];j.total=reply.total;sendFrame({operation:'download',requestId:j.request.requestId,index:0});return;
  }
  if(reply.transport==='part'){
   if(!j.download||reply.index!==j.download.length||reply.total!==j.total||typeof reply.data!=='string'||reply.data.length>4096)throw Error('Response chunk mismatch');
   j.download.push(reply.data);
   if(j.download.length<j.total){sendFrame({operation:'download',requestId:j.request.requestId,index:j.download.length});return;}
   finish(null,JSON.parse(decode(j.download.join(''))));return;
  }
  finish(null,reply);
 }catch(error){finish(error);}
};
window.loreEditorUnavailable=message=>finish(Error(String(message)));
window.editorSessionChanged=function(session){
 if(session===state.session)return;
 if(state.pending){clearTimeout(state.pending.timer);state.pending.reject(Error('Game/UI session changed; reload before saving.'));state.pending=null;}
 for(const job of state.queue)job.reject(Error('Session changed.'));state.queue=[];
 state.session=session;state.uncertain=!!state.revision;updateFooter();
 if(!el('lore-panel').hidden && state.uncertain){
  rpc('catalog').then(reply=>{if(reply.revision===state.revision){state.uncertain=false;updateFooter();status('Saved revision unchanged. Drafts retained.');}else status('Saved text changed. Copy drafts before Reload Saved.');}).catch(error=>status(error.message));
 }
 if(!el('lore-panel').hidden&&!state.catalog.length)loadCatalog(false);
};
function validation(meta,value){
 const values=Array.isArray(value)?value:[value];
 if(meta.poolOnly&&!Array.isArray(value))return 'This entry requires variants.';
 if(values.length<1||values.length>64)return 'Use 1 to 64 variants.';
 for(const text of values){
  if(typeof text!=='string'||!text.trim())return 'Every variant needs nonblank text.';
  try{if(encode(text).length/2>8192)return 'Each variant is limited to 8192 UTF-8 bytes.';}catch(error){return 'Invalid Unicode character.';}
  if(/[\x00-\x08\x0b\x0c\x0e-\x1f]/.test(text))return 'Remove unsupported control characters.';
  const found=[];let rest=text.replace(/\{([^{}]+)\}/g,(_,token)=>{
   if((meta.family==='AI narration'||(meta.presentation&&meta.presentation.section==='skyrimnet'))&&(token==='ACTOR'||token==='ActorName'))token='actor';found.push(token);return '';
  });
  if(/[{}]/.test(rest))return 'Unmatched or nested placeholder braces.';
  for(const token of found)if(meta.allowed.indexOf(token)<0)return 'Unsupported placeholder: {'+token+'}';
  for(const token of meta.required)if(found.indexOf(token)<0)return 'Keep required placeholder: {'+token+'}';
 }
 return '';
}
function updateFooter(){
 let invalid=0;for(const [id,value] of state.drafts){const meta=state.catalog.find(m=>m.id===id);if(value!==null&&meta&&validation(meta,value))++invalid;}
 const busy=!!state.pending||!!state.queue.length;
 for(const card of el('editor-list').children)if(card.children&&card.children[1])card.children[1].disabled=busy;
 el('editor-reload').disabled=busy;
 el('editor-size').textContent='Saved document: '+state.documentBytes+' / 262144 UTF-8 bytes Â· projected size checked before Save';
 el('editor-save').disabled=!state.revision||!state.drafts.size||!!invalid||busy||state.uncertain;
 el('editor-changes').textContent=state.drafts.size+' unsaved entr'+(state.drafts.size===1?'y':'ies')+(invalid?' Â· '+invalid+' invalid':'')+(busy?' Â· workingâ€¦':'');
 for(const id of ['editor-export','editor-import','editor-capture','editor-legacy','editor-reset-all'])el(id).disabled=busy||!state.revision;
}
function stage(meta,value){
 if(state.pending||state.queue.length)return;
 const saved=state.cache.get(meta.id);
 if(value!==null&&saved&&JSON.stringify(value)===JSON.stringify(saved.value))state.drafts.delete(meta.id);
 else state.drafts.set(meta.id,clone(value));
 updateFooter();
}
function showEditor(meta,container){
 container.textContent='Loadingâ€¦';
 const ready=state.cache.has(meta.id)?Promise.resolve(state.cache.get(meta.id)):rpc('entry',{entryId:meta.id}).then(reply=>{
  if(reply.revision!==state.revision)throw Error('Text changed elsewhere. Reload Saved before editing more entries.');
  state.cache.set(meta.id,reply);return reply;
 });
 ready.then(saved=>{
  container.textContent='';
  const current=state.drafts.has(meta.id)?state.drafts.get(meta.id):saved.value;
  let value=clone(current===null?saved.baseValue:current);
  const display=presentation(meta);
  if(display.note)container.appendChild(node('p',display.note,'editor-hint'));
  if(display.shared)container.appendChild(node('p','Also used by Skyrim.Net: editing this message can affect both the displayed wording and the situation supplied to the AI when narration is enabled.','editor-hint'));
  const hint=node('p','Required: '+(meta.required.length?meta.required.map(t=>'{'+t+'}').join(' '):'none')+' Â· 8192 UTF-8 bytes per variant Â· 64 variants maximum','editor-hint');container.appendChild(hint);
  for(const token of meta.allowed)container.appendChild(node('p','{'+token+'}: '+(display.tokenHelp[token]||'Value supplied by the event; preserve this placeholder.'),'editor-hint'));
  const badge=node('span',state.drafts.has(meta.id)?(current===null?'Reset staged':'Unsaved'):(saved.customized?'Personal':saved.inherited?'Inherited':'Base / fallback'),'badge');container.appendChild(badge);
  const error=node('p','','error');error.setAttribute('role','status');
  const fields=node('div');container.appendChild(fields);
  function draw(){
   fields.textContent='';const pool=Array.isArray(value),variants=pool?value:[value];
   variants.forEach((text,index)=>{
    const block=node('div',undefined,'variant');const label=node('label',pool?'Variant '+(index+1):'Template');
    const input=node('textarea');input.value=text;input.rows=6;input.spellcheck=true;input.setAttribute('aria-label',meta.label+' '+(pool?'variant '+(index+1):'template'));
    const counter=node('span','','editor-hint');
    function changed(){if(pool)value[index]=input.value;else value=input.value;stage(meta,value);badge.textContent='Unsaved';error.textContent=validation(meta,value);try{counter.textContent=(encode(input.value).length/2)+' / 8192 bytes';}catch(e){counter.textContent='Invalid Unicode';}}
    input.addEventListener('input',changed);try{counter.textContent=(encode(text).length/2)+' / 8192 bytes';}catch(e){counter.textContent='Invalid Unicode';}
    block.appendChild(label);block.appendChild(input);block.appendChild(counter);
    if(pool){const actions=node('div',undefined,'variant-actions');
     const remove=button('Remove',()=>{value.splice(index,1);stage(meta,value);draw();});remove.disabled=variants.length===1;
     const up=button('â†‘ Move up',()=>{[value[index-1],value[index]]=[value[index],value[index-1]];stage(meta,value);draw();});up.disabled=index===0;
     const down=button('â†“ Move down',()=>{[value[index+1],value[index]]=[value[index],value[index+1]];stage(meta,value);draw();});down.disabled=index===variants.length-1;
     actions.appendChild(up);actions.appendChild(down);actions.appendChild(remove);block.appendChild(actions);
    }fields.appendChild(block);
   });
   if(pool){const add=button('Add variant',()=>{value.push('');stage(meta,value);draw();});add.disabled=value.length>=64;fields.appendChild(add);}
   if(!meta.poolOnly){const convert=button(pool?'Use a single template':'Use random variants',()=>{value=pool?value[0]:[value];stage(meta,value);draw();});convert.disabled=pool&&value.length>1;fields.appendChild(convert);}
   error.textContent=validation(meta,value);if(state.drafts.has(meta.id))badge.textContent=state.drafts.get(meta.id)===null?'Reset staged':'Unsaved';
  }
  draw();container.appendChild(error);
  container.appendChild(button('Reset this entry',()=>{stage(meta,null);showEditor(meta,container);}));
  const advanced=node('details',undefined,'editor-advanced');advanced.appendChild(node('summary','Advanced details'));advanced.appendChild(node('p',meta.id,'editor-hint'));container.appendChild(advanced);
 }).catch(error=>{container.textContent=error.message;status(error.message);});
}
function renderList(){
 const list=el('editor-list'),position=list.scrollTop;list.textContent='';
 const query=el('editor-search').value.toLowerCase(),group=el('editor-group').value,modified=el('editor-modified').checked;
 let count=0;
 for(const meta of orderedEntries()){
  const display=presentation(meta);
  if(display.section!==preferences.section)continue;
  if(group&&display.feature!==group)continue;
  if(query&&[meta.label,meta.id,display.feature,display.description,display.badge].join(' ').toLowerCase().indexOf(query)<0)continue;
  if(modified&&!meta.customized&&!state.drafts.has(meta.id))continue;
  ++count;const card=node('details',undefined,'editor-card'),heading=node('summary',meta.label),body=node('fieldset',undefined,'entry-body');
  heading.appendChild(node('small',display.badge+' Â· '+display.feature+(state.drafts.has(meta.id)?' Â· Unsaved':meta.customized?' Â· Personal':'')));
  heading.appendChild(node('span',display.description,'editor-description'));
  heading.addEventListener('click',event=>{if(state.pending||state.queue.length)event.preventDefault();});
  heading.addEventListener('keydown',event=>{if((state.pending||state.queue.length)&&(event.key==='Enter'||event.key===' '))event.preventDefault();});
  card.setAttribute('data-entry-id',meta.id);card.appendChild(heading);card.appendChild(body);let loaded=false;
  card.addEventListener('toggle',()=>{if(card.open&&!loaded&&!state.pending&&!state.queue.length){loaded=true;showEditor(meta,body);}});
  list.appendChild(card);
 }
 list.scrollTop=position;el('editor-count').textContent=count+' / '+state.catalog.filter(m=>listed(m)&&presentation(m).section===preferences.section).length+' entries in this section';updateFooter();
}
function presets(){return rpc('presets').then(reply=>{const select=el('editor-preset-list');select.textContent='';for(const name of reply.presets){const option=node('option',name);option.value=name;select.appendChild(option);}});}
function loadCatalog(discard){
 status('Loading narration catalogâ€¦');
 return rpc('catalog').then(reply=>{
  if(reply.protocolVersion!==2||!Array.isArray(reply.entries))throw Error('Editor and native backend versions do not match.');
  if(reply.entries.some(m=>!m.presentation||!['skyrimnet','messages','internal'].includes(m.presentation.section)))throw Error('Editor presentation metadata is unavailable. Update the dashboard and native plugin together.');
  state.catalog=reply.entries;state.revision=reply.revision;state.documentBytes=reply.documentBytes||0;state.uncertain=false;state.cache.clear();if(discard)state.drafts.clear();
  updateSections();
  el('editor-path').textContent='Personal file: '+reply.path;renderList();status('Open an entry to edit. Save commits all changed entries together.');
  presets().catch(error=>status(error.message));
 }).catch(error=>{status(error.message);updateFooter();});
}
function save(){
 const changes={};for(const [id,value] of state.drafts)changes[id]=value;
 status('Saving '+state.drafts.size+' entriesâ€¦');
 return rpc('saveBatch',{revision:state.revision,changes}).then(()=>loadCatalog(true)).catch(error=>status(error.message));
}
el('editor-save').addEventListener('click',()=>{if(!el('editor-save').disabled)save();});
el('editor-reload').addEventListener('click',()=>{if(state.drafts.size)ask('Discard unsaved entries and reload committed text?',()=>loadCatalog(true));else loadCatalog(false);});
el('editor-search').addEventListener('input',renderList);el('editor-group').addEventListener('change',()=>{preferences.features[preferences.section]=el('editor-group').value;remember();renderList();});el('editor-modified').addEventListener('change',renderList);
el('editor-skyrimnet').addEventListener('click',()=>changeSection('skyrimnet'));el('editor-messages').addEventListener('click',()=>changeSection('messages'));el('editor-message-link').addEventListener('click',()=>changeSection('messages'));
el('editor-minor').addEventListener('change',()=>{preferences.features[preferences.section]=el('editor-group').value;preferences.minor=el('editor-minor').checked;remember();updateSections();renderList();});
el('editor-up').addEventListener('click',()=>{el('editor-list').scrollTop-=el('editor-list').clientHeight||400;});
el('editor-down').addEventListener('click',()=>{el('editor-list').scrollTop+=el('editor-list').clientHeight||400;});
el('editor-reset-all').addEventListener('click',()=>ask('Reset all player-editable entries in BOTH sections, including minor messages hidden by filters? Internal and unknown customizations are preserved. Save Changes applies this reset.',()=>{for(const meta of state.catalog)if(visible(meta)&&(meta.customized||state.drafts.has(meta.id)))state.drafts.set(meta.id,null);updateSections();renderList();}));
el('editor-export').addEventListener('click',()=>{
 if(state.drafts.size){status('Save or discard drafts before exporting committed text.');return;}
 rpc('export',{revision:state.revision,name:el('editor-preset-name').value}).then(()=>{status('Preset exported outside installed mods.');presets();}).catch(error=>status(error.message));
});
el('editor-import').addEventListener('click',()=>{
 if(state.drafts.size){status('Save or discard drafts before importing a preset.');return;}
 const name=el('editor-preset-list').value,mode=el('editor-import-mode').value;
 rpc('importPreview',{name}).then(preview=>ask('Import '+preview.entries+' preset entries? '+preview.conflicts+' conflicts. '+(mode==='merge'?'Merge keeps existing personal entries, including internal customizations.':'Replace replaces the entire personal override set, including internal and unknown entries.'),()=>{
  rpc('importApply',{name,mode,presetRevision:preview.presetRevision,revision:state.revision}).then(()=>loadCatalog(true)).catch(error=>status(error.message));
 })).catch(error=>status(error.message));
});
function capture(operation){rpc(operation).then(reply=>{const ids=Object.keys(reply.changes).filter(id=>state.catalog.some(m=>m.id===id&&visible(m)));ask('Stage '+ids.length+' player-editable customizations? Existing personal entries and internal fields are kept. Save Changes applies them.',()=>{for(const id of ids)if(!state.drafts.has(id))state.drafts.set(id,reply.changes[id]);renderList();});}).catch(error=>status(error.message));}
el('editor-capture').addEventListener('click',()=>capture('capture'));el('editor-legacy').addEventListener('click',()=>capture('legacy'));
function showTab(editor){
 el('roster-tab').setAttribute('aria-selected',String(!editor));el('lore-tab').setAttribute('aria-selected',String(editor));
 el('roster-panel').hidden=editor;el('lore-panel').hidden=!editor;el('refresh').hidden=editor;
 if(editor&&(!state.catalog.length||(state.uncertain&&!state.drafts.size)))loadCatalog(false);
 else if(editor&&state.uncertain){
  status('Checking saved revision; drafts are retainedâ€¦');
  rpc('catalog').then(reply=>{if(reply.revision===state.revision){state.uncertain=false;status('Saved revision unchanged. Your drafts are ready to save.');updateFooter();}else status('Saved text changed while the window was closed. Drafts kept; copy them before Reload Saved.');}).catch(error=>status(error.message));
 }
}
el('roster-tab').addEventListener('click',()=>showTab(false));el('lore-tab').addEventListener('click',()=>{showTab(true);applySplit();});
window.requestEditorClose=function(){
 const close=()=>{if(typeof window.mmeRosterClose==='function')window.mmeRosterClose(state.session);};
 if(state.drafts.size||state.pending)ask('Leave with unsaved entries or a pending operation? Save before exiting Skyrim. Drafts remain in this page until it reloads.',close);else close();
};
el('close').addEventListener('click',window.requestEditorClose);
document.addEventListener('keydown',event=>{
 if(event.key==='Escape'){event.preventDefault();if(!el('lore-confirm').hidden)cancelConfirm();else window.requestEditorClose();}
 if(event.key==='Tab'&&!el('lore-confirm').hidden){event.preventDefault();const target=document.activeElement===el('confirm-cancel')?el('confirm-accept'):el('confirm-cancel');if(target.focus)target.focus();}
});
// One divider resizes the existing controls/list split; drafts and scrolling stay in place.
const divider=el('editor-divider'),controls=el('editor-controls'),panel=el('lore-panel');
let split=null,drag=null;
try{const raw=window.localStorage.getItem('mme-editor-split-v1');if(raw!==null&&Number.isFinite(Number(raw)))split=Math.max(0,Math.min(1,Number(raw)));}catch(error){}
function applySplit(){
 if(panel.hidden||!panel.getBoundingClientRect)return;
 const available=panel.clientHeight-el('editor-save').parentElement.parentElement.offsetHeight-divider.offsetHeight;
 const max=Math.max(64,available-100);
 if(split!==null)controls.style.height=Math.round(64+split*(max-64))+'px';
 controls.style.maxHeight=max+'px';
 divider.setAttribute('aria-valuenow',String(Math.round((split===null?0.5:split)*100)));
}
function saveSplit(value){split=Math.max(0,Math.min(1,value));try{window.localStorage.setItem('mme-editor-split-v1',String(split));}catch(error){}applySplit();}
divider.addEventListener('pointerdown',event=>{
 if(event.button!==0)return;
 const available=panel.clientHeight-el('editor-save').parentElement.parentElement.offsetHeight-divider.offsetHeight;
 drag={id:event.pointerId,y:event.clientY,height:controls.getBoundingClientRect().height,max:Math.max(64,available-100)};
 divider.setPointerCapture(event.pointerId);document.body.classList.add('editor-resizing');event.preventDefault();
});
divider.addEventListener('pointermove',event=>{if(drag&&event.pointerId===drag.id)saveSplit((drag.height+event.clientY-drag.y-64)/Math.max(1,drag.max-64));});
function finishSplit(){drag=null;document.body.classList.remove('editor-resizing');}
divider.addEventListener('pointerup',finishSplit);divider.addEventListener('pointercancel',finishSplit);divider.addEventListener('lostpointercapture',finishSplit);
divider.addEventListener('keydown',event=>{
 const steps={ArrowUp:-0.05,ArrowDown:0.05,PageUp:-0.2,PageDown:0.2};
 if(Object.hasOwn(steps,event.key)){event.preventDefault();if(split===null){const max=Math.max(64,panel.clientHeight-el('editor-save').parentElement.parentElement.offsetHeight-divider.offsetHeight-100);split=(controls.getBoundingClientRect().height-64)/Math.max(1,max-64);}saveSplit(split+steps[event.key]);}
 else if(event.key==='Home'||event.key==='End'){event.preventDefault();saveSplit(event.key==='Home'?0:1);}
});
divider.addEventListener('dblclick',()=>{split=null;controls.style.height='';try{window.localStorage.removeItem('mme-editor-split-v1');}catch(error){}applySplit();});
if(window.addEventListener){window.addEventListener('resize',applySplit);window.addEventListener('blur',finishSplit);}
if(window.ResizeObserver)new window.ResizeObserver(applySplit).observe(panel);

// Expose only pure validation/encoding for offline contract tests, never disk or game access.
window.mmeDashboard={validation,encode,decode};updateFooter();
})();
