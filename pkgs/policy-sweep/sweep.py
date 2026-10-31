#!/usr/bin/env python3
import argparse, bisect, collections, fnmatch, json, os, re, shutil, subprocess, sys, tempfile

SKIP_DIRS = {".git","node_modules","target","dist","build","result",".direnv","vendor","ref","corpus",
             "third_party","uv-cache",".venv","venv",".cache",".dioxus","engine-reference","subprojects"}
OWN_OWNERS = {"y0usaf","sylvarant-ai","Inscendai","thepresciencecompany","shodown96"}
LANG_OF_EXT = {"py":"Python","pyi":"Python","rs":"Rust","ts":"TypeScript","tsx":"Tsx","js":"JavaScript",
  "jsx":"JavaScript","mjs":"JavaScript","cjs":"JavaScript","go":"Go","nix":"Nix","lua":"Lua","c":"C","h":"C",
  "cpp":"Cpp","cc":"Cpp","hpp":"Cpp","cxx":"Cpp","cs":"CSharp","zig":"Zig","sh":"Bash","bash":"Bash","rb":"Ruby",
  "swift":"Swift","kt":"Kotlin","scala":"Scala","ex":"Elixir","exs":"Elixir","hs":"Haskell","php":"Php","dart":"Dart"}
KINDS = {"Rust":["line_comment","block_comment"],"Java":["line_comment","block_comment"],
         "Kotlin":["line_comment"],"Scala":["comment","block_comment"],"Dart":["comment","block_comment"]}
DIRECTIVE = [
  r"^#!", r"^//go:", r"^//\+build", r"^#\s*type:", r"^#\s*noqa", r"^#\s*fmt:", r"^#\s*isort:",
  r"^#\s*pyright:", r"^#\s*mypy:", r"coding[:=]", r"^#\s*pylint:", r"^#\s*pragma:",
  r"@ts-expect-error", r"@ts-ignore", r"@ts-nocheck", r"@ts-check", r"eslint", r"biome-ignore",
  r"prettier-ignore", r"@__PURE__", r"///\s*<reference", r"SPDX-License-Identifier", r"shellcheck",
  r"^#\s*strictix:", r"nolint", r"no cover", r"@jsxImportSource", r"@jsxRuntime",
  r"^//\s*SAFETY", r"^---@", r"istanbul ignore", r"c8 ignore", r"v8 ignore", r"jscpd:ignore",
  r"noinspection", r"@flow", r"fallthrough", r"^//\s*@vitest-environment", r"rome-ignore",
  r"@vite-ignore", r"webpackIgnore", r"turbopackIgnore", r"webpackChunkName", r"webpackMode",
  r"@jest-environment", r"Copyright \(c\)", r"Copyright \d{4}", r"Permission is hereby granted",
  r"Apache License", r"MIT License", r"Licensed under", r"@generated", r"DO NOT EDIT",
]
DOC = [r"^///", r"^//!", r"^/\*\*", r"^/\*!"]
KEEP_MD = [r"^README(\.|$)", r"^README$", r"^AGENTS\.md$"]
LEGAL_MD = [r"^LICEN[CS]E", r"^NOTICE", r"^PROVENANCE", r"^THIRD_PARTY"]
_ag = None
def ag():
    global _ag
    if _ag and os.path.exists(_ag): return _ag
    found = shutil.which("ast-grep")
    if found:
        _ag = found; return _ag
    cache = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".ast-grep")
    link = os.path.join(os.path.dirname(cache), "ast-grep-root")
    if os.path.exists(cache):
        path = open(cache).read().strip()
        if os.path.exists(path): _ag = path; return _ag
    subprocess.run(["nix","build","--out-link",link,"nixpkgs#ast-grep"], capture_output=True)
    path = os.path.join(link, "bin", "ast-grep")
    if not os.path.exists(path):
        raise SystemExit("sweep: ast-grep not found on PATH and nixpkgs#ast-grep would not build")
    open(cache,"w").write(path)
    _ag = path
    return _ag

