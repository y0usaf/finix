// lumen: pixel as light rather than matter. Every frame is one row of round LED
// dots five pixels from dot to dot in the ten pixels round its card, so the two
// columns' rings meet in a single shared column of dots down the middle of the
// seam and every corner lands on a dot. A card out of focus is unlit dots --
// slate in the dark, warm grey on paper -- with its title lit dim; the focused
// card's ring is lit, warm white with a halo in the dark and ink with a faint
// darkening one on paper, and its top edge carries a five-row dot-matrix
// readout: the title at the left, a scope for bolo's voice beside it, then CPU,
// MEM, GPU and VRAM each as a label, a twelve-dot bar and its value, and the
// clock and the date at the right, three dots by five a character.
//
// A focus change is a marquee chase: a bright head starts at the point of the
// new ring nearest the old card -- at the title's corner for a change within a
// column -- and runs both ways round it at nine thousand pixels a second,
// lighting the dots behind it and the readout's columns as it reaches them,
// while the old frame fades on a phosphor afterglow in a fifth of a second. The
// voice moves the whole ring at once: every dot of the focused ring takes the
// level being spoken, louder speech lifting them further, so all four sides
// answer together and no corner waits for a wave; spikes of one or two dots
// stand off the ring's sides and bottom with that level, and the readout's scope
// scrolls the level history, newest at its right.
//
// With no card in focus -- a peek, an empty desktop -- there is no frame for the
// readings to ride and no card for the compositor's reach ring to hang on, so
// they stand as one band of dots at the top centre, on a small surface of their
// own that names no reach; the band is the same band, on a card that is not
// there, through the same code.
//
// On an output the deck gives no seam -- the headset's -- the readout stands
// along the bars the deck hands it instead: the same five rows of dots, the
// clock and the date along the top bar, the readings and bolo's scope along the
// bottom, and every item in the block the shared placement lays for it, so the
// rail's geometry is the strip's and not this shader's.
//
// Everything is premultiplied, as the compositor blends the surface, and
// coordinates are the output's, y down. A fragment costs a few dots: the nearest
// dot of a ring and the two beside it for their share of the halo (a readout dot
// keeps its light inside its own cell), and one walk of the readout's items
// through a single call of the three-by-five type -- never a copy of the type per
// item, and no copy of the readout per neighbour, which is what makes this
// shader quick to compile as well as to draw.

// the theme's own numbers: the flag that says this surface is a bar rather than
// a card's ring, the palette and the shape, the readings' value lengths, the
// ring's radius, and then either a card's title lengths or -- on a bar -- the
// box the readout stands in and the blocks its items take their columns from
const int TH_ON = THEME + 1, TH_OFF = THEME + 4, TH_GLOW = THEME + 7, TH_HOT = THEME + 10;
const int TH_OUT = THEME + 13, TH_PITCH = THEME + 14, TH_DOT = THEME + 15;
const int TH_CHASE = THEME + 16, TH_VU = THEME + 17, TH_HALO = THEME + 18;
const int TH_FREE = THEME + 19, TH_ITEMS = THEME + 20, TH_PASSES = THEME + 21, TH_RAD = THEME + 26;
const int TH_VLEN = THEME + 22, TH_TLEN = THEME + 27;
const int L_MODE = THEME, L_BOX = THEME + 27, L_BLOCKS = THEME + 31;

const int BAND_ROWS = 5;
const int SCOPE_COLS = 44;
const int BAR_COLS = 12;
const int BAR_AT = 13;
const int VALUE_AT = 27;
const int VALUE_COLS = 15;
const int GAUGE_COLS = 48;
const int FREE_COLS = SCOPE_COLS + 3 + 4 * GAUGE_COLS + 5 + 19 + 5 + 23;
const float GSIG2 = 2.0 * 3.2 * 3.2;
const float HEAD_LAG = 0.03;
const float ZONE = 16.0;

vec3 g_on, g_off, g_glow, g_hot;
float g_out, g_pitch, g_dot, g_chase, g_vu, g_halo, g_rad;
int g_f, g_o;
float g_age, g_ua, g_per, g_env;
bool g_hasua;

