// grain: pixel sand on glass's footprint. A card's frame is one rule of four
// pixel grains on the third art pixel outside its content, cut square at the
// corners, each grain its own tone and a few catching the light. The deck's
// seam is five art pixels wide, so both columns' third art pixel is the same
// column and the rules of two cards side by side are joined there by
// construction; the focused card's frame is doubled, a second rule on the first
// art pixel outside its content, so the neighbour's single rule runs on through
// the seam as the outer half of the focused frame.
//
// The focused card's top rule carries, in a three-by-five pixel type of four
// pixel cells, its title in the rule's own ink -- typed in behind the pour, no
// plate of its own -- a small compartment beside it for bolo's voice, and at
// the right end a sand compartment for each reading (a label, a recessed box
// filling left to right with a grain falling in while the reading climbs, the
// value), then the clock cast in sand digits and the date. The rule opens round
// each of them; the inner rule runs on beneath them as the shelf they stand on.
//
// Focus is a pour. The frame that loses focus runs its rules back along
// themselves into the point nearest the card taking focus, its type and sand
// dropping away; the new frame is poured from that point both ways along its
// rules, grains landing out of a small arc ahead of the front and the title
// typing in behind it, a short stream crossing the seam and sparks flying where
// the two fronts meet, stepped at twenty a second. Every place, tone and jump
// is a closed form of the cell, the time since the switch and a hash of the
// cell: nothing is integrated, nothing is simulated, and once the motion has
// landed the surface holds its last picture and draws nothing.
//
// Bolo's voice jumps every grain of the focused double rule off the frame at
// once, each grain by its own share of the level, so the whole frame is the
// waveform and no side waits for a wave to run round to it, hot grains glinting;
// the bed in the compartment beside the title scrolls the level history. Only the focused card's rules move. Coordinates are the output's,
// y down.

const float A = 4.0;                       // the art pixel, in output pixels
const int TITLE_CHARS = 18;                // characters of a card's title the kit packs
const float DESIGN = 0.65;                 // seconds the pour was drawn for

const int T_LINE = THEME, T_NAME = THEME + 3, T_GLINT = THEME + 6;
const int T_DIM = THEME + 9, T_BOX = THEME + 12;
const int T_FRAME = THEME + 15, T_INK = THEME + 27;
const int T_POUR = THEME + 39, T_CRUMBLE = THEME + 40, T_FALL = THEME + 41;
// a bar: which edge its rule stands on (1 the top bar's, 2 the bottom's), and
// the strip's rect
const int G_MODE = THEME + 42, G_RECT = THEME + 43;

const vec2 OUT[4] = vec2[4](vec2(0.0, -1.0), vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0));

// ---------------------------------------------------------------- grains
vec3 frame_tone(float h) {
    int i = int(clamp(floor(h * 3.999), 0.0, 3.0));
    return D3(T_FRAME + 3 * i);
}

vec3 ink_tone(float h) {
    int i = int(clamp(floor(h * 3.999), 0.0, 3.0));
    return D3(T_INK + 3 * i);
}

vec3 ink_idx(int i) { return D3(T_INK + 3 * (i & 3)); }

// the grain of art cell CELL: its tone from the palette, now and then a glint,
// and a fresh grain -- one that has just landed -- always glinting
vec3 grain_tone(vec2 cell, uint seed, bool frame, bool fresh) {
    uint h3 = hu(int(cell.x), int(cell.y), seed);
    uint h4 = hu(int(cell.x), int(cell.y), seed + 1u);
    if (fresh || hf(h4) < 0.03) return D3(T_GLINT);
    return frame ? frame_tone(hf(h3)) : ink_tone(hf(h3));
}

// ---------------------------------------------------------------- geometry
struct Ring {
    float m;        // how far outside the content the pixel is, negative inside
    int sd;         // 0 top, 1 right, 2 bottom, 3 left
};

int band_of(float m) { return int(floor(m / A)) + 1; }

