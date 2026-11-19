// membrane: THREAD in living glass.
//
// THREAD's seam, beads, readings, weld and motion (shaders/thread.glsl), drawn
// in a glass that reads as glass and grows like tissue. The glass is a dome over
// THREAD's field: its edge bends the sharp backdrop (beneath()) inward, the
// three primaries by slightly different amounts, and further in it carries the
// windows' own blur of it (frost()); a Fresnel rim mirrors the sky and the
// desktop beside it, a highlight runs down the lit side, and the light it
// carried gathers on the far inner edge and falls on the backdrop beside it.
// The walls are a soap film whose colour turns with its thickness, with a thin
// dark inner membrane a little way in; the plasm inside carries faint
// organelles, the thread's girth wanders along its length, and the voice bead
// is a nucleus. A switch sends a swell out along the thread from the weld and
// streams the organelles with it; the new rim buds out of the weld, its swollen
// tip riding just behind its front, and the old rim pearls into droplets as it
// drains. Nothing moves once the rail's clock holds, so a still rail draws
// nothing.
//
// Everything comes from iData (laid out by rail-kit.lisp, rail-thread.lisp and
// rail-membrane.lisp, whose +rail-membrane--glass+ sets every strength), the
// cards from iWindow, and time from iTime. Coordinates are the output's, y down.

const int T_TW = THEME, T_RIM = THEME + 1, T_WELD = THEME + 2, T_WSIG = THEME + 3;
const int T_CORNER = THEME + 4, T_VW = THEME + 5, T_AMP = THEME + 6, T_PLUCK = THEME + 7;
const int T_PHZ = THEME + 8, T_ENV = THEME + 9, T_BEND = THEME + 10, T_BDEC = THEME + 11;
const int T_BHZ = THEME + 12, T_BSIG = THEME + 13, T_FDELAY = THEME + 14, T_FDUR = THEME + 15;
const int T_DDUR = THEME + 16, T_X = THEME + 17, T_TOP = THEME + 18, T_BOT = THEME + 19;
const int T_WY = THEME + 20, T_BEADS = THEME + 21, T_VLEN = THEME + 42, T_FSTYLE = THEME + 46;
// a bar: which one this surface is (1 the top, 2 the bottom, 3 the frames alone,
// 4 a side), its rect, and the blocks the thread carries there
const int T_MODE = THEME + 59, T_BR = THEME + 48, T_BN = THEME + 52;

const int NBEADS = 7;
const int B_CLOCK = 0, B_DATE = 1, B_CPU = 2, B_MEM = 3, VOICE_BEAD = 4, B_GPU = 5, B_VRAM = 6;

float g_mid, g_top, g_bot, g_wy;
vec4 g_fbox;
float g_dt, g_fill, g_drain, g_raw;
bool g_f;

// the backdrop under a point of the output, as the surface beneath it holds it
vec3 under(vec2 q) { return beneath(vec2(q.x - k_origin.x, k_h - (q.y - k_origin.y))).rgb; }

// ------------------------------------------------------------ the material
//
// Glass that reads as glass, from what the compositor hands every frosted
// shader: beneath() is the sharp backdrop, frost() the windows' own blur of it
// (their passes and offset, finished with the blur's vibrancy and noise). The
// glass is a dome over its field: steep at its edge, flat a radius in. Its
// edge band refracts the sharp backdrop inward, the three primaries by
// slightly different amounts; further in it carries the frost. Light comes
// from the top left: a sharp highlight where the dome faces it, a Fresnel
// reflection of a soft sky round the whole rim, and the light it carried
// through gathered on the far inner edge and thrown on the backdrop beside it.
// Every strength is a knob of +rail-membrane--glass+ (rail-membrane.lisp).

const int T_FROST = THEME + 47, T_LENS = THEME + 48, T_DISP = THEME + 49;
const int T_SPEC = THEME + 50, T_FRES = THEME + 51, T_VIB = THEME + 52;
const int T_GRAIN = THEME + 53, T_CAUS = THEME + 54, T_TINT = THEME + 55;
const int T_FILM = THEME + 56, T_BUD = THEME + 57, T_PLASM = THEME + 58;

const vec3 LIGHT = vec3(-0.80, -0.38, 0.62);   // y down: from the left and a little above, towards the viewer

vec3 frost_under(vec2 q) { return frost(vec2(q.x - k_origin.x, k_h - (q.y - k_origin.y))).rgb; }