def sh(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)

def git(repo, *args):
    return sh(["git","-C",repo,*args])

def repo_root(gitdir):
    return os.path.dirname(gitdir)

def common_dir(repo):
    p = git(repo,"rev-parse","--path-format=absolute","--git-common-dir")
    return p.stdout.strip() or repo

def discover(root):
    gitdirs = sh(["find",root,"-maxdepth","6","-name",".git","-not","-path","*/.git/*"]).stdout.split()
    groups = {}
    for g in gitdirs:
        d = repo_root(g)
        if any(part in SKIP_DIRS for part in d.split(os.sep)): continue
        rel = os.path.relpath(d, root)
        if any(part.startswith(".") for part in rel.split(os.sep)): continue
        groups.setdefault(common_dir(d), []).append((d, rel))
    repos = []
    for cd, members in groups.items():
        members.sort(key=lambda x: (os.path.isdir(os.path.join(x[0], ".git")) is False,
                                    x[1].startswith("sandbox/"), len(x[1])))
        d, rel = members[0]
        remote = git(d,"remote","get-url","origin").stdout.strip()
        m = re.search(r"[:/]([^/:]+)/([^/]+?)(?:\.git)?$", remote)
        owner = m.group(1) if m else ""
        repos.append({"path":d,"common":cd,"remote":remote,"owner":owner,
                      "clones":[x[0] for x in members[1:]],
                      "zone": rel.split(os.sep)[0],
                      "owned": owner in OWN_OWNERS or (owner == "" and rel.split(os.sep)[0] in {"developing","maintaining"})})
    return repos

def tracked(repo):
    p = git(repo,"ls-files","-z","--cached","--others","--exclude-standard")
    return [f for f in p.stdout.split("\0") if f]

def lang_files(repo):
    out = collections.defaultdict(list)
    for rel in tracked(repo):
        if any(part in SKIP_DIRS for part in rel.split("/")): continue
        e = rel.rsplit(".",1)[-1].lower() if "." in os.path.basename(rel) else ""
        l = LANG_OF_EXT.get(e)
        if l: out[l].append(os.path.join(repo,rel))
    return out

def rule(lang, kinds=None):
    ks = kinds or KINDS.get(lang,["comment"])
    return "id: c\nlanguage: %s\nrule:\n  any:\n%s" % (lang, "".join("    - kind: %s\n" % k for k in ks))

def scan(files, lang, kinds=None):
    if not files: return []
    p = sh([ag(),"scan","--inline-rules",rule(lang,kinds),"--json=stream",*files])
    if p.returncode != 0 and not p.stdout.strip():
        print("sweep: ast-grep failed for %s (%s)" % (lang, (p.stderr or "").strip().splitlines()[:1]), file=sys.stderr)
    out = []
    for line in p.stdout.splitlines():
        if '"ruleId"' in line:
            try: out.append(json.loads(line))
            except ValueError: pass
    return out

def error_nodes(files, lang):
    if not files: return 0
    r = "id: e\nlanguage: %s\nrule:\n  kind: ERROR\n" % lang
    p = sh([ag(),"scan","--inline-rules",r,"--json=stream",*files])
    return sum(1 for l in p.stdout.splitlines() if '"ruleId"' in l)

def classified(text, strip_docs):
    t = text.strip()
    for p in DIRECTIVE:
        if re.search(p, t): return "keep"
    if not strip_docs:
        first = text.lstrip("\n")
        for p in DOC:
            if re.search(p, first): return "keep"
    return "drop"

def md_policy(rel):
    base = rel.rsplit("/",1)[-1]
    for p in KEEP_MD:
        if re.search(p, base): return "keep"
    for p in LEGAL_MD:
        if re.search(p, base): return "legal"
    return "drop"

