// thread: liquid glass on a thin seam.
//
// One glass thread runs down the middle of the deck's 34 px seam, as tall as the
// cards, and the readings hang on it as beads: the clock (hours over minutes),
// the date (day over month), CPU, memory, bolo's voice at the weld, the GPU and
// the VRAM. Each gauge bead keeps a level of denser glass from its foot up to
// its load, with its label above its value. The focused card wears a 5 px glass
// rim, welded to the thread by a meniscus at the weld; every other card keeps
// only a dark and a light hairline. A switch across the seam bends the thread
// after the new side while the old rim drains back into the thread and the new
// one fills out of the weld both ways; within a column the weld stays and the
// rims only drain and fill. bolo plucks the thread -- a travelling wave out from
// the weld whose reach is the level the voice had when it passed, the beads the
// nodes of the string, the voice bead swelling -- and the ripple runs round the
// focused rim, thickening and brightening it as it goes, all dying away over the
// turn's settle.
//
// ONE set of glass numbers for dark and light: the same frost, lens, tint lift,
// a bright inner highlight on the lit side and a dark outer hairline all round,
// so the glass reads on a light or a dark wallpaper alike. The readout inside
// each bead takes its ink from the luminance of what lies behind that bead --
// dark ink over a bright backdrop, light ink over a dark one -- so the type holds
// where the glass follows the wallpaper, not the theme's mode.
//
// Everything comes from iData (laid out by rail-kit.lisp and rail-thread.lisp),
// the cards from iWindow, and time from iTime, which the rail holds once nothing
// moves. Coordinates are the output's, y down.

const int T_TW = THEME, T_RIM = THEME + 1, T_WELD = THEME + 2, T_WSIG = THEME + 3;
const int T_CORNER = THEME + 4, T_VW = THEME + 5, T_AMP = THEME + 6, T_PLUCK = THEME + 7;
const int T_PHZ = THEME + 8, T_ENV = THEME + 9, T_BEND = THEME + 10, T_BDEC = THEME + 11;
const int T_BHZ = THEME + 12, T_BSIG = THEME + 13, T_FDELAY = THEME + 14, T_FDUR = THEME + 15;
const int T_DDUR = THEME + 16, T_X = THEME + 17, T_TOP = THEME + 18, T_BOT = THEME + 19;
const int T_WY = THEME + 20, T_BEADS = THEME + 21, T_VLEN = THEME + 42, T_FSTYLE = THEME + 46;

const int NBEADS = 7;
const int B_CLOCK = 0, B_DATE = 1, B_CPU = 2, B_MEM = 3, VOICE_BEAD = 4, B_GPU = 5, B_VRAM = 6;

float g_mid, g_top, g_bot, g_wy;
vec4 g_fbox;
float g_dt, g_fill, g_drain;
bool g_f;

// the backdrop under a point of the output, as the surface beneath it holds it
vec3 under(vec2 q) { return beneath(vec2(q.x - k_origin.x, k_h - (q.y - k_origin.y))).rgb; }

// the glass frost: a small disc of the backdrop, spun per pixel; the nine
// offsets are the disc's, cos/sin taken once here rather than per pixel
vec3 frosted(vec2 q, float r) {
    float spin = 6.2832 * fract(52.9829 * fract(dot(q, vec2(0.06711, 0.00584))));
    vec2 disc[9] = vec2[9](vec2(0.389, 0.000), vec2(0.120, 0.370), vec2(-0.315, 0.228),
                           vec2(-0.315, -0.228), vec2(0.120, -0.370), vec2(0.666, 0.470),
                           vec2(0.046, 0.816), vec2(-0.665, 0.470), vec2(-0.665, -0.470));
    vec3 sum = vec3(0.0);
    float c = cos(spin), s = sin(spin);
    for (int i = 0; i < 9; i++) {
        vec2 o = vec2(disc[i].x * c - disc[i].y * s, disc[i].x * s + disc[i].y * c);
        sum += under(q + r * o);
    }
    return sum / 9.0;
}

