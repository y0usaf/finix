import {readFileSync,writeFileSync} from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const source=readFileSync(process.argv[2],'utf8');
const segment=(start,end)=>source.slice(source.indexOf(start),source.indexOf(end,source.indexOf(start)));
const atom=v=>({get:()=>v,set:n=>{v=n;}});
const state={profile:atom('alice'),connectionId:atom('local'),gateway:atom('open'),focusedStoredSessionId:atom('other'),focusedSessionOwner:atom({connectionId:'local',profile:'alice'})};
const bot={name:'alice',connectionId:'local',canonical_session:{id:'canonical'}};
const rows=[{id:'canonical',title:'Bot Chat',running:false,last_active:100},{id:'other',title:'Fix UI',running:true,last_active:200}];
const opened=[],writes=[];
let persisted={};
const storage={get:async()=>persisted,set:async(k,v)=>{persisted=JSON.parse(JSON.stringify(v));writes.push([k,v]);}};
const ctx=vm.createContext({console,Promise,JSON,Date,Map,
 Pe:{state,openSession:async(id,opts)=>opened.push([id,opts]),notifyError:err=>{throw err;}},
 le:()=>({storage}),Yq:atom,botsModPins:atom({}),botsModPinsLoaded:false,botsModPinWrite:Promise.resolve(),
 fc:()=>({t:{sidebar:{row:{}},common:{delete:'Delete'}}}),te:()=>({bot:{},roster:{}}),Ip:v=>[v,()=>{}],or:()=>{},
 rc:()=>({data:rows}),oc:x=>x,Xt:a=>a.get(),
 ln:atom(null),dt:atom(null),Rn:atom(null),fe:atom(null),B:atom({}),yn:atom({}),Wn:()=>null,j:()=>({}),fo:()=>false,Fr:()=>false,kt:()=>({available:true}),at:()=>[],Xl:()=>false,Wt:()=>true,
 Rt:()=>({}),Ut:()=>null,wi:()=>false,Yo:b=>b.canonical_session?.id,Ne:b=>b.name,Y:b=>b.name,Ql:()=>({}),Mo:x=>x,ee:x=>x,U:b=>b.name,et:()=> 'bot:alice',an:()=>true,
 q:(type,props)=>({type,props}),ot:(type,props,key)=>({type,props,key}),Zt:(...xs)=>xs.filter(Boolean).join(' '),We:()=>'',gc:n=>String(n),
 Gn:'icon',je:'avatar',ho:'tip',Gp:'lead',Pp:'status',pc:'row',cc:'context',dc:'context-trigger',uc:'context-content',Ft:'context-item',Vo:'context-separator',mu:'dropdown',fu:'dropdown-trigger',pu:'dropdown-content',_n:'dropdown-item',ji:'dropdown-separator'
});
vm.runInContext(segment('function botsModSessionLabel(','function rc('),ctx);
vm.runInContext(segment('const botsModLifecycleCss=', 'function yc('),ctx);
const walk=node=>node&&typeof node==='object'?[node,...[node.props?.children].flat(Infinity).flatMap(walk)]:[];
const render=()=>walk(ctx.hc({bot,onDelete:()=>{},onEdit:()=>{},onGroup:()=>{}}));
let tree=render();
assert.ok(!tree.some(n=>typeof n.props?.children==='string'&&/activity unavailable|running ·|idle ·/.test(n.props.children)),'Activity text must not be rendered');
const titleNode=tree.find(n=>n.type==='span'&&n.props.children==='Fix UI');
const statusNode=tree.find(n=>n.type==='span'&&n.props.children==='200000');
const rowButton=tree.find(n=>n.type==='button'&&n.props?.title==='Fix UI');
assert.ok([rowButton.props.children].flat().includes(titleNode)&&[rowButton.props.children].flat().includes(statusNode),'Title and metadata must share the native row');
assert.equal(titleNode.props.style.flex,'1 1 0%');
assert.equal(titleNode.props.style.minWidth,0);
assert.equal(statusNode.props.style.textAlign,'right','Metadata must be right-aligned like native Sessions');
assert.equal(statusNode.props.style.flex,'0 0 auto');
assert.equal(statusNode.props.style.maxWidth,'4rem');
assert.equal(statusNode.props.style.marginLeft,'0.25rem');
assert.equal(statusNode.props.style.overflow,'hidden','Metadata must not overlap the title');
assert.equal(titleNode.props.style.display,'block');
assert.ok(tree.some(n=>n.type==='dropdown-trigger'),'Bot must use an actual primary-click DropdownMenuTrigger, not ContextMenuTrigger');
const headerTrigger=tree.find(n=>n.type==='dropdown-trigger');
const headerButton=headerTrigger.props.children;
const headerGroup=[headerButton.props.children].flat().find(n=>n?.props?.style?.justifyContent==='center');
assert.ok(headerGroup,'Bot icon/title must be an in-flow centered group');
assert.equal(headerGroup.props.style.minWidth,0);
assert.equal(headerGroup.props.style.flex,'1 1 0%');
assert.equal(headerButton.props.style.minHeight,'2.25rem');
assert.equal(headerButton.props.style.height,'2.25rem');
assert.equal(headerButton.props.style.display,'flex');
assert.match(headerButton.props.className,/px-0\.5 py-0\.5/);
const outer=tree.find(n=>n.type==='div'&&n.props?.style?.border==='1px solid var(--ui-stroke-tertiary)');
assert.ok(outer,'Header and sessions must share one subtle outer bot container');
assert.equal(outer.props.style.borderRadius,'var(--radius-md)');
assert.equal(outer.props.style.overflow,'visible','Lifecycle shine must remain unclipped');
assert.equal(outer.props.style.padding,'0.125rem');
assert.equal(outer.props.children[1].type,'dropdown');
assert.equal(outer.props.children[2].type,'div');
assert.equal(outer.props.style.background,'transparent');
assert.equal(headerTrigger.props.children.props.onClick,undefined,'Bot header must not navigate');
let selected=tree.filter(n=>n.props?.['aria-current']==='page');
assert.equal(selected.length,1);assert.equal(selected[0].props.title,'Fix UI');
selected[0].props.onClick();await Promise.resolve();assert.equal(opened[0][0],'other');assert.equal(opened[0][1].tabTitle,'Fix UI');
state.focusedStoredSessionId.set('canonical');tree=render();selected=tree.filter(n=>n.props?.['aria-current']==='page');assert.equal(selected.length,1);assert.equal(selected[0].props.title,'Chat with @alice');
state.focusedSessionOwner.set({connectionId:'remote',profile:'alice'});assert.equal(render().filter(n=>n.props?.['aria-current']==='page').length,0,'Same ID on another source must not select local session');
state.focusedSessionOwner.set({connectionId:'local',profile:'alice'});
assert.ok(!render().some(n=>/^(Unpin|Pin)( |$)/.test(n.props?.['aria-label']||'')||/^(Unpin|Pin to top)$/.test(n.props?.children||'')), 'No session or bot pin controls');
const dots=render().filter(n=>n.type==='status');
assert.deepEqual(dots.map(n=>n.props.storedSessionId),rows.map(n=>n.id),'Every row uses the native lifecycle dot keyed by stored id');
assert.equal(render().filter(n=>n.props?.className==='arc-border arc-row').length,rows.length,'Every row provides the native arc controlled by its lifecycle dot');
assert.ok(render().some(n=>n.props?.children==='200000'));assert.ok(render().some(n=>n.props?.children==='100000'));
rows.push({id:'unknown',title:'A meaningful session title with missing activity metadata'});
assert.ok(!render().some(n=>typeof n.props?.children==='string'&&/activity unavailable|running ·|idle ·/.test(n.props.children)));
const unknown=render().find(n=>n.props?.title==='A meaningful session title with missing activity metadata');
assert.ok(![unknown.props.children].flat(Infinity).some(child=>child?.props?.children==='last active unavailable'),'Missing activity metadata is omitted');
if(process.env.BOTS_UI_TREE){writeFileSync(process.env.BOTS_UI_TREE,JSON.stringify(render()));}
console.log('PASS: real roster rendering, dropdown trigger, focused selection/source isolation, open handler, no pins, native lifecycle dots/arcs and last-active metadata');