def inventory(root, strip_docs=False):
    rows = []
    for r in discover(root):
        p = r["path"]
        mds = [(m, md_policy(m)) for m in tracked(p)
               if m.lower().endswith((".md",".mdx")) and not any(x in SKIP_DIRS for x in m.split("/"))]
        per = {}
        for lang, files in lang_files(p).items():
            ms = scan(files, lang)
            keep = sum(1 for m in ms if classified(m["text"], strip_docs)=="keep")
            per[lang] = {"files":len(files),"comments":len(ms),"keep":keep,"drop":len(ms)-keep}
        rows.append({**{k:v for k,v in r.items() if k!="common"}, "md":mds, "langs":per,
                     "md_drop":sum(1 for _,pol in mds if pol=="drop")})
    return rows

def strip_src(src, nodes, strip_docs, containers=()):
    data = src.encode()
    lines = data.split(b"\n")
    starts, off = [], 0
    for l in lines:
        starts.append(off); off += len(l) + 1
    def span(s, e):
        return bisect.bisect_right(starts, s) - 1, bisect.bisect_right(starts, e) - 1
    def line_end(k):
        return starts[k] + len(lines[k])
    cuts = collections.defaultdict(list)
    dropped = set()
    kept = [(n["range"]["byteOffset"]["start"], n["range"]["byteOffset"]["end"])
            for n in nodes if classified(n["text"], strip_docs) == "keep"]
    drops = [(n["range"]["byteOffset"]["start"], n["range"]["byteOffset"]["end"])
             for n in nodes if classified(n["text"], strip_docs) == "drop"]
    for n in nodes:
        if classified(n["text"], strip_docs) == "keep": continue
        s = n["range"]["byteOffset"]["start"]; e = n["range"]["byteOffset"]["end"]
        inner = [c for c in containers
                 if c["range"]["byteOffset"]["start"] <= s and e <= c["range"]["byteOffset"]["end"]]
        if inner:
            c = min(inner, key=lambda k: k["range"]["byteOffset"]["end"] - k["range"]["byteOffset"]["start"])
            cs0, ce0 = c["range"]["byteOffset"]["start"], c["range"]["byteOffset"]["end"]
            inside = data[cs0:ce0]
            for a, b in kept + drops:
                if cs0 <= a and b <= ce0: inside = inside.replace(data[a:b], b"", 1)
            if inside.replace(b"{", b"").replace(b"}", b"").strip() == b"":
                s, e = cs0, ce0
        i, j = span(s, e)
        if i == j and data[starts[i]:s].strip() == b"" and data[e:line_end(i)].strip() == b"":
            dropped.add(i); continue
        if i < j and data[starts[i]:s].strip() == b"" and data[e:line_end(j)].strip() == b"":
            dropped.update(range(i, j + 1)); continue
        k = i
        while k <= j:
            lo = s if k == i else starts[k]
            hi = e if k == j else line_end(k)
            if k < j and lo == starts[k] and hi == line_end(k):
                dropped.add(k)
            else:
                cuts[k].append((lo - starts[k], hi - starts[k]))
            k += 1
    out, after_drop = [], False
    for i, l in enumerate(lines):
        if i in dropped:
            after_drop = True; continue
        if i in cuts:
            for a, b in sorted(cuts[i], reverse=True):
                a = max(0, a); b = min(len(l), b)
                left = l[:a]; right = l[b:]
                if left.rstrip() and right.lstrip():
                    l = left + b" " + right
                else:
                    l = left + right
            l = l.rstrip()
        if after_drop and l.strip() == b"" and out and out[-1].strip() == b"":
            after_drop = False; continue
        if l.strip(): after_drop = False
        out.append(l)
    return b"\n".join(out).decode()

BINS = "/tmp/policy-sweep/bins"
def tool(name, attr):
    os.makedirs(BINS, exist_ok=True)
    cache = os.path.join(BINS, name)
    if not os.path.exists(cache):
        p = subprocess.run(["nix","build","--no-link","--print-out-paths",attr], capture_output=True, text=True)
        if p.returncode != 0: return None
        open(cache,"w").write(p.stdout.strip())
    root = open(cache).read().strip()
    for cand in (os.path.join(root,"bin",name), os.path.join(root,name)):
        if os.path.exists(cand): return cand
    return None

