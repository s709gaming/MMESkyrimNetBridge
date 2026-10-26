'use strict';
const fs=require('fs'),vm=require('vm'),assert=require('assert');
class Element {
 constructor(tag){this.tagName=tag;this.children=[];this.style={};this.listeners={};this._text='';this.disabled=false;this.hidden=false;}
 set textContent(value){this._text=String(value);this.children=[];}get textContent(){return this._text+this.children.map(c=>c.textContent).join('');}
 appendChild(child){this.children.push(child);return child;}get firstChild(){return this.children[0];}
 setAttribute(name,value){this[name]=value;}addEventListener(name,fn){this.listeners[name]=fn;}
}
const elements={};for(const id of ['rows','empty','count','notice','refresh','close'])elements[id]=new Element('div');
const handlers={},calls=[];const document={getElementById:id=>elements[id],createElement:tag=>new Element(tag),addEventListener:(name,fn)=>handlers[name]=fn};
const window={mmeRosterRefresh:s=>calls.push(['refresh',s]),mmeRosterClose:s=>calls.push(['close',s]),mmeRosterError:s=>calls.push(['error',s])};
const html=fs.readFileSync(process.argv[2],'utf8'),script=html.match(/<script>([\s\S]*?)<\/script>/)[1];vm.runInNewContext(script,{window,document,Number,Math,JSON,Error});
elements.close.listeners.click();assert.deepEqual(calls.pop(),['close','']); // Close works before any data arrives.
window.setRoster(JSON.stringify({session:'4',message:'',rows:[{name:'<img src=x onerror=alert(1)> 雪 "Hulda"',milk:24,capacity:20,percent:120,status:'Last stored values'},{name:'Player',milk:0,capacity:null,percent:null,status:''}]}));
assert.equal(elements.rows.children.length,2);const first=elements.rows.children[0];assert(first.children[0].textContent.startsWith('<img src=x'));assert.equal(first.children[0].children.length,1);assert.equal(first.children[1].textContent,'24.0 / 20.0');assert.equal(first.children[2].children[0].children[0].textContent,'120.0%');assert.equal(first.children[2].children[0].children[1].children[0].style.width,'100%');assert(first.children[3].firstChild.disabled);assert.equal(elements.rows.children[1].children[1].textContent,'0.0 / N/A');assert.equal(elements.rows.children[1].children[2].children[0].firstChild.textContent,'N/A');
elements.refresh.listeners.click();assert.deepEqual(calls.pop(),['refresh','4']);let prevented=false;handlers.keydown({key:'Escape',preventDefault:()=>prevented=true});assert(prevented);assert.deepEqual(calls.pop(),['close','4']);
window.setRoster({session:'5',rows:[]});assert.equal(elements.rows.children.length,0);assert.equal(elements.empty.textContent,'No registered Milk Maids.');assert.equal(elements.empty.hidden,false);
window.setRoster('{bad');assert(elements.notice.textContent.includes('Unable to display'));assert.equal(calls.pop()[0],'error');assert.equal(elements.refresh.disabled,false);
console.log('PASS: actual page JS: data refresh/empty state, Unicode/HTML-as-text, unknown capacity, over-capacity, disabled action, callbacks and initial Close/Escape.');
