// sand: pixels as matter. The rail's seam is a glass tube with the date and the
// clock cast in grains, the readings piled as sand in glass compartments, and
// bolo's voice a bed of grains that hops with the level history and a frame of
// grains that all jump at once, the frame's own grains by their own share of the
// level so the whole border is the waveform. Every card the
// rail carries has a frame of packed four-pixel grains, three rows deep, each
// grain its own tone and a few catching the light; a card out of focus keeps
// only a dusting of loose grains along its inner edge.
//
// Focus is poured. The old frame's grains drop, drift and run along its bottom
// edge into the tube while the new frame is poured out of the tube: its top
// edge fills from the far end toward the rail behind a spray, its sides fill
// from the bottom up as grains fall from the top corner, and its bottom edge
// runs in from both corners. Every grain's position is a closed form of its
// cell, the time since the switch and a hash of that cell, so nothing is
// integrated or simulated: the shader can draw any instant of the motion and
// stops drawing when it has landed. The tube draws its own three-by-five
// bitmap text in the SAND palette; its sand levels follow the glided readings
// and its bed hops with the level history under the voice envelope, dying away
// over the settle when the turn closes.
//
// One shader draws both surfaces: the frames over the output (iData mode
// 0), and the tube down the seam (mode 1). Coordinates below are the output's,
// y down.

float D(int i) { return iData[i >> 2][i & 3]; }
vec3 D3(int i) { return vec3(D(i), D(i + 1), D(i + 2)); }

const int MODE = 0, OX = 1, OY = 2, GRAIN = 3, RING = 4, MID = 5;
const int TONE = 6, GLINT = 18, DUST = 21, GLASS = 24, GLASSHI = 27;
const int INSIDE = 30, INK = 33, DIM = 36, RED = 39;
const int GRAV = 42, VTOP = 43, VFLOW = 44;
const int VOICE = 45, LEVELS = 51;
const int TSW = 99, SETTLE = 100, FOCUS = 101, OLD = 102, ANIM = 103;
const float DESIGN = 0.7;      // seconds the pour was drawn for
const int TX0 = 99, TX1 = 100, TY0 = 101, TY1 = 102, VY1 = 103;
const int DATEY = 104, DATE2Y = 105, CLK1 = 106, CLK2 = 107;
const int GY = 108, GN = 109, GH = 110;
const int DAY = 111, DATE = 113, HOUR = 115, MINUTE = 117, TIMER = 119, VKIND = 121;
const int GAUGES = 122, GSLOT = 10;

#define PI 3.14159265358979

float sm(float a, float b, float x) {
    float u = clamp((x - a) / (b - a), 0.0, 1.0);
    return u * u * (3.0 - 2.0 * u);
}

uint hu(int a, int b, uint s) {
    uint h = uint(a) * 73856093u ^ uint(b) * 19349663u ^ s * 83492791u;
    h = (h ^ (h >> 13)) * 1274126177u;
    h = h ^ (h >> 16);
    return h;
}

float hf(uint h) { return float(h & 0xffffu) / 65536.0; }

vec3 tonef(float h) {
    float f = h * 3.999;
    if (f < 1.0) return D3(TONE);
    if (f < 2.0) return D3(TONE + 3);
    if (f < 3.0) return D3(TONE + 6);
    return D3(TONE + 9);
}

float voice_amp() {
    float on = D(VOICE), since = D(VOICE + 1), fade = D(VOICE + 2);
    float settle = max(0.01, D(VOICE + 3)), rise = max(0.01, D(VOICE + 4));
    if (int(D(VOICE + 5)) <= 0) return 0.0;
    if (on > 0.5) return sm(0.0, 1.0, (iTime - since) / rise);
    if (fade > -1e8)
        return sm(0.0, 1.0, (fade - since) / rise) * (1.0 - sm(0.0, 1.0, (iTime - fade) / settle));
    return 0.0;
}

float level_age(float age) {
    int n = int(D(VOICE + 5));
    if (n <= 0) return 0.0;
    int i = clamp(int(age * 30.0 + 0.5), 0, n - 1);
    return D(LEVELS + i);
}