vec4 overp(vec4 s, vec4 d) { return s + d * (1.0 - s.a); }

vec3 ink(float b) {
    vec3 c = mix(g_off, g_on, clamp(b, 0.0, 1.0));
    return mix(c, g_hot, 0.55 * clamp(b - 1.0, 0.0, 1.0));
}

// how much of a lit dot's light lands on its own rim and just past it
float bell(float d) { return exp(-d * d / GSIG2); }

// the same for a readout dot, whose light stays inside its own cell: a cell-wide
// bloom that reaches nothing at the cell's edge, so it needs no neighbours
float cellglow(float d, float sx) {
    float u = clamp(d / (0.72 * sx), 0.0, 1.0);
    return (1.0 - u * u) * (1.0 - u * u);
}

vec4 core(float d, float b) {
    if (b < -0.004) return vec4(0.0);
    float a = clamp(g_dot + 0.5 - d, 0.0, 1.0);
    return vec4(ink(max(b, 0.0)) * a, a);
}

vec4 haze(float s) {
    if (s <= 0.004) return vec4(0.0);
    float a = clamp(s * g_halo, 0.0, 1.0);
    return vec4(g_glow * a, a);
}

// ---------------------------------------------------------------- the ring

// The ring runs along the rounded corner its card has: the card's corners
// grown by the ring's offset, so a dot lands on the arc and the ring meets the
// corner instead of cutting across it with a square lattice.

// the ring's perimeter in pieces: the top edge, a quarter circle, the right
// edge, and so on round, clockwise from the top edge's own start
void rr_pieces(vec4 b, float r, out float sx, out float sy, out float arc, out float per) {
    sx = max(0.0, (b.z - b.x) - 2.0 * r);
    sy = max(0.0, (b.w - b.y) - 2.0 * r);
    arc = 1.5708 * r;
    per = 2.0 * (sx + sy) + 4.0 * arc;
}

// the point at perimeter coordinate U, and the edge it stands on
vec2 rr_at(float u, vec4 b, float r, float per, out int sd) {
    float sx, sy, arc, p0;
    rr_pieces(b, r, sx, sy, arc, p0);
    u = mod(u, per);
    if (u < sx) { sd = 0; return vec2(b.x + r + u, b.y); }
    u -= sx;
    if (u < arc) { sd = 0; float a = u / r;
        return vec2(b.z - r + r * sin(a), b.y + r - r * cos(a)); }
    u -= arc;
    if (u < sy) { sd = 1; return vec2(b.z, b.y + r + u); }
    u -= sy;
    if (u < arc) { sd = 1; float a = u / r;
        return vec2(b.z - r + r * cos(a), b.w - r + r * sin(a)); }
    u -= arc;
    if (u < sx) { sd = 2; return vec2(b.z - r - u, b.w); }
    u -= sx;
    if (u < arc) { sd = 2; float a = u / r;
        return vec2(b.x + r - r * sin(a), b.w - r + r * cos(a)); }
    u -= arc;
    if (u < sy) { sd = 3; return vec2(b.x, b.w - r - u); }
    u -= sy;
    sd = 3;
    float a = u / r;
    return vec2(b.x + r - r * cos(a), b.y + r - r * sin(a));
}

// the nearest point of the ring to P, pushed out of the card's core by the
// ring's radius
vec2 rr_closest(vec2 p, vec4 b, float r) {
    vec2 q = clamp(p, b.xy + vec2(r), b.zw - vec2(r));
    vec2 dv = p - q;
    float l = length(dv);
    if (l < 1e-4) return q + vec2(0.0, -r);
    return q + dv * (r / l);
}