// the art cell of a rule pixel on SIDE at BAND: the band's own row (top and
// bottom) or column (left and right), so a grain fills the rule's four pixels
vec2 ring_cell(vec2 p, vec4 b, int sd, int band) {
    float fb = float(band);
    if (sd == 0) return vec2(floor((p.x - b.x) / A), -fb);
    if (sd == 2) return vec2(floor((p.x - b.x) / A), ceil((b.w - b.y) / A) - 1.0 + fb);
    if (sd == 3) return vec2(-fb, floor((p.y - b.y) / A));
    return vec2(ceil((b.z - b.x) / A) - 1.0 + fb, floor((p.y - b.y) / A));
}

Ring ring_of(vec2 p, vec4 b) {
    vec4 o = vec4(b.x - p.x, p.x - b.z, b.y - p.y, p.y - b.w);
    float m = max(max(o.z, o.y), max(o.w, o.x));
    Ring r;
    r.m = m;
    r.sd = o.z >= m ? 0 : (o.y >= m ? 1 : (o.w >= m ? 2 : 3));
    return r;
}

// the point U along the perimeter of BOX, clockwise from its top-left corner
vec2 ring_at(float u, vec4 box) {
    float w = box.z - box.x, h = box.w - box.y;
    u = mod(u, 2.0 * (w + h));
    if (u < w) return vec2(box.x + u, box.y);
    u -= w;
    if (u < h) return vec2(box.z, box.y + u);
    u -= h;
    if (u < w) return vec2(box.z - u, box.w);
    u -= w;
    return vec2(box.x, box.w - u);
}

// the point of BOX nearest Q, or nearest its edge when Q is inside
vec2 nearest_on(vec4 box, vec2 q) {
    vec2 t = clamp(q, box.xy, box.zw);
    if (t.x > box.x && t.x < box.z && t.y > box.y && t.y < box.w) {
        float d0 = t.y - box.y, d1 = box.z - t.x, d2 = box.w - t.y, d3 = t.x - box.x;
        float dm = min(min(d0, d1), min(d2, d3));
        if (dm == d0) t.y = box.y;
        else if (dm == d1) t.x = box.z;
        else if (dm == d2) t.y = box.w;
        else t.x = box.x;
    }
    return t;
}

// ---------------------------------------------------------------- the host
// the card carrying the readings and the pour, its frame's geometry, and the
// theme's own speeds, read once for the whole pixel
int g_host;
bool g_anim;
bool g_double;
float g_pour, g_crumble, g_fall;
float g_ropen;
bool g_voiced;                   // bolo has the turn this instant

// when the pour that starts at UA reaches the art column at X
float arrive_at(float x, vec4 ubox, float ua, float per) {
    float u = clamp(x, ubox.x, ubox.z) - ubox.x;
    return 0.08 + pdist(u, ua, per) / g_pour + 0.06;
}

vec4 g_ubox;
float g_per, g_ua;

// ---------------------------------------------------------------- type
int title_base(int i) { return K_CARDS + i * K_CARD + 1; }

// The rail's own type: the same three-by-five masks cut to the characters it
// sets, so the driver's lookup stays small, and a length that costs a few
// compares on the packed numbers instead of a loop over every character.
const int GRAIN_GLYPH[64] = int[64](
    0, 0, 0, 0, 0, 21157, 0, 0,
    0, 0, 0, 1488, 0, 448, 8192, 4772,
    31599, 29850, 29671, 31143, 18925, 31183, 31695, 9511,
    31727, 31215, 1040, 0, 0, 0, 6105, 0,
    0, 23530, 15083, 25166, 15211, 29391, 4815, 27470,
    23533, 29847, 11044, 23277, 29257, 23549, 23403, 11114,
    4843, 26474, 23275, 14478, 9367, 31597, 11117, 24557,
    23213, 9389, 29351, 0, 0, 0, 0, 0
);

