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
// voice is a VU chase: every dot of the focused ring takes the level the voice
// had when the chase, which starts at the title's corner, ran that far round
// it, spikes of one or two dots stand off its sides and bottom with that level,
// and the readout's scope scrolls the level history, newest at its right.
//
// With no card in focus -- a peek, an empty desktop -- there is no frame for the
// readings to ride and no card for the compositor's reach ring to hang on, so
// they stand as one band of dots at the top centre, on a small surface of their
// own that names no reach; the band is the same band, on a card that is not
// there, through the same code.
//
// Everything is premultiplied, as the compositor blends the surface, and
// coordinates are the output's, y down. A fragment costs a few dots: the nearest
// dot of a ring and the two beside it for their share of the halo (a readout dot
// keeps its light inside its own cell), and one walk of the readout's items
// through a single call of the three-by-five type -- never a copy of the type per
// item, and no copy of the readout per neighbour, which is what makes this
// shader quick to compile as well as to draw.

const int TH_ON = THEME, TH_OFF = THEME + 3, TH_GLOW = THEME + 6, TH_HOT = THEME + 9;
const int TH_OUT = THEME + 12, TH_PITCH = THEME + 13, TH_DOT = THEME + 14;
const int TH_CHASE = THEME + 15, TH_VU = THEME + 16, TH_HALO = THEME + 17;
const int TH_FREE = THEME + 18, TH_ITEMS = THEME + 19, TH_PASSES = THEME + 20;
const int TH_VLEN = THEME + 21, TH_TLEN = THEME + 25;

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
float g_out, g_pitch, g_dot, g_chase, g_vu, g_halo;
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

// The dot of the ring round card B nearest P: its centre, the perimeter
// coordinate of that centre clockwise from the ring's top-left corner, the edge
// it lies on (0 top, 1 right, 2 bottom, 3 left) and the pitch along that edge.
float ring_dot(vec2 p, vec4 b, out vec2 c, out float u, out int sd, out float s) {
    vec4 r = vec4(b.x - g_out, b.y - g_out, b.z + g_out, b.w + g_out);
    float w = r.z - r.x, h = r.w - r.y;
    float nx = max(1.0, floor(w / g_pitch + 0.5));
    float ny = max(1.0, floor(h / g_pitch + 0.5));
    float sx = w / nx, sy = h / ny;
    float dt = r.y - p.y, dr = p.x - r.z, db = p.y - r.w, dl = r.x - p.x;
    float m = max(max(dt, dr), max(db, dl));
    float t;
    if (m == dt) {
        t = clamp(floor((p.x - r.x) / sx + 0.5), 0.0, nx);
        c = vec2(r.x + t * sx, r.y); u = t * sx; s = sx; sd = 0;
    } else if (m == dr) {
        t = clamp(floor((p.y - r.y) / sy + 0.5), 0.0, ny);
        c = vec2(r.z, r.y + t * sy); u = w + t * sy; s = sy; sd = 1;
    } else if (m == db) {
        t = clamp(floor((r.z - p.x) / sx + 0.5), 0.0, nx);
        c = vec2(r.z - t * sx, r.w); u = w + h + t * sx; s = sx; sd = 2;
    } else {
        t = clamp(floor((r.w - p.y) / sy + 0.5), 0.0, ny);
        c = vec2(r.x, r.w - t * sy); u = 2.0 * w + h + t * sy; s = sy; sd = 3;
    }
    return length(p - c);
}

// How far the marquee's head has run round the new frame AGE seconds in: at the
// theme's pace, or faster on a frame so big that half its ring would take longer
// than the settle to run, so the chase always finishes inside the settle.
float chase_head(float age) {
    float dur = max(D(K_SETTLE) - HEAD_LAG, 0.05);
    float v = max(g_chase, g_per * 0.5 / dur);
    return v * max(age - HEAD_LAG, 0.0);
}

// The level the voice had when the chase, which starts at the title's corner,
// ran U round the ring.
float voice_round(float u, float sx) {
    return g_env * voice_level(pdist(u, 3.0 * sx, g_per) / g_vu);
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
        return 0.9 + 1.5 * voice_round(u, sx);
    }
    return i == g_o ? 0.9 * exp(-g_age / 0.2) : 0.0;
}

// ---------------------------------------------------------------- the readout

// The text the readout sets in column COL of card TI, if any: ITEM walks the
// items -- the title, the clock, the date, the four labels, the four values --
// and the type is called once, inside that walk, so the shader holds one copy of
// it however many items it sets. TITLE is the title's length in characters (0
// for the fallback band, which has none), NX the band's dot columns, SX its
// pitch, X0 and ROW0 the left dot column and the first row's centre.
float readout_text(vec2 q, int col, float x0, float row0, float sx, int ti, int title,
        float nx, bool full, float mul) {
    float cGauges = nx - 4.0 - 23.0 - 5.0 - 19.0 - 5.0 - float(4 * GAUGE_COLS);
    float cClock = cGauges + float(4 * GAUGE_COLS) + 5.0;
    float cDate = cClock + 19.0 + 5.0;
    float fcol = float(col);
    int items = full ? int(D(TH_ITEMS)) : 1;
    int idx;
    for (int k = 0; k < items; k++) {
        // one item: where its first character's cell is, what it is, how many
        // characters it has and how brightly it is lit
        float at;
        int kind = k, n;
        float bright = mul;
        if (k == 0) {
            at = 3.0; n = title; bright = max(mul, 0.42);
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
    if (ringed && abs(sd_rbox(p, rb, 0.0)) < ZONE) {
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
        float b0 = ring_bright(u, sx, ti, foc);
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
            float lev = voice_round(u, sx);
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
        acc = overp(haze(gs), acc);
        if (spb > 0.0) acc = overp(core(spd, spb), acc);
        acc = overp(core(d, b0), acc);
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
    g_f = int(D(K_FOCUS)); g_o = int(D(K_OLD));
    g_age = iTime - D(K_TSW);
    g_hasua = D(K_TSW) > -1e5 && g_age >= 0.0 && g_age < D(K_SETTLE);
    g_env = voice_env();
    g_ua = 0.0;
    g_per = 1.0;
    if (card_shown(g_f)) {
        // where the marquee starts: the point of the new ring nearest the old
        // card, or the title's corner when the focus stayed in its column
        vec4 b = card(g_f);
        vec4 r = vec4(b.x - g_out, b.y - g_out, b.z + g_out, b.w + g_out);
        g_per = 2.0 * ((r.z - r.x) + (r.w - r.y));
        if (g_hasua && card_shown(g_o) && D(K_FROM) != D(K_SIDE) &&
                card_side(g_o) * card_side(g_f) < 0.0) {
            vec4 ob = card(g_o);
            g_ua = perim(vec2((ob.x + ob.z) * 0.5, (ob.y + ob.w) * 0.5), r).x;
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
