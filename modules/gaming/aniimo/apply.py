import hashlib
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

LUA_DIRS = ["Aniimo_Data/StreamingAssets/cvs/res/lua", "Aniimo_Data/cvs/res/lua"]
FILES = ["LuaScripts.xdf", "LuaScripts.xdt", "LuaCacheVer.txt"]


def md5(b):
    return hashlib.md5(b).hexdigest()


def die(msg):
    sys.exit(f"aniimo-mods: {msg}")


def read_dir(d):
    xdf = (d / "LuaScripts.xdf").read_bytes()
    xdt_raw = (d / "LuaScripts.xdt").read_bytes()
    xdt = json.loads(xdt_raw)
    if json.dumps(xdt, indent=4).encode() != xdt_raw:
        die(f"{d}/LuaScripts.xdt does not round-trip; unknown format")
    if md5(xdf) != xdt["CMDataMD5"]:
        die(f"{d}/LuaScripts.xdf does not match its xdt; verify game files")
    return xdf, xdt, md5(xdt_raw)


def entry_bytes(xdf, e):
    raw = xdf[e["CEOffset"] : e["CEOffset"] + e["CECSize"]]
    if e["CECSize"] != e["CESize"]:
        die(f"{e['CEName']} is compressed; only stored entries can be modded")
    return raw


def lua_bytes(b):
    return '"' + "".join(f"\\{c:03d}" for c in b) + '"'


def wrap(luajit, entry, orig, wrapper):
    src = (
        "return (function(...)\n"
        + Path(wrapper).read_text()
        + f"\nend)(assert(load({lua_bytes(orig)}, {lua_bytes(('@' + entry).encode())})), ...)\n"
    )
    with tempfile.TemporaryDirectory() as t:
        name = Path(entry).name
        (Path(t) / name).write_text(src)
        subprocess.run([luajit, "-b", "-g", name, "out.luac"], cwd=t, check=True)
        return (Path(t) / "out.luac").read_bytes()


def patched_entries(xdf, xdt, mods, luajit):
    by_name = {e["CEName"]: e for e in xdt["CMList"]}
    out = {}
    for m in mods:
        e = by_name.get(m["entry"])
        if e is None:
            die(f"{m['name']}: entry {m['entry']} missing; game updated, re-pin")
        data = out.get(m["entry"]) or entry_bytes(xdf, e)
        if m["entry"] not in out and md5(data) != m["entryMD5"]:
            die(f"{m['name']}: {m['entry']} changed (md5 {md5(data)}); game updated, re-pin")
        if "wrapper" in m:
            data = wrap(luajit, m["entry"], data, m["wrapper"])
        else:
            data = bytearray(data)
            for ed in m["edits"]:
                old, new, off = bytes.fromhex(ed["old"]), bytes.fromhex(ed["new"]), ed["offset"]
                if len(old) != len(new) or data[off : off + len(old)] != old:
                    die(f"{m['name']}: bytes at {m['entry']}+{off} differ from pin")
                data[off : off + len(old)] = new
            data = bytes(data)
        out[m["entry"]] = data
    return out


