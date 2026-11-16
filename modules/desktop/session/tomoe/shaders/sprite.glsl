// sprite: the deck drawn as a game HUD on four-pixel art pixels.
//
// One shader draws two surfaces, picked by D(0): the panel down the seam (0)
// and the frames round the carried cards (1). Everything is snapped to the art
// grid; the window radius is zero, so a frame is a bevel of hard rectangles.
//
// The panel is a cabinet face: a keyline, a four-pixel bevel lit from the top
// left, a plate, and cut grooves between the blocks the rail hands over as
// sections (kind 0 the voice's label, 1 the VU tower of PIPS pips, 2 the date,
// 3 the clock, 4 a gauge, 5 the media meter, 6 the network). All type is a 3x5
// face, two characters packed into one float as ASCII codes: slot 0 is the low
// byte, 1 the high. The panel's numbers are laid out as
//   KIND 0, GRID 1, SECTIONS 2, PIPS 3, TOWER 4, PITCH 5, PIP 6, EDGE 7, BAR 8,
//   VSINCE 9, VFADE 10, VON 11, VRISE 12, VSETTLE 13, LEVEL-A 14, LEVEL-B 15,
//   PEAK-A 16, PEAK-B 17, SWITCH-T 18, CLAMP-SIDE 19, CLAMP-TOP 20,
//   CLAMP-MID 21, CLAMP-BOT 22, LABEL-LEN 23, LIGHT 24, TRAY 25,
//   VOICE 26 (two), DATE 28 (six: day, number, month), CLOCK 34 (four),
//   GAUGE 38 (six slots of nine: percent, moving, hot, label, value, detail),
//   SECTION 92 (twelve of four: top, height, kind, index; kind -1 pads), MEDIA
//   179 and NET 181 and NETVAL 183 (two each of packed characters), COLOUR 140
//   (thirteen triples: keyline, body, highlight, shadow, idle line, accent,
//   white, plate, ink, dim, pip, red, bar).
//
// The frames data is
//   KIND 0, GRID 1, BAND 2, ARM 3, NOTCH 4, SPARK 5, SEAM-X 6, SEAM-W 7,
//   SIDE 8, PREV-SIDE 9, SWITCH-T 10, SWITCH-ON 11, FOCUS 12, OLD 13,
//   SETTLE 14, OLD-BOX 15 (four), VSINCE 19, VFADE 20, VON 21, VRISE 22,
//   VSETTLE 23, LEVEL 24, FPS 25, EASE1 26, EASE2 27, EASE3 28, EASE4 29,
//   SPARK-R 30, BURST 31, ARM-R 32, PULL 33, LAND 34, LIGHT 35,
//   COLOUR 36 (seven triples: keyline, highlight, shadow, body, idle, accent,
//   white).
//
// A switch is a sprite sheet at FPS: frame zero pulls the brackets in on the
// card that had focus, frames one to three fly them to the new card on the
// eased steps leaving a dithered afterimage and a dashed smear behind, frame
// four lands them white with a spark at every corner, frame five settles them
// in the accent while the burst spreads. The side of a frame that faces the
// rail is the panel's edge, so rail and frames read as one cabinet face.

float D(int i) { return iData[i >> 2][i & 3]; }
vec3 D3(int i) { return vec3(D(i), D(i + 1), D(i + 2)); }

const int KIND = 0, GRID = 1, SECTIONS = 2, PIPS = 3, TOWER = 4, PITCH = 5, PIP = 6;
const int EDGE = 7, BAR = 8;
const int VSINCE = 9, VFADE = 10, VON = 11, VRISE = 12, VSETTLE = 13;
const int LEVEL_A = 14, LEVEL_B = 15, PEAK_A = 16, PEAK_B = 17, SWITCH_T = 18;
const int CLAMP = 19, LABEL_LEN = 23, LIGHT = 24, TRAY = 25;
const int VOICE = 26, DATE = 28, CLOCK = 34, GAUGE = 38, SECTION = 92, COLOUR = 140;
const int MEDIA = 179, NET = 181, NETVAL = 183;

