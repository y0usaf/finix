// Reuse the installed module's backend safety tests unchanged. Old UI
// expectations (boxed menu headers, substituted Bot Chat titles) are superseded
// by roster.test.mjs; this suite deliberately excludes only those UI checks.
import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
import vm from 'node:vm';
const source=readFileSync(process.argv[2],'utf8');
const original=readFileSync(process.argv[3] || new URL('./test_bots_mod.mjs',import.meta.url),'utf8');
const listing=original.slice(original.indexOf('const allSessions='),original.indexOf('const rosterSource='));
const backend=original.slice(original.indexOf('const ps ='));
const AsyncFunction=Object.getPrototypeOf(async function(){}).constructor;
await new AsyncFunction('source','assert','vm',listing+'\n'+backend)(source,assert,vm);
console.log('PASS: complete listing and existing backend safety regressions');