const int GLYPH[96] = int[96](
    0, 0, 0, 0, 0, 21157, 0, 0, 0, 0, 0, 1488,
    0, 448, 8192, 4772, 31599, 29850, 29671, 31143, 18925, 31183, 31695, 9511,
    31727, 31215, 1040, 0, 0, 0, 6105, 0, 0, 23530, 15083, 25166,
    15211, 29391, 4815, 27470, 23533, 29847, 11044, 23277, 29257, 23549, 23403, 11114,
    4843, 26474, 23275, 14478, 9367, 31597, 11117, 24557, 23213, 9389, 29351, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 9362, 0, 0, 0
);

int gmask(int c) {
    if (c == 176) return 27;
    if (c < 32 || c > 127) return 0;
    return GLYPH[c - 32];
}

int gcode(float a, float b, int i) {
    if (i == 0) return int(mod(a, 256.0) + 0.5);
    if (i == 1) return int(floor(a / 256.0) + 0.5);
    if (i == 2) return int(mod(b, 256.0) + 0.5);
    return int(floor(b / 256.0) + 0.5);
}

int text_len(float a, float b, int nmax) {
    int n = 0;
    for (int i = 0; i < 4; i++) {
        int c = gcode(a, b, i);
        if (c != 32 && c != 0) n = i + 1;
    }
    return min(n, nmax);
}

float text_width(float s, int n) { return 3.5 * s * float(n) - 0.5 * s; }

bool text_hit(vec2 p, vec2 at, float s, int nmax, float a, float b) {
    vec2 q = p - at;
    if (q.x < 0.0 || q.y < 0.0 || q.y >= 5.0 * s) return false;
    float adv = 3.5 * s;
    float fi = floor(q.x / adv);
    if (fi >= float(nmax)) return false;
    int col = int(floor((q.x - fi * adv) / s));
    if (col > 2) return false;
    int row = int(floor(q.y / s));
    int mask = gmask(gcode(a, b, int(fi)));
    return (mask & (1 << (row * 3 + col))) != 0;
}

vec2 g_origin;
float g_h;

vec4 card(int i) {
    vec4 w = iWindow[i];
    float top = g_h - (w.y + w.w);
    return vec4(w.x + g_origin.x, top + g_origin.y, w.x + w.z + g_origin.x, top + w.w + g_origin.y);
}

bool card_shown(int i) { return i >= 0 && i < iWindowCount && iWindow[i].z > 0.0; }

vec4 miss() { return vec4(0.0); }

vec4 grain_colour(uint h3, uint h4, bool fresh) {
    if (fresh || hf(h4) < 0.025) return vec4(D3(GLINT), 1.0);
    return vec4(tonef(hf(h3)), 1.0);
}

// The voice's three bands, read out of the history the rail already packs: the
// swell of the last third of a second, the level now, and how fast it is moving.
float vo_lo() {
    int n = max(1, int(D(VOICE + 5)));
    float m = 0.0;
    for (int i = 0; i < 9; i++) m = max(m, D(LEVELS + min(i, n - 1)));
    return m;
}

float vo_hi() {
    int n = int(D(VOICE + 5));
    if (n < 2) return 0.0;
    float s = 0.0;
    for (int i = 0; i < 6; i++)
        s += abs(D(LEVELS + min(i, n - 1)) - D(LEVELS + min(i + 1, n - 1)));
    return min(1.0, s * 0.5);
}

// How far the voice reaches at perimeter point D of PER right now: a standing
// pattern, fixed in space and filled by the three bands, so the whole frame
// moves at once and the far corner is as loud as the near one.
float voice_here(float d, float per) {
    float th = 6.2832 * d / max(1.0, per);
    float stand = 0.58 + 0.42 * (0.62 * sin(3.0 * th + 0.7) + 0.38 * sin(5.0 * th - 1.3));
    float beat = 0.55 + 0.45 * sin(iTime * 12.0);
    float spark = fract(sin(floor(d / 8.0) * 12.9898 + floor(iTime * 26.0) * 78.233) * 43758.5453);
    return vo_lo() * (0.60 + 0.40 * stand)
         + D(LEVELS) * (0.30 + 0.70 * beat) * (0.55 + 0.45 * stand)
         + vo_hi() * (0.20 + 0.80 * spark);
}