const int BAND = 2, ARM = 3, NOTCH = 4, SPARK = 5, SEAMX = 6, SEAMW = 7;
const int SIDE = 8, PREV = 9, FSWITCH = 10, SWOK = 11, FOCUS = 12, OLD = 13;
const int SETTLE = 14, OLD_BOX = 15;
const int FVSINCE = 19, FVFADE = 20, FVON = 21, FVRISE = 22, FVSETTLE = 23;
const int FLEVEL = 24, FPS = 25, EASE1 = 26, EASE2 = 27, EASE3 = 28, EASE4 = 29;
const int SPARK_R = 30, BURST = 31, ARM_R = 32, PULL = 33, LAND = 34, FCOLOUR = 36;

const int FG[45] = int[45](
    31599, 29850, 29671, 31143, 18925, 31183, 31695, 9511,
    31727, 31215, 23530, 15083, 25166, 15211, 29391, 4815,
    27470, 23533, 29847, 11044, 23277, 29257, 23549, 23403,
    11114, 4843, 26474, 23275, 14478, 9367, 31597, 11117,
    24557, 23213, 9389, 29351, 0, 21157, 27, 8192,
    1040, 448, 4772, 6105, 18724);

int gidx(int c) {
    if (c >= 48 && c <= 57) return c - 48;
    if (c >= 65 && c <= 90) return c - 55;
    if (c == 32) return 36;
    if (c == 37) return 37;
    if (c == 176) return 38;
    if (c == 46) return 39;
    if (c == 58) return 40;
    if (c == 45) return 41;
    if (c == 47) return 42;
    if (c == 62) return 43;
    if (c == 124) return 44;
    return 36;
}

int two_at(int k, int which) {
    float v = D(k);
    return (which & 1) == 1 ? int(floor(v / 256.0)) : int(mod(v, 256.0));
}

int strlen4(int base) {
    int n = 4;
    for (int i = 3; i >= 0; i--) {
        if (two_at(base + (i >> 1), i & 1) != 32) break;
        n = i;
    }
    return n;
}

bool out_of_glyph(int cx, int cy) { return cx < 0 || cx > 2 || cy < 0 || cy > 4; }

float gpix(int idx, int cx, int cy) {
    if (out_of_glyph(cx, cy)) return 0.0;
    return float((FG[idx] >> (cy * 3 + cx)) & 1);
}

float sm(float a, float b, float x) {
    float u = clamp((x - a) / (b - a), 0.0, 1.0);
    return u * u * (3.0 - 2.0 * u);
}

float hash2(vec2 cell, float seed) {
    return fract(sin(dot(cell, vec2(12.9898, 78.233)) + seed * 37.719) * 43758.5453);
}

vec3 mix3(vec3 a, vec3 b, float t) { return a + (b - a) * t; }

vec3 SO, SB, SH, SL, SI, SA, SW, SR, SK, SD, SP, SX, SG;

float text_width(int n, float cell) { return (4.0 * float(n) - 1.0) * cell; }

void text(vec2 p, float x, float y, float cell, int n, int base, vec3 col, int top, vec3 topcol,
        inout vec4 c) {
    if (n <= 0) return;
    float w = text_width(n, cell);
    if (p.x < x || p.x >= x + w || p.y < y || p.y >= y + 5.0 * cell) return;
    vec2 q = floor((p - vec2(x, y)) / cell);
    int ci = int(floor(q.x / 4.0));
    int cx = int(q.x) - ci * 4;
    int cy = int(q.y);
    if (ci >= n) return;
    if (gpix(gidx(two_at(base + (ci >> 1), ci & 1)), cx, cy) > 0.5)
        c = vec4(cy < top ? topcol : col, 1.0);
}

void centred(vec2 p, float y, float cell, int n, int base, vec3 col, int top, vec3 topcol,
        inout vec4 c) {
    if (n <= 0) return;
    text(p, (iResolution.x - text_width(n, cell)) * 0.5, y, cell, n, base, col, top, topcol, c);
}

void right(vec2 p, float x, float y, float cell, int n, int base, vec3 col, int top, vec3 topcol,
        inout vec4 c) {
    if (n <= 0) return;
    text(p, x - text_width(n, cell), y, cell, n, base, col, top, topcol, c);
}

