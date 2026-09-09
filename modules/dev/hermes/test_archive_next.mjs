import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import {stripTypeScriptTypes} from 'node:module';
const plugin=readFileSync(process.argv[2],'utf8');
const core=readFileSync(process.argv[3],'utf8');
const helper=plugin.slice(plugin.indexOf('function botsModArchiveSuccessor('),plugin.indexOf('function hc('));
const selection=plugin.match(/function botsModIsSelected\([^\n]+/)[0];
const archive=stripTypeScriptTypes(core.slice(core.indexOf('  const archiveSession = useCallback('),core.indexOf('\n  return {\n    archiveSession,')));
let count=0;
async function scenario({ids=['a','b','c'],id='b',selected=id,mode='bots',fail=false,switchTo=null,openFail=false,owner='default',connection='local',dispose=false}={}){
 const calls=[], rows=ids.map(id=>({id,profile:'default'})), target=new EventTarget();
 const ref={current:selected};
 const ctx=vm.createContext({console,Promise,Map,window:target,CustomEvent, useCallback:fn=>fn,
  clearNotifications(){}, findListedSession:id=>({session:rows.find(r=>r.id===id),slice:'main'}),
  resolveSessionProfile:async()=> 'default', $profiles:{get:()=>[{name:'default'}]},
  $workspaceMode:{get:()=>mode}, selectedStoredSessionIdRef:ref,
  $pinnedSessionIds:{get:()=>[id],set:v=>calls.push(['pins',v])},sessionPinId:r=>r.id,
  dropListedSession:()=>calls.push(['drop']),tombstoneSessions(){},beginSessionMutation(){},
  startFreshSessionDraft:()=>calls.push(['draft']),
  setSessionArchived:async()=>{calls.push(['rpc']);if(switchTo)ref.current=switchTo;if(fail)throw Error('archive failed')},
  forgetSessionUnread(){},runtimeIdByStoredSessionIdRef:{current:new Map()},
  sessionStateByRuntimeIdRef:{current:new Map()},closeSessionTile:()=>calls.push(['close']),dropSessionState(){},
  notify:()=>calls.push(['success']),notifyError:e=>calls.push(['error',e.message]),
  restoreListedSession:()=>calls.push(['restore']),untombstoneSessions(){},endSessionMutation(){},
  copy:{archiveFailed:'archive failed',archived:'archived'},
  host:{state:{focusedStoredSessionId:{get:()=>ref.current},focusedSessionOwner:{get:()=>({profile:owner,connectionId:connection})}}},
  open:async id=>{calls.push(['open',id]);if(openFail)throw Error('open failed')},invalidate:()=>calls.push(['invalidate']),
  rows,target,calls
 });
 vm.runInContext(selection+'\n'+helper+'\n'+archive+'\nglobalThis.run=archiveSession; globalThis.cleanup=botsModBindArchive({name:"default"},rows,open,host,target,invalidate);',ctx);
 if(dispose)ctx.cleanup();
 await ctx.run(id);ctx.cleanup();count++;
 return calls;
}
const kinds=c=>c.map(x=>x[0]);
for(const [id,next] of [['a','b'],['b','c'],['c','b']]){
 const c=await scenario({id});assert.deepEqual(c.filter(x=>x[0]==='open'),[['open',next]]);
 assert.ok(kinds(c).indexOf('rpc')<kinds(c).indexOf('open'));assert.ok(!kinds(c).includes('draft'));
}
assert.ok(kinds(await scenario({ids:['a'],id:'a'})).includes('draft'));
assert.ok(!kinds(await scenario({ids:['a'],id:'a',fail:true})).includes('draft'));
assert.ok(!kinds(await scenario({ids:['a'],id:'a',switchTo:'other'})).includes('draft'));
assert.ok(!kinds(await scenario({selected:'a'})).includes('open'));
assert.ok(!kinds(await scenario({selected:'a'})).includes('draft'));
const failed=await scenario({fail:true});assert.ok(kinds(failed).includes('restore'));assert.ok(!kinds(failed).includes('open'));assert.ok(!kinds(failed).includes('draft'));
assert.ok(!kinds(await scenario({switchTo:'c'})).includes('open'));
for(const opts of [{mode:'sessions'},{owner:'other'},{connection:'remote'},{dispose:true}]){
 const c=await scenario(opts);assert.ok(!kinds(c).includes('open'));assert.ok(kinds(c).includes('draft'));
}
const openingFailed=await scenario({openFail:true});assert.ok(kinds(openingFailed).includes('draft'));assert.ok(!kinds(openingFailed).includes('restore'));
const h=vm.createContext({});vm.runInContext(helper,h);
assert.equal(h.botsModArchiveSuccessor([{id:'root',resolved_id:'tip'},{id:'next'}],'tip').id,'next');
assert.equal(h.botsModArchiveSuccessor([{id:'a'}],'missing'),null);
console.log(`PASS: ${count} archive lifecycle scenarios plus lineage and missing-row selection; actual core handler and plugin adapter executed.`);