vec4 packed_shot(vec2 p, vec4 box, bool rail_right, bool voicing) {
    float g = D(GRAIN), ring = D(RING);
    float bw = box.z - box.x, bh = box.w - box.y;
    ivec2 ci = ivec2(floor(p / g));
    vec2 cc = (vec2(ci) + 0.5) * g;
    float rx = cc.x - box.x, ry = cc.y - box.y;
    bool inside = rx > 0.0 && rx < bw && ry > 0.0 && ry < bh;
    float amp0 = voicing ? voice_amp() : 0.0;
    if (amp0 > 0.001) {
        // The frame's own grains, each hopping out off its edge by at most five
        // grains: the top and bottom rows run the card's width and its corners,
        // the sides its height, so nothing past this card's own ring moves.
        float hop = ring + 5.0 * g;
        if (inside || rx <= -hop || rx >= bw + hop || ry <= -hop || ry >= bh + hop) return miss();
        for (int edge = 0; edge < 4; edge++) {
            float along = edge < 2 ? rx : ry;
            if (edge < 2 ? (along <= -ring || along >= bw + ring) : (along <= 0.0 || along >= bh))
                continue;
            for (int row = 0; row < 3; row++) {
                float off = 0.5 * g + float(row) * g;
                int sx = ci.x, sy = ci.y;
                if (edge == 0) sy = int(floor((box.y - off) / g));
                else if (edge == 1) sy = int(floor((box.y + bh + off) / g));
                else if (edge == 2) sx = int(floor((box.x - off) / g));
                else sx = int(floor((box.x + bw + off) / g));
                float d = max(0.0, edge == 0 ? (rail_right ? bw - along : along)
                        : edge == 1 ? (bh + (rail_right ? bw - along : along))
                        : edge == 2 ? along : (bw + along));
                float hh = hf(hu(sx, sy, 2u));
                float per = 0.11 + 0.06 * hh;
                float ph = hh * per;
                float tl = iTime - d / 7200.0;
                float kk = floor((tl + ph) / per);
                float u = (tl + ph) / per - kk;
                float lv = voice_here(d, 2.0 * (bw + bh));
                float m = amp0 * min(1.0, lv) * (1.0 + 3.5 * hh) * 16.0 * u * (1.0 - u);
                vec2 sc = (vec2(float(sx), float(sy)) + 0.5) * g;
                bool hit;
                if (edge == 0) hit = abs(cc.y - (sc.y - m)) < g * 0.5 && abs(cc.x - sc.x) < g * 0.5;
                else if (edge == 1) hit = abs(cc.y - (sc.y + m)) < g * 0.5 && abs(cc.x - sc.x) < g * 0.5;
                else if (edge == 2) hit = abs(cc.x - (sc.x - m)) < g * 0.5 && abs(cc.y - sc.y) < g * 0.5;
                else hit = abs(cc.x - (sc.x + m)) < g * 0.5 && abs(cc.y - sc.y) < g * 0.5;
                if (hit) return grain_colour(hu(sx, sy, 3u), hu(sx, sy, 4u), false);
            }
        }
        return miss();
    }
    float b = max(max(-rx, rx - bw), max(-ry, ry - bh));
    if (inside || b < 0.0 || b >= ring) return miss();
    ivec2 co = ivec2(floor(p / g));
    return grain_colour(hu(co.x, co.y, 3u), hu(co.x, co.y, 4u), false);
}

vec4 dust_shot(vec2 p, vec4 box) {
    float g = D(GRAIN), ring = D(RING);
    float bw = box.z - box.x, bh = box.w - box.y;
    ivec2 ci = ivec2(floor(p / g));
    vec2 cc = (vec2(ci) + 0.5) * g;
    float rx = cc.x - box.x, ry = cc.y - box.y;
    float b = max(max(-rx, rx - bw), max(-ry, ry - bh));
    if (b < 0.0 || b >= g) return miss();
    if (hf(hu(ci.x, ci.y, 2u)) < 0.45) return vec4(D3(DUST), 1.0);
    return miss();
}