vec3 saturate3(vec3 c, float s) {
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    return clamp(mix(vec3(l), c, s), 0.0, 1.0);
}

// interleaved gradient noise: a fixed per-pixel dither, so nothing shimmers
float ign(vec2 q) { return fract(52.9829189 * fract(dot(q, vec2(0.06711056, 0.00583715)))); }

// what the glass passes at Q: sharp at its rim, the frost where FRO says so
vec3 seen_at(vec2 q, float fro) { return mix(under(q), frost_under(q), fro); }

// The dome over the field: T 0 at the edge and 1 a radius in, its normal
struct dome { float t, e, h; vec3 n; };
dome dome_at(float f, vec2 dir, float radius) {
    dome d;
    d.t = clamp(-f / radius, 0.0, 1.0);
    d.e = 1.0 - d.t;
    d.h = sqrt(max(0.0, 1.0 - d.e * d.e));
    float slope = min(d.e / max(d.h, 0.15), 5.0);
    d.n = normalize(vec3(dir * slope, 1.0));
    return d;
}

// The light a dome of glass sends to the eye at P: refraction with
// dispersion, frost, vibrancy, a thin absorption, the Fresnel sky, the
// highlight and the gathered light on the far edge. LENS scales the bend
// (a membrane's wall bends less than a bead).
vec3 material(vec2 p, dome d, vec2 dir, float lens, float frostiness) {
    vec2 bend = -dir * lens * pow(d.e, 1.6) - d.n.xy * lens * 0.18;
    float k = D(T_DISP);
    float fro = mix(0.2, frostiness, smoothstep(0.05, 0.75, d.t));
    vec3 c = vec3(seen_at(p + bend * (1.0 - k), fro).r,
                  seen_at(p + bend, fro).g,
                  seen_at(p + bend * (1.0 + k), fro).b);
    c = saturate3(c, D(T_VIB));
    // glass scatters a little light, so dark glass still has a body
    c = c * 0.90 + 0.055;
    // a thin green-blue absorption through the thick of it, as soda glass has
    c *= mix(vec3(1.0), vec3(0.94, 0.985, 0.975), D(T_TINT) * d.h);
    vec3 l = normalize(LIGHT);
    // Fresnel: the rim mirrors a soft sky above and the room's dark below
    float fres = 0.04 + 0.96 * pow(1.0 - d.n.z, 5.0);
    // and the desktop beside it: the rim mirrors what stands a little outside it
    vec3 sky = mix(vec3(0.06), vec3(1.0), smoothstep(-0.7, 0.5, -d.n.y));
    vec3 near = frost_under(p + dir * 16.0) * 1.15 + 0.04;
    c = mix(c, mix(sky, near, 0.55), clamp(fres * D(T_FRES), 0.0, 1.0));
    // the highlight, sharp, with a broad sheen under it
    vec3 hv = normalize(l + vec3(0.0, 0.0, 1.0));
    float nh = max(dot(d.n, hv), 0.0);
    c += vec3(1.0) * D(T_SPEC) * (1.25 * pow(nh, 90.0) + 0.06 * pow(nh, 6.0));
    // the light it carried, gathered on the inner edge away from the lamp
    float far = max(0.0, dot(dir, -normalize(l.xy)));
    c += vec3(1.0, 0.985, 0.95) * D(T_CAUS) * far * smoothstep(0.30, 0.80, d.e)
        * (1.0 - smoothstep(0.86, 1.0, d.e)) * 0.45;
    // and the dark the very edge takes, where it turns light away
    c *= 1.0 - 0.30 * smoothstep(0.84, 1.0, d.e) * (1.0 - far);
    return c;
}