float voice_amp(float now) {
    float since = D(VSINCE), fade = D(VFADE);
    if (D(VON) > 0.5) return sm(0.0, 1.0, (now - since) / max(0.01, D(VRISE)));
    if (fade > -1e8)
        return sm(0.0, 1.0, (fade - since) / max(0.01, D(VRISE)))
            * (1.0 - sm(0.0, 1.0, (now - fade) / max(0.01, D(VSETTLE))));
    return 0.0;
}

void panel(vec2 p, out vec4 col) {
    float w = iResolution.x, h = iResolution.y;
    float edge = D(EDGE);
    float e = min(min(p.x, w - 1.0 - p.x), min(p.y, h - 1.0 - p.y));
    if (e < 1.0) col = vec4(SO, 1.0);
    else if (e < edge) col = vec4((p.x < edge || p.y < edge) ? SH : SL, 1.0);
    else col = vec4(SR, 1.0);
    float grid = D(GRID);
    int n = int(D(SECTIONS));
    int n_pips = int(D(PIPS));
    float pitch = D(PITCH);
    float pip = D(PIP);
    float barh = D(BAR);
    float now = iTime;
    float flash = 0.0;
    float st = D(SWITCH_T);
    if (st > -1e8) {
        float f = floor((now - st) * 20.0);
        flash = (f >= 4.0 && f < 6.0) ? 1.0 : 0.0;
    }
    float lx = (w - 66.0) * 0.5;
    vec3 flash_col = D(LIGHT) > 0.5 ? SK : SW;
    for (int i = 0; i < n && i < 12; i++) {
        float top = D(SECTION + i * 4);
        int kind = int(D(SECTION + i * 4 + 2));
        int idx = int(D(SECTION + i * 4 + 3));
        if ((kind == 2 || kind == 3 || (kind == 4 && idx == 0)) && top > 24.0) {
            float gy = top - 16.0;
            if (p.x > edge && p.x < w - edge) {
                if (p.y >= gy && p.y < gy + 4.0) col = vec4(SO, 1.0);
                if (p.y >= gy + 4.0 && p.y < gy + 8.0) col = vec4(SH, 1.0);
            }
        }
        if (kind == 0) {
            centred(p, top, grid, int(D(LABEL_LEN)), VOICE, SD, 0, SD, col);
        } else if (kind == 1) {
            for (int k = 0; k < 32; k++) {
                if (k >= n_pips) break;
                float py = top + float(n_pips - 1 - k) * pitch;
                if (p.y < py || p.y >= py + pip) continue;
                bool left = p.x >= lx && p.x < lx + 32.0;
                bool right_side = p.x >= lx + 34.0 && p.x < lx + 66.0;
                if (!left && !right_side) continue;
                float level = left ? D(LEVEL_A) : D(LEVEL_B);
                float peak = left ? D(PEAK_A) : D(PEAK_B);
                int lit = int(floor(level * float(n_pips) + 0.5));
                vec3 pc = SP;
                if (k < lit) {
                    if (k >= n_pips - 4) pc = SW;
                    else if (k >= n_pips - 10) pc = mix3(SA, SW, 0.55);
                    else pc = SA;
                    if (p.y < py + 4.0) pc = mix3(pc, SW, 0.35);
                }
                if (k == int(peak) && int(peak) > lit) pc = SA;
                col = vec4(pc, 1.0);
            }
        } else if (kind == 2) {
            centred(p, top, grid, 3, DATE, SD, 0, SD, col);
            centred(p, top + 28.0, grid, 2, DATE + 2, SK, 0, SK, col);
            centred(p, top + 56.0, grid, 3, DATE + 4, SD, 0, SD, col);
        } else if (kind == 3) {
            centred(p, top, grid * 2.0, 2, CLOCK, SK, 2, flash_col, col);
            centred(p, top + 52.0, grid * 2.0, 2, CLOCK + 2, SK, 2, flash_col, col);
        } else if (kind == 4) {
            int base = GAUGE + idx * 9;
            float percent = D(base);
            float moving = D(base + 1);
            float hot = D(base + 2);
            text(p, lx + 1.0, top, grid, strlen4(base + 3), base + 3, SD, 0, SD, col);
            right(p, lx + 65.0, top + 28.0, grid, strlen4(base + 5), base + 5,
                  moving > 0.5 ? flash_col : SK, 0, flash_col, col);
            float by = top + 56.0;
            if (p.x >= lx + 0.5 && p.x < lx + 66.5 && p.y >= by && p.y < by + barh) {
                bool inside = p.x >= lx + 1.5 && p.x < lx + 65.5 && p.y >= by + 1.0
                    && p.y < by + barh - 1.0;
                if (!inside) {
                    col = vec4(SO, 1.0);
                } else {
                    int pi = int(floor((p.x - (lx + 1.5)) / 4.0));
                    int lit = int(floor(percent / 100.0 * 16.0 + 0.5));
                    col = vec4(percent / 100.0, float(lit) / 16.0, float(pi) / 16.0, 1.0);
                    vec3 pc = SP;
                    if (pi < lit) {
                        pc = (hot > 0.5 && pi >= 11) ? SX : SG;
                        if (pi == lit - 1 && moving > 0.5) pc = SW;
                        if (p.y < by + 6.0) pc = mix3(pc, SW, 0.35);
                    }
                    col = vec4(pc, 1.0);
                }
            }
            if (hot > 0.5) {
                float dw = text_width(4, grid);
                if (p.x >= lx + 63.0 - dw && p.x < lx + 66.0 && p.y >= top + 86.0
                    && p.y < top + 110.0)
                    col = vec4(SX, 1.0);
                right(p, lx + 65.0, top + 88.0, grid, strlen4(base + 7), base + 7, SW, 0, SW, col);
            } else {
                right(p, lx + 65.0, top + 88.0, grid, strlen4(base + 7), base + 7, SD, 0, SD, col);
            }
        } else if (kind == 5) {
            float played = clamp(float(idx) / 100.0, 0.0, 1.0);
            centred(p, top, grid * 2.0, 2, MEDIA, SK, 0, SW, col);
            float by = top + 28.0;
            if (p.x >= lx + 1.0 && p.x < lx + 65.0 && p.y >= by && p.y < by + 8.0) {
                col = vec4(SP, 1.0);
                if (p.x < lx + 1.0 + 64.0 * played) col = vec4(SG, 1.0);
            }
        } else if (kind == 6) {
            centred(p, top, grid, 3, NET, SD, 0, SD, col);
            centred(p, top + 20.0, grid, strlen4(NETVAL), NETVAL, SK, 0, SK, col);
        }
    }

    int side = int(D(CLAMP));
    if (side != 0) {
        float bx = side < 0 ? 0.0 : w - 5.0;
        for (int k = 0; k < 3; k++) {
            float cy = D(CLAMP + 1 + k);
            if (p.x >= bx && p.x < bx + 5.0 && p.y >= cy - 12.0 && p.y < cy + 12.0) {
                bool rim = p.x < bx + 1.0 || p.x >= bx + 4.0 || p.y < cy - 11.0
                    || p.y >= cy + 11.0;
                col = vec4(rim ? SO : (flash > 0.5 ? SW : SA), 1.0);
            }
        }
    }
}

