import { chmodSync, existsSync, mkdirSync, readdirSync, readFileSync, renameSync, rmSync, statSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export const NAME = /^[A-Z][A-Z0-9_]{0,63}$/;
export const REFERENCE = /\$\{?SECRET_([A-Z][A-Z0-9_]{0,63})/g;
export const ROOT = join(process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"), "omp-secrets");
export const KEY = join(ROOT, "secrets.key");
const DEFAULT_TTL = "24h";

export type Scope = string | undefined;
export type Meta = { name: string; reason?: string; set: number; expires: number | null };
export type Request = { bot?: string; name: string; reason: string; ttl?: string; at: number };

export function current(): Scope {
	return process.env.OMP_BOT_NAME || undefined;
}

export function label(bot: Scope): string {
	return bot ?? "user";
}

export function dir(bot: Scope): string {
	return bot ? join(ROOT, "bots", bot) : join(ROOT, "user");
}

export function scopes(): Scope[] {
	const bots = join(ROOT, "bots");
	return [...(existsSync(dir(undefined)) ? [undefined] : []), ...(existsSync(bots) ? readdirSync(bots) : [])];
}

export function names(command: string): string[] {
	return [...new Set([...command.matchAll(REFERENCE)].map(match => match[1]))];
}

export function ttl(text: string | undefined): number | null {
	const value = text || DEFAULT_TTL;
	if (value === "never") return null;
	const match = /^(\d+)(m|h|d)$/.exec(value);
	if (!match || Number(match[1]) === 0) throw new Error(`bad expiry '${value}': use 30m, 12h, 7d or never`);
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
	const tmp = `${path}.${process.pid}.tmp`;
	writeFileSync(tmp, `${JSON.stringify(value, null, "\t")}\n`, { mode: 0o600 });
	renameSync(tmp, path);
}

export function forget(bot: Scope, name: string): boolean {
	const base = join(dir(bot), name);
	const had = existsSync(`${base}.age`);
	rmSync(`${base}.age`, { force: true });
	rmSync(`${base}.json`, { force: true });
	return had;
}

export function meta(bot: Scope, name: string): Meta | undefined {
	const base = join(dir(bot), name);
	if (!existsSync(`${base}.age`)) return undefined;
	const found = readJson<Meta | undefined>(`${base}.json`, undefined);
	if (!found || (found.expires !== null && found.expires <= Date.now())) {
		forget(bot, name);
		return undefined;
	}
	return found;
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
	if (code !== 0) throw new Error(`age: ${stderr.trim()}`);
	return stdout;
}

async function key() {
	if (existsSync(KEY)) return;
	own(ROOT);
	const child = Bun.spawn(["age-keygen", "-o", KEY], { stdout: "ignore", stderr: "pipe" });
	const [stderr, code] = await Promise.all([new Response(child.stderr).text(), child.exited]);
	if (code !== 0) throw new Error(`age-keygen: ${stderr.trim()}`);
	chmodSync(KEY, 0o600);
}

export async function reveal(bot: Scope, name: string): Promise<string | undefined> {
	if (!meta(bot, name)) return undefined;
	return age(["-d", "-i", KEY, join(dir(bot), `${name}.age`)]);
}

export function modified(bot: Scope, name: string): number {
	try {
		return statSync(join(dir(bot), `${name}.age`)).mtimeMs;
	} catch {
		return 0;
	}
}

export async function store(bot: Scope, name: string, value: string, expiry: string | undefined, reason?: string): Promise<Meta> {
	const life = ttl(expiry);
	await key();
	own(dir(bot));
	const base = join(dir(bot), name);
	const cipher = await age(["-e", "-a", "-i", KEY], value);
	const now = Date.now();
	const found: Meta = { name, reason, set: now, expires: life === null ? null : now + life };
	writeFileSync(`${base}.age.tmp`, cipher, { mode: 0o600 });
	renameSync(`${base}.age.tmp`, `${base}.age`);
	writeJson(`${base}.json`, found);
	settle(bot, name);
	return found;
}

function requestsFile(bot: Scope): string {
	return join(dir(bot), "requests.json");
}

export function request(bot: Scope, name: string, reason: string, expiry?: string) {
	own(ROOT);
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