// the perimeter coordinate of a point ON the ring, and the edge it stands on
float rr_u(vec2 q, vec4 b, float r, float per, out int sd) {
    float sx, sy, arc, p0;
    rr_pieces(b, r, sx, sy, arc, p0);
    float e = 0.02;
    if (abs(q.y - b.y) < e && q.x >= b.x + r - e) { sd = 0; return clamp(q.x - b.x - r, 0.0, sx); }
    if (abs(q.x - b.z) < e && q.y >= b.y + r - e) { sd = 1; return sx + arc + clamp(q.y - b.y - r, 0.0, sy); }
    if (abs(q.y - b.w) < e && q.x >= b.x + r - e) { sd = 2; return sx + arc + sy + arc + clamp(b.z - r - q.x, 0.0, sx); }
    if (abs(q.x - b.x) < e && q.y >= b.y + r - e) { sd = 3; return 2.0 * (sx + arc) + sy + arc + clamp(b.w - r - q.y, 0.0, sy); }
    // on one of the four arcs: the angle round its centre says where
    if (q.x > b.z - r && q.y < b.y + r) {                 // top right
        sd = 1;
        return sx + clamp(atan(q.y - (b.y + r), q.x - (b.z - r)) + 1.5708, 0.0, 1.5708) * r;
    }
    if (q.x > b.z - r && q.y > b.w - r) {                 // bottom right
        sd = 2;
        return sx + arc + sy + clamp(atan(q.x - (b.z - r), (b.w - r) - q.y), 0.0, 1.5708) * r;
    }
    if (q.x < b.x + r && q.y > b.w - r) {                 // bottom left
        sd = 2;
        return sx + arc + sy + arc + sx +
            clamp(atan((b.w - r) - q.y, (b.x + r) - q.x), 0.0, 1.5708) * r;
    }
    sd = 0;                                               // top left
    return 2.0 * (sx + arc) + sy + arc + sy +
        clamp(atan((b.x + r) - q.x, q.y - (b.y + r)), 0.0, 1.5708) * r;
}

// The dot of the ring round card B nearest P: its centre, the perimeter
// coordinate of that centre clockwise from the ring's top edge, the edge it
// lies on (0 top, 1 right, 2 bottom, 3 left) and the pitch.
float ring_dot(vec2 p, vec4 b, out vec2 c, out float u, out int sd, out float s) {
    vec4 r = vec4(b.x - g_out, b.y - g_out, b.z + g_out, b.w + g_out);
    float rad = g_rad + g_out;
    float per = 0.0, sx = 0.0, sy = 0.0, arc = 0.0;
    rr_pieces(r, rad, sx, sy, arc, per);
    float n = max(4.0, floor(per / g_pitch + 0.5));
    float pitch = per / n;
    vec2 q = rr_closest(p, r, rad);
    float uq = rr_u(q, r, rad, per, sd);
    float t = floor(uq / pitch + 0.5);
    u = t * pitch;
    int sd2;
    c = rr_at(u, r, rad, per, sd2);
    if (sd2 != sd) sd = sd2;
    s = pitch;
    return length(p - c);
}

// How far the marquee's head has run round the new frame AGE seconds in: at the
// theme's pace, or faster on a frame so big that half its ring would take longer
// than the move to run, so the chase always finishes inside it.
const float DESIGN = 0.6;      // seconds the chase was drawn for

float chase_head(float age) {
    float dur = max(DESIGN - HEAD_LAG, 0.05);
    float v = max(g_chase, g_per * 0.5 / dur);
    return v * max(age - HEAD_LAG, 0.0);
}

// The level the voice had when the chase, which starts at the title's corner,
// ran U round the ring.
float voice_round(float u) {
    return g_env * voice_around(u, g_per);
}

// How brightly a dot at U on card I's ring is lit: the marquee's head behind it
// with its trail, or else the whole ring lit and the voice's level where it ran.
float ring_bright(float u, float sx, int i, bool foc) {
    if (foc) {
        if (g_hasua) {
            float head = chase_head(g_age);
            float d = pdist(u, g_ua, g_per);
            return d > head ? 0.0 : 0.9 + 1.2 * exp(-(head - d) / 45.0);
        }
        return 0.9 + 1.5 * voice_round(u);
    }
    return i == g_o ? 0.9 * exp(-g_age / 0.2) : 0.0;
}

// ---------------------------------------------------------------- the readout

// A bar's table: how many blocks it carries, then each one's kind and its rect
// in output pixels, as the shared placement lays them along the strip.
const int L_BLOCK_MAX = 5;