def fmt_cmd(repo, lang, path):
    if lang == "Rust":
        t = tool("rustfmt","nixpkgs#rustfmt")
        return [t,"--edition","2021",path] if t else None
    if lang in {"TypeScript","Tsx","JavaScript"}:
        t = tool("biome","nixpkgs#biome") or shutil.which("biome")
        return [t,"format","--write",path] if t else None
    if lang == "Nix":
        t = tool("nixfmt","nixpkgs#nixfmt")
        return [t,path] if t else None
    if lang == "Python":
        t = tool("ruff","nixpkgs#ruff")
        return [t,"format","--quiet",path] if t else None
    return None

def error_map(files, lang):
    if not files: return {}
    r = "id: e\nlanguage: %s\nrule:\n  kind: ERROR\n" % lang
    p = sh([ag(),"scan","--inline-rules",r,"--json=stream",*files])
    out = collections.Counter()
    for line in p.stdout.splitlines():
        if '"ruleId"' in line:
            try: out[json.loads(line)["file"]] += 1
            except ValueError: pass
    return out

def corpus(top, files):
    parts = []
    for f in files:
        if f.lower().endswith((".md",".mdx")): continue
        if any(x in SKIP_DIRS for x in f.split("/")): continue
        p = os.path.join(top, f)
        try:
            if os.path.islink(p) or os.path.getsize(p) > 2_000_000: continue
            with open(p, "rb") as fh: parts.append(fh.read())
        except OSError: continue
    return b"\n".join(parts)

def refs_in(top, rel, files=None, blob=None):
    base = os.path.basename(rel)
    if blob is not None:
        return ["*"] if (rel.encode() in blob or base.encode() in blob) else []
    hits = []
    for f in (files if files is not None else tracked(top)):
        if f.lower().endswith((".md",".mdx")) or f == rel: continue
        if any(x in SKIP_DIRS for x in f.split("/")): continue
        p = os.path.join(top, f)
        try:
            if os.path.getsize(p) > 2_000_000: continue
            with open(p, "rb") as fh: data = fh.read()
        except OSError: continue
        if rel.encode() in data or base.encode() in data: hits.append(f)
    return hits

def refs_to(repo, rel):
    hits = []
    for f in tracked(repo):
        if f.lower().endswith((".md",".mdx")): continue
        if any(x in SKIP_DIRS for x in f.split("/")): continue
        p = os.path.join(repo, f)
        try:
            if os.path.getsize(p) > 2_000_000: continue
            t = open(p, encoding="utf-8", errors="ignore").read()
        except OSError: continue
        if rel in t or rel.rsplit("/",1)[-1] in t:
            hits.append((f, "exact" if rel in t else "basename"))
    return hits

