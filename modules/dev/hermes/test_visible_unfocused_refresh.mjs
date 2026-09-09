// Tests the visible-unfocused data refresh behavior against the ACTUAL upstream
// source files (paths given in argv), using the same vm + stripTypeScriptTypes
// pattern as test_plugin_policy.mjs.
//
// Usage: node test_visible_unfocused_refresh.mjs <use-background-sync.ts> <use-status-snapshot.ts>
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';

const [bgSyncPath, statusPath] = process.argv.slice(2);

function loadModule(path, stubs) {
  let src = readFileSync(path, 'utf8');
  // Strip import statements (single- and multi-line, incl. `import type`).
  src = src.replace(/^import[\s\S]*?from\s+['"][^'"]*['"];?[ \t]*$/gm, '');
  src = src.replace(/^import\s+['"][^'"]*['"];?[ \t]*$/gm, '');
  src = src.replace(/^export (?=(async function|function|const|let|class|interface|type))/gm, '');
  const ctx = vm.createContext(stubs);
  vm.runInContext(stripTypeScriptTypes(src), ctx, {filename: path});
  return ctx;
}

// ---------------------------------------------------------------------------
// 1) use-background-sync.ts — windowIsActivelyViewed + visiblePoll gating
// ---------------------------------------------------------------------------
{
  const timers = {intervals: [], cleared: new Set()};
  let id = 0;
  const listeners = {doc: {}, win: {}};
  const view = {visibility: 'visible', focused: true};

  const ctx = loadModule(bgSyncPath, {
    window: {
      setInterval: (fn, ms) => {
        const handle = ++id;
        timers.intervals.push({handle, fn, ms});
        return handle;
      },
      clearInterval: h => timers.cleared.add(h),
      addEventListener: (t, fn) => (listeners.win[t] = fn),
      removeEventListener: () => {}
    },
    document: {
      get visibilityState() {
        return view.visibility;
      },
      hasFocus: () => view.focused,
      addEventListener: (t, fn) => (listeners.doc[t] = fn),
      removeEventListener: () => {}
    },
    $onBattery: {get: () => false, listen: () => () => {}},
    batteryPollInterval: ms => ms
  });

  const activeIntervals = () => timers.intervals.filter(t => !timers.cleared.has(t.handle));

  // Visible + UNFOCUSED must still be considered actively viewed (data refresh).
  assert.equal(ctx.windowIsActivelyViewed({focused: false, visibilityState: 'visible'}), true,
    'visible+unfocused must count as actively viewed');

  // Hidden must pause even when focused.
  assert.equal(ctx.windowIsActivelyViewed({focused: true, visibilityState: 'hidden'}), false,
    'hidden must pause polls');

  // The caller still passes focus through (call-shape unchanged).
  assert.equal(ctx.windowIsActivelyViewed({focused: true, visibilityState: 'visible'}), true);

  // visiblePoll: visible+unfocused ticks fire; hidden does not; refocus does not
  // stack a second interval.
  let ticks = 0;
  const dispose = ctx.visiblePoll(1500, () => ticks++);
  view.focused = false;
  activeIntervals()[0].fn();
  assert.equal(ticks, 1, 'visible+unfocused interval tick must fire');

  view.visibility = 'hidden';
  activeIntervals()[0].fn();
  assert.equal(ticks, 1, 'hidden interval tick must not fire');

  listeners.win['focus']();
  assert.equal(ticks, 1, 'focus listener must not tick while hidden');
  assert.equal(activeIntervals().length, 1, 'refocus must not create a second interval');

  listeners.doc['visibilitychange'](); // visible again
  view.visibility = 'visible';
  activeIntervals()[0].fn();
  assert.equal(ticks, 2, 'visible+unfocused tick fires again after returning');
  assert.equal(activeIntervals().length, 1, 'still exactly one interval');

  dispose();
  assert.equal(activeIntervals().length, 0, 'dispose clears the interval');

  console.log('PASS use-background-sync: visible+unfocused polls fire, hidden pauses, refocus never stacks timers');
}

// ---------------------------------------------------------------------------
// 2) use-status-snapshot.ts — refresh gate + single-chain timer discipline
// ---------------------------------------------------------------------------
{
  const view = {visibility: 'visible', focused: false};
  let statusCalls = 0;
  let resolveFirst;
  const firstStatus = new Promise(r => (resolveFirst = r));

  const pending = [];
  const cleared = new Set();
  let timerId = 0;
  const docListeners = {};
  const winListeners = {};
  const stateUpdates = [];

  const ctx = loadModule(statusPath, {
    window: {
      setTimeout: (fn, ms) => {
        const h = ++timerId;
        pending.push({h, fn, ms});
        return h;
      },
      clearTimeout: h => cleared.add(h),
      addEventListener: (t, fn) => (winListeners[t] = fn),
      removeEventListener: () => {}
    },
    document: {
      get visibilityState() {
        return view.visibility;
      },
      hasFocus: () => view.focused,
      addEventListener: (t, fn) => (docListeners[t] = fn),
      removeEventListener: () => {}
    },
    useState: init => [init, v => stateUpdates.push(v)],
    useEffect: fn => void fn(),
    getStatus: () => {
      statusCalls++;
      return statusCalls === 1 ? firstStatus : Promise.resolve({ok: true});
    },
    evaluateRuntimeReadiness: () => Promise.resolve({source: 'runtime_check'}),
    requestGateway: () => Promise.resolve({})
  });

  const activeTimers = () => pending.filter(t => !cleared.has(t.h));

  // The hook starts the initial refresh synchronously when mounted.
  ctx.useStatusSnapshot('open', ctx.requestGateway);

  // Visible + unfocused: the initial refresh must proceed (no focus bail).
  assert.equal(statusCalls, 1, 'initial refresh must run while visible even when unfocused');

  // Concurrent-refresh discipline: while the first poll is in flight, the user
  // refocuses; onReturn fires a catch-up refresh. Both ends schedule the next
  // poll — only ONE chain may survive.
  view.focused = true;
  winListeners['focus']();
  assert.equal(statusCalls, 2, 'refocus catch-up refresh fires while visible');

  resolveFirst({ok: true});
  await Promise.resolve();
  await new Promise(r => setImmediate(r));
  // Both in-flight refreshes resolved; each schedules the next poll in `finally`.
  assert.equal(activeTimers().length, 1,
    `overlapping refreshes must leave exactly one pending timer, got ${activeTimers().length}`);

  // Hidden: next scheduled tick must pause (no RPC) and keep re-scheduling.
  view.visibility = 'hidden';
  activeTimers()[0].fn();
  await new Promise(r => setImmediate(r));
  assert.equal(statusCalls, 2, 'hidden tick must not issue RPCs');
  assert.equal(activeTimers().length, 1, 'hidden still reschedules (pause, not stop)');

  // Refocus while hidden→visible transition: visibilitychange listener catch-up.
  view.visibility = 'visible';
  docListeners['visibilitychange']();
  await new Promise(r => setImmediate(r));
  assert.equal(statusCalls, 3, 'visibilitychange catch-up fires when visible');
  assert.equal(activeTimers().length, 1, 'still exactly one chain after catch-up');

  console.log('PASS use-status-snapshot: visible+unfocused refreshes, hidden pauses, refocus leaves one timer chain');
}

console.log('PASS all visible-unfocused refresh tests');