vec4 pour_shot(vec2 p, vec4 box, bool rail_right, float dt) {
    float g = D(GRAIN), ring = D(RING);
    float bw = box.z - box.x, bh = box.w - box.y;
    ivec2 ci = ivec2(floor(p / g));
    vec2 cc = (vec2(ci) + 0.5) * g;
    float rx = cc.x - box.x, ry = cc.y - box.y;
    float b = max(max(-rx, rx - bw), max(-ry, ry - bh));
    bool inside = rx > 0.0 && rx < bw && ry > 0.0 && ry < bh;
    if (inside || b < 0.0 || b >= ring) return miss();
    int e = ry < 0.0 ? 0 : (ry >= bh ? 1 : (rx < 0.0 ? 2 : 3));
    uint h1 = hu(ci.x, ci.y, 1u), h2 = hu(ci.x, ci.y, 2u);
    uint h3 = hu(ci.x, ci.y, 3u), h4 = hu(ci.x, ci.y, 4u);
    float grav = D(GRAV), vtop = D(VTOP), vflow = D(VFLOW);
    float d = rail_right ? bw - rx : rx;
    float tfar = bw / vtop;
    float fallall = sqrt(2.0 * (bh + 2.0) / grav);
    float arr;
    if (e == 0) arr = d / vtop + 0.01 * hf(h1);
    else if (e == 1)
        arr = (d < bw * 0.5 ? fallall + d / vflow : tfar + fallall + (bw - d) / vflow) + 0.01 * hf(h1);
    else {
        bool near = (rail_right && e == 3) || (!rail_right && e == 2);
        float tc = near ? 0.0 : tfar;
        arr = tc + 0.16 * (1.0 - (ry + 2.0) / (bh + 4.0)) + 0.008 * hf(h1)
            + sqrt(2.0 * max(ry + 2.0, 0.0) / grav);
    }
    if (dt >= arr) return grain_colour(h3, h4, dt - arr < 0.05);
    if (e == 0 && dt > 0.0) {
        float sx = rail_right ? bw - vtop * dt : vtop * dt;
        if (abs(rx - sx) <= g * 0.5 && dt < tfar + 0.03) {
            float lead = rail_right ? bw - rx : rx;
            float hop = 4.0 * g * hf(h2) * sin(clamp(lead / 400.0, 0.0, 1.0) * PI);
            return grain_colour(h3, h4, false);
        }
    }
    if ((e == 2 || e == 3) && dt > 0.0) {
        bool near = (rail_right && e == 3) || (!rail_right && e == 2);
        float tc = near ? 0.0 : tfar;
        float tt = sqrt(max(2.0 * (ry + 2.0) / grav, 0.0));
        float depart = dt - tt;
        if (depart > tc) {
            float src = (bh + 4.0) * (1.0 - (depart - tc) / 0.16) - 2.0;
            if (src > ry && src <= bh + ring) {
                int sy = int(floor((box.y + src) / g));
                return grain_colour(hu(ci.x, sy, 3u), hu(ci.x, sy, 4u),
                                    abs(src - ry) < 6.0);
            }
        }
    }
    if (e == 1 && dt > 0.0) {
        float x1 = rail_right ? bw + fallall * vflow - vflow * dt : vflow * dt - fallall * vflow;
        float x2 = rail_right ? vflow * dt - (tfar + fallall) * vflow
                              : bw - vflow * dt + (tfar + fallall) * vflow;
        if (abs(rx - x1) <= g * 0.5 || abs(rx - x2) <= g * 0.5) return grain_colour(h3, h4, false);
    }
    return miss();
}