vec4 card_box(int i) {
    vec4 v = iWindow[i];
    float top = iResolution.y - (v.y + v.w);
    return vec4(v.x, top, v.x + v.z, top + v.w);
}

bool shown(int i) { return i >= 0 && i < iWindowCount && iWindow[i].z > 0.0; }

float box_out(vec2 p, vec4 b) {
    return max(max(b.x - p.x, p.x - b.z), max(b.y - p.y, p.y - b.w));
}

vec4 snap_out(vec4 b, float g) {
    return vec4(floor(b.x / g) * g, floor(b.y / g) * g, ceil(b.z / g) * g, ceil(b.w / g) * g);
}

vec4 snap_near(vec4 b, float g) {
    return vec4(floor(b.x / g + 0.5) * g, floor(b.y / g + 0.5) * g,
        floor(b.z / g + 0.5) * g, floor(b.w / g + 0.5) * g);
}

vec3 frame_paint(vec2 p, vec4 b, bool focused, float dither) {
    float d = box_out(p, b);
    float band = D(BAND);
    if (d < 0.0 || d >= band) return vec3(-1.0);
    float cx = min(p.x - b.x, b.z - p.x), cy = min(p.y - b.y, b.w - p.y);
    bool lit = p.x < b.x || p.y < b.y;
    if (!focused) {
        if (d >= 4.0) return SO;
        return SI;
    }
    if (dither > 0.0 && hash2(floor(p / 4.0), 7.0) < dither) return vec3(-1.0);
    if (d < 4.0) return SO;
    if (d < 8.0) return SB;
    if (d < band - 4.0) return lit ? SH : SL;
    if (cx < 4.0 && cy < 4.0 && d >= band - 4.0) return vec3(-1.0);
    return SO;
}