// the dot column block KIND starts at, measured from X0 at SX a dot, or -1 when
// this bar carries no block of that kind
float bar_col(int kind, float x0, float sx) {
    int nb = int(D(L_BLOCKS));
    for (int i = 0; i < L_BLOCK_MAX; i++) {
        if (i >= nb) break;
        int b0 = L_BLOCKS + 1 + i * 5;
        if (int(D(b0)) == kind) return floor((D(b0 + 1) - x0) / sx + 0.5);
    }
    return -1.0;
}

// The text the readout sets in column COL of card TI, if any: ITEM walks the
// items -- the title, the clock, the date, the four labels, the four values --
// and the type is called once, inside that walk, so the shader holds one copy of
// it however many items it sets. TITLE is the title's length in characters (0
// for the fallback band, which has none), NX the band's dot columns, SX its
// pitch, X0 and ROW0 the left dot column and the first row's centre. On a bar
// each item stands at its own block instead of in the band's own layout.
float readout_text(vec2 q, int col, float x0, float row0, float sx, int ti, int title,
        float nx, bool full, float mul) {
    float cGauges = nx - 4.0 - 23.0 - 5.0 - 19.0 - 5.0 - float(4 * GAUGE_COLS);
    float cClock = cGauges + float(4 * GAUGE_COLS) + 5.0;
    float cDate = cClock + 19.0 + 5.0;
    float fcol = float(col);
    bool bar = D(L_MODE) > 0.5;
    int items = full ? int(D(TH_ITEMS)) : 1;
    int idx;
    for (int k = 0; k < items; k++) {
        // one item: where its first character's cell is, what it is, how many
        // characters it has and how brightly it is lit
        float at;
        int kind = k, n;
        float bright = mul;
        if (k == 0) {
            // the title takes the room left before the scope, so a long one is
            // set as far as it fits instead of running under the readings
            at = 3.0; n = min(title, int((cGauges - 10.0 - float(SCOPE_COLS)) / 4.0));
            bright = max(mul, 0.42);
        } else if (bar) {
            // on a bar an item stands in the block the shared placement gives
            // it: the clock in the clock's, the date in the date's, and a
            // reading's label and value in that reading's own
            at = bar_col(k == 1 ? 0 : (k == 2 ? 1 : (k < 7 ? k - 1 : k - 5)), x0, sx);
            if (at < 0.0) continue;
            if (k == 1) {
                n = 5;
            } else if (k == 2) {
                n = 6; bright = 0.55 * mul;
            } else if (k < 7) {
                n = 3; bright = 0.55 * mul;
            } else {
                // a value, right aligned in four characters as it glides
                int g = k - 7;
                n = int(D(TH_VLEN + g));
                at += float(VALUE_AT) + 4.0 * float(4 - n);
            }
        } else if (k == 1) {
            at = cClock; n = 5;
        } else if (k == 2) {
            at = cDate; n = 6; bright = 0.55 * mul;
        } else if (k < 7) {
            at = cGauges + float((k - 3) * GAUGE_COLS); n = 3; bright = 0.55 * mul;
        } else {
            // a value, right aligned in four characters as it glides
            int g = k - 7;
            n = int(D(TH_VLEN + g));
            at = cGauges + float(g * GAUGE_COLS + VALUE_AT) + 4.0 * float(4 - n);
        }
        if (fcol < at || fcol > at + 4.0 * float(n) - 2.0) continue;
        // what the item is: 0 the card's title, 1 the clock, 2 the date, 3..6 a
        // label and 7..10 a value
        int base = K_CARDS + ti * K_CARD + 1;
        if (kind == 1) base = K_CLOCK;
        else if (kind == 2) base = K_DATE;
        else if (kind >= 3) base = K_GAUGES + ((kind - 3) % 4) * K_GAUGE +
            (kind < 7 ? 4 : 2);
        return text_hit(q, vec2(x0 + at * sx, row0), sx, base, n, idx) ? bright : 0.0;
    }
    return -1.0;
}

