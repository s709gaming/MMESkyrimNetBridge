'use strict';
const fs=require('fs'),vm=require('vm'),assert=require('assert');
class Element {
 constructor(tag){this.tagName=tag;this.children=[];this.style={};this.listeners={};this._text='';this.disabled=false;this.hidden=false;}
 set textContent(value){this._text=String(value);this.children=[];}get textContent(){return this._text+this.children.map(c=>c.textContent).join('');}
 appendChild(child){this.children.push(child);return child;}get firstChild(){return this.children[0];}
 setAttribute(name,value){this[name]=value;}addEventListener(name,fn){this.listeners[name]=fn;}
}
const elements={};for(const id of ['rows','empty','count','notice','refresh','close','tooltip','arousal-heading','roster-tab','lore-tab','roster-panel','lore-panel','lore-text','lore-status','lore-save','lore-reset','lore-length','lore-validation','lore-source','lore-path','lore-reload','lore-confirm','confirm-message','confirm-cancel','confirm-accept'])elements[id]=new Element('div');
elements['lore-confirm'].hidden=true;
const handlers={},calls=[];const document={getElementById:id=>elements[id],createElement:tag=>new Element(tag),addEventListener:(name,fn)=>handlers[name]=fn};
const window={requestEditorClose:()=>{},confirm:()=>true,mmeLoreRequest:s=>calls.push(['lore',s]),mmeRosterAction:s=>calls.push(['action',s]),mmeRosterRefresh:s=>calls.push(['refresh',s]),mmeRosterClose:s=>calls.push(['close',s]),mmeRosterError:s=>calls.push(['error',s])};
const html=fs.readFileSync(process.argv[2],'utf8'),script=html.match(/<script>([\s\S]*?)<\/script>/)[1];vm.runInNewContext(script,{window,document,Number,Math,JSON,Error});

window.setRoster(JSON.stringify({session:'4',message:'',rows:[{name:'<img src=x onerror=alert(1)> 雪 "Hulda"',milk:24,capacity:20,percent:120,status:'Last stored values'},{name:'Player',milk:0,capacity:null,percent:null,status:'',token:'1:1',player:1,available:1,selfReason:'no milk available'}]}));
assert.equal(elements.rows.children.length,2);const first=elements.rows.children[0];assert(first.children[0].textContent.startsWith('<img src=x'));assert.equal(first.children[0].children.length,1);assert.equal(first.children[1].firstChild.children[0].textContent,'24.0 / 20.0');assert.equal(first.children[1].firstChild.children[1].children[0].textContent,'120.0%');assert.equal(first.children[1].firstChild.children[1].children[1].children[0].style.width,'100%');assert(first.children[2].firstChild.firstChild.firstChild.disabled);assert.equal(elements.rows.children[1].children[1].firstChild.children[0].textContent,'0.0 / N/A');assert.equal(elements.rows.children[1].children[1].firstChild.children[1].firstChild.textContent,'N/A');
const playerAction=elements.rows.children[1].children[2].firstChild;assert.equal(playerAction.children[0].firstChild['aria-label'],'Drink');assert.equal(playerAction.children[0].firstChild.disabled,false);assert.equal(playerAction.children[1].firstChild.disabled,true);playerAction.children[0].firstChild.listeners.click();assert.deepEqual(calls.pop(),['action','4|1:1|drink']);assert(playerAction.children[0].firstChild.disabled);playerAction.children[0].firstChild.listeners.click();assert.equal(calls.filter(c=>c[0]==='action').length,0);
elements.refresh.listeners.click();assert.deepEqual(calls.pop(),['refresh','4']);
window.setRoster({session:'6',rows:[{name:'Hulda',milk:3,capacity:4,percent:75,token:'9:0',player:0,available:1,selfReason:''}]});const npcActions=elements.rows.children[0].children[2].firstChild;assert.equal(npcActions.children[0].firstChild['aria-label'],'Give Milk');assert.equal(npcActions.children[1].firstChild.disabled,false);npcActions.children[1].firstChild.listeners.click();assert.deepEqual(calls.pop(),['action','6|9:0|self']);assert(npcActions.children[0].firstChild.disabled);
window.setRoster({session:'5',rows:[]});assert.equal(elements.rows.children.length,0);assert.equal(elements.empty.textContent,'No registered Milk Maids.');assert.equal(elements.empty.hidden,false);
window.setRoster('{bad');assert(elements.notice.textContent.includes('Unable to display'));assert.equal(calls.pop()[0],'error');assert.equal(elements.refresh.disabled,false);
console.log('PASS: actual page JS: data refresh/empty state, Unicode/HTML-as-text, unknown capacity, over-capacity, player Drink/NPC Give Milk/Self Milk callbacks, duplicate-click guard and initial Close/Escape.');

