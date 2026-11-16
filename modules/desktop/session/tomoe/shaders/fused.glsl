// FUSED: the rail as a pixel HUD cast in sand.
//
// Two surfaces share this shader. The frames surface draws round each card the
// rail carries: the focused card a double line -- two four pixel rules a title
// row above the box, opening round the card's name in the line's own ink, the
// rail-side rule running into the slab -- and every other card one light rule
// with its name set into the top. A switch turns those rules to sand: the old
// frame lets go from the rail outward and its grains fall and drain into the
// slab, the new frame is poured out of the slab cell by cell, and the title
// rule's opening grows behind the pour.
//
// The slab surface draws the bevelled slab down the seam, its grooves, the
// compartments recessed into it -- gauges filled with sand, the clock's digits
// cast grain by grain, bolo's voice a bed of grains -- and the clamps that bolt
// it to the focused frame. Everything is timed from iTime and the rail's
// numbers; the shaders stop with their surfaces once the pour has settled and
// the voice has calmed.
//
// iData layout is packed by rail--fused--frames-data and rail--fused--slab-data
// in lisp/rail-fused.lisp; coordinates are the output's, y down, and cards come
// from iWindow in the surface's own pixels, y up.

#define PI 3.14159265358979

float D(int i) { return iData[i >> 2][i & 3]; }
vec3 D3(int i) { return vec3(D(i), D(i + 1), D(i + 2)); }

const int ORIGIN = 1, SKIP = 3, FRAME_C = 5, LINE_C = 8, DUST_C = 11, GLINT_C = 17;
const int SETTLE = 20, VTOP = 21, GRAV = 22, ON = 23, TSW = 24;
const int BLOCK = 25;

const int SX0 = 1, SX1 = 2, SH = 3, GROOVE = 4;
const int MAT = 5, MAT_HI = 8, MAT_LO = 11, SHADOW = 14, DEEP = 17, GROOVE_C = 20;
const int FRAME_S = 23, GLINT_S = 26, TONES = 29;
const int HOURS = 41, MINUTES = 42, VOICE_ON = 43, VOICE_SINCE = 44, VOICE_FADE = 45;
const int RISE = 46, VSETTLE = 47, NLEVELS = 48, LEVELS = 49;
const int NCOMP = 81, COMP = 82, CLOCK_Y = 112, VOICE_Y = 114;
const int STSW = 116, SWITCH = 117, GROOVES = 118;

vec2 g_origin;
float g_h;

float h2(vec2 c) {
    return fract(sin(dot(c, vec2(41.31, 289.77)) + 0.37) * 43758.5453);
}

bool inr(vec2 p, float x0, float y0, float x1, float y1) {
    return p.x >= x0 && p.x < x1 && p.y >= y0 && p.y < y1;
}

vec4 card(int i) {
    vec4 w = iWindow[i];
    float top = g_h - (w.y + w.w);
    return vec4(w.x + g_origin.x, top + g_origin.y, w.x + w.z + g_origin.x, top + w.w + g_origin.y);
}

bool shown(int i) { return i >= 0 && i < iWindowCount && iWindow[i].z > 0.0; }

float frame_band(vec2 p, vec4 b, float s, bool dbl, float g0, float g1) {
    float lo = (s < 0.0) ? 12.0 : 8.0;
    float ro = (s < 0.0) ? 8.0 : 12.0;
    bool gap = p.x > g0 && p.x < g1;
    float c = 0.0;
    if (dbl) {
        c = max(c, inr(p, b.x - 8.0, b.y - 12.0, b.x - 4.0, b.w + 4.0) ? 1.0 : 0.0);
        c = max(c, inr(p, b.z + 4.0, b.y - 12.0, b.z + 8.0, b.w + 4.0) ? 1.0 : 0.0);
        c = max(c, inr(p, b.x - 8.0, b.w, b.z + 8.0, b.w + 4.0) ? 1.0 : 0.0);
        c = max(c, inr(p, b.x - lo - 4.0, b.y - 20.0, b.x - lo, b.w + 12.0) ? 1.0 : 0.0);
        c = max(c, inr(p, b.z + ro, b.y - 20.0, b.z + ro + 4.0, b.w + 12.0) ? 1.0 : 0.0);
        c = max(c, inr(p, b.x - lo - 4.0, b.w + 8.0, b.z + ro + 4.0, b.w + 12.0) ? 1.0 : 0.0);
        if (!gap) {
            c = max(c, inr(p, b.x - 8.0, b.y - 12.0, b.z + 8.0, b.y - 8.0) ? 1.0 : 0.0);
            c = max(c, inr(p, b.x - lo - 4.0, b.y - 20.0, b.z + ro + 4.0, b.y - 16.0) ? 1.0 : 0.0);
        }
    } else {
        c = max(c, inr(p, b.x - lo - 4.0, b.y - 20.0, b.x - lo, b.w + 8.0) ? 1.0 : 0.0);
        c = max(c, inr(p, b.z + ro, b.y - 20.0, b.z + ro + 4.0, b.w + 8.0) ? 1.0 : 0.0);
        c = max(c, inr(p, b.x - lo - 4.0, b.w + 4.0, b.z + ro + 4.0, b.w + 8.0) ? 1.0 : 0.0);
        if (!gap) c = max(c, inr(p, b.x - lo - 4.0, b.y - 20.0, b.z + ro + 4.0, b.y - 16.0) ? 1.0 : 0.0);
    }
    return c;
}