float bead_cy(int i) { return D(T_BEADS + 3 * i); }
float bead_hy(int i) { return D(T_BEADS + 3 * i + 1); }
float bead_hw(int i) { return D(T_BEADS + 3 * i + 2); }

// How far the thread is pulled sideways at height Y: bolo's wave running out
// from the weld, each stretch as loud as the voice was when it passed that far,
// plus the bend a switch across the seam leaves toward the new side. A bead is a
// node -- the string rings between them -- so the beads' glass and the type set
// in it stay put.
float thread_off(float y) {
    float dy = abs(y - g_wy);
    float lev = voice_env() * voice_level(dy / max(1.0, D(T_VW)));
    float pluck = D(T_AMP) * lev * sin(dy * D(T_PLUCK) - iTime * D(T_PHZ))
        * (0.4 + 0.6 * exp(-dy * D(T_ENV)));
    float bend = 0.0;
    if (g_dt >= 0.0 && g_dt < D(K_SETTLE) && D(K_FLOW) > -0.5
            && D(K_FROM) != 0.0 && D(K_SIDE) != 0.0 && D(K_FROM) != D(K_SIDE))
        bend = D(K_SIDE) * D(T_BEND) * exp(-g_dt / D(T_BDEC)) * sin(g_dt * D(T_BHZ) + 0.4)
            * exp(-pow((y - g_wy) / D(T_BSIG), 2.0));
    float node = 1.0;
    for (int i = 0; i < NBEADS; i++)
        node = min(node, clamp((abs(y - bead_cy(i)) - bead_hy(i)) / 18.0, 0.0, 1.0));
    return (pluck + bend) * node;
}

// the thread: a capsule down the seam, its x the pluck's at each height
float thread_field(vec2 p) {
    float y = clamp(p.y, g_top, g_bot);
    vec2 d = vec2(p.x - g_mid - thread_off(y), p.y - y);
    return length(d) - D(T_TW);
}

// a bead: a rounded cell, the voice bead swelling as the turn comes up
float bead_field(vec2 p, int i, float swell) {
    float hx = bead_hw(i) + 2.0 * swell;
    float hy = bead_hy(i) + 6.0 * swell;
    float cx = g_mid, cy = bead_cy(i);
    return sd_rbox(p, vec4(cx - hx, cy - hy, cx + hx, cy + hy), min(hx, 12.0));
}

// where the welded rim's length starts: on the card's edge facing the seam, at
// the weld's height
float weld_u(vec4 b) { return perim(vec2((b.x + b.z) * 0.5 < g_mid ? b.z : b.x, g_wy), b).x; }

// how much of the rim round B is there at P: the fill's front runs out of the
// weld both ways, so the rim grows from the weld and, draining, sinks back into
// it. S is how far along the rim P is from the weld, PER the rim's length.
float rim_pres(vec2 p, vec4 b, float progress, out float s, out float per) {
    vec2 pp = perim(p, b);
    s = pdist(pp.x, weld_u(b), pp.y);
    per = pp.y;
    return clamp((progress * per * 0.5 - s) / 60.0 + (progress >= 1.0 ? 1.0 : 0.0), 0.0, 1.0);
}

// the rim's thickness at rim distance S: five pixels, and as much again where
// the voice was loud when the ripple passed, the crests of a wave running round
float rim_width(float s) {
    float lev = voice_env() * voice_level(s / max(1.0, D(T_VW)));
    return D(T_RIM) + 12.0 * lev * (0.45 + 0.55 * sin(s * 0.030 - iTime * 26.0));
}