def apply(repo, strip_docs=False, dry=False, fmt=False, force=False):
    changes = []
    if not force and policy_reason(repo).startswith("explicit off"):
        return [("", "skip-explicit-off", 0)]
    exclude = ignore_patterns(repo)
    for lang, files in lang_files(repo).items():
        nodes = scan(files, lang)
        if not nodes: continue
        containers = {}
        if lang == "Tsx":
            for c in scan(files, lang, ["jsx_expression"]):
                containers.setdefault(c["file"], []).append(c)
        byfile = collections.defaultdict(list)
        for n in nodes: byfile[n["file"]].append(n)
        before = error_map(list(byfile), lang)
        edited, orig = {}, {}
        for f, ns in byfile.items():
            src = open(f, encoding="utf-8", errors="surrogateescape").read()
            new = strip_src(src, ns, strip_docs, containers.get(f, ()))
            if new != src:
                edited[f] = new; orig[f] = src
        if not edited: continue
        if dry:
            for f in edited: changes.append((f, "strip", len(byfile[f])))
            continue
        modes = {}
        for f, new in edited.items():
            try:
                modes[f] = os.stat(f).st_mode
                if not os.access(f, os.W_OK): os.chmod(f, modes[f] | 0o200)
                open(f,"w",encoding="utf-8",errors="surrogateescape").write(new)
                os.chmod(f, modes[f])
            except OSError as exc:
                changes.append((f, "REJECT_IO", 0))
        edited = {f: v for f, v in edited.items() if os.path.exists(f) and not any(c[0] == f and c[1] == "REJECT_IO" for c in changes)}
        after = error_map(list(edited), lang)
        for f in list(edited):
            if before.get(f, 0) == 0 and after.get(f, 0) > 0:
                open(f,"w",encoding="utf-8",errors="surrogateescape").write(orig[f])
                changes.append((f, "REJECT_SYNTAX", len(byfile[f])))
                del edited[f]
        for f in edited:
            changes.append((f, "strip", len(byfile[f])))
            if fmt:
                c = fmt_cmd(repo, lang, f)
                if c: sh(c)
    for m in tracked(repo):
        if not m.lower().endswith((".md",".mdx")): continue
        if any(x in SKIP_DIRS for x in m.split("/")): continue
        pol = md_policy(m)
        if pol == "legal":
            changes.append((os.path.join(repo,m), "keep-legal", 0)); continue
        if pol != "drop": continue
        if ignored(exclude, m): continue
        refs = refs_to(repo, m)
        if refs and not force:
            changes.append((os.path.join(repo,m), "keep-referenced", len(refs))); continue
        full = os.path.join(repo, m)
        if not os.path.exists(full):
            changes.append((full, "md-gone", 0)); continue
        changes.append((full, "rm-md", 0))
        if not dry: os.remove(full)
    return changes

def dirty(repo):
    return bool(git(repo,"status","--porcelain","--untracked-files=no").stdout.strip())

def default_scope(root):
    out = []
    for r in discover(root):
        if not r["owned"] or r["owner"] == "Inscendai": continue
        rel = os.path.relpath(r["path"], os.path.expanduser("~/dev"))
        if rel.startswith(("contributing/","sandbox/")): continue
        if any(x in rel for x in (".spike-work","inscend-followup","grok-presets-scratch")): continue
        out.append(r)
    return out

def staged(repo):
    return [f for f in git(repo,"diff","--cached","--name-only","--diff-filter=ACMR","-z").stdout.split("\0") if f]

def added_lines(repo, path):
    out = git(repo,"diff","--cached","-U0","--",path).stdout
    lines = set()
    for m in re.finditer(r"^@@ -\S+ \+(\d+)(?:,(\d+))? @@", out, re.M):
        start = int(m.group(1)); count = int(m.group(2) or 1)
        lines.update(range(start, start + count))
    return lines

def ignored(patterns, path):
    return any(fnmatch.fnmatch(path, pat) or path.startswith(pat.rstrip("/") + "/") for pat in patterns)

SWEEP_KEY = "sweep.policy"

def setting(repo, key):
    v = git(repo,"config","--local","--get",key)
    if v.returncode == 0: return v.stdout.strip()
    v = git(repo,"config","--get",key)
    return v.stdout.strip() if v.returncode == 0 else ""

def remote_owner(repo):
    rem = git(repo,"remote","get-url","origin").stdout.strip()
    m = re.search(r"[:/]([^/:]+)/[^/]+?(?:\.git)?$", rem)
    return m.group(1) if m else ""

def policy_reason(repo):
    local = git(repo,"config","--local","--get",SWEEP_KEY)
    if local.returncode == 0:
        on = local.stdout.strip().lower() in {"true","1","yes","on"}
        return "explicit on" if on else "explicit off"
    owners = setting(repo,"sweep.owners").replace(",", " ").split()
    if owners:
        owner = remote_owner(repo)
        if owner and owner in owners: return "owner " + owner
        if not owner:
            roots = setting(repo,"sweep.roots").replace(",", " ").split()
            top = git(repo,"rev-parse","--show-toplevel").stdout.strip()
            for root in roots:
                root = os.path.expanduser(root)
                if top == root or top.startswith(root.rstrip("/") + "/"): return "path " + root
    merged = git(repo,"config","--get",SWEEP_KEY)
    if merged.returncode == 0 and merged.stdout.strip().lower() in {"true","1","yes","on"}:
        return "explicit on"
    return ""