float arrival(vec2 p, vec4 b, float s, float hh) {
    float d = (s < 0.0) ? (b.z - p.x) : (p.x - b.x);
    if (p.y < b.y) return 0.02 + d / max(1.0, D(VTOP)) + 0.10 * hh;
    float yf = clamp((p.y - b.y) / max(1.0, b.w - b.y), 0.0, 1.0);
    return 0.03 + 0.08 * (1.0 - yf) + 0.85 * sqrt(2.0 * max(p.y - b.y, 0.0) / max(1.0, D(GRAV))) + 0.10 * hh;
}

float release_time(vec2 p, vec4 b, float s, float hh) {
    float d = (s < 0.0) ? (b.z - p.x) : (p.x - b.x);
    if (p.y < b.y) return 0.02 + 0.01 * hh + d / max(1.0, D(VTOP));
    float yf = clamp((p.y - b.y) / max(1.0, b.w - b.y), 0.0, 1.0);
    return 0.02 + 0.03 * hh + 0.08 * (1.0 - yf);
}

void frames(out vec4 color, in vec2 fragCoord) {
    vec2 p = fragCoord + g_origin;
    if (D(SKIP + 1) > D(SKIP) && p.x >= D(SKIP) && p.x < D(SKIP + 1)) discard;
    float dt = iTime - D(TSW);
    bool live = D(ON) > 0.5 && dt >= 0.0 && dt < D(SETTLE);
    vec3 frameC = D3(FRAME_C), lineC = D3(LINE_C);
    vec3 dust = D3(DUST_C), dust2 = D3(DUST_C + 3), glint = D3(GLINT_C);
    vec3 c = vec3(0.0);
    float a = 0.0;
    for (int i = 0; i < iWindowCount; i++) {
        if (!shown(i)) continue;
        vec4 b = card(i);
        float s = D(BLOCK + i * 8);
        bool focus = D(BLOCK + i * 8 + 1) > 0.5;
        bool was = D(BLOCK + i * 8 + 2) > 0.5;
        float chars = D(BLOCK + i * 8 + 3);
        float tx = D(BLOCK + i * 8 + 4);
        float prog = D(BLOCK + i * 8 + 5);
        if (p.x < b.x - 40.0 || p.x > b.z + 40.0 || p.y < b.y - 48.0 || p.y > b.w + 40.0) continue;
        float g0 = tx - 8.0;
        float g1 = tx + 12.0 * chars * prog + 8.0;
        if (chars < 0.5) { g0 = 1.0; g1 = 0.0; }
        if (was && live) {
            float hh = h2(floor((p - b.xy) / 4.0) + 17.0);
            float rel = release_time(p, b, s, hh);
            if (dt < rel) {
                if (frame_band(p, b, s, true, g0, g1) > 0.5) { c = frameC; a = 1.0; }
            } else {
                vec2 src = p;
                for (int k = 0; k < 2; k++) {
                    float rs = release_time(vec2(p.x, src.y), b, s, hh);
                    src.y = p.y - 0.5 * D(GRAV) * pow(max(dt - rs, 0.0), 2.0);
                }
                float rs = release_time(src, b, s, hh);
                if (dt > rs && frame_band(src, b, s, true, g0, g1) > 0.5) {
                    vec2 cell = floor(src / 4.0);
                    if (h2(cell + 23.0) < 0.62) {
                        c = h2(cell + 29.0) < 0.5 ? dust : dust2;
                        a = 1.0;
                    }
                }
            }
            continue;
        }
        if (focus && live) {
            vec2 cell = floor((p - b.xy) / 4.0);
            vec2 cc = b.xy + (cell + 0.5) * 4.0;
            float hh = h2(cell + 7.0);
            float arr = arrival(cc, b, s, hh);
            if (frame_band(p, b, s, true, g0, g1) > 0.5) {
                if (dt >= arr) {
                    c = frameC;
                    if (dt - arr < 0.035 && hh > 0.35) c = glint;
                    a = 1.0;
                } else if (arr - dt < 0.045) {
                    c = hh > 0.5 ? dust : dust2;
                    a = 1.0;
                }
            }
            continue;
        }
        if (frame_band(p, b, s, focus, g0, g1) > 0.5) {
            c = focus ? frameC : lineC;
            a = 1.0;
        }
    }
    if (a <= 0.0) discard;
    color = vec4(c, a);
}

