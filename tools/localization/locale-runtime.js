(function () {
  'use strict';
  const dict = window.MMERussianStrings || {};
  const keys = Object.keys(dict).filter(k => k.length >= 5 && k.length < 180).sort((a,b) => b.length-a.length);
  function translate(value) {
    if (!value || !/[A-Za-z]/.test(value)) return value;
    const trimmed=value.trim();
    if (dict[trimmed]) return value.replace(trimmed,dict[trimmed]);
    // Dynamic counters/statuses use the same English fragments as the source UI.
    for (const key of keys) if (value.includes(key)) value=value.split(key).join(dict[key]);
    return value;
  }
  function visit(root) {
    if (root.nodeType===3) {
      const parent=root.parentElement;
      if (!parent || parent.closest('script,style,textarea,input,[contenteditable],.actor-name') || parent.matches('td:first-child')) return;
      const result=translate(root.nodeValue);if (result!==root.nodeValue) root.nodeValue=result;
      return;
    }
    if (root.nodeType!==1 && root.nodeType!==9) return;
    if (root.nodeType===1) {
      if (root.matches('script,style,textarea,[contenteditable]')) return;
      for (const attr of ['title','placeholder','aria-label']) if (root.hasAttribute(attr)) {
        const value=root.getAttribute(attr),result=translate(value);if(result!==value)root.setAttribute(attr,result);
      }
    }
    for (const child of [...root.childNodes]) visit(child);
  }
  function start() {
    document.documentElement.lang='ru';visit(document.body);
    new MutationObserver(changes => { for(const change of changes) {
      if(change.type==='characterData')visit(change.target);
      else for(const node of change.addedNodes)visit(node);
    }}).observe(document.body,{subtree:true,childList:true,characterData:true});
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start);else start();
})();