// Outside the glass: the shadow it casts away from the lamp and the light it
// focuses there, both falling off within a few pixels.
void cast_light(vec2 p, float f, vec2 dir, inout vec3 c, inout float a, float strength) {
    if (f <= 0.0 || f > 14.0) return;
    vec3 l = normalize(LIGHT);
    float far = max(0.0, dot(dir, -normalize(l.xy)));
    float caust = D(T_CAUS) * strength * far * exp(-pow((f - 4.0) / 2.6, 2.0)) * 0.30;
    if (caust > 0.0) {
        vec3 lit = min(under(p) * 1.35 + 0.10, vec3(1.0));
        c = mix(c, lit, caust);
        a = caust + a * (1.0 - caust);
    }
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
    if (g_raw >= 0.0 && g_raw < D(K_SETTLE) && D(K_FLOW) > -0.5
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
    // a strand of living stuff, not drawn wire: its girth wanders a little
    // along its length (fixed, so a still rail stays still), and a switch
    // sends a peristaltic swell out from the weld both ways
    float girth = 1.0 + D(T_PLASM) * 0.30 * sin(y * 0.029 + 1.3) * sin(y * 0.0113 + 0.4);
    float swell = 0.0;
    if (g_raw >= 0.0 && g_raw < D(K_SETTLE) && D(K_FLOW) > -0.5)
        swell = 0.55 * exp(-pow((abs(y - g_wy) - 1500.0 * g_dt) / 46.0, 2.0))
            * (1.0 - smoothstep(0.15, 0.55, g_dt));
    vec2 d = vec2(p.x - g_mid - thread_off(y), p.y - y);
    return length(d) - D(T_TW) * (girth + swell);
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

// the rim's thickness at rim distance S of PER: five pixels, and a little more
// where the voice is loud now -- the whole rim answers at once, so no side of
// the frame waits for a wave to arrive. The swell is the string's shape, not its
// bulk: it never thins the rim below its five, and it tops out at eleven, so a
// loud turn reads as the frame breathing rather than as a wide white band.
float rim_width(float s, float per) {
    float lev = voice_env() * min(1.0, voice_around(s, per));
    return D(T_RIM) + 6.0 * lev * (0.55 + 0.45 * sin(s * 0.030 - iTime * 26.0));
}

// the whole glass: the thread, its beads, the focused card's rim welded to the
// thread by a meniscus at the weld, and the drained rim of the card focus left
float field(vec2 p) {
    // far from the seam neither the thread nor a bead can reach within the
    // shadow's ten pixels, so the glass there is only the rim's
    float f = 1e3;
    if (abs(p.x - g_mid) < 48.0 && D(T_MODE) < 2.5) {
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
            // the new rim buds: a swollen tip rides just behind its front
            float w = rim_width(s, per);
            if (g_fill < 1.0)
                w += D(T_BUD) * 4.5 * exp(-pow((s - (g_fill * per * 0.5 - 34.0)) / 30.0, 2.0));
            float ring = max(d - w * pres, -d);
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
            // the old rim pearls as it drains: surface tension breaks it into
            // beads that run back into the weld
            float pearl = mix(1.0, 0.18 + 0.82 * pow(abs(cos(s * 0.034)), 1.6),
                              smoothstep(0.0, 0.65, 1.0 - g_drain) * D(T_BUD));
            f = min(f, max(d - D(T_RIM) * pres * pearl, -d));
        }
    }
    return f;
}

// The glass as a living membrane: the material over a dome, its outer wall a
// soap film whose colour turns with the film's thickness, a thin dark inner
// membrane a little way in, and the plasm inside carrying faint organelles.
vec3 glass(vec2 p, float f, vec2 dir, float shine) {
    dome d = dome_at(f, dir, 6.0);
    vec3 c = material(p, d, dir, D(T_LENS) * 0.8, D(T_FROST));
    float film = 0.55 * d.e + 0.22 * sin(p.x * 0.043 + p.y * 0.017)
               + 0.18 * sin(p.y * 0.0091 - p.x * 0.031 + 2.0);
    vec3 irid = 0.5 + 0.5 * cos(6.2832 * (film * 1.7 + vec3(0.0, 0.33, 0.67)));
    float edge = pow(d.e, 2.2) * (1.0 - smoothstep(0.92, 1.0, d.e) * 0.5);
    c = mix(c, c * 0.55 + irid * 0.62, clamp(D(T_FILM) * edge * 0.62, 0.0, 1.0));
    // the wall has a thickness: a clear band, then a thin dark inner membrane
    float inner = exp(-pow((-f - 3.2) / 0.55, 2.0)) * step(4.5, D(T_TW) + 6.0);
    float wall = smoothstep(0.35, 0.6, d.e) * (1.0 - smoothstep(0.8, 0.95, d.e));
    c = mix(c, c * 1.06 + 0.04, 0.5 * wall * D(T_FILM));
    c *= 1.0 - 0.38 * inner * D(T_FILM);
    if (d.t > 0.45 && D(T_PLASM) > 0.0) {
        // organelles: specks in the plasm, carried along the thread by a switch
        float stream = 0.0;
        bool bar = (D(T_MODE) > 0.5 && D(T_MODE) < 2.5) || D(T_MODE) > 3.5;
        if (!bar && g_raw >= 0.0 && g_raw < D(K_SETTLE) && D(K_FLOW) > -0.5)
            stream = 60.0 * sm(0.0, 1.0, g_dt / 0.44) * sign(p.y - g_wy);
        vec2 q = (p + vec2(0.0, stream)) / 3.0;
        vec2 cell = floor(q);
        float h = hf(hu(int(cell.x), int(cell.y), 11u));
        if (h < 0.22) {
            vec2 at = cell + 0.25 + 0.5 * vec2(hf(hu(int(cell.x), int(cell.y), 13u)),
                                               hf(hu(int(cell.x), int(cell.y), 17u)));
            float r = length(q - at);
            float lum = dot(c, vec3(0.3, 0.59, 0.11));
            float speck = (1.0 - smoothstep(0.18, 0.34, r)) * D(T_PLASM) * 0.16
                * smoothstep(0.45, 0.75, d.t);
            c = mix(c, lum > 0.5 ? c * 0.72 : c * 1.35 + 0.05, speck);
        }
    }
    return c + vec3(0.22) * clamp(shine, 0.0, 1.0);
}

// THREAD on a bar: the same glass, its thread run along the strip with a cell
// of it round each reading, the type of the readings set in by the rail
vec4 thread_bar(vec2 p) {
    vec4 r = vec4(D(T_BR), D(T_BR + 1), D(T_BR + 2), D(T_BR + 3));
    if (p.x < r.x || p.x >= r.z || p.y < r.y || p.y >= r.w) return vec4(0.0);
    bool down = D(T_MODE) > 3.5;      // a bar on a side runs down y
    float mid = down ? 0.5 * (r.x + r.z) : 0.5 * (r.y + r.w);
    float halfw = max(2.0, D(T_TW));
    float f = down ? sd_rbox(p, vec4(mid - halfw, r.y, mid + halfw, r.w), halfw)
                   : sd_rbox(p, vec4(r.x, mid - halfw, r.z, mid + halfw), halfw);
    int nb = int(D(T_BN));
    for (int i = 0; i < 8; i++) {
        if (i >= nb) break;
        int b0 = T_BN + 1 + i * 5;
        vec4 br = vec4(D(b0 + 1), D(b0 + 2), D(b0 + 3), D(b0 + 4));
        if (br.z <= br.x) break;
        f = smin(f, down ? sd_rbox(p, vec4(br.x + 8.0, br.y + 4.0, br.z - 8.0, br.w - 4.0), 10.0)
                         : sd_rbox(p, vec4(br.x + 4.0, br.y + 8.0, br.z - 4.0, br.w - 8.0), 10.0), 6.0);
    }
    float cov = clamp(0.5 - f, 0.0, 1.0);
    if (cov <= 0.0) return vec4(0.0);
    vec2 dir = down ? normalize(vec2(p.x - mid, 1e-5)) : normalize(vec2(1e-5, p.y - mid));
    return vec4(glass(p, f, dir, 0.0), cov);
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


// Horizontal bar (T_MODE == 1 top, 2 bottom): the exact same living-glass
// membrane thread and beads rotated 90 degrees, with organic girth wander,
// caustic, soap film, organelles, gauge fills, voice nucleus, and bitmap type.
float hbar_off(float x) {
    float dx = abs(x - g_wy);
    float lev = voice_env() * voice_level(dx / max(1.0, D(T_VW)));
    float pluck = D(T_AMP) * lev * sin(dx * D(T_PLUCK) - iTime * D(T_PHZ))
        * (0.4 + 0.6 * exp(-dx * D(T_ENV)));
    float node = 1.0;
    for (int i = 0; i < NBEADS; i++) {
        float hx = bead_hy(i);
        if (hx <= 0.0) continue;
        node = min(node, clamp((abs(x - bead_cy(i)) - hx) / 18.0, 0.0, 1.0));
    }
    return pluck * node;
}

float hbar_field(vec2 p) {
    float x = clamp(p.x, g_top, g_bot);
    vec2 d = vec2(p.x - x, p.y - g_mid - hbar_off(x));
    float girth = 1.0 + 0.14 * D(T_PLASM)
        * (0.6 * sin(x * 0.017 + 0.7) + 0.4 * sin(x * 0.041 - 1.3));
    float f = length(d) - D(T_TW) * girth;
    float swell = voice_env();
    for (int i = 0; i < NBEADS; i++) {
        float hx = bead_hy(i);
        if (hx <= 0.0) continue;
        float hy = bead_hw(i);
        if (i == VOICE_BEAD) {
            hx += 6.0 * swell;
            hy += 2.0 * swell;
        }
        float cx = bead_cy(i);
        f = smin(f, sd_rbox(p, vec4(cx - hx, g_mid - hy, cx + hx, g_mid + hy), min(hy, 12.0)), 6.0);
    }
    return f;
}

void set_type_hbar(vec2 p, inout vec3 c) {
    for (int i = 0; i < NBEADS; i++) {
        float hx = bead_hy(i);
        if (hx <= 0.0) continue;
        float cx = bead_cy(i), cy = g_mid, hy = bead_hw(i);
        if (abs(p.x - cx) > hx + 2.0 || abs(p.y - cy) > hy + 2.0) continue;
        vec2 mid = vec2(cx, cy);
        bool on = false;
        float a = 1.0;
        if (i == B_CLOCK) {
            float x0 = cx - 0.5 * text_span(5, 3.0);
            on = char_hit(p, vec2(x0, cy - 7.5), vec2(3.0), K_CLOCK, 0, 5);
        } else if (i == B_DATE) {
            float w_day = text_span(3, 2.0);
            float w_num = text_span(2, 3.0);
            float w_mon = text_span(3, 2.0);
            float gap = 6.0;
            float x0 = cx - 0.5 * (w_day + gap + w_num + gap + w_mon);
            on = char_hit(p, vec2(x0, cy - 5.0), vec2(2.0), K_DAY, 0, 3);
            a = 0.72;
            if (!on) {
                on = char_hit(p, vec2(x0 + w_day + gap, cy - 7.5), vec2(3.0), K_DATE, 0, 2);
                a = 1.0;
            }
            if (!on) {
                on = char_hit(p, vec2(x0 + w_day + gap + w_num + gap, cy - 5.0), vec2(2.0), K_DATE, 3, 3);
                a = 0.76;
            }
        } else if (i != VOICE_BEAD) {
            int k = i == B_CPU ? 0 : (i == B_MEM ? 1 : (i == B_GPU ? 2 : 3));
            if (gauge_pct(k) < 0.0) continue;
            int base = K_GAUGES + k * K_GAUGE;
            int vlen = clamp(int(D(T_VLEN + k)), 1, 6);
            float w_lbl = text_span(3, 2.0);
            float w_val = text_span(vlen, 2.0);
            float gap = 7.0;
            float x0 = cx - 0.5 * (w_lbl + gap + w_val);
            on = char_hit(p, vec2(x0, cy - 5.0), vec2(2.0), base + 4, 0, 3);
            a = 0.72;
            if (!on) {
                on = char_hit(p, vec2(x0 + w_lbl + gap, cy - 7.5), vec2(2.0, 3.0), base + 2, 0, vlen);
                a = 1.0;
            }
        }
        if (on) c = mix(c, ink_of(mid), a);
    }
}

vec4 hbar_render(vec2 p) {
    g_mid = D(T_X);
    g_top = D(T_TOP);
    g_bot = D(T_BOT);
    g_wy = D(T_WY);
    g_raw = iTime - D(K_TSW);
    g_dt = move_age(D(T_FDELAY) + D(T_FDUR));

    float f = hbar_field(p);
    if (f > 14.0) return vec4(0.0);

    vec2 slant = vec2(hbar_field(p + vec2(1.0, 0.0)) - f, hbar_field(p + vec2(0.0, 1.0)) - f);
    vec2 dir = slant / (length(slant) + 1e-5);

    vec3 c = vec3(0.0);
    float a = 0.0;
    float cov = clamp(0.5 - f, 0.0, 1.0);
    float sh = f > 0.0 ? 0.16 * pow(clamp(1.0 - f / 10.0, 0.0, 1.0), 2.0) : 0.0;
    float hair = 0.34 * clamp(1.0 - abs(f - 0.6) / 0.9, 0.0, 1.0);
    c *= 1.0 - sh;
    a = sh + a * (1.0 - sh);
    c *= 1.0 - hair;
    a = hair + a * (1.0 - hair);
    cast_light(p, f, dir, c, a, 1.0);
    if (cov > 0.0) {
        c = mix(c, glass(p, f, dir, 0.0), cov);
        a = cov + a * (1.0 - cov);
    }

    if (cov > 0.25) {
        for (int k = 0; k < 4; k++) {
            int bead = k < 2 ? 2 + k : 3 + k;
            float hx = bead_hy(bead);
            if (hx <= 0.0) continue;
            float pct = gauge_pct(k);
            if (pct < 0.0) continue;
            float cx = bead_cy(bead), cy = g_mid;
            vec4 box = vec4(cx - hx + 3.0, cy - 11.0, cx + hx - 3.0, cy + 11.0);
            float d = sd_rbox(p, box, 9.0);
            if (d > 1.0) continue;
            float lum = dot(under(vec2(cx, cy)), vec3(0.3, 0.59, 0.11));
            float x1 = box.x + (box.z - box.x) * clamp(pct, 0.0, 100.0) / 100.0;
            float fill = clamp(x1 - p.x, 0.0, 1.0) * clamp(0.5 - d, 0.0, 1.0);
            float fa = fill * (lum > 0.5 ? 0.22 : 0.30);
            c = mix(c, lum > 0.5 ? vec3(0.0) : vec3(1.0), fa);
            a = fa + a * (1.0 - fa);
        }
        if (bead_hy(VOICE_BEAD) > 0.0) {
            float rr = 5.0 + 6.0 * voice_env() * voice_level(0.0);
            vec2 nc = vec2(bead_cy(VOICE_BEAD), g_mid);
            float dd = length((p - nc) * vec2(0.82, 1.0)) - rr;
            if (dd < 1.5) {
                float lum = dot(under(nc), vec3(0.3, 0.59, 0.11));
                float da = clamp(0.5 - dd, 0.0, 1.0) * (0.30 + 0.45 * voice_env());
                c = mix(c, lum > 0.5 ? c * 0.55 : c * 0.70 + vec3(0.10, 0.12, 0.14), da);
                float nl = length(p - nc - vec2(-1.6, -1.4)) - 1.6 - 1.5 * voice_env();
                float na = clamp(0.5 - nl, 0.0, 1.0) * 0.8;
                c = mix(c, lum > 0.5 ? vec3(0.10) : vec3(0.95, 0.94, 0.90), na);
                a = max(a, da);
            }
        }
        set_type_hbar(p, c);
    }

    if (a <= 0.0) return vec4(0.0);
    c = clamp(c + (ign(p) - 0.5) * D(T_GRAIN) / 255.0, 0.0, 1.0);
    return vec4(c, a);
}

void mainImage(out vec4 color, in vec2 fragCoord) {
    kit_begin();
    vec2 p = kit_point(fragCoord);
    if (D(T_MODE) > 0.5 && D(T_MODE) < 2.5) {
        color = hbar_render(p);
        if (color.a <= 0.0) discard;
        return;
    }
    if (D(T_MODE) > 3.5) {
        color = thread_bar(p);
        if (color.a <= 0.0) discard;
        return;
    }
    color = vec4(0.0);

    g_mid = D(T_X);
    g_top = D(T_TOP);
    g_bot = D(T_BOT);
    g_wy = D(T_WY);
    g_raw = iTime - D(K_TSW);
    g_dt = move_age(D(T_FDELAY) + D(T_FDUR));
    int focus = int(D(K_FOCUS)), old = int(D(K_OLD));
    g_f = card_shown(focus);
    if (g_f) g_fbox = card(focus);
    g_fill = 1.0;
    g_drain = 0.0;
    if (D(K_TSW) > -1e5 && g_raw >= 0.0 && g_raw < D(K_SETTLE) && D(K_FLOW) > -0.5) {
        g_fill = clamp((g_dt - D(T_FDELAY)) / max(0.01, D(T_FDUR)), 0.0, 1.0);
        if (card_shown(old) && old != focus)
            g_drain = 1.0 - pow(clamp(g_dt / max(0.01, D(T_DDUR)), 0.0, 1.0), 1.7);
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
    // The focused card's shadow, only where the rail asks for one: a low, wide
    // contact shadow in the ink that reads on what lies there, so the card sits
    // on the wallpaper instead of wearing a band of it. It is cast six pixels
    // down from the rim, where a light above the screen would throw it, falls
    // away over twenty-two pixels rather than twelve, and is two-fifths the
    // alpha the old halo carried. It comes in as the rim fills and leaves the
    // card focus left as that rim drains.
    float glow = 0.0;
    vec4 gbox = g_fbox;
    if (style == 3 && g_f) {
        float drim = sd_rbox(p - vec2(0.0, 6.0), g_fbox, D(T_CORNER)) - D(T_RIM);
        if (drim > 0.0) glow = 0.18 * g_fill * exp(-drim / 22.0);
    }
    if (style == 3 && g_drain > 0.0 && card_shown(old)) {
        vec4 ob = card(old);
        float drim = sd_rbox(p - vec2(0.0, 6.0), ob, D(T_CORNER)) - D(T_RIM);
        float was = drim > 0.0 ? 0.18 * g_drain * exp(-drim / 22.0) : 0.0;
        if (was > glow) {
            glow = was;
            gbox = ob;
        }
    }

    float f = field(p);
    if (f > 14.0 && hdark <= 0.0 && hlight <= 0.0 && glow <= 0.0) discard;

    vec2 slant = vec2(field(p + vec2(1.0, 0.0)) - f, field(p + vec2(0.0, 1.0)) - f);
    vec2 dir = slant / (length(slant) + 1e-5);

    // how brightly the voice's crests light the glass at p
    float shine = 0.0;
    if (g_f && f < 0.5) {
        float s, per;
        float pres = rim_pres(p, g_fbox, g_fill, s, per);
        if (pres > 0.01)
            shine = voice_env() * min(1.0, voice_around(s, per)) * pres;
    }

    vec3 c = vec3(0.0);
    float a = 0.0;
    c = mix(c, vec3(0.0), hdark);
    a = hdark + a * (1.0 - hdark);
    c = mix(c, vec3(1.0), hlight);
    a = hlight + a * (1.0 - hlight);
    if (glow > 0.0) {
        c = mix(c, ink_of(clamp(p, gbox.xy, gbox.zw)), glow);
        a = glow + a * (1.0 - glow);
    }

    float cov = clamp(0.5 - f, 0.0, 1.0);
    float sh = f > 0.0 ? 0.16 * pow(clamp(1.0 - f / 10.0, 0.0, 1.0), 2.0) : 0.0;
    float hair = 0.34 * clamp(1.0 - abs(f - 0.6) / 0.9, 0.0, 1.0);
    c *= 1.0 - sh;
    a = sh + a * (1.0 - sh);
    c *= 1.0 - hair;
    a = hair + a * (1.0 - hair);
    cast_light(p, f, dir, c, a, 1.0);
    if (cov > 0.0) {
        c = mix(c, glass(p, f, dir, shine), cov);
        a = cov + a * (1.0 - cov);
    }

    // inside the beads: each gauge's level of denser glass from its foot up, and
    // the voice bead's own dot; both take their tone from the backdrop's luminance
    if (cov > 0.25 && D(T_MODE) < 2.5) {
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
        // the voice bead's nucleus: a darker body that swells with the voice,
        // a bright nucleolus off its centre
        float rr = 5.0 + 6.0 * voice_env() * voice_level(0.0);
        vec2 nc = vec2(g_mid, bead_cy(VOICE_BEAD));
        float dd = length((p - nc) * vec2(1.0, 0.82)) - rr;
        if (dd < 1.5) {
            float lum = dot(under(nc), vec3(0.3, 0.59, 0.11));
            float da = clamp(0.5 - dd, 0.0, 1.0) * (0.30 + 0.45 * voice_env());
            c = mix(c, lum > 0.5 ? c * 0.55 : c * 0.70 + vec3(0.10, 0.12, 0.14), da);
            float nl = length(p - nc - vec2(-1.6, -1.4)) - 1.6 - 1.5 * voice_env();
            float na = clamp(0.5 - nl, 0.0, 1.0) * 0.8;
            c = mix(c, lum > 0.5 ? vec3(0.10) : vec3(0.95, 0.94, 0.90), na);
            a = max(a, da);
        }
        set_type(p, c);
    }

    if (a <= 0.0) discard;
    c += (ign(p) - 0.5) * D(T_GRAIN) / 255.0 * a;
    color = vec4(c, a);
}