bool digit_px(vec2 p, float ox, float oy, int d) {
    vec2 q = (p - vec2(ox, oy)) / 4.0;
    if (q.x < 0.0 || q.x >= 3.0 || q.y < 0.0 || q.y >= 5.0) return false;
    int x = int(q.x), y = int(q.y);
    int row = 0;
    if (d == 0) row = (y == 0 || y == 4) ? 7 : 5;
    else if (d == 1) row = (y == 4) ? 7 : (y == 1 ? 6 : 2);
    else if (d == 2) row = (y == 1) ? 1 : ((y == 3) ? 4 : 7);
    else if (d == 3) row = (y == 1 || y == 3) ? 1 : 7;
    else if (d == 4) row = (y >= 2) ? ((y == 2) ? 7 : 1) : 5;
    else if (d == 5) row = (y == 1) ? 4 : ((y == 3) ? 1 : 7);
    else if (d == 6) row = (y == 1) ? 4 : (((y == 3) ? 5 : 7));
    else if (d == 7) row = (y == 0) ? 7 : 1;
    else if (d == 8) row = (y == 1 || y == 3) ? 5 : 7;
    else row = (y == 3) ? 1 : ((y == 1) ? 5 : 7);
    return ((row >> (2 - x)) & 1) == 1;
}

vec3 tone(vec2 p) {
    float t = h2(floor(p / 4.0) + 3.0);
    int i = int(t * 3.999);
    return D3(TONES + i * 3);
}

float sand(vec2 p, float bx0, float bx1, float by0, float by1, float level, float seed) {
    float flo = by1 - 2.0;
    float top = by0 + 4.0;
    float hgt = (flo - top) * clamp(level, 0.0, 100.0) / 100.0;
    float cell = floor((p.x - bx0) / 4.0);
    float wob = 2.0 * h2(vec2(cell, seed)) + 2.0 * sin(cell * 0.7 + seed);
    float surf = flo - hgt - wob;
    return p.y >= surf ? 1.0 : 0.0;
}

float smooth01(float u) {
    u = clamp(u, 0.0, 1.0);
    return u * u * (3.0 - 2.0 * u);
}