// The dot at column COL, row ROW (0 top) of a readout: its brightness, or -1
// where the band has no dot. FULL: the focused card's whole readout, else only
// its title; MUL fades an old card's afterglow.
float readout_cell(vec2 q, int col, int row, float x0, float row0, float sx, int ti,
        int title, float nx, bool full, float mul) {
    float fcol = float(col);
    float hit = readout_text(q, col, x0, row0, sx, ti, title, nx, full, mul);
    if (hit >= 0.0) return hit;
    if (!full) return -1.0;
    // On a bar the readings' bars and bolo's scope stand in their own blocks,
    // the twelve dots of a bar in the reading's block and the scope's columns in
    // the voice's; on a card they are laid out along the band.
    if (D(L_MODE) > 0.5) {
        for (int g = 0; g < 4; g++) {
            float bc = bar_col(2 + g, x0, sx);
            if (bc < 0.0) continue;
            float rel = fcol - bc;
            if (rel < 0.0 || rel >= float(GAUGE_COLS)) continue;
            if (rel < float(BAR_AT) || rel >= float(BAR_AT + BAR_COLS)) return 0.0;
            if (row < 1 || row > 3) return -1.0;
            float v = max(gauge_pct(g), 0.0) * 0.12;
            float k = rel - float(BAR_AT);
            return k + 1.0 <= v ? 1.0 : (k < v ? v - k : 0.0);
        }
        // bolo's scope: the level history, newest at its right, dark till it
        // speaks; a bar has its columns only while it carries the voice's block
        float sc = bar_col(6, x0, sx);
        if (sc >= 0.0 && fcol >= sc && fcol < sc + float(SCOPE_COLS)) {
            float lev = g_env * voice_level((sc + float(SCOPE_COLS) - 1.0 - fcol) / 30.0);
            bool lit = abs(float(row) - 2.0) <= lev * 2.6 - 0.2;
            return lit ? (1.0 + 0.6 * lev) * mul : 0.0;
        }
        return 0.0;
    }
    // the readings' bars: twelve dots each, the leading one fractionally lit
    float cGauges = nx - 4.0 - 23.0 - 5.0 - 19.0 - 5.0 - float(4 * GAUGE_COLS);
    float rel = fcol - cGauges;
    if (rel >= 0.0 && rel < float(4 * GAUGE_COLS)) {
        int g = int(rel / float(GAUGE_COLS));
        int off = int(rel) - g * GAUGE_COLS;
        if (off < BAR_AT || off >= BAR_AT + BAR_COLS) return 0.0;
        if (row < 1 || row > 3) return -1.0;
        float v = max(gauge_pct(g), 0.0) * 0.12;
        float k = float(off - BAR_AT);
        return k + 1.0 <= v ? 1.0 : (k < v ? v - k : 0.0);
    }
    // bolo's scope: the level history, newest at its right, dark till it speaks
    float cScope = 4.0 * float(title) + 5.0;
    float sEnd = min(cScope + float(SCOPE_COLS), cGauges - 4.0);
    if (fcol >= cScope && fcol < sEnd) {
        float lev = g_env * voice_level((sEnd - 1.0 - fcol) / 30.0);
        bool lit = abs(float(row) - 2.0) <= lev * 2.6 - 0.2;
        return lit ? (1.0 + 0.6 * lev) * mul : 0.0;
    }
    return 0.0;
}

// ---------------------------------------------------------------- a frame

