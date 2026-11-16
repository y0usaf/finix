// glyph: the rail and the frames as one text field.
//
// The rail is a column of box-drawing rules in the seam: bolo's turn and the
// braille waterfall under it, the date, the clock built out of 3x5 blocks on a
// half-row grid, the gauges as bars in sixths with a four-second sparkline
// under each, and the network at the foot. Every card the rail carries is
// fenced by square lines in the gap round it -- one faint line, doubled in ink
// where the card holds focus -- under the title row the frame cuts off from the
// window. A focus change retypes the frame: two heads leave the middle of the
// rail-side edge and run up and down the perimeter, and the line behind them is
// doubled by the time they pass, meeting at the far edge. The frame the card
// wore before un-types the same way, its heads running back to the rail.
// Bolo's voice is a dithered field of dots down the rail, the newest at the top,
// fading out over the settle once the turn closes.
//
// One shader draws both surfaces: the frames over the whole output (only the
// rings round the cards are shaded, so it is cheap) and the rail down the seam.
// The numbers are iData, laid out by rail-glyph--frame-data and
// rail-glyph--rail-data in rail.lisp in this order:
//
//   0 mode (0 frames, 1 rail)   1,2 origin of the surface in the output
//   3..23 the palette: bg, ink, dim, faint, acc, red, track (three reals each)
//   24,25 the published seam's left edge and width
//   frames 26 gap 27 line 28 pair 29 title 30 tsw 31 sweep 32 focus 33 old
//          34 flow
//   rail   35 track x 36 track w 37 seam top 38 seam height
//          39 mic y 40 mic h 41 water y 42 water h 43 date y 44 date h
//          45 clock y 46 clock h 47 gauge y 48 gauge block h 49 net y 50 net h
//          51 bar y 52 bar h 53 spark y 54 spark h 55 rule 56..59 the rules
//          122,123 the rules at the frames' top and bottom, on the screen's edges
//          60..63 clock digits 64..67 gauge percents 68..83 gauge history
//          84 voice since 85 voice fade 86 voice on 87 rise 88 settle
//          89 level count 90..121 levels
//
// iWindow holds the drawn boxes of up to eight cards (x, y, w, h in the
// surface's own pixels, y up), iTime counts from the clock the rail passes and
// holds once nothing moves. Coordinates here are the output's, y down.

float D(int i) { return iData[i >> 2][i & 3]; }
vec3 D3(int i) { return vec3(D(i), D(i + 1), D(i + 2)); }

const int MODE = 0, ORIGIN = 1;
const int BG = 3, INK = 6, DIM = 9, FAINT = 12, ACC = 15, RED = 18, TRACK = 21;
const int SEAM = 24;
const int GAP = 26, LINE = 27, PAIR = 28, TITLE = 29;
const int TSW = 30, SWEEP = 31, FOCUS = 32, OLD = 33, FLOW = 34;
const int RX = 35, RW = 36, RTOP = 37, RH = 38;
const int MICY = 39, MICH = 40, WATY = 41, WATH = 42, DATEY = 43, DATEH = 44;
const int CLKY = 45, CLKH = 46, GAUY = 47, BLOK = 48, NETY = 49, NETH = 50;
const int BARY = 51, BARH = 52, SPKY = 53, SPKH = 54, RULE = 55, RULES = 56, OUTER = 122;
const int DIGIT = 60, GAUGE = 64, HIST = 68;
const int VSINCE = 84, VFADE = 85, VON = 86, RISE = 87, SETTLE = 88;
const int LEVELS = 89;

vec2 g_origin;
float g_h;

float sm(float a, float b, float x) {
    float u = clamp((x - a) / (b - a), 0.0, 1.0);
    return u * u * (3.0 - 2.0 * u);
}

vec4 card(int i) {
    vec4 w = iWindow[i];
    float top = g_h - (w.y + w.w);
    return vec4(w.x + g_origin.x, top + g_origin.y, w.x + w.z + g_origin.x, top + w.w + g_origin.y);
}