vec4 collapse_shot(vec2 p, vec4 box, bool rail_right, float dt) {
    float g = D(GRAIN), ring = D(RING);
    float bw = box.z - box.x, bh = box.w - box.y;
    ivec2 ci = ivec2(floor(p / g));
    vec2 cc = (vec2(ci) + 0.5) * g;
    float rx = cc.x - box.x, ry = cc.y - box.y;
    float b = max(max(-rx, rx - bw), max(-ry, ry - bh));
    bool inside = rx > 0.0 && rx < bw && ry > 0.0 && ry < bh;
    if (!inside && (b < 0.0 || b >= ring)) return miss();
    uint h1 = hu(ci.x, ci.y, 1u), h2 = hu(ci.x, ci.y, 2u);
    if (!inside && b < g && hf(h2) < 0.45) return vec4(D3(DUST), 1.0);
    float rel = 0.012 + 0.05 * hf(h1);
    float tt = dt - rel;
    int e = ry < 0.0 ? 0 : (ry >= bh ? 1 : (rx < 0.0 ? 2 : 3));
    if (!inside && e == 0) {
        if (tt <= 0.0) return grain_colour(hu(ci.x, ci.y, 3u), hu(ci.x, ci.y, 4u), false);
        return miss();
    }
    float grav = D(GRAV);
    if (!inside && e == 1) {
        if (tt <= 0.0) return grain_colour(hu(ci.x, ci.y, 3u), hu(ci.x, ci.y, 4u), false);
        float ybot = bh + g - 2.0 * hf(h2) * g;
        float spend = sqrt(max(2.0 * max(ybot - ry, 0.0) / grav, 0.0));
        float run = max(tt - spend, 0.0) * D(VFLOW) * (0.8 + 0.4 * hf(h1));
        float dir = rail_right ? 1.0 : -1.0;
        float sx = rx - dir * run;
        if (sx > -ring && sx < bw + ring) {
            int sxc = int(floor((box.x + sx) / g)), syc = int(floor((box.y + ry) / g));
            return grain_colour(hu(sxc, syc, 3u), hu(sxc, syc, 4u), false);
        }
        return miss();
    }
    float sy = ry - 0.5 * grav * max(dt - 0.037, 0.0) * max(dt - 0.037, 0.0);
    float sxx = rx;
    for (int k = 0; k < 2; k++) {
        int sxc = int(floor((box.x + sxx) / g)), syc = int(floor((box.y + sy) / g));
        uint hs = hu(sxc, syc, 1u);
        float r = 0.012 + 0.05 * hf(hs);
        float fall = 0.5 * grav * max(dt - r, 0.0) * max(dt - r, 0.0);
        sy = ry - fall;
        sxx = rx - (hf(hu(sxc, syc, 2u)) - 0.5) * 12.0 * sm(0.0, 0.2, dt);
    }
    float sb = max(max(-sxx, sxx - bw), max(-sy, sy - bh));
    if (sb >= 0.0 && sb < ring && sy < ry) {
        int sxc = int(floor((box.x + sxx) / g)), syc = int(floor((box.y + sy) / g));
        return grain_colour(hu(sxc, syc, 3u), hu(sxc, syc, 4u), false);
    }
    return miss();
}

vec4 frames_shot(vec2 p) {
    float raw = iTime - D(TSW);
    float dt = DESIGN * max(raw, 0.0) / max(D(SETTLE), 0.02);
    bool anim = D(ANIM) > 0.5 && raw >= 0.0;
    int focus = int(D(FOCUS));
    int old = int(D(OLD));
    vec4 hit = miss();
    if (card_shown(focus))
        hit = anim ? pour_shot(p, card(focus), (card(focus).x + card(focus).z) * 0.5 < D(MID), dt)
                   : packed_shot(p, card(focus), (card(focus).x + card(focus).z) * 0.5 < D(MID),
                                 D(VOICE + 5) > 0.0);
    if (hit.a <= 0.0 && anim && old >= 0 && old != focus && card_shown(old))
        hit = collapse_shot(p, card(old), (card(old).x + card(old).z) * 0.5 < D(MID), dt);
    if (hit.a <= 0.0) {
        for (int i = 0; i < iWindowCount; i++) {
            if (!card_shown(i) || i == focus || (anim && i == old)) continue;
            hit = dust_shot(p, card(i));
            if (hit.a > 0.0) break;
        }
    }
    return hit;
}