int bracket(vec2 p, vec4 b, float arm, float thick, out float d) {
    float dl = b.x - p.x, dr = p.x - b.z, dt = b.y - p.y, db = p.y - b.w;
    d = max(max(dl, dr), max(dt, db));
    if (d < 0.0 || d >= thick) return 0;
    float along;
    if (dt >= dl && dt >= dr && dt >= db) along = min(p.x - b.x, b.z - p.x);
    else if (db >= dl && db >= dr) along = min(p.x - b.x, b.z - p.x);
    else along = min(p.y - b.y, b.w - p.y);
    if (along < -thick || along > arm) return 0;
    return d < thick * 0.5 ? 2 : 1;
}

vec3 brackets(vec2 p, vec4 b, float arm, float thick, bool white, bool dither, float seed) {
    float d;
    int r = bracket(p, b, arm, thick, d);
    if (r == 0) return vec3(-1.0);
    if (dither && hash2(floor(p / 4.0), seed) > 0.5) return vec3(-1.0);
    if (white) return SW;
    return r == 2 ? mix3(SA, SW, 0.25) : mix3(SA, SO, 0.35);
}

float seg_d(vec2 p, vec2 a, vec2 b, out float t) {
    vec2 pa = p - a, ba = b - a;
    t = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * t);
}

vec3 sparks(vec2 p, vec4 b, float r, bool wide) {
    for (int k = 0; k < 4; k++) {
        vec2 corner = vec2((k & 1) == 0 ? b.x : b.z, (k & 2) == 0 ? b.y : b.w);
        vec2 dir = vec2((k & 1) == 0 ? -1.0 : 1.0, (k & 2) == 0 ? -1.0 : 1.0);
        vec2 q = abs(p - corner - dir * r);
        if (!wide) {
            if ((q.x < 4.0 && q.y < 16.0) || (q.y < 4.0 && q.x < 16.0) || (q.x < 8.0 && q.y < 8.0))
                return SW;
        } else if (max(q.x, q.y) < 16.0 && min(q.x, q.y) < 4.0) {
            return SA;
        }
    }
    return vec3(-1.0);
}