int grain_glyph(int c) {
    if (c < 32 || c > 95) return 0;
    return GRAIN_GLYPH[c - 32];
}

int grain_char(int base, int i) {
    float v = D(base + i / 3);
    int k = i - (i / 3) * 3;
    float s = k == 0 ? 1.0 : (k == 1 ? 256.0 : 65536.0);
    return int(mod(floor(v / s + 0.5 / s), 256.0));
}

// how many characters of the text at BASE, up to N, before its trailing spaces
int grain_len(int base, int n) {
    int nums = (n + 2) / 3;
    for (int i = 6; i > 0; i--) {
        int j = i - 1;
        if (j >= nums) continue;
        float v = D(base + j);
        int b = 3 * j;
        if (v >= 2170912.0) return min(b + 3, n);
        if (v >= 2105632.0) return min(b + 2, n);
        if (v >= 2105377.0) return min(b + 1, n);
    }
    return 0;
}

// whether P is on a lit cell of the text at BASE, its first cell at AT, each
// cell S pixels, advancing four cells a character; IDX the character's index
bool grain_text(vec2 p, vec2 at, float s, int base, int n, out int idx) {
    vec2 q = (p - at) / s;
    idx = -1;
    if (q.x < 0.0 || q.y < 0.0 || q.y >= 5.0) return false;
    int ci = int(floor(q.x / 4.0));
    if (ci >= n) return false;
    int col = int(floor(q.x)) - ci * 4;
    if (col > 2) return false;
    int row = int(floor(q.y));
    idx = ci;
    return (grain_glyph(grain_char(base, ci)) & (1 << (row * 3 + col))) != 0;
}

// whether pixel p is a lit cell of I's title, and which character it belongs to
bool title_hit(vec2 p, vec4 b, int i, out int idx) {
    idx = -1;
    if (p.x < b.x + 2.0 * A || p.x > b.x + 74.0 * A) return false;
    if (p.y < b.y - 6.0 * A || p.y >= b.y - A) return false;
    int n = grain_len(title_base(i), TITLE_CHARS);
    if (n <= 0) return false;
    return grain_text(p, vec2(b.x + 3.0 * A, b.y - 6.0 * A), A, title_base(i), TITLE_CHARS, idx);
}

// ---------------------------------------------------------------- the furniture
// The readings, right to left: the date, the clock, then every sand compartment
// that has a reading. This is the art column the top rule opens at on their
// side; a card too narrow to hold them falls back to the date and clock alone.
float readings_clock(float AW) { return (AW - 4.0) - 29.0 - 25.0; }

float readings_open(float AW) {
    float x = readings_clock(AW) - 4.0;
    for (int k = 3; k >= 0; k--) {
        if (!gauge_shown(k)) continue;
        x -= 60.0;
    }
    return x;
}

// Whether the top rule opens at art column X: round every card's own title, and
// round the host's bolo compartment and readings as far as the pour has reached.
bool rule_open(vec2 p, vec4 b, int i, float x, float dt, bool anim) {
    if (p.y < b.y - 24.0 || p.y >= b.y - 4.0) return false;
    int n = grain_len(title_base(i), TITLE_CHARS);
    if (n <= 0) return false;
    float t1 = 4.0 * float(n) + 2.0;
    if (x >= 1.0 && x < t1 + 1.0) return true;
    if (i != g_host) return false;
    float vx0 = t1 + 3.0;
    bool span = g_voiced && (x >= 1.0 && x < vx0 + 28.0);
    if (!span) {
        float AW = ceil((b.z - b.x) / A);
        span = (x >= g_ropen - 2.0 && x < AW - 1.0);
    }
    if (!span) return false;
    return !anim || dt >= arrive_at(b.x + (x + 0.5) * A, g_ubox, g_ua, g_per);
}

// whether the furniture at art column X has typed in yet
bool furn_live(float x, vec4 b, float dt, bool anim) {
    return !anim || dt >= arrive_at(b.x + x * A, g_ubox, g_ua, g_per);
}