bool shown(int i) { return i >= 0 && i < iWindowCount && iWindow[i].z > 0.0; }

// How far round a card's perimeter a point sits from the middle of its
// rail-side edge: 0 on that edge, w + h at the far edge's middle, the same
// either way round, so two heads leaving the rail meet there.
float ring_s(vec2 p, vec4 box, bool rail_right) {
    float w = box.z - box.x, h = box.w - box.y, cy = (box.y + box.w) * 0.5;
    float rail = rail_right ? abs(p.x - box.z) : abs(p.x - box.x);
    float far = rail_right ? abs(p.x - box.x) : abs(p.x - box.z);
    float tb = min(abs(p.y - box.y), abs(p.y - box.w));
    float d;
    if (rail <= min(tb, far)) {
        d = abs(p.y - cy);
    } else if (tb <= far) {
        if (p.y < cy) d = h * 0.5 + (rail_right ? box.z - p.x : p.x - box.x);
        else d = h * 0.5 + w + h + (rail_right ? p.x - box.x : box.z - p.x);
    } else {
        d = h * 0.5 + w + (p.y - box.y);
    }
    return min(d, 2.0 * (w + h) - d);
}

// The frame round one card: its gutter, the line or the pair of lines, and the
// title row, whose ground the frame owns -- plain ground for a card at rest, ink
// typing across it from the rail-less end as the card takes focus, and giving
// the ink back as the card loses it. The window's own name is a surface of its
// own over this, in the ground's colour, so the letters arrive as the ink does.
void card_frame(vec2 p, int i, inout vec4 color) {
    if (!shown(i)) return;
    vec4 box = card(i);
    float gap = D(GAP), line = D(LINE), title = D(TITLE), pair = D(PAIR);
    vec4 frame = vec4(box.x, box.y - title, box.z, box.w);
    if (p.x < frame.x - gap || p.x > frame.z + gap) return;
    if (p.y < frame.y - gap || p.y > frame.w + gap) return;
    if (p.x > frame.x && p.x < frame.z && p.y > box.y && p.y < frame.w) return;
    vec3 bg = D3(BG), ink = D3(INK), faint = D3(FAINT), acc = D3(ACC);
    color = vec4(bg, 1.0);
    float t = iTime - D(TSW);
    float sweep = max(0.001, D(SWEEP));
    int focus = int(D(FOCUS)), old = int(D(OLD));
    bool moving = D(FLOW) > -1.5 && t >= 0.0 && t < sweep && old != focus;
    bool here = i == focus, was = i == old;
    if (p.y > box.y - title && p.y < box.y) {
        float fill = here ? 1.0 : 0.0;
        if (moving) {
            float head = clamp(t / sweep, 0.0, 1.0);
            if (here) fill = head;
            else if (was) fill = 1.0 - head;
            else fill = 0.0;
        }
        color = vec4(p.x < frame.x + fill * (frame.z - frame.x) ? ink : bg, 1.0);
        if (p.y > box.y - line) color = vec4(fill > 0.5 ? ink : faint, 1.0);
        return;
    }
    float hw = line * 0.5;
    float top = frame.y - p.y, bottom = p.y - frame.w;
    float left = frame.x - p.x, right = p.x - frame.z;
    bool row = p.x >= frame.x - gap && p.x <= frame.z + gap;
    bool column = p.y >= frame.y - gap && p.y <= frame.w + gap;
    bool dbl = here;
    float head = -1e6, s = 0.0;
    bool rail_right = (box.x + box.z) * 0.5 < D(SEAM) + D(SEAM + 1) * 0.5;
    if (moving && (here || was)) {
        s = ring_s(p, frame, rail_right);
        head = clamp(t / sweep, 0.0, 1.0) * ((frame.z - frame.x) + (frame.w - frame.y));
        dbl = here ? s < head : s >= head;
    }
    bool lit = false;
    float d = 1e6;
    if (row && top > -1.0 && top < gap) { lit = true; d = top; }
    else if (row && bottom > -1.0 && bottom < gap) { lit = true; d = bottom; }
    else if (column && left > -1.0 && left < gap) { lit = true; d = left; }
    else if (column && right > -1.0 && right < gap) { lit = true; d = right; }
    if (lit) {
        bool on = dbl ? (abs(d - (4.0 - pair * 0.5)) < hw || abs(d - (4.0 + pair * 0.5)) < hw)
                      : abs(d - 4.0) < hw;
        if (on) color = vec4(dbl ? ink : faint, 1.0);
    }
    if (moving && head > -1e5 && abs(s - head) < 7.0 && lit)
        color = vec4(dbl ? ink : acc, 1.0);
}