// the whole glass: the thread, its beads, the focused card's rim welded to the
// thread by a meniscus at the weld, and the drained rim of the card focus left
float field(vec2 p) {
    // far from the seam neither the thread nor a bead can reach within the
    // shadow's ten pixels, so the glass there is only the rim's
    float f = 1e3;
    if (abs(p.x - g_mid) < 48.0) {
        f = thread_field(p);
        float swell = voice_env();
        for (int i = 0; i < NBEADS; i++)
            f = smin(f, bead_field(p, i, i == VOICE_BEAD ? swell : 0.0), 6.0);
    }
    if (g_f) {
        float s, per;
        float pres = rim_pres(p, g_fbox, g_fill, s, per);
        if (pres > 0.01) {
            float d = sd_rbox(p, g_fbox, D(T_CORNER));
            float ring = max(d - rim_width(s) * pres, -d);
            float k = D(T_WELD) * exp(-pow((p.y - g_wy) / D(T_WSIG), 2.0))
                * min(g_fill * 1.5, 1.0);
            f = smin(f, ring, k);
        }
    }
    int old = int(D(K_OLD));
    if (g_drain > 0.0 && card_shown(old)) {
        vec4 ob = card(old);
        float s, per;
        float pres = rim_pres(p, ob, g_drain, s, per);
        if (pres > 0.01) {
            float d = sd_rbox(p, ob, D(T_CORNER));
            f = min(f, max(d - D(T_RIM) * pres, -d));
        }
    }
    return f;
}

// The glass itself, one set of numbers for both modes: the backdrop frosted and
// refracted toward the rim, a light lift, a bright inner highlight on the lit
// side and a darkening on the other, and a frosting further in.
vec3 glass(vec2 p, float f, vec2 dir, float shine) {
    float depth = clamp(-f / 6.0, 0.0, 1.0);
    float lens = 13.0 * (1.0 - depth) * (1.0 - depth);
    vec3 seen = frosted(p - dir * lens, 7.0);
    seen = seen * 0.90 + vec3(0.07) + vec3(0.22) * clamp(shine, 0.0, 1.0);
    float lit = dot(dir, vec2(0.45, 0.89));
    float rim = clamp(1.0 + f / 1.7, 0.0, 1.0);
    seen = mix(seen, vec3(1.0), (0.28 + 0.60 * clamp(lit, 0.0, 1.0)) * rim);
    seen = mix(seen, vec3(0.0), clamp(-lit, 0.0, 1.0) * rim * 0.22);
    seen = mix(seen, vec3(1.0), clamp(1.0 + f / 4.0, 0.0, 1.0) * 0.10);
    return seen;
}

// ---------------------------------------------------------------- the readout

// a character of the text at BASE starting at BASE + START, its first cell's
// top-left at AT, each cell S pixels: whether P is on a lit cell of it
bool char_hit(vec2 p, vec2 at, vec2 cell, int base, int start, int n) {
    vec2 q = (p - at) / cell;
    if (q.x < 0.0 || q.y < 0.0 || q.y >= 5.0) return false;
    int ci = int(floor(q.x / 4.0));
    if (ci >= n) return false;
    int col = int(floor(q.x)) - ci * 4;
    if (col > 2) return false;
    int row = int(floor(q.y));
    return (glyph(char_at(base, start + ci)) & (1 << (row * 3 + col))) != 0;
}

float text_span(int n, float s) { return (4.0 * float(n) - 1.0) * s; }

// The ink that reads on what lies behind a bead: the mock's rule -- dark ink
// over a bright backdrop, light ink over a dark one -- decided per bead from the
// backdrop itself, so the readout holds on a light or a dark wallpaper alike.
vec3 ink_of(vec2 c) {
    float lum = dot(under(c), vec3(0.3, 0.59, 0.11));
    return lum > 0.5 ? vec3(0.094, 0.094, 0.110) : vec3(0.957, 0.949, 0.925);
}

