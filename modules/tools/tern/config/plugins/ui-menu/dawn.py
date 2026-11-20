import re
import struct
import sys

SHEETS = [
    "ua.css", "theme.css", "base.css", "doc.css", "highlight.css", "markdown.css", "termview.css", "surface.css",
    "surface-crash.css", "surface-content.css", "surface-data.css", "surface-list.css", "surface-input.css",
    "surface-controls.css", "surface-lens.css", "surface-el.css", "surface-attachment.css", "surface-avatar.css",
    "surface-breadcrumb.css", "surface-buttons.css", "surface-cite.css", "surface-doc.css", "surface-empty.css",
    "surface-field.css", "surface-menu.css", "surface-message.css", "surface-nav.css", "surface-pager.css",
    "surface-questions.css", "surface-scroll.css", "surface-skeleton.css", "surface-slider.css", "surface-split.css",
    "surface-stacktrace.css", "surface-suggestions.css", "surface-switch.css", "surface-trace.css", "omp.css",
    "omp-agents.css", "omp-apps.css", "omp-pickers.css", "omp-tray.css", "omp-transcript.css", "omp-tools.css",
    "omp-composer.css", "omp-panels.css", "omp-chat-reader.css",
]
ELSEWHERE = re.compile(
    r"\.sf-chat-(?:console|spine|touch)\b|\.tn-phone\b|omp\.rewind|#(?:tabbar|sidebar|widgetbar|wg-gallery|pal|thm|pick|banners|inbox)\b"
    r"|\.(?:cmdk|mdl|mdl-layer|dlg-card|pk-sheet|tn-hd|tn-ib|tn-bn-card|tn-signin|toast|tooltip|pf)\b"
)
PSEUDO = re.compile(r"::|:(?:before|after|first-line|first-letter)\b")

binary, target, scope, keep, sheet = sys.argv[1:6]
extra = sys.argv[6:]
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


def word(vaddr):
    return relative[vaddr] if vaddr in relative else struct.unpack_from("<Q", data, offset(vaddr))[0]


stock = {}
for where in relative:
    if where + 16 not in relative:
        continue
    try:
        name_at, name_len, css_at, css_len = (word(where + k) for k in (0, 8, 16, 24))
        if not (0 < name_len < 64 and 0 < css_len < 500000):
            continue
        name = data[offset(name_at):offset(name_at) + name_len]
        if re.fullmatch(rb"[a-z0-9_-]+\.css", name):
            stock.setdefault(name.decode(), data[offset(css_at):offset(css_at) + css_len].decode())
    except (KeyError, UnicodeDecodeError, struct.error):
        continue
missing = [name for name in SHEETS if name not in stock]
if missing:
    sys.exit("dawn: no " + ", ".join(missing) + " in " + binary)


def parse(text, i=0):
    items, buf = [], ""
    while i < len(text):
        c = text[i]
        if text.startswith("/*", i):
            i = text.index("*/", i) + 2
        elif c in "\"'":
            j = i + 1
            while text[j] != c:
                j += 2 if text[j] == "\\" else 1
            buf += text[i:j + 1]
            i = j + 1
        elif c == "(" or c == "[":
            depth, j = 0, i
            while True:
                if text[j] in "([":
                    depth += 1
                elif text[j] in ")]":
                    depth -= 1
                elif text[j] in "\"'":
                    q = text[j]
                    j += 1
                    while text[j] != q:
                        j += 2 if text[j] == "\\" else 1
                if depth == 0:
                    break
                j += 1
            buf += text[i:j + 1]
            i = j + 1
        elif c == "{":
            body, i = parse(text, i + 1)
            items.append((buf.strip(), body))
            buf = ""
        elif c == "}":
            if buf.strip():
                items.append((buf.strip(), None))
            return items, i + 1
        elif c == ";":
            if buf.strip():
                items.append((buf.strip(), None))
            buf = ""
            i += 1
        else:
            buf += c
            i += 1
    if buf.strip():
        items.append((buf.strip(), None))
    return items, i


def split(selectors):
    out, depth, start, quote = [], 0, 0, None
    for i, c in enumerate(selectors):
        if quote:
            quote = None if c == quote else quote
        elif c in "\"'":
            quote = c
        elif c in "([":
            depth += 1
        elif c in ")]":
            depth -= 1
        elif c == "," and depth == 0:
            out.append(selectors[start:i].strip())
            start = i + 1
    out.append(selectors[start:].strip())
    return [s for s in out if s]


def toplevel_pseudo(selector):
    depth = 0
    for i, c in enumerate(selector):
        if c in "([":
            depth += 1
        elif c in ")]":
            depth -= 1
        elif depth == 0 and c == ":" and PSEUDO.match(selector, i):
            return i
    return -1


IDS = ":not(#dawn-a):not(#dawn-b):not(#dawn-c)"
BOOST = f"{IDS}:where({scope}, {scope} *):where(:not({keep}))"


def boost(selector):
    at = toplevel_pseudo(selector)
    return selector + BOOST if at < 0 else selector[:at] + BOOST + selector[at:]


def positive(selector):
    while True:
        bare = re.sub(r":not\([^()]*\)", "", selector)
        if bare == selector:
            return bare
        selector = bare


def resolve(selector, parent):
    whole = parent[0] if len(parent) == 1 else ":is(" + ", ".join(parent) + ")"
    return selector.replace("&", whole) if "&" in selector else whole + " " + selector


def emit(items, parent=None):
    out = []
    decls = [h for h, b in items if b is None]
    kept = [p for p in parent or [] if not ELSEWHERE.search(positive(p))]
    if decls and kept:
        out.append(", ".join(boost(p) for p in kept) + " {\n" + "".join("\t" + d + ";\n" for d in decls) + "}\n")
    for head, body in items:
        if body is None:
            continue
        if head.startswith("@"):
            if re.match(r"@(media|supports|container|layer)\b", head):
                inner = emit(body, parent)
                if inner:
                    out.append(head + " {\n" + inner + "}\n")
            continue
        selectors = split(head)
        if parent:
            selectors = [resolve(s, parent) for s in selectors]
        out.append(emit(body, selectors))
    return "".join(out)


own = open(sheet).read()
out = [own.rstrip("\n") + "\n"]
out.append(f":where({scope}){IDS},\n:where({scope}) :where(:not({keep})){IDS} {{\n\tall: unset;\n}}\n")
for name in SHEETS:
    out.append(emit(parse(stock[name])[0]))
for path in extra:
    out.append(emit(parse(open(path).read())[0]))
out.append(emit(parse(own)[0]))
open(target + "/dawn.css", "w").write("".join(out))
open(target + "/dawn.boost", "w").write(BOOST + "\n")