// One card's ring and its readout, or -- for the fallback band, TI at the end of
// the table -- the readout alone on a band whose card is not there.
vec4 lumen_frame(vec2 p, vec4 b, int ti, bool full, float mul) {
    float Lx = (b.z - b.x) + 2.0 * g_out;
    float nx = max(1.0, floor(Lx / g_pitch + 0.5));
    float sx = Lx / nx;
    float ringY = b.y - g_out;
    bool ringed = ti < 8;
    bool foc = ringed && ti == g_f, old = ringed && ti == g_o;
    vec4 acc = vec4(0.0);
    // the ring
    vec4 rb = vec4(b.x - g_out, b.y - g_out, b.z + g_out, b.w + g_out);
    if (ringed && abs(sd_rbox(p, rb, g_rad + g_out)) < ZONE) {
        vec2 c;
        float u, s;
        int sd;
        float d = ring_dot(p, b, c, u, sd, s);
        vec2 tg = sd == 0 ? vec2(1.0, 0.0)
                : sd == 1 ? vec2(0.0, 1.0)
                : sd == 2 ? vec2(-1.0, 0.0) : vec2(0.0, -1.0);
        vec2 nm = sd == 0 ? vec2(0.0, -1.0)
                : sd == 1 ? vec2(1.0, 0.0)
                : sd == 2 ? vec2(0.0, 1.0) : vec2(-1.0, 0.0);
        float b0 = ring_bright(u, sx, ti, foc) * (foc ? 1.15 : 1.0);
        float unl = foc || old ? 1.0 : 0.38;   // how much of an unlit dot shows
        float gs = b0 > 0.004 ? bell(d) * b0 : 0.0;
        if (b0 > 0.004) {
            // the dots either side of the lit one share their halo with it
            for (int k = -1; k <= 1; k += 2) {
                float bk = ring_bright(u + float(k) * s, sx, ti, foc);
                if (bk > 0.004) gs += bell(length(p - (c + tg * (float(k) * s)))) * bk;
            }
        }
        // the spikes the voice stands off the ring's sides and bottom: the two
        // dots straight off the nearest one, which is the lattice dot any spike
        // of theirs belongs to
        float spd = 1e9, spb = 0.0;
        if (foc && !g_hasua && sd != 0) {
            float lev = voice_round(u);
            if (lev > 0.02) {
                int seam_sd = card_side(ti) < 0.0 ? 1 : 3;
                float hs = hf(hu(int(u / g_pitch), sd, uint(int(iTime * 30.0) % 97)));
                float amp = lev * (0.5 + hs) * 2.0;
                for (int j = 1; j <= 2; j++) {
                    float aj = j == 1 ? clamp(amp, 0.0, 1.6) : clamp(amp - 0.9, 0.0, 1.6);
                    if (aj < 0.25 || (j == 2 && sd == seam_sd)) continue;
                    float dj = length(p - (c + nm * (g_pitch * float(j))));
                    gs += bell(dj) * aj;
                    if (dj < spd) { spd = dj; spb = aj; }
                }
            }
        }
        if (foc) {
            // the focused ring's own light, wide enough to read at a glance
            acc = overp(haze(0.55 * exp(-d * d / (2.0 * 26.0 * 26.0))), acc);
        }
        acc = overp(haze(gs), acc);
        if (spb > 0.0) acc = overp(core(spd, spb) * unl, acc);
        acc = overp(core(d, b0) * unl, acc);
    }
    // the readout over the top edge
    float t = (ringY - p.y) / sx;
    if (t > 0.25 && t < float(BAND_ROWS) + 1.6) {
        float fx = (p.x - (b.x - g_out)) / sx;
        float cx = clamp(floor(fx + 0.5), 0.0, nx);
        float ry = clamp(floor(t + 0.5), 1.0, float(BAND_ROWS));
        int col = int(cx), row = BAND_ROWS - int(ry);
        vec2 c2 = vec2(b.x - g_out + cx * sx, ringY - ry * sx);
        // the band is made of its dots: the title of a card out of focus, or the
        // whole readout of one in focus
        int title = ringed ? int(D(TH_TLEN + ti)) : 0;
        float bb = readout_cell(c2, col, row, b.x - g_out, ringY - sx * float(BAND_ROWS),
                                sx, ti, title, nx, full, mul);
        if (bb > 0.0 && foc && g_hasua) {
            // the head lights the readout as it passes its columns
            float dd = pdist(float(col) * sx, g_ua, g_per);
            float head = chase_head(g_age);
            bb = dd <= head ? bb + 0.7 * exp(-(head - dd) / 24.0) : 0.0;
        }
        if (bb >= 0.0) {
            // a lit cell's own light, dying inside its cell: a dot of the readout
            // needs no neighbour walked to make its bloom, which is what keeps
            // this shader quick to compile
            acc = overp(haze(bb * cellglow(length(p - c2), sx)), acc);
            acc = overp(core(length(p - c2), bb), acc);
        }
    }
    return acc;
}

