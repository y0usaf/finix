import { current, forget, held, label, list, meta, NAME, names, pending, reveal, scopes, share, store, type Request, type Scope } from "./store";

const USAGE = `usage: omp-secret [COMMAND]
  (nothing)                              secrets omp chats and bots asked for and haven't got, and the ones set
  NAME [--bot BOT | --user] [--ttl TTL]  enter NAME's value, masked, for the bot that asked, else shared (--user): every bot without its own NAME and your own chats read it (TTL: 30m, 12h, 7d or never; default the ask's, else 24h)
  list [--bot BOT | --user]              set secrets: scope, name, when set, when they expire; never values
  forget NAME [--bot BOT | --user]       delete a secret now
  sync [--bot BOT]                       copy the shared secrets into boxed bots' own stores (omp-bot-box runs it before a boxed bot starts)
  run                                    run the command on stdin with its $SECRET_ names set (the bot's own, else the shared one) and their values redacted (omp's bash hook uses it)`;

function fail(message: string): never {
	console.error(`omp-secret: ${message}`);
	process.exit(1);
}

function flags(args: string[]): { rest: string[]; opts: Record<string, string>; scope?: { bot: Scope } } {
	const rest: string[] = [];
	const opts: Record<string, string> = {};
	let scope: { bot: Scope } | undefined;
	for (let i = 0; i < args.length; i++) {
		if (args[i] === "--bot" || args[i] === "--ttl") {
			if (i + 1 >= args.length) fail(`${args[i]} needs a value`);
			opts[args[i].slice(2)] = args[++i];
		} else if (args[i] === "--user") scope = { bot: undefined };
		else rest.push(args[i]);
	}
	if (opts.bot !== undefined) scope = { bot: opts.bot };
	return { rest, opts, scope };
}

function when(ms: number | null): string {
	if (ms === null) return "never";
	const d = new Date(ms);
	const two = (n: number) => String(n).padStart(2, "0");
	return `${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())} ${two(d.getHours())}:${two(d.getMinutes())}`;
}

function show(only?: { bot: Scope }) {
	const rows = (only ? [only.bot] : scopes()).flatMap(bot => list(bot).map(found => ({ scope: label(bot), ...found })));
	if (rows.length === 0) return console.log("No secrets set.");
	for (const row of rows) console.log(`${row.scope}\t${row.name}\tset ${when(row.set)}\texpires ${when(row.expires)}${row.reason ? `\t${row.reason}` : ""}`);
}

function asked(): Request[] {
	return pending().filter(entry => !meta(entry.bot, entry.name));
}

function flag(bot: Scope): string {
	return bot ? ` --bot ${JSON.stringify(bot)}` : " --user";
}

async function masked(prompt: string): Promise<string> {
	const stdin = process.stdin;
	if (!stdin.isTTY) {
		const text = await new Response(Bun.stdin.stream()).text();
		return text.replace(/\r?\n$/, "");
	}
	process.stderr.write(prompt);
	stdin.setRawMode(true);
	stdin.resume();
	return new Promise((resolve, reject) => {
		let value = "";
		const done = (error?: Error) => {
			stdin.setRawMode(false);
			stdin.pause();
			stdin.off("data", onData);
			process.stderr.write("\n");
			error ? reject(error) : resolve(value);
		};
		const onData = (chunk: Buffer) => {
			for (const char of chunk.toString("utf8")) {
				if (char === "\r" || char === "\n") return done();
				if (char === "\u0003" || char === "\u0004") return done(new Error("cancelled"));
				if (char === "\u007f" || char === "\b") {
					if (value.length > 0) {
						value = [...value].slice(0, -1).join("");
						process.stderr.write("\b \b");
					}
					continue;
				}
				if (char === "\u0015") {
					process.stderr.write("\b \b".repeat([...value].length));
					value = "";
					continue;
				}
				if (char < " ") continue;
				value += char;
				process.stderr.write("*");
			}
		};
		stdin.on("data", onData);
	});
}

function pick(name: string, scope: { bot: Scope } | undefined, candidates: Scope[], what: string, fallback: boolean): Scope {
	if (scope) return scope.bot;
	if (candidates.length === 1) return candidates[0];
	if (candidates.length === 0) {
		if (fallback) return undefined;
		fail(`nothing ${what} ${name}`);
	}
	fail(`${candidates.map(label).join(", ")} ${what} ${name}; pass --bot BOT or --user`);
}