def rebuild(xdf, xdt, repl):
    eocd = xdf.rfind(b"PK\x05\x06")
    n, cd_size, cd_off = struct.unpack("<HII", xdf[eocd + 10 : eocd + 20])
    cd = xdf[cd_off : cd_off + cd_size]
    out = bytearray()
    new_off = {}
    meta = {}
    p = 0
    while p < len(cd):
        nl, el, cl = struct.unpack("<HHH", cd[p + 28 : p + 34])
        name = cd[p + 46 : p + 46 + nl].decode()
        lho = struct.unpack("<I", cd[p + 42 : p + 46])[0]
        meta[name] = (p, 46 + nl + el + cl, lho)
        p += 46 + nl + el + cl
    if len(meta) != n:
        die("zip central directory count mismatch")
    for name, (_, _, lho) in sorted(meta.items(), key=lambda kv: kv[1][2]):
        f = bytearray(xdf[lho : lho + 30])
        nl, el = struct.unpack("<HH", f[26:30])
        csize = struct.unpack("<I", f[18:22])[0]
        start = lho + 30 + nl + el
        data = xdf[start : start + csize]
        if name in repl:
            data = repl[name]
            struct.pack_into("<III", f, 14, zlib.crc32(data), len(data), len(data))
        new_off[name] = (len(out), len(out) + 30 + nl + el, f)
        out += f + xdf[lho + 30 : start] + data
    new_cd = bytearray()
    for name, (p, ln, _) in sorted(meta.items(), key=lambda kv: kv[1][0]):
        r = bytearray(cd[p : p + ln])
        r[16:28] = new_off[name][2][14:26]
        struct.pack_into("<I", r, 42, new_off[name][0])
        new_cd += r
    cd_start = len(out)
    out += new_cd
    tail = bytearray(xdf[eocd:])
    struct.pack_into("<II", tail, 12, len(new_cd), cd_start)
    out += tail
    out = bytes(out)
    new_xdt = json.loads(json.dumps(xdt))
    for e in new_xdt["CMList"]:
        e["CEOffset"] = new_off[e["CEName"]][1]
        if e["CEName"] in repl:
            data = repl[e["CEName"]]
            e["CEMD5"], e["CESize"], e["CECSize"] = md5(data), len(data), len(data)
    new_xdt["CMDataLen"] = len(out)
    new_xdt["CMDataMD5"] = md5(out)
    return out, json.dumps(new_xdt, indent=4).encode()


def write_atomic(path, data):
    tmp = path.with_name(path.name + ".finix-tmp")
    tmp.write_bytes(data)
    if path.exists():
        shutil.copymode(path, tmp)
    os.replace(tmp, path)


def install(d, xdf, xdt_raw):
    write_atomic(d / "LuaScripts.xdf", xdf)
    write_atomic(d / "LuaScripts.xdt", xdt_raw)
    ver = d / "LuaCacheVer.txt"
    if ver.exists():
        prefix = ver.read_text().split(",")[0]
        write_atomic(ver, f"{prefix},{len(xdt_raw)},{md5(xdt_raw)}".encode())


def main():
    settings = json.loads(Path(sys.argv[1]).read_text())
    mods = settings["mods"]
    game = Path(settings["gameDirectory"])
    state_dir = game / ".finix-aniimo"
    if not (game / "Aniimo.exe").exists():
        if mods or state_dir.exists():
            die(f"{game} has no Aniimo.exe; skipped")
        return
    for cmdline in Path("/proc").glob("[0-9]*/cmdline"):
        try:
            if b"Aniimo.exe" in cmdline.read_bytes():
                die("Aniimo is running; skipped")
        except OSError:
            pass
    state_file = state_dir / "state.json"
    state = json.loads(state_file.read_text()) if state_file.exists() else {}
    changed = {}
    for rel in LUA_DIRS:
        d = game / rel
        if not (d / "LuaScripts.xdt").exists():
            continue
        _, _, cur_xdt_md5 = read_dir(d)
        backup = state_dir / rel.replace("/", "_")
        ours = state.get(rel) == cur_xdt_md5
        if not mods:
            if ours:
                for f in FILES:
                    if (backup / f).exists():
                        write_atomic(d / f, (backup / f).read_bytes())
                changed[rel] = "vanilla"
            state.pop(rel, None)
            continue
        if not ours:
            shutil.rmtree(backup, ignore_errors=True)
            backup.mkdir(parents=True)
            for f in FILES:
                if (d / f).exists():
                    shutil.copy2(d / f, backup / f)
        xdf, xdt, _ = read_dir(backup)
        new_xdf, new_xdt = rebuild(xdf, xdt, patched_entries(xdf, xdt, mods, settings.get("luajit")))
        if md5(new_xdt) != cur_xdt_md5:
            install(d, new_xdf, new_xdt)
            changed[rel] = [m["name"] for m in mods]
        state[rel] = md5(new_xdt)
    if state:
        state_dir.mkdir(exist_ok=True)
        write_atomic(state_file, json.dumps(state, indent=2).encode())
    else:
        shutil.rmtree(state_dir, ignore_errors=True)
    if changed:
        print(json.dumps({"aniimo": changed}))


if __name__ == "__main__":
    main()