// The fallback band's card, which is not there: a box whose top edge puts the
// band's left dot column at 4 and its first row at 8, as wide as the surface
// holds -- FREE_COLS dot columns of air.
vec4 free_box() {
    float nx = float(FREE_COLS - 1);
    float x = 4.0 + g_out;
    float y = 8.0 + g_out + float(BAND_ROWS) * g_pitch;
    return vec4(x, y, x + nx * g_pitch - 2.0 * g_out, y + 1.0);
}

// ---------------------------------------------------------------- the output

void mainImage(out vec4 color, in vec2 fragCoord) {
    kit_begin();
    vec2 p = kit_point(fragCoord);
    g_on = D3(TH_ON); g_off = D3(TH_OFF);
    g_glow = D3(TH_GLOW); g_hot = D3(TH_HOT);
    g_out = D(TH_OUT); g_pitch = D(TH_PITCH); g_dot = D(TH_DOT);
    g_chase = D(TH_CHASE); g_vu = D(TH_VU); g_halo = D(TH_HALO);
    g_rad = D(TH_RAD);
    g_f = int(D(K_FOCUS)); g_o = int(D(K_OLD));
    g_hasua = D(K_TSW) > -1e5 && sw_age() >= 0.0 && sw_age() < D(K_SETTLE);
    g_age = move_age(DESIGN);
    g_env = voice_env();
    if (D(L_MODE) > 0.5) {
        // a bar: the readout's own dots, laid along the strip
        vec4 b = vec4(D(L_BOX), D(L_BOX + 1), D(L_BOX + 2), D(L_BOX + 3));
        vec4 acc = lumen_frame(p, b, 8, true, 1.0);
        if (acc.a <= 0.002) discard;
        color = acc;
        return;
    }
    g_ua = 0.0;
    g_per = 1.0;
    if (card_shown(g_f)) {
        // where the marquee starts: the point of the new ring nearest the old
        // card, or the top edge's corner when the focus stayed in its column
        vec4 b = card(g_f);
        vec4 r = vec4(b.x - g_out, b.y - g_out, b.z + g_out, b.w + g_out);
        float rad = g_rad + g_out, qx, qy, qa;
        rr_pieces(r, rad, qx, qy, qa, g_per);
        if (g_hasua && card_shown(g_o) && D(K_FROM) != D(K_SIDE) &&
                card_side(g_o) * card_side(g_f) < 0.0) {
            vec4 ob = card(g_o);
            vec2 q = rr_closest(vec2((ob.x + ob.z) * 0.5, (ob.y + ob.w) * 0.5), r, rad);
            int sdd;
            g_ua = rr_u(q, r, rad, g_per, sdd);
        }
    }
    // One walk over the frames, in the passes the theme names -- every other card,
    // then the focused one, then the fallback band -- so the focused ring's dots
    // win the column the two cards share. The pass count is read from the data so
    // the walk stays a loop instead of being unrolled into copies.
    bool free_band = D(TH_FREE) > 0.5;
    vec4 acc = vec4(0.0);
    for (int pass = 0; pass < int(D(TH_PASSES)); pass++) {
        for (int k = 0; k < 9; k++) {
            vec4 b;
            int ti = k;
            bool full = false, ringed = k < 8;
            float mul = 1.0;
            if (k < 8) {
                if (pass == 2 || !card_shown(k)) continue;
                if ((k == g_f) == (pass == 0)) continue;
                b = card(k);
                bool foc = k == g_f, old = k == g_o;
                full = foc || (old && g_age < 0.6);
                mul = old && !foc ? (g_age < 0.6 ? exp(-g_age / 0.2) : 1.0) : 1.0;
            } else {
                if (pass != 2 || !free_band) continue;
                b = free_box();
                ti = 8;
                full = true;
                ringed = false;
            }
            if (!ringed && !full) continue;
            acc = overp(lumen_frame(p, b, ti, full, mul), acc);
        }
    }
    if (acc.a <= 0.002) discard;
    color = acc;
}
