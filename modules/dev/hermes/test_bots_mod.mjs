import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import vm from 'node:vm';
const source = readFileSync(process.argv[2], 'utf8');
const metadata = source.match(/var Kw=\{(.*?)register\(/s)?.[1];
assert.ok(metadata, 'Pinned plugin metadata must be recognizable');
assert.match(metadata, /defaultEnabled:!1/, 'Install must not double-register bundled Bots');
console.log('PASS: plugin installs opt-in without duplicating bundled Bots');
assert.match(source, /function botsModSessionLabel\(/, 'Session rows must have a meaningful display-label fallback');
const labels = vm.createContext({gc:(value,strings)=>`${value}:${strings.marker}`});
vm.runInContext(segmentForLabel(source), labels);
function segmentForLabel(text) {
  const a = text.indexOf('function botsModSessionLabel('), b = text.indexOf('function rc(', a);
  assert.ok(a >= 0 && b > a, 'Missing session label seam');
  return text.slice(a, b);
}
assert.equal(labels.botsModSessionLabel({title:'Bot Chat', preview:'You: investigate pinned bundle'}, 'alice'), 'investigate pinned bundle');
assert.equal(labels.botsModSessionLastActive({last_active:123},{marker:'ago'}),'123000:ago');
assert.equal(labels.botsModSessionLastActive({started_at:123},{marker:'ago'}),'123000:ago');
assert.equal(labels.botsModSessionLastActive({},{}),'');
assert.equal(labels.botsModSessionLabel({title:'Bot Chat'}, 'alice'), 'Chat with @alice');
assert.equal(labels.botsModSessionLabel({title:'Existing title', preview:'ignored'}, 'alice'), 'Existing title');
const allSessions=Array.from({length:2101},(_,i)=>({id:`s${i}`,last_active:100+i,title:i===0?'Bot Chat':i===1?'Agent Inbox':`Task ${i}`}));
const listCalls=[];
const listing=vm.createContext({Yq:v=>({get:()=>v}),hp:{request(){}},H:async(bot,method,args)=>{listCalls.push(args);return {sessions:allSessions.slice(0,args.limit)};}});
vm.runInContext(segment('async function Sp(', 'function botsModSessionLabel('),listing);
const listed=await listing.Sp({name:'alice'});
assert.equal(listed[0].last_active,100,'Listing must preserve backend timestamps');
assert.equal(listed.length,allSessions.length,'All sessions, including canonical, must be listed once');
assert.equal(new Set(listed.map(s=>s.id)).size,allSessions.length);
assert.ok(listCalls.length<12,'Listing must not repeatedly request a capped page');
assert.ok(listCalls.filter(c=>c.include_hidden).every(c=>c.include_hidden&&c.profile==='alice'));
assert.ok(listCalls.every(c=>c.include_hidden),'Activity is returned by the enriched session.list without extra RPCs');
const rosterSource=segment('function hc(', 'function yc(');
assert.doesNotMatch(rosterSource, /onClick:wt|onPointerEnter:he/, 'Header must not navigate or warm bots');
assert.match(rosterSource, /Ge=ot\("button",/, 'Clicking a bot opens its management menu');
assert.match(rosterSource, /Qe=q\("div"/, 'Sessions must always render');
assert.match(rosterSource, /tabTitle:botsModSessionLabel\(/, 'Opened tabs must receive the session label');
new vm.Script(rosterSource);
assert.doesNotMatch(rosterSource, /More actions/, 'The redundant More actions control is removed');
assert.doesNotMatch(source, /botsModSetSessionPinned\(|session-pins-v1/, 'Session pinning and persistence are removed');
assert.doesNotMatch(source, /session\.update/, 'No invented session.update RPC is used');
assert.doesNotMatch(source, /botsModSessionActivity\(/, 'Activity text is removed; retain the selected-session dot');
assert.match(source, /botsModSessionLastActive\(/, 'Rows expose authoritative last-active time');
assert.match(source, /botsModIsSelected\(V,e,Ht,botsOwner\)/, 'Selection uses focused stored identity and source ownership');
const sorting=vm.createContext({Rk:{get:()=>({})},nc:()=>0});
vm.runInContext(segment('function oc(', 'var wp='),sorting);
assert.equal(sorting.oc(allSessions).length,allSessions.length,'Rendered list must not retain the eight-session cap');
console.log('PASS: meaningful labels, settings headers, expanded and complete sessions');
const ps = source.slice(source.indexOf('function Ps('), source.indexOf('async function gr('));
async function kickoffCount(resume) {
  let submitted = 0;
  const context = vm.createContext({
    $o: () => ({bot: {}, name: 'test', key: 'test', route: null}),
    pr: new Map(), nt: {}, As: async () => null, Kt: (_, name) => name,
    Yt: 'Bot Chat', Yu: () => 'hello',
    window: {setTimeout: (fn) => fn()},
    H: async (_, method) => {
      if (method === 'session.create') return {stored_session_id: 'stored', session_id: 'runtime'};
      if (method === 'session.resume') { if (resume === null) throw Error('offline'); return resume; }
      if (method === 'prompt.submit') submitted++;
      return {};
    },
  });
  await vm.runInContext(`${ps}; Ps({}, {kickoff: true})`, context);
  return submitted;
}
assert.equal(await kickoffCount(null), 0, 'Failed history check must never spend tokens on a greeting');
assert.equal(await kickoffCount({}), 0, 'Unknown message count must fail closed');
assert.equal(await kickoffCount({message_count: 3}), 0, 'Existing history must not be greeted');
assert.equal(await kickoffCount({message_count: 0}), 0, 'Empty bot chats must never submit an unsolicited greeting');
console.log('PASS: kickoff fails closed on unknown history');

function segment(start, end) {
  const a = source.indexOf(start), b = source.indexOf(end, a + start.length);
  assert.ok(a >= 0 && b > a, `Missing pinned seam: ${start}`);
  return source.slice(a, b);
}
const controls = vm.createContext({});
vm.runInContext(segment('function Hm(', 'function Km('), controls);
for (const text of ['@alice do not stop; finish the tests', '@alice explain the stop button', '@everyone where should this change go?', '@alice hello', '/resume @alice and explain why']) {
  const result = controls.Hm(text, ['alice'], text.includes('@everyone'));
  assert.equal(result.hold.length, 0, text);
  assert.equal(result.release.length, 0, text);
  assert.equal(result.releaseAll, false, text);
}
assert.equal(controls.Hm('@alice /pause', ['alice'], false).hold[0], 'alice');
assert.equal(controls.Hm('/resume @everyone', ['alice'], true).releaseAll, true);
assert.equal(controls.Hm('/stop', [], false).holdAll, true);
assert.equal(controls.Hm('/resume', [], false).releaseAll, true);
assert.equal(controls.Hm('@alice /resume', ['alice'], false).releaseAll, false);
assert.equal(controls.Hm('@alice /resume', ['alice'], false).release[0], 'alice');
const held = {alice:{at:1}};
assert.equal(controls.qm(held, {mentioned:['alice']}, '@alice hello', {}, ['alice']), held);
console.log('PASS: only explicit control commands change holds');

async function stopScenario(mode) {
  const state={room:{turn:'alice',members:[{name:'alice'}],sessions:{alice:'stored'},epoch:0,running:true}};
  const events=[], calls=[]; let interrupted=false;
  const ctx=vm.createContext({
    N:{get:()=>state}, ce:(id,fn)=>{state[id]=fn({...state[id]});}, ne:m=>m.name, botsModWaitPending:async()=>true,
    Le:(id,event)=>events.push(event), setTimeout:fn=>fn(),
    H:async (bot,method,args)=>{
      calls.push({method,args});
      if(method==='session.interrupt') {
        assert.equal(args.session_id,'runtime', 'Interrupt must use resolved runtime identity');
        if(mode==='reject') throw Error('Gateway unavailable');
        interrupted=true; return {};
      }
      assert.equal(method,'session.resume');
      if(mode==='unknown')return {};
      return {session_id:'runtime',running: mode==='busy'||!interrupted,inflight:null};
    }
  });
  vm.runInContext(segment('async function zl(', 'async function Ul('),ctx);
  const result=await ctx.zl('room','thread');
  return {state:state.room,events,calls,result,ctx};
}
for(const mode of ['reject','busy','unknown']) {
  const outcome=await stopScenario(mode);
  assert.equal(outcome.result,false,mode);
  assert.equal(outcome.events.some(e=>e.kind==='stopped'),false,mode);
  assert.ok(outcome.state.stopError,mode);
  assert.equal(outcome.state.stopping,false,mode);
  assert.ok(outcome.state.holds.alice,mode);
  if(mode==='reject') {
    const before=outcome.calls.length;
    await outcome.ctx.zl('room','thread');
    assert.ok(outcome.calls.length>before,'Failed stop must be retryable');
  }
}
const stopped=await stopScenario('success');
assert.equal(stopped.result,true);
assert.equal(stopped.state.stopError,null);
assert.equal(stopped.events.at(-1).kind,'stopped');
assert.equal(stopped.events[0].kind,'stop-requested');
assert.ok(stopped.calls.filter(c=>c.method==='session.resume').length>=2);
console.log('PASS: stop resolves runtime ID, confirms idle, retains errors and supports retry');
const notices=[];
const submit=vm.createContext({N:{get:()=>({room:{stopError:'offline'}})}, Fe:{notify:n=>notices.push(n)}});
vm.runInContext(segment('function pi(', 'import'),submit);
assert.equal(submit.pi('room',[],'keep my draft'),null);
assert.equal(notices[0].kind,'error');
console.log('PASS: sending during an unconfirmed stop preserves the draft');

const raceState={room:{epoch:0,stopping:false,holds:{}}};
const raceCtx=vm.createContext({N:{get:()=>raceState},ne:m=>m.name});
vm.runInContext(segment('function botsModSendStale(', 'async function botsModWaitPending'),raceCtx);
const deferredRpc=new Promise(resolve=>setTimeout(resolve,0));
const raceToken={epoch:0,cancelled:false};
const raceMember={name:'alice'};
const raceResult=deferredRpc.then(()=>{raceCtx.N.get().room.epoch=1;return raceCtx.botsModSendStale('room',raceMember,raceToken);});
assert.equal(await raceResult,true,'A send released after Stop must be cancelled before submission');
console.log('PASS: deferred send is stale after Stop advances the epoch');

// Exercise actual send + stop functions across deferred gateway boundaries.
async function stopSendRace(phase) {
  let state={room:{members:[{name:'alice'}],sessions:{},epoch:0,running:true,turn:'alice',holds:{}}};
  let release, entered=false, clock=0, submits=0, checked=0;
  const gate=new Promise(resolve=>{release=resolve;});
  const events=[], timers=[];
  const ctx=vm.createContext({
    N:{get:()=>state},ce:(id,fn)=>{state={...state,[id]:fn({...state[id]})};},
    ne:m=>m.name,Le:(_,event)=>events.push(event),Date:{now:()=>clock},
    setTimeout:(fn,delay)=>{timers.push({fn,delay});},Mm:async()=>()=>{},
    Sm:async()=>{if(phase!=='submit'){entered=true;await gate;}
      state={...state,room:{...state.room,sessions:{alice:'new-stored'}}};
      return {runtime:'runtime',stored:'new-stored'};},
    H:async(_,method,args)=>{assert.equal(method,'session.resume');checked++;
      assert.equal(args.session_id,'new-stored');return {session_id:'runtime',running:false,messages:[]};},
    Am:async()=>{submits++;entered=true;await gate;return 'runtime';},
    km:50,$l:1000,Tm:10000,ei:()=>false,
    botsModPendingSends:new Map(),botsModWaitPending:async()=>true,
  });
  if(source.includes('function botsModPendingSet('))
    vm.runInContext(segment('function botsModPendingSet(', 'async function oi('),ctx);
  vm.runInContext(segment('async function oi(', 'async function Nm('),ctx);
  vm.runInContext(segment('async function Nm(', 'async function ri('),ctx);
  vm.runInContext(segment('async function zl(', 'async function Ul('),ctx);
  const flush=async()=>{for(let i=0;i<20;i++)await Promise.resolve();};
  const send=ctx.oi('room',{name:'alice'},'task','thread',[]);
  await flush();assert.ok(entered);
  let completed=false;
  const stop=ctx.zl('room','thread').then(value=>{completed=true;return value;});
  await flush();
  assert.equal(events.some(e=>e.kind==='stopped'),false,'Stop must not claim idle while an old send can still arrive');
  if(phase!=='timeout')release();
  for(let i=0;i<150&&!completed;i++){
    await flush();const timer=timers.shift();if(timer){clock+=timer.delay;timer.fn();}
  }
  await flush();assert.ok(completed,'Stop must settle within a bounded interval');
  const result=await stop;
  if(phase==='timeout'){
    assert.equal(result,false);assert.ok(state.room.stopError);assert.equal(state.room.stopping,false);
    assert.equal(events.some(e=>e.kind==='stopped'),false);
    release();await send;
    assert.equal(await ctx.zl('room','thread'),true,'Timed-out stop must be retryable');
  }else{
    assert.equal(result,true);await send;
  }
  assert.ok(checked>0,'Stop must check a session created while it was waiting');
  assert.equal(submits,phase==='submit'?1:0,'Cancelled preparation must never submit');
  assert.equal(state.room.stopError,null);
}
await stopSendRace('prepare');
await stopSendRace('submit');
await stopSendRace('timeout');
console.log('PASS: integrated deferred preparation/submission, stop timeout and retry');

let now=0, attempts=0, fail=true;
const bootstrap=vm.createContext({_o:false, Date:{now:()=>now},
  Ic:{request:async()=>{attempts++;if(fail)throw Error('temporary disconnect');return {soul:'configured'};}},
  _c:()=>true,ts:()=>'',
});
vm.runInContext(segment('var es=new Set', 'function Dc('),bootstrap);
const flush=()=>new Promise(resolve=>setImmediate(resolve));
bootstrap.Bc([{name:'alice'}]);await flush();
assert.equal(attempts,1);
bootstrap.Bc([{name:'alice'}]);await flush();
assert.equal(attempts,1,'No immediate retry storm');
now=6000;fail=false;
bootstrap.Bc([{name:'alice'}]);await flush();
assert.equal(attempts,2,'Transient failure must retry');
now=60000;bootstrap.Bc([{name:'alice'}]);await flush();
assert.equal(attempts,2,'Success must be cached');
fail=true;
for(let i=0;i<8;i++){now+=60000;bootstrap.Bc([{name:'bob'}]);await flush();}
assert.equal(attempts,5,'Persistent failures are capped at three attempts per bot');
console.log('PASS: legacy setup retries transient failures with bounded backoff');