void slab(out vec4 color, in vec2 fragCoord) {
    float H = iResolution.y;
    vec2 p = fragCoord;
    float x0 = D(SX0), x1 = D(SX1), height = D(SH), groove = D(GROOVE);
    vec3 mat = D3(MAT), matHi = D3(MAT_HI), matLo = D3(MAT_LO), shadow = D3(SHADOW);
    vec3 deep = D3(DEEP), grooveC = D3(GROOVE_C), frameC = D3(FRAME_S), glint = D3(GLINT_S);
    vec3 c = vec3(0.0);
    float a = 0.0;
    if (inr(p, x0 + 4.0, 4.0, x1 + 4.0, height + 4.0)) { c = shadow; a = 1.0; }
    if (inr(p, x0, 0.0, x1, height)) {
        c = mat;
        a = 1.0;
        if (p.x < x0 + 4.0 || p.y < 4.0) c = matHi;
        if (p.x >= x1 - 4.0 || p.y >= height - 4.0) c = matLo;
    }
    for (int g = 0; g < 8; g++) {
        float gy = D(GROOVES + g);
        if (gy <= 0.0) continue;
        if (inr(p, x0, gy, x1, gy + groove)) { c = grooveC; a = 1.0; }
        else if (inr(p, x0 + 4.0, gy + groove, x1 - 4.0, gy + groove + 4.0)) c = matHi;
    }
    int n = int(D(NCOMP));
    for (int i = 0; i < n && i < 6; i++) {
        float y0 = D(COMP + i * 5), y1 = D(COMP + i * 5 + 1);
        float lv = D(COMP + i * 5 + 2);
        int kind = int(D(COMP + i * 5 + 4));
        float by1 = y1 - (kind == 2 ? 32.0 : 36.0);
        float by0 = y0 + 64.0;
        if (inr(p, x0 + 4.0, by0, x1 - 4.0, by1)) {
            c = deep;
            a = 1.0;
            if (inr(p, x0 + 4.0, by0, x1 - 4.0, by0 + 4.0)) c = matLo;
            if (sand(p, x0 + 4.0, x1 - 4.0, by0, by1, lv, float(i) * 11.0) > 0.5) {
                if (h2(floor(p / 4.0) + 5.0) < 0.94) c = tone(p);
            }
        }
    }
    float cy0 = D(CLOCK_Y), cy1 = D(CLOCK_Y + 1);
    if (cy1 > cy0) {
        if (inr(p, x0 + 4.0, cy0, x1 - 4.0, cy1)) {
            c = deep;
            a = 1.0;
            if (inr(p, x0 + 4.0, cy0, x1 - 4.0, cy0 + 4.0)) c = matLo;
            float cx = (x0 + x1) * 0.5;
            int hrs = int(D(HOURS)), mins = int(D(MINUTES));
            float top = cy0 + 12.0;
            if (digit_px(p, cx - 12.0, top, hrs / 10) || digit_px(p, cx, top, hrs % 10)
                || digit_px(p, cx - 12.0, top + 28.0, mins / 10)
                || digit_px(p, cx, top + 28.0, mins % 10)) c = tone(p);
            float bed = cy1 - 4.0 - 6.0 * h2(vec2(floor(p.x / 4.0), 8.0));
            if (p.y >= bed && h2(floor(p / 4.0) + 13.0) < 0.85) c = tone(p);
        }
    }
    float vy0 = D(VOICE_Y), vy1 = D(VOICE_Y + 1);
    if (vy1 > vy0) {
        if (inr(p, x0 + 4.0, vy0, x1 - 4.0, vy1)) {
            c = deep;
            a = 1.0;
            if (inr(p, x0 + 4.0, vy0, x1 - 4.0, vy0 + 4.0)) c = matLo;
            float amp = 0.0;
            if (D(VOICE_ON) > 0.5) {
                float since = D(VOICE_SINCE), fade = D(VOICE_FADE);
                amp = smooth01((iTime - since) / max(0.01, D(RISE)));
                if (fade > -1e8) amp *= 1.0 - smooth01((iTime - fade) / max(0.01, D(VSETTLE)));
            }
            int nl = int(D(NLEVELS));
            float u = clamp((p.x - (x0 + 4.0)) / max(1.0, (x1 - 4.0) - (x0 + 4.0)), 0.0, 1.0);
            int li = nl > 0 ? min(nl - 1, int(u * float(nl))) : 0;
            float lvl = nl > 0 ? D(LEVELS + li) : 0.0;
            float cell = floor((p.x - x0) / 4.0);
            float mound = amp * lvl * (190.0 + 110.0 * h2(vec2(cell, 5.0)));
            float flo = vy1 - 6.0;
            float bed = 6.0 + 6.0 * h2(vec2(cell, 2.0)) + 4.0 * sin(cell * 0.9);
            float surf = flo - bed - mound;
            if (p.y >= surf) {
                if (h2(floor(p / 4.0) + 9.0) < 0.92) c = tone(p);
            } else if (p.y > surf - 40.0 && h2(floor(p / 4.0) + 31.0) < 0.06) {
                c = tone(p);
            }
        }
    }
    if (shown(0)) {
        vec4 b = card(0);
        float near = (b.x + b.z) * 0.5 < (x0 + x1) * 0.5 ? x0 : x1 - 12.0;
        float dt = iTime - D(STSW);
        bool flash = D(SWITCH) > 0.5 && dt >= 0.0 && dt < 0.12;
        for (int g = 0; g < 8; g++) {
            float gy = D(GROOVES + g);
            if (gy <= 0.0 || gy < b.y - 20.0 || gy > b.w) continue;
            if (inr(p, near, gy - 4.0, near + 12.0, gy + 8.0)) {
                c = flash ? glint : frameC;
                a = 1.0;
                if (inr(p, near, gy - 4.0, near + 4.0, gy)) c = glint;
            }
        }
    }
    if (a <= 0.0) discard;
    color = vec4(c, a);
}

void mainImage(out vec4 color, in vec2 fragCoord) {
    g_h = iResolution.y;
    vec2 fc = vec2(fragCoord.x, g_h - fragCoord.y);
    if (int(D(0)) == 0) {
        g_origin = vec2(D(ORIGIN), D(ORIGIN + 1));
        frames(color, fc);
    } else {
        g_origin = vec2(0.0);
        slab(color, fc);
    }
}