vec4 tube_shot(vec2 p) {
    float x0 = D(TX0), x1 = D(TX1), y0 = D(TY0), y1 = D(TY1);
    if (p.x < x0 || p.x >= x1 || p.y < y0 || p.y >= y1) return miss();
    float g = D(GRAIN);
    float cx = (x0 + x1) * 0.5;
    float vy1 = D(VY1);
    vec3 c = D3(INSIDE);
    if (p.x < x0 + 2.0 || p.x >= x1 - 2.0 || p.y < y0 + 2.0 || p.y >= y1 - 2.0) c = D3(GLASS);
    if (p.x >= x0 && p.x < x0 + 2.0 && mod(floor((p.y - y0) / g), 2.0) < 0.5)
        c = D3(GLASSHI);
    if (p.y >= vy1 - 2.0 && p.y < vy1) c = D3(GLASS);
    float amp = voice_amp();
    if (p.y > vy1 - 380.0 && p.y < vy1 - 2.0) {
        ivec2 ci = ivec2(floor(p / g));
        vec2 cc = (vec2(ci) + 0.5) * g;
        if (cc.x > x0 + 2.0 && cc.x < x1 - 2.0) {
            for (int row = 0; row < 7; row++) {
                float depth = float(row);
                int sy = int(floor((vy1 - 2.0 - float(row) * g) / g));
                if (!(depth < 0.5 || hf(hu(ci.x, sy, 11u)) < 0.75 - 0.12 * depth)) continue;
                vec2 sc = (vec2(float(ci.x), float(sy)) + 0.5) * g;
                float hh = hf(hu(ci.x, sy, 13u));
                float per = 0.12 + 0.07 * hh;
                float ph = hf(hu(ci.x, sy, 12u)) * per;
                float tl = iTime + ph;
                float kk = floor(tl / per);
                float u = tl / per - kk;
                float lv = level_age(max(0.0, u * per));
                float hop = amp * lv * (0.3 + 0.7 * hh) * exp(-max(depth, 0.0) / 4.0)
                    * (0.6 + 0.4 * cos((cc.x - cx) / 20.0)) * 340.0 * u * (1.0 - u);
                if (abs(cc.y - (sc.y - hop)) < g * 0.5)
                    c = tonef(hf(hu(ci.x, sy, 14u)));
            }
        }
    }
    float s = 4.0;
    float a0 = D(DAY), a1 = D(DAY + 1);
    int n = text_len(a0, a1, 3);
    if (n > 0 && text_hit(p, vec2(cx - text_width(s, n) * 0.5, D(DATEY)), s, 3, a0, a1))
        c = D3(DIM);
    a0 = D(DATE);
    a1 = D(DATE + 1);
    n = text_len(a0, a1, 2);
    if (n > 0 && text_hit(p, vec2(cx - text_width(s, n) * 0.5, D(DATE2Y)), s, 2, a0, a1))
        c = tonef(hf(hu(int(floor(p.x / g)), int(floor(p.y / g)), 21u)) * 0.5);
    float cs = 8.0;
    a0 = D(HOUR);
    a1 = D(HOUR + 1);
    n = text_len(a0, a1, 2);
    if (n > 0 && text_hit(p, vec2(cx - text_width(cs, n) * 0.5, D(CLK1)), cs, 2, a0, a1))
        c = tonef(hf(hu(int(floor(p.x / g)), int(floor(p.y / g)), 21u)));
    a0 = D(MINUTE);
    a1 = D(MINUTE + 1);
    n = text_len(a0, a1, 2);
    if (n > 0 && text_hit(p, vec2(cx - text_width(cs, n) * 0.5, D(CLK2)), cs, 2, a0, a1))
        c = tonef(hf(hu(int(floor(p.x / g)), int(floor(p.y / g)), 21u)));
    a0 = D(TIMER);
    a1 = D(TIMER + 1);
    n = text_len(a0, a1, 4);
    if (n > 0 && text_hit(p, vec2(cx - text_width(s, n) * 0.5, y0 + 16.0), s, 4, a0, a1))
        c = D(VKIND) > 0.5 ? D3(INK) : D3(DIM);
    int gn = int(D(GN));
    float gy = D(GY), gh = D(GH);
    for (int i = 0; i < 6; i++) {
        if (i >= gn) break;
        float top = gy + float(i) * gh;
        float bot = top + gh;
        int b = GAUGES + i * GSLOT;
        if (p.y < top || p.y >= bot) continue;
        if (p.y >= bot - 2.0) {
            c = D3(GLASS);
        } else {
            float s_top = top + 88.0;
            if (p.y >= s_top) {
                float kind = D(b + 7);
                float pct = clamp(D(b + 8), 0.0, 100.0);
                if (kind > 0.5) {
                    if (p.y > bot - 16.0) {
                        float fillx = x0 + 4.0 + (x1 - x0 - 8.0) * pct / 100.0;
                        if (p.x >= x0 + 4.0 && p.x < fillx)
                            c = tonef(hf(hu(int(floor(p.x / g)), int(floor(p.y / g)), 31u)));
                    }
                } else {
                    float level = pct / 100.0 * (bot - 2.0 - s_top);
                    float mound = clamp(1.0 - abs(p.x - cx) / 28.0, 0.0, 1.0);
                    float trend = D(b + 9);
                    float surf = level + (trend > 0.5 ? mound * 4.0 : (trend < -0.5 ? -mound * 6.0 : 0.0));
                    surf += (hf(hu(int(floor(p.x / g)), 7, 30u + uint(i))) - 0.5) * 4.0;
                    surf = floor(surf / g) * g;
                    float depth = (bot - 2.0) - p.y;
                    bool hot = D(b + 6) > 0.5;
                    if (depth <= surf) {
                        vec3 sc = tonef(hf(hu(int(floor(p.x / g)), int(floor(p.y / g)), 31u)));
                        if (hot && depth > surf - 12.0) sc = D3(RED);
                        if (trend != 0.0 && abs(depth - surf) <= 4.0 &&
                            hf(hu(int(floor(p.x / g)), int(floor(p.y / g)),
                                  40u + uint(int(iTime * 30.0)) % 97u)) < 0.12)
                            sc = hot ? D3(RED) : D3(GLINT);
                        c = sc;
                    }
                    if (trend > 0.5 && depth > surf && abs(p.x - cx) < 4.0 &&
                        hf(hu(int(floor(p.x / g)), int(floor(p.y / g)) + int(iTime * 240.0) % 997,
                              50u)) < 0.45)
                        c = D3(TONE);
                }
            }
        }
        a0 = D(b);
        a1 = D(b + 1);
        n = text_len(a0, a1, 4);
        if (n > 0 && text_hit(p, vec2(cx - text_width(s, n) * 0.5, top + 12.0), s, 4, a0, a1))
            c = D3(DIM);
        a0 = D(b + 2);
        a1 = D(b + 3);
        n = text_len(a0, a1, 4);
        if (n > 0 && text_hit(p, vec2(cx - text_width(s, n) * 0.5, top + 36.0), s, 4, a0, a1))
            c = D3(INK);
        a0 = D(b + 4);
        a1 = D(b + 5);
        n = text_len(a0, a1, 4);
        if (n > 0 && text_hit(p, vec2(cx - text_width(s, n) * 0.5, top + 60.0), s, 4, a0, a1))
            c = D(b + 6) > 0.5 ? D3(RED) : D3(DIM);
    }
    return vec4(c, 1.0);
}

void mainImage(out vec4 color, in vec2 fragCoord) {
    g_origin = vec2(D(OX), D(OY));
    g_h = iResolution.y;
    vec2 p = vec2(fragCoord.x, iResolution.y - fragCoord.y) + g_origin;
    color = int(D(MODE)) == 0 ? frames_shot(p) : tube_shot(p);
    if (color.a <= 0.0) discard;
}