// Fullness is proportional, clamped visually only; invalid values stay N/A.
for(const [percent,width] of [[0,'0%'],[23,'23%'],[50,'50%'],[67,'67%'],[100,'100%'],[150,'100%'],[-5,'0%'],[null,'0%']]){
 window.setRoster({session:'7',rows:[{name:'Maid',milk:2,capacity:4,percent,token:'10:0',player:0,available:1,selfReason:''}]});
 const wrap=elements.rows.children[0].children[1].firstChild.children[1];
 assert.equal(wrap.children[1].firstChild.style.width,width);
 assert.equal(wrap.firstChild.textContent,percent===null?'N/A':percent.toFixed(1)+'%');
}
window.setRoster({session:'8',rows:[{name:'Player',milk:0,capacity:4,percent:0,token:'11:0',player:1,available:1,selfReason:'no milk available'}]});
const slots=elements.rows.children[0].children[2].firstChild.children;
assert.equal(slots[0].firstChild.textContent,'\u{1f95b}');assert.equal(slots[1].firstChild.textContent,'\u{1f42e}');
assert.equal(slots[1].tabindex,'0');assert(slots[1].firstChild.disabled);
slots[1].listeners.focus();assert(!elements.tooltip.hidden);assert(elements.tooltip.textContent.includes('no milk available'));
slots[1].listeners.blur();assert(elements.tooltip.hidden);
slots[0].firstChild.listeners.focus();assert(elements.tooltip.textContent.includes('Lactacid'));assert(elements.tooltip.textContent.includes('ordinary milk'));
elements.refresh.listeners.click();assert(elements.tooltip.hidden);assert.deepEqual(calls.pop(),['refresh','8']);
slots[0].listeners.mouseenter();assert(!elements.tooltip.hidden);slots[0].listeners.mouseleave();assert(elements.tooltip.hidden);
slots[1].listeners.focus();window.setRoster({session:'9',rows:[]});assert(elements.tooltip.hidden);
assert(html.includes('aria-label="Refresh"'));assert(html.includes('aria-label="Close"'));assert(html.includes('role="tooltip"'));
console.log('PASS: proportional white bar, numeric overflow, icon labels, disabled keyboard tooltip, hover and refresh cleanup.');

assert(html.includes('Milk Capacity</th>'));assert(html.includes('&#129371;'));assert(html.includes('&#9829;'));assert(!html.includes('<th>Fullness</th>'));assert.equal(elements.rows.children.length,0);

assert(elements['arousal-heading'].hidden); // Older payloads must retain the three-column layout.
for(const [value,label,width] of [[0,'0.0%','0%'],[50,'50.0%','50%'],[100,'100.0%','100%'],[150,'100.0%','100%'],[-1,'N/A','0%'],[null,'N/A','0%'],['bad','N/A','0%']]){
 window.setRoster({session:'10',arousalAvailable:1,rows:[{name:'Hulda',milk:2,capacity:4,percent:50,arousal:value,token:'12:0',available:1,player:0,selfReason:''}]});
 assert(!elements['arousal-heading'].hidden);const row=elements.rows.children[0];assert.equal(row.children.length,4);
 const meter=row.children[2].firstChild.firstChild;assert.equal(meter.firstChild.textContent,label);assert.equal(meter.children[1].firstChild.style.width,width);
 assert.equal(row.children[1].firstChild.children[1].firstChild.textContent,'50.0%');
 row.children[3].firstChild.firstChild.firstChild.listeners.click();assert.deepEqual(calls.pop(),['action','10|12:0|drink']);
}
window.setRoster({session:'11',arousalAvailable:0,rows:[{name:'Player',milk:2,capacity:4,percent:50,arousal:50,token:'13:0',available:1,player:1,selfReason:''}]});
assert(elements['arousal-heading'].hidden);assert.equal(elements.rows.children[0].children.length,3);
window.setRoster({session:'12',arousalAvailable:1,rows:[]});assert(!elements['arousal-heading'].hidden);assert(elements.empty.textContent.includes('No registered'));
console.log('PASS: optional arousal column, old payload compatibility, 0/50/100/out-of-range/N/A, layout transitions and unchanged NPC action tokens.');

const alignmentCell=elements.rows.children[0];
window.setRoster({session:'13',rows:[{name:'Maid',milk:2,capacity:4,percent:50}]});
const actionCell=elements.rows.children[0].children[2];assert.equal(actionCell.tagName,'td');assert.notEqual(actionCell.className,'actions');assert.equal(actionCell.firstChild.tagName,'div');assert.equal(actionCell.firstChild.className,'actions');
