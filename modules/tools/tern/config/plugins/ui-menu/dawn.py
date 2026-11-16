import re
import struct
import sys

binary, scope, avatar, sheet = sys.argv[1:5]
data = open(binary, "rb").read()
shoff = struct.unpack_from("<Q", data, 0x28)[0]
shentsize, shnum = struct.unpack_from("<HH", data, 0x3A)
sections = [struct.unpack_from("<IIQQQQIIQQ", data, shoff + i * shentsize) for i in range(shnum)]


def offset(vaddr):
    for s in sections:
        if s[3] and s[1] != 8 and s[3] <= vaddr < s[3] + s[5]:
            return vaddr - s[3] + s[4]
    raise KeyError(hex(vaddr))


relative = {}
for s in sections:
    if s[1] == 4:
        for i in range(s[5] // 24):
            where, info, addend = struct.unpack_from("<QQq", data, s[4] + i * 24)
            if info & 0xFFFFFFFF == 8:
                relative[where] = addend
pointing = {}
for where, target in relative.items():
    pointing.setdefault(target, []).append(where)


def word(vaddr):
    return relative[vaddr] if vaddr in relative else struct.unpack_from("<Q", data, offset(vaddr))[0]


def entry(vaddr):
    if vaddr not in relative or vaddr + 16 not in relative:
        return None
    name_at, name_len, css_at, css_len = (word(vaddr + k) for k in (0, 8, 16, 24))
    if not (0 < name_len < 64 and 0 < css_len < 500000):
        return None
    name = data[offset(name_at):offset(name_at) + name_len]
    if not re.fullmatch(rb"[a-z0-9_-]+\.css", name):
        return None
    return name.decode(), data[offset(css_at):offset(css_at) + css_len].decode()


def ua():
    for match in re.finditer(rb"ua\.css", data):
        for slot in pointing.get(match.start(), []):
            found = entry(slot)
            if found and found[0] == "ua.css":
                return found[1]
    sys.exit("bot-view: no ua.css table entry in " + binary)


rules = []
for selectors, body in re.findall(r"([^{}]+)\{([^{}]*)\}", re.sub(r"/\*.*?\*/", "", ua(), flags=re.S)):
    picked = [s.strip() for s in selectors.split(",") if s.strip() and not re.fullmatch(r"html|body", s.strip())]
    if picked:
        lines = [line.strip() for line in body.strip().splitlines() if line.strip()]
        rules.append("\t" + ",\n\t".join("& " + s for s in picked) + " {\n" + "".join("\t\t" + line + "\n" for line in lines) + "\t}")

out = [scope + " {", "\t&,", f"\t& :where(:not({avatar})) {{", "\t\tall: unset;", "\t}"]
out += rules
nested, _, outside = open(sheet).read().replace("%avatar%", avatar).partition("\n@keyframes")
out.append(nested.rstrip("\n"))
out.append("}")
if outside:
    out.append("@keyframes" + outside.rstrip("\n"))
sys.stdout.write("\n".join(out) + "\n")