// the art pixel the grain of CELL has fallen by at DT, or -1 once it is gone:
// the old frame's type and sand drop a little and are gone
int fallen(vec2 cell, float dt) {
    float h = hf(hu(int(cell.x), int(cell.y), 41u));
    float tau = dt - 0.02 * h;
    if (tau <= 0.0) return 0;
    if (tau > 0.10 * (0.5 + h)) return -1;
    return int(floor(0.5 * g_fall * tau * tau / A));
}

// The top rule's furniture at P, or false. TYPED: only what the pour has
// reached shows. DROP: which art pixel the grain has fallen by, -1 for none.
bool furn(vec2 p, vec4 b, int i, float dt, bool typed, bool voiced, out vec4 col) {
    col = vec4(0.0);
    if (p.y < b.y - 24.0 || p.y >= b.y - 4.0) return false;
    if (p.x < b.x || p.x >= b.z) return false;
    float cx = floor((p.x - b.x) / A), cy = floor((p.y - b.y) / A);
    float bw = b.z - b.x;
    float AW = ceil(bw / A);
    int base = title_base(i);
    int n = grain_len(base, TITLE_CHARS);
    float t1 = 4.0 * float(n) + 2.0;
    float vx0 = t1 + 3.0;
    int idx = -1;
    if (n > 0 && grain_text(p, vec2(b.x + 3.0 * A, b.y - 6.0 * A), A, base, TITLE_CHARS, idx)) {
        if (typed && !furn_live(3.0 + 4.0 * float(idx), b, dt, true)) return false;
        col = vec4(grain_tone(vec2(cx, cy), 9u, false, false), 1.0);
        return true;
    }
    // bolo's compartment: an outline of grains beside the title, and inside it a
    // bed of the last three quarters of a second of the voice. It is only there
    // while bolo has the turn -- a still rail shows the rule running on, not an
    // empty box beside the title.
    if (g_voiced && cx >= vx0 && cx < vx0 + 26.0 && cy >= -6.0 && cy <= -2.0) {
        if (typed && !furn_live(vx0, b, dt, true)) return false;
        bool border = cx < vx0 + 1.0 || cx >= vx0 + 25.0 || cy <= -6.0 || cy >= -2.0;
        if (border) {
            col = vec4(D3(T_BOX), 1.0);
            return true;
        }
        int j = int(vx0 + 24.0 - cx);
        int r = int(cy + 5.0);
        float lv = 0.0;
        if (voiced) lv = voice_level(float(j) / 30.0) * voice_env();
        int hgt = int(round(lv * 3.0));
        if (hgt <= 0) {
            if (cy == -3.0) {
                col = vec4(D3(T_BOX), 1.0);
                return true;
            }
            return false;
        }
        if (r >= 3 - hgt) {
            col = vec4(ink_idx(j + r), 1.0);
            return true;
        }
        if (lv > 0.5 && r == 2 - hgt) {
            col = vec4(D3(T_GLINT), 1.0);
            return true;
        }
        return false;
    }
    // The readings ride the top rule's right end: the date, then the clock,
    // then a sand compartment for every reading. One walk from that end finds
    // the piece this pixel is on, and one piece of code draws it, so a reading
    // costs the driver no more than the next one.
    float ty = b.y - 6.0 * A;
    float xr = b.x + (AW - 4.0) * A;
    float clear = b.x + (vx0 + 30.0) * A;
    int ng = 0;
    for (int j = 0; j < 4; j++) ng += gauge_shown(j) ? 1 : 0;
    float ge = xr - 58.0 * A;                       // the gauges' right edge
    bool showg = (xr - 58.0 * A - 60.0 * A * float(ng)) > clear;
    bool showc = (xr - 48.0 * A) > clear;
    int rb = -1;                                    // the text this pixel is on
    int rn = 0;
    float rx = 0.0;
    bool rsand = false;
    bool rbox = false;                              // a compartment instead
    float rbx = 0.0;
    int rg = 0;
    if (showc && p.x >= xr - 23.0 * A && p.x < xr) {
        rb = K_DATE;
        rn = 6;
        rx = xr - 23.0 * A;
    } else if (showc && p.x >= xr - 48.0 * A && p.x < xr - 29.0 * A) {
        rb = K_CLOCK;
        rn = 6;
        rx = xr - 48.0 * A;
        rsand = true;
    } else if (showg && p.x >= ge - 60.0 * A * float(ng) && p.x < ge) {
        int q = int((ge - p.x) / (60.0 * A));   // which compartment, from the right
        int k = 3, seen = -1;
        while (k >= 0) {
            if (gauge_shown(k)) {
                seen++;
                if (seen == q) break;
            }
            k--;
        }
        if (k >= 0) {
            rg = k;
            float e = ge - 60.0 * A * float(q);     // the item's right edge
            float ox = e - p.x;
            if (ox < 19.0 * A) {                    // the value, right-aligned in its field
                int vb = K_GAUGES + k * K_GAUGE + 2;
                int vl = grain_len(vb, 6);
                rb = vb;
                rn = 6;
                rsand = true;
                rx = e - (4.0 * float(vl) - 1.0) * A;
            } else if (ox >= 21.0 * A && ox < 39.0 * A) {
                rbox = true;
                rbx = e - 39.0 * A;
            } else if (ox >= 41.0 * A && ox < 52.0 * A) {
                rb = K_GAUGES + k * K_GAUGE + 4;
                rn = 3;
                rx = e - 52.0 * A;
            }
        }
    }
    int ti = -1;
    if (rbox) {
        int bc = int(round((rbx - b.x) / A));
        if (cx >= float(bc) && cx < float(bc + 18) && cy >= -6.0 && cy <= -2.0) {
            if (typed && !furn_live((rbx - b.x) / A, b, dt, true)) return false;
            bool border = cx <= float(bc) || cx >= float(bc + 17) || cy <= -6.0 || cy >= -2.0;
            if (border) {
                col = vec4(D3(T_BOX), 1.0);
                return true;
            }
            int ix = int(cx) - bc - 1;
            int iy = int(cy) + 5;
            float cells = 16.0 * 3.0 * clamp(gauge_pct(rg), 0.0, 100.0) / 100.0;
            int full = int(floor(cells / 3.0));
            int rem = int(round(cells - float(full) * 3.0));
            if (ix < full || (ix == full && iy >= 3 - rem)) {
                float h = hf(hu(int(cx), int(cy), 31u));
                col = vec4(h < 0.04 ? D3(T_GLINT) : ink_tone(h), 1.0);
                return true;
            }
            if (gauge_trend(rg) > 0.0 && ix == full && iy == int(iTime * 20.0) % 3) {
                col = vec4(ink_idx(ix), 1.0);
                return true;
            }
            return false;
        }
    } else if (rb >= 0 && grain_text(p, vec2(rx, ty), A, rb, rn, ti)) {
        if (typed && !furn_live((rx - b.x) / A, b, dt, true)) return false;
        col = rsand ? vec4(grain_tone(vec2(cx, cy), 9u, false, false), 1.0)
                    : vec4(D3(T_DIM), 1.0);
        return true;
    }
    return false;
}