void frames(vec2 p, out vec4 col) {
    col = vec4(0.0);
    float grid = D(GRID);
    int focus = int(D(FOCUS)), old = int(D(OLD));
    float sx0 = D(SEAMX), sx1 = sx0 + D(SEAMW);
    bool in_seam = p.x >= sx0 - 1.0 && p.x < sx1 + 1.0;
    bool on = D(SWOK) >= 0.0 && D(FSWITCH) > -1e8;
    float dt = iTime - D(FSWITCH);
    float f = floor(dt * D(FPS));
    bool switching = on && dt >= 0.0 && f < 6.0;
    bool crossed = D(SIDE) != 0.0 && D(PREV) != 0.0 && D(SIDE) != D(PREV);
    float arm = D(ARM_R);
    float thick = D(BAND);
    float band = D(BAND);
    if (!switching) {
        for (int i = 0; i < iWindowCount; i++) {
            if (!shown(i)) continue;
            vec4 b = snap_out(card_box(i), grid);
            if (box_out(p, b) > 40.0) continue;
            if (in_seam) continue;
            if (i == focus) {
                vec4 shown_box = b;
                vec3 bc = brackets(p, shown_box, arm + 60.0 * D(FLEVEL), thick, false, false, 1.0);
                if (bc.r >= 0.0) {
                    col = vec4(bc, 1.0);
                    return;
                }
            }
            vec3 fc = frame_paint(p, b, i == focus, 0.0);
            if (fc.r >= 0.0) {
                col = vec4(fc, 1.0);
                return;
            }
        }
        return;
    }
    for (int i = 0; i < iWindowCount; i++) {
        if (!shown(i)) continue;
        vec4 b = snap_out(card_box(i), grid);
        if (box_out(p, b) > 40.0) continue;
        bool is_focus = i == focus;
        bool is_old = i == old && i != focus;
        float dither = 0.0;
        bool focused = is_focus;
        if (is_focus && f < 4.0 && crossed) focused = false;
        if (is_old && f < 4.0) {
            focused = true;
            dither = 0.35;
        }
        if (is_focus && f >= 4.0 && f < 5.0) {
            float db = box_out(p, b);
            if (db >= 0.0 && db < band) {
                col = vec4(SW, 1.0);
                return;
            }
        }
        if (in_seam) continue;
        vec3 fc = frame_paint(p, b, focused, dither);
        if (fc.r >= 0.0) {
            col = vec4(fc, 1.0);
            return;
        }
    }
    vec4 b0 = vec4(D(OLD_BOX), D(OLD_BOX + 1), D(OLD_BOX + 2), D(OLD_BOX + 3));
    if (shown(old) && old != focus) b0 = card_box(old);
    b0 = snap_out(b0, grid);
    vec4 b1 = snap_out(card_box(focus), grid);
    vec3 bc = vec3(-1.0);
    if (f < 1.0) {
        bc = brackets(p, b0, arm - D(PULL), thick, true, false, 1.0);
    } else if (f < 4.0) {
        float e1 = D(EASE1), e2 = D(EASE2), e3 = D(EASE3), e4 = D(EASE4);
        vec4 from = snap_near(mix(b0, b1, f < 2.0 ? 0.0 : (f < 3.0 ? e1 : e2)), grid);
        vec4 to = snap_near(mix(b0, b1, f < 2.0 ? e1 : (f < 3.0 ? e2 : e3)), grid);
        for (int k = 0; k < 4; k++) {
            vec2 a = vec2((k & 1) == 0 ? from.x : from.z, (k & 2) == 0 ? from.y : from.w);
            vec2 b = vec2((k & 1) == 0 ? to.x : to.z, (k & 2) == 0 ? to.y : to.w);
            float moved = length(b - a);
            vec2 back = b - normalize(b - a + vec2(1e-5)) * min(moved, 140.0);
            float t;
            float d = seg_d(p, back, b, t);
            if (d < 5.0 && fract(t * min(moved, 140.0) / 14.0) < 0.55)
                bc = mix3(SA, SO, 0.3);
        }
        vec3 after = brackets(p, from, arm * 0.8, thick, false, true, f);
        if (after.r >= 0.0) bc = after;
        vec3 front = brackets(p, to, arm, thick, false, false, f);
        if (front.r >= 0.0) bc = front;
    } else if (f < 5.0) {
        bc = brackets(p, b1, arm + D(LAND), thick, true, false, 1.0);
        vec3 sp = sparks(p, b1, D(SPARK_R), false);
        if (sp.r >= 0.0) bc = sp;
    } else {
        bc = brackets(p, b1, arm, thick, false, false, 1.0);
        vec3 sp = sparks(p, b1, D(BURST), true);
        if (sp.r >= 0.0) bc = sp;
    }
    if (bc.r >= 0.0) col = vec4(bc, 1.0);
}

void mainImage(out vec4 color, in vec2 fragCoord) {
    vec2 p = vec2(fragCoord.x, iResolution.y - fragCoord.y);
    int kind = int(D(0));
    if (kind == 0) {
        SO = D3(COLOUR);
        SB = D3(COLOUR + 3);
        SH = D3(COLOUR + 6);
        SL = D3(COLOUR + 9);
        SI = D3(COLOUR + 12);
        SA = D3(COLOUR + 15);
        SW = D3(COLOUR + 18);
        SR = D3(COLOUR + 21);
        SK = D3(COLOUR + 24);
        SD = D3(COLOUR + 27);
        SP = D3(COLOUR + 30);
        SX = D3(COLOUR + 33);
        SG = D3(COLOUR + 36);
        panel(p, color);
    } else {
        SO = D3(FCOLOUR);
        SH = D3(FCOLOUR + 3);
        SL = D3(FCOLOUR + 6);
        SB = D3(FCOLOUR + 9);
        SI = D3(FCOLOUR + 12);
        SA = D3(FCOLOUR + 15);
        SW = D3(FCOLOUR + 18);
        frames(p, color);
        if (color.a <= 0.0) discard;
    }
}