// ---- the rail

// One pixel of a 3x5 digit. The code packs the rows bottom up, three bits each,
// the left of a row in the least significant of its three.
bool digit_px(float code, int row, int col) {
    return mod(floor(code / exp2(float(row * 3 + col))), 2.0) > 0.5;
}

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
                                  3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float voice_amp(float t) {
    float since = D(VSINCE), fade = D(VFADE), on = D(VON), rise = max(0.01, D(RISE));
    if (D(LEVELS) < 1.0) return 0.0;
    if (on > 0.5) return sm(0.0, 1.0, (t - since) / rise);
    if (fade > -1e8)
        return sm(0.0, 1.0, (fade - since) / rise)
            * (1.0 - sm(0.0, 1.0, (t - fade) / max(0.01, D(SETTLE))));
    return 0.0;
}

// The waterfall: sixteen dots across the track, sixty-four rows down it, the
// newest at the top. Each row carries the level the voice had when it passed,
// sifted through a Bayer field, so how loud it was is how densely the dots fill.
vec4 waterfall(vec2 p, float amp) {
    int count = int(D(LEVELS));
    if (amp <= 0.0 || count < 1) return vec4(0.0);
    float y0 = D(WATY), y1 = y0 + D(WATH), x0 = D(RX), x1 = x0 + D(RW);
    if (p.y < y0 || p.y > y1 || p.x < x0 || p.x > x1) return vec4(0.0);
    float cy = (p.y - y0) / max(1.0, y1 - y0) * 64.0;
    float cx = (p.x - x0) / max(1.0, x1 - x0) * 16.0;
    float fx = fract(cx), fy = fract(cy);
    if (fx > 0.76 || fy > 0.72) return vec4(0.0);
    int row = int(floor(cy)), col = int(floor(cx));
    float level = D(LEVELS + 1 + min(count - 1, row / 2));
    float prof = 0.45 + 0.55 * (0.5 + 0.5 * sin(float(col) * 0.85 + iTime * 2.1)
                                         * cos(float(col) * 0.31 - iTime * 0.9));
    float centre = exp(-pow((float(col) - 7.5) / (3.5 + 4.0 * level), 2.0));
    float energy = level * amp * (0.35 + 0.65 * prof) * (0.45 + 0.55 * centre) * 1.9;
    int at = (row + col) % 4;
    float threshold = (BAYER[at * 4 + col % 4] + 0.5) / 16.0;
    if (energy <= threshold) return vec4(0.0);
    if (energy > 0.72) return vec4(D3(ACC), 1.0);
    if (energy > 0.34) return vec4(D3(INK), 1.0);
    return vec4(D3(DIM), 1.0);
}