// ---------------------------------------------------------------- the cards
// every card's single rule on the third art pixel, and its quiet title
vec4 plain_card(vec2 p, vec4 b, int i, float dt) {
    vec4 col = vec4(0.0);
    Ring r = ring_of(p, b);
    // the host's own rules are the focused pass's to draw once the pour has
    // landed, so a grain that jumps off the frame leaves a hole, not a line
    bool line = !(g_double && i == g_host && !g_anim);
    if (line && r.m >= 8.0 && r.m < 12.0) {
        bool open = false;
        if (r.sd == 0) {
            float xc = floor((p.x - b.x) / A);
            int tn = grain_len(title_base(i), TITLE_CHARS);
            open = tn > 0 && xc >= 1.0 && xc < 4.0 * float(tn) + 3.0;
            if (!open && i == g_host) open = rule_open(p, b, i, xc, dt, g_anim);
        }
        // a card out of focus keeps a dimmer rule, so the focused card's
        // doubled one is the frame the eye lands on
        if (!open) col = vec4(D3(T_LINE), i == g_host ? 1.0 : 0.55);
    }
    int idx;
    if (title_hit(p, b, i, idx)) col = vec4(D3(T_NAME), 1.0);
    return col;
}

// the old frame letting go: its rules run back along themselves into the point
// nearest the card taking focus, each grain keeping the tone of the cell it
// came from
vec4 drain_over(vec2 p, vec4 b, vec4 obox, float ou, float dt) {
    Ring r = ring_of(p, b);
    int band = int(floor(r.m / A)) + 1;
    if (r.m < 0.0 || (band != 1 && band != 3)) return vec4(0.0);
    float per = 2.0 * ((obox.z - obox.x) + (obox.w - obox.y));
    float u = perim(p, obox).x;
    float delta = mod(u - ou + per * 0.5, per) - per * 0.5;
    float dist = abs(delta);
    vec2 cell = ring_cell(p, b, r.sd, band);
    float hh = hf(hu(int(cell.x), int(cell.y), 31u));
    float run = g_crumble * (0.85 + 0.3 * hh) * max(dt - 0.02, 0.0);
    if (dist <= run) return vec4(0.0);
    vec2 from = ring_at(u + (delta > 0.0 ? run : -run), obox);
    vec4 o = vec4(b.x - from.x, from.x - b.z, b.y - from.y, from.y - b.w);
    float fm = max(max(o.z, o.y), max(o.w, o.x));
    int fside = o.z >= fm ? 0 : (o.y >= fm ? 1 : (o.w >= fm ? 2 : 3));
    int fband = band_of(fm);
    return vec4(grain_tone(ring_cell(from, b, fside, fband), uint(3 + fband), true, false), 1.0);
}

