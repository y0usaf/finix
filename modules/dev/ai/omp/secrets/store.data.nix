''
  import { chmodSync, existsSync, mkdirSync, readdirSync, readFileSync, renameSync, rmSync, statSync, writeFileSync } from "node:fs";
  import { homedir } from "node:os";
  import { join } from "node:path";

  export const NAME = /^[A-Z][A-Z0-9_]{0,63}$/;
  export const REFERENCE = /\$\{?SECRET_([A-Z][A-Z0-9_]{0,63})/g;
  const STATE = process.env.XDG_STATE_HOME || join(homedir(), ".local", "state");
  // OMP_SECRETS_DIR moves the store: omp-bot points a boxed bot's at a folder of its own shared into the box, where
  // the shared secrets are a copy the host keeps in step.
  const BOXED = Boolean(process.env.OMP_SECRETS_DIR);
  export const ROOT = process.env.OMP_SECRETS_DIR || join(STATE, "omp-secrets");
  const BOTS = process.env.OMP_BOT_STATE || join(STATE, "omp-bot");
  const DEFAULT_TTL = "24h";

  // A scope is one bot's secrets, or undefined: the shared ones, which every bot without its own copy reads and your
  // own omp chats use.
  export type Scope = string | undefined;
  export type Meta = { name: string; reason?: string; set: number; expires: number | null };
  export type Request = { bot?: string; name: string; reason: string; ttl?: string; at: number };

  export function current(): Scope {
  	return process.env.OMP_BOT_NAME || undefined;
  }

  export function label(bot: Scope): string {
  	return bot ?? "shared";
  }

  // The bots omp-bot runs in its box (bots.json "box": true); seen from the host only, since in a box the store is
  // already that bot's own.
  export function boxed(): string[] {
  	if (BOXED) return [];
  	const roster = readJson<{ name?: unknown; box?: unknown }[]>(join(BOTS, "bots.json"), []);
  	return Array.isArray(roster) ? roster.filter(bot => bot?.box === true && typeof bot.name === "string").map(bot => bot.name as string) : [];
  }

  // The store a scope's secrets live in: a boxed bot's own folder, which its box shares, else this one.
  function root(bot: Scope): string {
  	return bot && boxed().includes(bot) ? join(BOTS, "bots", bot, "secrets") : ROOT;
  }

  function keyFile(base: string): string {
  	return join(base, "secrets.key");
  }

  export function dir(bot: Scope): string {
  	return bot ? join(root(bot), "bots", bot) : join(ROOT, "user");
  }

  export function scopes(): Scope[] {
  	const bots = join(ROOT, "bots");
  	const found = new Set<string>(existsSync(bots) ? readdirSync(bots) : []);
  	for (const bot of boxed()) if (existsSync(dir(bot))) found.add(bot);
  	return [...(existsSync(dir(undefined)) ? [undefined] : []), ...found];
  }

  export function names(command: string): string[] {
  	return [...new Set([...command.matchAll(REFERENCE)].map(match => match[1]))];
  }

  export function ttl(text: string | undefined): number | null {
  	const value = text || DEFAULT_TTL;
  	if (value === "never") return null;
  	const match = /^(\d+)(m|h|d)$/.exec(value);
  	if (!match || Number(match[1]) === 0) throw new Error(`bad expiry ''\'''${value}': use 30m, 12h, 7d or never`);
  	return Number(match[1]) * { m: 60_000, h: 3_600_000, d: 86_400_000 }[match[2] as "m" | "h" | "d"];
  }

  function own(path: string) {
  	mkdirSync(path, { recursive: true, mode: 0o700 });
  	chmodSync(path, 0o700);
  }

  function readJson<T>(path: string, fallback: T): T {
  	try {
  		return JSON.parse(readFileSync(path, "utf8"));
  	} catch {
  		return fallback;
  	}
  }

  function writeJson(path: string, value: unknown) {
  	const tmp = `''${path}.''${process.pid}.tmp`;
  	writeFileSync(tmp, `''${JSON.stringify(value, null, "\t")}\n`, { mode: 0o600 });
  	renameSync(tmp, path);
  }

  function remove(base: string): boolean {
  	const had = existsSync(`''${base}.age`);
  	rmSync(`''${base}.age`, { force: true });
  	rmSync(`''${base}.json`, { force: true });
  	return had;
  }

  export function forget(bot: Scope, name: string): boolean {
  	const had = remove(join(dir(bot), name));
  	if (!bot) for (const other of boxed()) remove(join(root(other), "user", name));
  	return had;
  }

  export function meta(bot: Scope, name: string): Meta | undefined {
  	const base = join(dir(bot), name);
  	if (!existsSync(`''${base}.age`)) return undefined;
  	const found = readJson<Meta | undefined>(`''${base}.json`, undefined);
  	if (!found || (found.expires !== null && found.expires <= Date.now())) {
  		forget(bot, name);
  		return undefined;
  	}
  	return found;
  }

  // Where a bot finds a secret: its own copy wins, else the shared one.
  export function held(bot: Scope, name: string): { scope: Scope; meta: Meta } | undefined {
  	const mine = meta(bot, name);
  	if (mine) return { scope: bot, meta: mine };
  	const shared = bot ? meta(undefined, name) : undefined;
  	return shared ? { scope: undefined, meta: shared } : undefined;
  }

  export function list(bot: Scope): Meta[] {
  	if (!existsSync(dir(bot))) return [];
  	return readdirSync(dir(bot))
  		.filter(file => file.endsWith(".age"))
  		.map(file => meta(bot, file.slice(0, -4)))
  		.filter((found): found is Meta => found !== undefined);
  }

  async function age(args: string[], input?: string): Promise<string> {
  	const child = Bun.spawn(["age", ...args], { stdin: input === undefined ? "ignore" : new Blob([input]), stdout: "pipe", stderr: "pipe" });
  	const [stdout, stderr, code] = await Promise.all([new Response(child.stdout).text(), new Response(child.stderr).text(), child.exited]);
  	if (code !== 0) throw new Error(`age: ''${stderr.trim()}`);
  	return stdout;
  }

  async function key(base: string) {
  	if (existsSync(keyFile(base))) return;
  	own(base);
  	const child = Bun.spawn(["age-keygen", "-o", keyFile(base)], { stdout: "ignore", stderr: "pipe" });
  	const [stderr, code] = await Promise.all([new Response(child.stderr).text(), child.exited]);
  	if (code !== 0) throw new Error(`age-keygen: ''${stderr.trim()}`);
  	chmodSync(keyFile(base), 0o600);
  }

  export async function reveal(bot: Scope, name: string): Promise<string | undefined> {
  	if (!meta(bot, name)) return undefined;
  	return age(["-d", "-i", keyFile(root(bot)), join(dir(bot), `''${name}.age`)]);
  }

  export function modified(bot: Scope, name: string): number {
  	try {
  		return statSync(join(dir(bot), `''${name}.age`)).mtimeMs;
  	} catch {
  		return 0;
  	}
  }

  async function seal(base: string, folder: string, found: Meta, value: string) {
  	await key(base);
  	own(folder);
  	const file = join(folder, found.name);
  	const cipher = await age(["-e", "-a", "-i", keyFile(base)], value);
  	writeFileSync(`''${file}.age.tmp`, cipher, { mode: 0o600 });
  	renameSync(`''${file}.age.tmp`, `''${file}.age`);
  	writeJson(`''${file}.json`, found);
  }

  export async function store(bot: Scope, name: string, value: string, expiry: string | undefined, reason?: string): Promise<Meta> {
  	const life = ttl(expiry);
  	const now = Date.now();
  	const found: Meta = { name, reason, set: now, expires: life === null ? null : now + life };
  	await seal(root(bot), dir(bot), found, value);
  	settle(bot, name);
  	if (!bot) await share();
  	return found;
  }

  // Copies the shared secrets into each boxed bot's store (or only BOT's), sealed with that store's own key, and drops
  // copies no longer shared, so a bot in a box reads them without the host's key. Store and forget keep it in step;
  // omp-bot-box runs it before a boxed bot starts.
  export async function share(only?: string) {
  	const shared = list(undefined);
  	for (const bot of boxed()) {
  		if (only !== undefined && bot !== only) continue;
  		const base = root(bot);
  		const folder = join(base, "user");
  		const keep = new Set(shared.map(found => found.name));
  		if (existsSync(folder)) for (const file of readdirSync(folder)) if (file.endsWith(".age") && !keep.has(file.slice(0, -4))) remove(join(folder, file.slice(0, -4)));
  		for (const found of shared) {
  			const copy = readJson<Meta | undefined>(join(folder, `''${found.name}.json`), undefined);
  			if (copy?.set === found.set && existsSync(join(folder, `''${found.name}.age`))) continue;
  			const value = await reveal(undefined, found.name);
  			if (value !== undefined) await seal(base, folder, found, value);
  		}
  	}
  }

  function requestsFile(bot: Scope): string {
  	return join(dir(bot), "requests.json");
  }

  export function request(bot: Scope, name: string, reason: string, expiry?: string) {
  	own(dir(bot));
  	const open = readJson<Request[]>(requestsFile(bot), []).filter(entry => entry.name !== name);
  	open.push({ bot, name, reason, ttl: expiry, at: Date.now() });
  	writeJson(requestsFile(bot), open);
  }

  export function settle(bot: Scope, name: string) {
  	const open = readJson<Request[]>(requestsFile(bot), []);
  	const left = open.filter(entry => entry.name !== name);
  	if (left.length !== open.length) writeJson(requestsFile(bot), left);
  }

  export function pending(): Request[] {
  	return scopes().flatMap(bot => readJson<Request[]>(requestsFile(bot), []));
  }
''