// The readings set in the beads' glass: the clock's hours over its minutes, the
// day over its month, each gauge its label over its value. Each block is centred
// on its bead both ways -- the value as wide as the characters it really has, so
// a four character reading like 8.2G centres like a three character one -- and
// every bead's centre is the thread's.
void set_type(vec2 p, inout vec3 c) {
    for (int i = 0; i < NBEADS; i++) {
        float cy = bead_cy(i);
        if (abs(p.y - cy) > bead_hy(i) + 2.0 || abs(p.x - g_mid) > bead_hw(i) + 2.0) continue;
        vec2 mid = vec2(g_mid, cy);
        bool on = false;
        float a = 1.0;
        if (i == B_CLOCK) {
            // hours over minutes: 15 + 5 + 15 rows about the bead's middle
            float x0 = mid.x - 0.5 * text_span(2, 3.0);
            on = char_hit(p, vec2(x0, cy - 18.0), vec2(3.0), K_CLOCK, 0, 2)
              || char_hit(p, vec2(x0, cy + 2.0), vec2(3.0), K_CLOCK, 3, 2);
        } else if (i == B_DATE) {
            // the day over the month: 15 + 5 + 10 rows about the bead's middle
            on = char_hit(p, vec2(mid.x - 0.5 * text_span(2, 3.0), cy - 15.0), vec2(3.0),
                          K_DATE, 0, 2);
            if (!on) {
                on = char_hit(p, vec2(mid.x - 0.5 * text_span(3, 2.0), cy + 5.0), vec2(2.0),
                              K_DATE, 3, 3);
                a = 0.76;
            }
        } else if (i != VOICE_BEAD) {
            int k = i == B_CPU ? 0 : (i == B_MEM ? 1 : (i == B_GPU ? 2 : 3));
            if (gauge_pct(k) < 0.0) continue;
            int base = K_GAUGES + k * K_GAUGE;
            int vlen = clamp(int(D(T_VLEN + k)), 1, 6);
            // the label over the value: 10 + 5 + 15 rows about the bead's middle
            on = char_hit(p, vec2(mid.x - 0.5 * text_span(3, 2.0), cy - 15.0), vec2(2.0),
                          base + 4, 0, 3);
            a = 0.72;
            if (!on) {
                on = char_hit(p, vec2(mid.x - 0.5 * text_span(vlen, 3.0), cy), vec2(2.0, 3.0),
                              base + 2, 0, vlen);
                a = 1.0;
            }
        }
        if (on) c = mix(c, ink_of(mid), a);
    }
}