// the host card's double rule: poured when the focus moves, jumped by bolo's
// voice when it speaks, still otherwise; then its top rule's furniture
vec4 focused_over(vec2 p, vec4 b, int i, float dt, float ua, float per, vec4 ubox,
                  bool double_frame, bool voiced, vec4 obox, vec2 src) {
    vec4 col = vec4(0.0);
    float bw = b.z - b.x;
    Ring r = ring_of(p, b);
    int band = int(floor(r.m / A)) + 1;
    float env = voiced ? voice_env() : 0.0;
    if (double_frame && r.m >= 0.0 && band <= 7) {
        for (int k = 0; k < 2; k++) {
            int bl = k == 0 ? 1 : 3;
            int d = band - bl;
            if (d < 0 || d > 4) continue;
            vec2 pl = p - OUT[r.sd] * (A * float(d));
            vec2 lc = ring_cell(pl, b, r.sd, bl);
            float u = perim(pl, ubox).x;
            float s = pdist(u, ua, per);
            float hh = hf(hu(int(lc.x), int(lc.y), 21u));
            if (g_anim) {
                float h2 = hf(hu(int(lc.x), int(lc.y), 22u));
                float arr = 0.08 + s / g_pour + 0.015 * hh;
                float fl = 0.03 + 0.03 * h2;
                float q = (dt - (arr - fl)) / fl;
                if (q >= 1.0) {
                    if (d != 0) continue;
                    if (bl == 3 && r.sd == 0 &&
                        rule_open(p, b, i, lc.x, dt, true)) continue;
                    col = vec4(grain_tone(lc, uint(3 + bl), true, dt - arr < 0.05), 1.0);
                    break;
                } else if (q > 0.0) {
                    float lift = (1.0 + 3.0 * hh) * sin(PI * q);
                    if (int(floor(lift)) == d)
                        col = vec4(grain_tone(lc, uint(3 + bl), true, false), 1.0);
                    if (col.a > 0.0) break;
                }
            } else {
                float lev = env * min(1.0, voice_around(u, per));
                float hop = floor(lev * 3.99 *
                                  (0.3 + 0.7 * hf(hu(int(lc.x), int(lc.y),
                                                     uint(int(iTime * 20.0) & 63)))));
                if (int(hop) != d) continue;
                if (bl == 3 && r.sd == 0 &&
                    rule_open(p, b, i, lc.x, dt, false)) continue;
                bool hot = lev * hh > 0.55;
                col = vec4(hot ? D3(T_GLINT) : grain_tone(lc, uint(3 + bl), true, false), 1.0);
                break;
            }
        }
    }
    // the stream across the seam and the sparks where the fronts meet
    if (g_anim && double_frame && obox.z > obox.x) {
        vec2 q = ring_at(ua, ubox);
        if (src.x > -1e5) {
            vec2 d = q - src;
            float tt = clamp(dot(p - src, d) / max(dot(d, d), 1.0), 0.0, 1.0);
            float j = floor(tt * 48.0);
            float jit = hf(hu(int(j), 3, 31u)) - 0.5;
            float qs = (dt - 0.12 * (j + 0.5) / 48.0) / 0.09;
            vec2 at = src + d * tt + vec2(jit * 3.0 * A, 0.0);
            at.y -= (10.0 + 6.0 * jit) * sin(PI * tt) * A * 0.9;
            if (qs > 0.0 && qs < 1.0 && abs(p.x - at.x) < 0.5 * A && abs(p.y - at.y) < 0.5 * A)
                col = vec4(frame_tone(0.25 * float(int(j) & 3) + 0.1), 1.0);
        }
        float tm = 0.08 + per * 0.5 / g_pour;
        float ts = dt - tm;
        if (ts >= 0.0 && ts < 0.14) {
            vec2 meet = ring_at(ua + per * 0.5, ubox);
            float tq = floor(ts * 20.0) / 20.0;
            float rad = (3.0 + 30.0 * tq) * A;
            vec2 d = p - meet;
            if (abs(length(d) - rad) < 0.5 * A) {
                // the spark nearest this angle, rather than ten tried in turn
                float a = 0.3 + 2.0 * PI * floor((atan(d.y, d.x) - 0.3) / (2.0 * PI / 10.0) + 0.5) / 10.0;
                vec2 dp = meet + vec2(cos(a), sin(a)) * rad;
                if (abs(p.x - dp.x) < 0.5 * A && abs(p.y - dp.y) < 0.5 * A)
                    col = vec4(D3(T_GLINT), 1.0);
            }
        }
    }
    return col;
}