void rail(vec2 p, inout vec4 color) {
    vec3 bg = D3(BG), ink = D3(INK), dim = D3(DIM), faint = D3(FAINT);
    vec3 acc = D3(ACC), red = D3(RED), track = D3(TRACK);
    float x0 = D(RX), w = D(RW), top = D(RTOP), hgt = D(RH), rule = D(RULE);
    color = vec4(0.0);
    if (p.y < top - 6.0 || p.y > top + hgt + 6.0) return;
    if (p.x < x0 - 6.0 || p.x > x0 + w + 6.0) return;
    if (p.x >= x0 - 2.0 && p.x <= x0 + w + 2.0) color = vec4(bg, 1.0);
    for (int i = 0; i < 6; i++) {
        float y = i == 0 ? D(OUTER) : (i == 5 ? D(OUTER + 1) : D(RULES + i - 1));
        if (p.y >= y && p.y < y + rule) color = vec4(faint, 1.0);
    }
    float amp = voice_amp(iTime);
    if (amp > 0.0) {
        vec4 dot = waterfall(p, amp);
        if (dot.a > 0.0) color = dot;
        if (abs(p.y - (D(MICY) + D(MICH) * 0.5)) < 4.0
                && abs(p.x - (x0 + 4.0)) < 4.0)
            color = vec4(red, 1.0);
    }
    float block = 7.0, dw = 3.0 * block;
    float wide = 2.0 * dw + block, tall = 2.0 * 5.0 * block + block;
    float cx0 = x0 + floor((w - wide) * 0.5);
    float cy0 = D(CLKY) + floor((D(CLKH) - tall) * 0.5);
    float dx = p.x - cx0, dy = p.y - cy0;
    if (dx >= 0.0 && dx < wide && dy >= 0.0 && dy < tall) {
        int cdigit = dx < dw ? 0 : (dx < dw + block ? -1 : 1);
        int cminute = dy < 5.0 * block ? 0 : (dy < 5.0 * block + block ? -1 : 1);
        if (cdigit >= 0 && cminute >= 0) {
            float lx = dx - (cdigit > 0 ? dw + block : 0.0);
            float ly = dy - (cminute > 0 ? 5.0 * block + block : 0.0);
            int col = int(floor(lx / block)), row = int(floor(ly / block));
            if (col >= 0 && col < 3 && row >= 0 && row < 5
                    && digit_px(D(DIGIT + cminute * 2 + cdigit), row, col))
                color = vec4(ink, 1.0);
        }
    }
    for (int i = 0; i < 4; i++) {
        float gy = D(GAUY) + float(i) * D(BLOK);
        float by0 = D(BARY) + gy, bh = D(BARH);
        if (p.y >= by0 && p.y < by0 + bh && p.x >= x0 + 1.0 && p.x < x0 + w - 1.0) {
            float cells = floor((w - 2.0) / 8.0);
            float cx = p.x - (x0 + 1.0);
            float index = floor(cx / 8.0);
            float sub = cx - index * 8.0;
            float filled = clamp(D(GAUGE + i) / 100.0, 0.0, 1.0) * cells * 6.0;
            color = vec4(track, 1.0);
            if (sub < 6.0 && index * 6.0 + sub < filled) color = vec4(ink, 1.0);
        }
        for (int k = 0; k < 4; k++) {
            float sx = x0 + 1.0 + float(k) * 14.0;
            if (p.x < sx || p.x >= sx + 12.0) continue;
            float yy = D(SPKY) + gy + D(SPKH);
            float lit = floor(D(HIST + i * 4 + k) / 100.0 * 8.0) / 8.0 * D(SPKH);
            if (p.y <= yy && p.y > yy - lit) color = vec4(k == 3 ? ink : dim, 1.0);
        }
    }
}

void mainImage(out vec4 color, in vec2 fragCoord) {
    g_origin = vec2(D(ORIGIN), D(ORIGIN + 1));
    g_h = iResolution.y;
    vec2 p = vec2(fragCoord.x, iResolution.y - fragCoord.y) + g_origin;
    if (D(MODE) > 0.5) {
        rail(p, color);
        return;
    }
    color = vec4(0.0);
    for (int i = 0; i < iWindowCount; i++) card_frame(p, i, color);
}