def enrolled(repo):
    reason = policy_reason(repo)
    return bool(reason) and not reason.startswith("explicit off")

def enroll(paths, on):
    done = []
    for p in paths:
        if on: git(p,"config","--local",SWEEP_KEY,"true")
        else: git(p,"config","--local","--unset",SWEEP_KEY)
        done.append((p, enrolled(p)))
    return done

def ignore_patterns(top):
    raw = git(top,"show",":.sweepignore").stdout
    if not raw:
        path = os.path.join(top, ".sweepignore")
        raw = open(path).read() if os.path.exists(path) else ""
    out = []
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("#"): continue
        if line in {"*", "**", "/*"}: continue
        out.append(line)
    return out

def hook() -> int:
    top = git(os.getcwd(),"rev-parse","--show-toplevel").stdout.strip()
    if not top: return 0
    if not enrolled(top): return 0
    gd = git(top,"rev-parse","--absolute-git-dir").stdout.strip()
    for marker in ("rebase-merge","rebase-apply","MERGE_HEAD","CHERRY_PICK_HEAD"):
        if os.path.exists(os.path.join(gd, marker)): return 0
    if os.environ.get("SWEEP_SKIP") == "1": return 0
    if not os.environ.get("SWEEP_IN_HOOK"):
        env = dict(os.environ, SWEEP_IN_HOOK="1")
        for cand in (os.path.join(top, ".husky", "pre-commit"), os.path.join(gd, "hooks", "pre-commit")):
            if os.path.isfile(cand) and os.access(cand, os.X_OK):
                if subprocess.run([cand], cwd=top, env=env).returncode: return 1
    patterns = ignore_patterns(top)
    bad = []
    hay = None
    blobs, tmp_of = {}, {}
    for f in staged(top):
        if ignored(patterns, f) or any(x in SKIP_DIRS for x in f.split("/")): continue
        low = f.lower()
        if low.endswith((".md",".mdx")):
            if md_policy(f) == "drop":
                if hay is None: hay = corpus(top, tracked(top))
                if refs_in(top, f, blob=hay): continue
            if md_policy(f) == "drop":
                bad.append((f, 0, "markdown: unreferenced prose; only README, AGENTS and machine-read docs survive"))
            continue
        ext = low.rsplit(".",1)[-1] if "." in os.path.basename(low) else ""
        lang = LANG_OF_EXT.get(ext)
        if not lang: continue
        data = subprocess.run(["git","-C",top,"show",":"+f],capture_output=True).stdout
        fd, tmp = tempfile.mkstemp(suffix="." + ext)
        os.close(fd)
        with open(tmp,"wb") as fh: fh.write(data)
        blobs[f] = (lang, data, tmp)
        tmp_of[tmp] = f
    by_lang = collections.defaultdict(list)
    for f, (lang, data, tmp) in blobs.items(): by_lang[lang].append(tmp)
    for lang, tmps in by_lang.items():
        for n in scan(tmps, lang):
            f = tmp_of[n["file"]]
            if classified(n["text"], False) == "keep": continue
            line = blobs[f][1].count(b"\n", 0, n["range"]["byteOffset"]["start"]) + 1
            if line in added_lines(top, f):
                bad.append((f, line, n["text"].strip().splitlines()[0][:70]))
    for _, _, tmp in blobs.values(): os.unlink(tmp)
    if not bad:
        return 0
    for f, line, why in bad:
        print("sweep: %s:%s: %s" % (f, line, why))
    print("sweep: %d violation(s); `sweep apply --repo .` previews the fix, `--apply` writes it; SWEEP_SKIP=1 or --no-verify bypasses" % len(bad))
    return 1