// GRAIN on a bar: the strip's inner edge carries one rule of four-pixel grains,
// as a card's top rule does, with the readings set in grain's ink above it
vec4 grain_bar(vec2 p) {
    vec4 r = vec4(D(G_RECT), D(G_RECT + 1), D(G_RECT + 2), D(G_RECT + 3));
    if (p.x < r.x || p.x >= r.z || p.y < r.y || p.y >= r.w) return vec4(0.0);
    bool top = D(G_MODE) < 1.5;
    float ry = top ? r.w : r.y + 4.0;
    if (p.y < ry - 4.0 * A || p.y >= ry) return vec4(0.0);
    vec2 cell = vec2(floor((p.x - r.x) / A), floor((p.y - ry) / A));
    return vec4(grain_tone(cell, 9u, true, false), 1.0);
}

void mainImage(out vec4 color, in vec2 fragCoord) {
    kit_begin();
    vec2 p = kit_point(fragCoord);
    if (D(G_MODE) > 0.5) {
        color = grain_bar(p);
        if (color.a <= 0.0) discard;
        return;
    }
    int F = int(D(K_FOCUS));
    int O = int(D(K_OLD));
    float dt = D(K_TSW) > -1e5 ? move_age(DESIGN) : 0.0;
    g_anim = D(K_FLOW) >= 0.0 && sw_age() >= 0.0 && sw_age() < D(K_SETTLE);
    int first = -1;
    for (int i = 0; i < 8; i++) {
        if (card_shown(i)) {
            first = i;
            break;
        }
    }
    if (first < 0) discard;
    g_host = F >= 0 ? F : first;
    g_double = F >= 0;
    g_voiced = F >= 0 && voice_env() > 0.002;
    g_pour = max(1.0, D(T_POUR));
    g_crumble = D(T_CRUMBLE);
    g_fall = D(T_FALL);
    vec4 hb = card(g_host);
    // where the readings' rule opens, for the host's own top rule
    g_ropen = 1e9;
    {
        float ha = ceil((hb.z - hb.x) / A);
        float hx0 = 4.0 * float(grain_len(title_base(g_host), 12)) + 5.0;
        float r = readings_open(ha);
        if (r <= hx0 + 30.0) r = readings_clock(ha);
        if (r > hx0 + 30.0) g_ropen = r;
    }
    g_ubox = vec4(hb.x - 10.0, hb.y - 10.0, hb.z + 10.0, hb.w + 10.0);
    g_per = 2.0 * ((g_ubox.z - g_ubox.x) + (g_ubox.w - g_ubox.y));
    g_ua = 0.0;
    vec4 obox = vec4(0.0);
    float ou = 0.0;
    vec2 src = vec2(-1e6);
    bool falling = g_anim && O >= 0 && O != g_host && card_shown(O);
    if (falling) {
        vec4 ob = card(O);
        obox = vec4(ob.x - 10.0, ob.y - 10.0, ob.z + 10.0, ob.w + 10.0);
        if (card_side(g_host) != D(K_FROM)) {
            vec2 q = nearest_on(g_ubox, vec2(0.5 * (ob.x + ob.z), hb.y - 12.0));
            g_ua = perim(q, g_ubox).x;
            src = nearest_on(obox, q);
        }
        ou = perim(src.x > -1e5 ? src : ring_at(0.0, obox), obox).x;
    }
    color = vec4(0.0);
    for (int i = 0; i < 8; i++) {
        if (!card_shown(i)) continue;
        vec4 c = plain_card(p, card(i), i, dt);
        if (c.a > 0.0) color = c;
    }
    if (falling) {
        vec4 c = drain_over(p, card(O), obox, ou, dt);
        if (c.a > 0.0) color = c;
    }
    if (card_shown(g_host)) {
        vec4 c = focused_over(p, card(g_host), g_host, dt, g_ua, g_per, g_ubox,
                              F >= 0, F >= 0, obox, falling ? src : vec2(-1e6));
        if (c.a > 0.0) color = c;
    }
    // The furniture over whichever card this pixel stands: the host's, or the old
    // card's while its type and sand drop away, each grain by its own hash. One
    // call, so the driver holds one copy of the drawing however many cards move.
    vec4 fbox = card(g_host);
    vec2 fp = p;
    int fid = g_host;
    bool ftyped = g_anim;
    bool fvoiced = F >= 0;
    if (falling && dt < 0.16) {
        vec4 ob2 = card(O);
        if (p.x >= ob2.x && p.x < ob2.z && p.y >= ob2.y - 24.0 && p.y < ob2.y - 4.0) {
            int dy = fallen(floor((p - ob2.xy) / A), dt);
            fbox = ob2;
            fid = O;
            ftyped = false;
            fvoiced = false;
            fp = dy < 0 ? vec2(1e6) : p - vec2(0.0, A * float(dy));
        }
    }
    if (card_shown(g_host)) {
        vec4 f = vec4(0.0);
        if (furn(fp, fbox, fid, dt, ftyped, fvoiced, f)) color = f;
    }
    if (color.a <= 0.0) discard;
}