void mainImage(out vec4 color, in vec2 fragCoord) {
    kit_begin();
    vec2 p = kit_point(fragCoord);
    color = vec4(0.0);

    g_mid = D(T_X);
    g_top = D(T_TOP);
    g_bot = D(T_BOT);
    g_wy = D(T_WY);
    g_dt = iTime - D(K_TSW);
    int focus = int(D(K_FOCUS)), old = int(D(K_OLD));
    g_f = card_shown(focus);
    if (g_f) g_fbox = card(focus);
    g_fill = 1.0;
    g_drain = 0.0;
    if (D(K_TSW) > -1e5 && g_dt >= 0.0 && g_dt < D(K_SETTLE) && D(K_FLOW) > -0.5) {
        g_fill = ease_out((g_dt - D(T_FDELAY)) / max(0.01, D(T_FDUR)));
        if (card_shown(old) && old != focus)
            g_drain = 1.0 - pow(ease_out(g_dt / max(0.01, D(T_DDUR))), 1.7);
    }

    // What a card without focus keeps, in the treatment the rail asks for: the
    // hairline pair (a dark line just outside the corner and a light one just
    // outside that, so a card reads on a light and on a dark wallpaper alike), a
    // dimmer dark line alone, or -- receding, and under the glow that marks the
    // focused card instead -- nothing at all.
    int style = int(D(T_FSTYLE));
    float hdark = 0.0, hlight = 0.0;
    if (style < 2) {
        float line = style == 0 ? 0.30 : 0.12;
        for (int i = 0; i < 8; i++) {
            if (!card_shown(i) || i == focus) continue;
            if (i == old && g_drain > 0.0) continue;
            float d = sd_rbox(p, card(i), D(T_CORNER));
            if (d < -1.0 || d > 3.0) continue;
            hdark = max(hdark, line * clamp(1.0 - abs(d - 0.5), 0.0, 1.0));
            if (style == 0)
                hlight = max(hlight, 0.16 * clamp(1.0 - abs(d - 1.6), 0.0, 1.0));
        }
    }
    // the focused card's soft halo, only where the rail asks for one: a wide
    // falloff outside its rim, in the ink that reads on what lies there
    float glow = 0.0;
    if (style == 3 && g_f) {
        float drim = sd_rbox(p, g_fbox, D(T_CORNER)) - D(T_RIM);
        if (drim > 0.0) glow = 0.45 * exp(-drim / 12.0);
    }

    float f = field(p);
    if (f > 12.0 && hdark <= 0.0 && hlight <= 0.0 && glow <= 0.0) discard;

    vec2 slant = vec2(field(p + vec2(1.0, 0.0)) - f, field(p + vec2(0.0, 1.0)) - f);
    vec2 dir = slant / (length(slant) + 1e-5);

    // how brightly the voice's crests light the glass at p
    float shine = 0.0;
    if (g_f && f < 0.5) {
        float s, per;
        float pres = rim_pres(p, g_fbox, g_fill, s, per);
        if (pres > 0.01)
            shine = voice_env() * voice_level(s / max(1.0, D(T_VW))) * pres;
    }

    vec3 c = vec3(0.0);
    float a = 0.0;
    c = mix(c, vec3(0.0), hdark);
    a = hdark + a * (1.0 - hdark);
    c = mix(c, vec3(1.0), hlight);
    a = hlight + a * (1.0 - hlight);
    if (glow > 0.0) {
        c = mix(c, ink_of(clamp(p, g_fbox.xy, g_fbox.zw)), glow);
        a = glow + a * (1.0 - glow);
    }

    float cov = clamp(0.5 - f, 0.0, 1.0);
    float sh = f > 0.0 ? 0.16 * pow(clamp(1.0 - f / 10.0, 0.0, 1.0), 2.0) : 0.0;
    float hair = 0.34 * clamp(1.0 - abs(f - 0.6) / 0.9, 0.0, 1.0);
    c *= 1.0 - sh;
    a = sh + a * (1.0 - sh);
    c *= 1.0 - hair;
    a = hair + a * (1.0 - hair);
    if (cov > 0.0) {
        c = mix(c, glass(p, f, dir, shine), cov);
        a = cov + a * (1.0 - cov);
    }

    // inside the beads: each gauge's level of denser glass from its foot up, and
    // the voice bead's own dot; both take their tone from the backdrop's luminance
    if (cov > 0.25) {
        for (int k = 0; k < 4; k++) {
            int bead = k < 2 ? 2 + k : 3 + k;
            float pct = gauge_pct(k);
            if (pct < 0.0) continue;
            float cx = g_mid, cy = bead_cy(bead);
            vec4 box = vec4(cx - 11.0, cy - bead_hy(bead) + 3.0,
                            cx + 11.0, cy + bead_hy(bead) - 3.0);
            float d = sd_rbox(p, box, 9.0);
            if (d > 1.0) continue;
            float lum = dot(under(vec2(cx, cy)), vec3(0.3, 0.59, 0.11));
            float y1 = box.w, y0 = y1 - (y1 - box.y) * clamp(pct, 0.0, 100.0) / 100.0;
            float fill = clamp(p.y - y0, 0.0, 1.0) * clamp(0.5 - d, 0.0, 1.0);
            float fa = fill * (lum > 0.5 ? 0.22 : 0.30);
            c = mix(c, lum > 0.5 ? vec3(0.0) : vec3(1.0), fa);
            a = fa + a * (1.0 - fa);
        }
        float rr = 3.0 + 7.0 * voice_env() * voice_level(0.0);
        float dd = length(p - vec2(g_mid, bead_cy(VOICE_BEAD))) - rr;
        if (dd < 1.0) {
            float lum = dot(under(vec2(g_mid, bead_cy(VOICE_BEAD))), vec3(0.3, 0.59, 0.11));
            float da = clamp(0.5 - dd, 0.0, 1.0) * (0.35 + 0.65 * voice_env());
            c = mix(c, lum > 0.5 ? vec3(0.09) : vec3(0.94, 0.93, 0.90), da);
            a = da + a * (1.0 - da);
        }
        set_type(p, c);
    }

    if (a <= 0.0) discard;
    color = vec4(c, a);
}