def main():
    ap = argparse.ArgumentParser(prog="sweep")
    ap.add_argument("cmd", choices=["check","apply","hook","enroll","disenroll","status"])
    ap.add_argument("--root", default=os.path.expanduser("~/dev"))
    ap.add_argument("--repo", action="append", default=[])
    ap.add_argument("--strip-docs", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--format", action="store_true")
    ap.add_argument("--commit", action="store_true")
    ap.add_argument("--include-dirty", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    if a.cmd == "hook":
        try:
            sys.exit(hook())
        except Exception as exc:
            print("sweep: policy check skipped (%s); commit allowed" % exc.__class__.__name__, file=sys.stderr)
            sys.exit(0)
    if a.cmd in {"enroll","disenroll"}:
        paths = [os.path.abspath(x) for x in a.repo] or [r["path"] for r in default_scope(a.root)]
        for p, state in enroll(paths, a.cmd == "enroll"):
            print("%-56s %-12s %s" % (os.path.relpath(p, os.path.expanduser("~")),
                                      "policy on" if state else "policy off", policy_reason(p) or "-"))
        return
    if a.cmd == "status":
        rows = [(os.path.relpath(r["path"], os.path.expanduser("~")), policy_reason(r["path"])) for r in discover(a.root)]
        on = [r for r in rows if r[1] and not r[1].startswith("explicit off")]
        off = [r for r in rows if r not in on]
        print("enforced: %d   unenforced: %d" % (len(on), len(off)))
        for path, why in on: print("  ON   %-48s %s" % (path, why))
        for path, why in off: print("  off  %-48s %s" % (path, why or "-"))
        return
    if a.cmd == "check":
        rows = inventory(a.root, a.strip_docs)
        if a.json:
            print(json.dumps(rows, indent=1)); return
        for r in sorted(rows, key=lambda r: -sum(v["drop"] for v in r["langs"].values())):
            drop = sum(v["drop"] for v in r["langs"].values())
            keep = sum(v["keep"] for v in r["langs"].values())
            if not drop and not r["md_drop"]: continue
            langs = ",".join("%s:%d/%d" % (k,v["drop"],v["comments"]) for k,v in sorted(r["langs"].items(), key=lambda kv:-kv[1]["drop"]) if v["comments"])
            print("%-58s own=%-5s zone=%-11s md=%-3d cmt=%d/%d %s" % (
                os.path.relpath(r["path"], os.path.expanduser("~")), r["owned"], r["zone"], r["md_drop"], drop, drop+keep, langs))
        return
    if a.repo:
        targets = [os.path.abspath(x) for x in a.repo]
    else:
        targets = [r["path"] for r in default_scope(a.root)]
    total = collections.Counter()
    for path in targets:
        if not os.path.isdir(os.path.join(path, ".git")): continue
        was_clean = not dirty(path)
        if not was_clean and not a.include_dirty:
            print("SKIP dirty %s" % os.path.relpath(path, os.path.expanduser("~"))); total["skipped_dirty"] += 1; continue
        ch = apply(path, a.strip_docs, dry=not a.apply, fmt=a.format, force=a.force)
        if not ch: continue
        n = collections.Counter(k for _, k, _ in ch)
        print("%-56s strips=%-4d md=%-3d legal=%-2d refs=%d rejects=%d" % (
            os.path.relpath(path, os.path.expanduser("~")), n["strip"], n["rm-md"], n["keep-legal"],
            sum(x for _,k,x in ch if k=="rm-md"), n["REJECT_SYNTAX"]))
        for k in n: total[k] += n[k]
        for f, k, _ in ch:
            if k == "REJECT_SYNTAX": print("   reject %s" % os.path.relpath(f, os.path.expanduser("~")))
        if a.apply and a.commit and was_clean:
            git(path,"add","-A")
            git(path,"commit","-q","-m","Strip comments, drop docs except README/AGENTS")
    print("TOTAL", dict(total))

if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.stdout = None
        os._exit(0)