function redactor(values: [string, Buffer][], out: NodeJS.WriteStream) {
	let held = Buffer.alloc(0);
	const partial = (rest: Buffer) => {
		let best = 0;
		for (const [, value] of values) {
			for (let k = Math.min(value.length - 1, rest.length); k > best; k--) {
				if (rest.subarray(rest.length - k).equals(value.subarray(0, k))) {
					best = k;
					break;
				}
			}
		}
		return best;
	};
	const scan = (buffer: Buffer, final: boolean) => {
		const parts: Buffer[] = [];
		let at = 0;
		for (;;) {
			let best = -1;
			let hit: [string, Buffer] | undefined;
			for (const entry of values) {
				const index = buffer.indexOf(entry[1], at);
				if (index >= 0 && (best < 0 || index < best || (index === best && entry[1].length > hit![1].length))) {
					best = index;
					hit = entry;
				}
			}
			if (!hit) break;
			parts.push(buffer.subarray(at, best), Buffer.from(`[SECRET_${hit[0]}]`));
			at = best + hit[1].length;
		}
		const keep = final ? 0 : partial(buffer.subarray(at));
		parts.push(buffer.subarray(at, buffer.length - keep));
		held = Buffer.from(buffer.subarray(buffer.length - keep));
		const text = Buffer.concat(parts);
		if (text.length > 0) out.write(text);
	};
	return {
		write: (chunk: Uint8Array) => scan(Buffer.concat([held, chunk]), false),
		end: () => scan(held, true),
	};
}

async function pipe(stream: ReadableStream<Uint8Array>, sink: ReturnType<typeof redactor>) {
	for await (const chunk of stream) sink.write(chunk);
	sink.end();
}

async function run() {
	const bot = current();
	const command = (await new Response(Bun.stdin.stream()).text()).replace(/\n$/, "");
	const env: Record<string, string | undefined> = { ...process.env };
	const values: [string, Buffer][] = [];
	for (const name of names(command)) {
		const found = held(bot, name);
		const value = found && (await reveal(found.scope, name));
		if (value === undefined) fail(`${label(bot)} has no secret ${name}, or it expired; ask for it with the secret tool`);
		env[`SECRET_${name}`] = value;
		if (value.length > 0) values.push([name, Buffer.from(value)]);
	}
	const child = Bun.spawn(["bash", "-c", command], { env, stdin: "ignore", stdout: "pipe", stderr: "pipe" });
	for (const signal of ["SIGINT", "SIGTERM", "SIGHUP"] as const) process.on(signal, () => child.kill(signal));
	const out = values.length ? redactor(values, process.stdout) : undefined;
	const err = values.length ? redactor(values, process.stderr) : undefined;
	await Promise.all([
		out ? pipe(child.stdout, out) : (async () => { for await (const chunk of child.stdout) process.stdout.write(chunk); })(),
		err ? pipe(child.stderr, err) : (async () => { for await (const chunk of child.stderr) process.stderr.write(chunk); })(),
	]);
	process.exit(await child.exited);
}

const [command, ...args] = process.argv.slice(2);
const { rest, opts, scope } = flags(args);
switch (command) {
	case undefined: {
		const open = asked();
		if (open.length === 0) console.log("Nothing is waiting for a secret.");
		for (const entry of open) console.log(`${label(entry.bot)} asks for ${entry.name} (${when(entry.at)}): ${entry.reason}\n  omp-secret ${entry.name}${open.filter(other => other.name === entry.name).length > 1 ? flag(entry.bot) : ""}`);
		console.log("");
		show();
		break;
	}
	case "list":
		show(scope);
		break;
	case "forget": {
		const name = rest[0];
		if (!name || !NAME.test(name)) fail(USAGE);
		const bot = pick(name, scope, scopes().filter(b => meta(b, name)), "holds", false);
		if (!forget(bot, name)) fail(`${label(bot)} has no secret ${name}`);
		console.log(`Forgot ${label(bot)}'s ${name}.`);
		break;
	}
	case "run":
		await run();
		break;
	case "sync":
		await share(opts.bot).catch(error => fail(error.message));
		break;
	case "-h":
	case "--help":
		console.log(USAGE);
		break;
	default: {
		if (!NAME.test(command)) fail(`'${command}' is not a secret name (capitals, digits and _, starting with a capital)\n${USAGE}`);
		const asking = asked().filter(entry => entry.name === command);
		const bot = pick(command, scope, [...new Set(asking.map(entry => entry.bot))], "asked for", true);
		const ask = asking.find(entry => entry.bot === bot);
		if (ask) console.error(`${label(bot)} asks for ${command}: ${ask.reason}`);
		const value = await masked(`${command} for ${label(bot)} (hidden): `).catch(() => fail("cancelled"));
		if (value === "") fail("empty value, nothing stored");
		const found = await store(bot, command, value, opts.ttl ?? ask?.ttl, ask?.reason).catch(error => fail(error.message));
		console.error(`Stored ${command} for ${label(bot)}, expires ${when(found.expires)}.`);
	}
}
