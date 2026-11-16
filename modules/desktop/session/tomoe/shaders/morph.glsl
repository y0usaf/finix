// morph: the rail's slab and the focused card's frame as one cast material.
//
// One signed field covers the slab in the seam and the frame round every card
// the rail carries. The focused frame is the slab's own material, as thick as
// the slab's lip, welded to it by a smooth minimum, so slab and frame read as
// one piece; every other card keeps a thin darker line. A switch across the
// seam hops the slab on two springs; one along a column leaves it on its side.
// Either moves the frame: after a pause the old frame drains back into the slab
// and the new one fills out of it (siphon), a rapid switch only swaps the two
// frames under a quick slide (pour). While bolo has the turn the slab's free
// edge is the voice, and the focused frame comes alive with it: its whole
// perimeter swells and thins in a ripple that runs out from the weld, each
// stretch as loud as the voice was when the ripple left the slab, its crests
// catching the light -- so the frame says which card is being spoken into.
//
// Every number comes from iData (laid out by rail.lisp's rail--tide-data), the
// cards from iWindow, and time from iTime, which the rail counts from its own
// clock and holds once nothing moves. Coordinates below are the output's, y down.

#define PI 3.14159265358979

float D(int i) { return iData[i >> 2][i & 3]; }
vec3 D3(int i) { return vec3(D(i), D(i + 1), D(i + 2)); }

// layout of iData
const int ORIGIN = 0, SKIP = 2, MAT = 4, REC_C = 7, SHADOW_C = 10, SPEC_C = 13, KS = 16, SA = 17;
const int RAD = 18, WF = 19, RECW = 20, SW = 21, INSET = 22, RS = 23, WELD = 24;
const int SEAM = 25, SEAMW = 26, SIDE = 27, PREV = 28, TSW = 29, FLOW = 30, HOLD = 31, GULP = 32;
const int SETTLE = 33, CURVE = 34, FOCUS = 35, OLD = 36, METERS = 37, EXTENT = 38;
const int LEAD = 40, TRAIL = 44, WOB = 47, SQUASH = 50, POUR = 51, SIPHON = 57, HEIGHT = 65;
const int VOICE = 66, BANDS = 86, LEVELS = 89, GAUGES = 137, SWELL = 152, GHOST = 153, PANE = 157;
// the strip: which way it runs, its rect, whether this surface draws the slab,
// which side of the focused card it stands on and which way a bar's free edge
// faces -- after the pane's eight numbers and the readings' ink
const int M_AXIS = 168, M_RECT = 169, M_SLAB = 173, M_RAIL = 174, M_FREE = 175;

vec2 g_origin;
float g_h;

float g_axis;      // 0: the strip runs down y; 1: across x
vec4 g_strip;      // the strip's rect in the output's y-up pixels
bool g_slab_on;    // whether this surface draws the slab
int g_rail;        // 0 the rail is to the card's right, 1 left, 2 above, 3 below
float g_free;      // which way a bar's free edge faces, +1 along +across

float acr(vec2 p) { return g_axis < 0.5 ? p.x : p.y; }
float alt(vec2 p) { return g_axis < 0.5 ? p.y : p.x; }
float acr_lo() { return g_axis < 0.5 ? g_strip.x : g_strip.y; }
float acr_hi() { return g_axis < 0.5 ? g_strip.z : g_strip.w; }

float sm(float a, float b, float x) {
    float u = clamp((x - a) / (b - a), 0.0, 1.0);
    return u * u * (3.0 - 2.0 * u);
}

float ease_out(float u) {
    u = clamp(u, 0.0, 1.0);
    return 1.0 - (1.0 - u) * (1.0 - u) * (1.0 - u);
}

float spring_v(float t, float w, float z, float v0) {
    if (t <= 0.0) return 0.0;
    float wd = w * sqrt(1.0 - z * z);
    float e = exp(-z * w * t);
    return 1.0 - e * (cos(wd * t) + (z * w - v0) / wd * sin(wd * t));
}

float pulse(float t, float w, float z) {
    if (t <= 0.0) return 0.0;
    float wd = w * sqrt(1.0 - z * z);
    return exp(-z * w * t) * sin(wd * t) * 1.6;
}

// The rail names how long a focus move is drawn for (SETTLE) and which curve
// shapes its clock (CURVE); this theme's choreography was drawn for DESIGN
// seconds, so it is played on that clock and keeps its shape at any duration.
// A move that arrives mid-flight is retargeted and drawn for less time, so a run
// of quick switches reads as one move rather than one transition per window.
float ease_code(float u, int c) {
    u = clamp(u, 0.0, 1.0);
    if (c == 1) return 1.0 - (1.0 - u) * (1.0 - u);
    if (c == 2) return 1.0 - pow(1.0 - u, 3.0);
    if (c == 3) return u >= 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * u);
    return u;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return b + (a - b) * h - k * h * (1.0 - h);
}

float ring(float b, float w, float c) { return abs(b - c) - w * 0.5; }
float ring(float b, float w) { return ring(b, w, max(w, 0.0) * 0.5); }

float cap(float w, float q, float front, float soft) {
    return (w + 1.0) * sqrt(clamp((front - q) / soft, 0.0, 1.0)) - 1.0;
}

// A card's box in output pixels: x0, y0, x1, y1.
vec4 card(int i) {
    vec4 w = iWindow[i];
    float top = g_h - (w.y + w.w);
    return vec4(w.x + g_origin.x, top + g_origin.y, w.x + w.z + g_origin.x, top + w.w + g_origin.y);
}

bool card_shown(int i) { return i >= 0 && i < iWindowCount && iWindow[i].z > 0.0; }

float box_b(vec2 p, vec4 box) {
    float R = D(RAD);
    vec2 c = (box.xy + box.zw) * 0.5, h = (box.zw - box.xy) * 0.5;
    vec2 q = abs(p - c) - (h - R);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - R;
}

// Perimeter coordinates round a card: q runs along the frame from the end of
// the edge that faces the rail (negative along that edge, -iy at its middle),
// b is the signed distance outside the box.
void perim(vec2 p, vec4 box, bool rail_right, out float q, out float b, out float qmax, out float iy) {
    float R = D(RAD);
    vec2 c = (box.xy + box.zw) * 0.5, h = (box.zw - box.xy) * 0.5;
    float ix = h.x - R, a = PI * R * 0.5;
    iy = h.y - R;
    vec2 d = p - c;
    float xr = rail_right ? d.x : -d.x;
    float ay = abs(d.y), ax = abs(xr);
    float qx = ax - ix, qy = ay - iy;
    b = length(max(vec2(qx, qy), 0.0)) + min(max(qx, qy), 0.0) - R;
    bool corner = qx > 0.0 && qy > 0.0;
    bool tb = !corner && (qy > 0.0 || (qx <= 0.0 && (h.y - ay) < (h.x - ax)));
    if (corner) q = xr > 0.0 ? R * atan(qy, qx) : a + 2.0 * ix + R * atan(-(xr + ix), qy);
    else if (tb) q = a + ix - xr;
    else q = xr > 0.0 ? ay - iy : 2.0 * a + 2.0 * ix + iy - ay;
    qmax = 2.0 * a + 2.0 * ix + iy;
}

// The perimeter of a card as the rail's side of it sees it: a quarter turn puts
// the bar's own edge where the seam's side edge is, so one set of coordinates
// serves a strip of either axis.
void perim_rail(vec2 p, vec4 box, out float q, out float b, out float qmax, out float iy) {
    if (g_rail < 2) { perim(p, box, g_rail == 0, q, b, qmax, iy); return; }
    vec2 c = 0.5 * (box.xy + box.zw);
    vec2 d = p - c;
    vec2 h = 0.5 * (box.zw - box.xy);
    vec2 rd = g_rail == 2 ? vec2(-d.y, d.x) : vec2(d.y, -d.x);
    vec4 rb = vec4(c - h.yx, c + h.yx);
    perim(c + rd, rb, true, q, b, qmax, iy);
}

float seam_mid() { return D(SEAM) + D(SEAMW) * 0.5; }

// ---- the voice on the focused frame

float g_vamp, g_now, g_raw;

// The voice's three bands, packed by rail.lisp: the swell the turn is riding,
// the level it has now and how fast it is moving. The bulk of the border moves
// with all three at once, so every side of the focused frame answers together
// and no corner waits for a wave to reach it.
float band(float k) { return D(BANDS + int(k)); }

float voice_around(float u, float per) {
    float th = 6.2832 * u / max(1.0, per);
    float stand = 0.58 + 0.42 * (0.62 * sin(3.0 * th + 0.7) + 0.38 * sin(5.0 * th - 1.3));
    float beat = 0.55 + 0.45 * sin(g_now * 12.0);
    float spark = fract(sin(floor(u / 6.0) * 12.9898 + floor(g_now * 26.0) * 78.233) * 43758.5453);
    return band(0.0) * (0.60 + 0.40 * stand)
         + band(1.0) * (0.30 + 0.70 * beat) * (0.55 + 0.45 * stand)
         + band(2.0) * (0.20 + 0.80 * spark);
}

// The voice at perimeter coordinate q round the focused frame: how far its
// outer edge moves out (a trough pulls it in), how far its inner edge laps over
// the card, and how brightly it catches the light. The border is the waveform of
// the sentence: its whole perimeter moves at once, as loud at the far corner as
// at the weld, the crests standing where they are instead of running out from
// the slab, so a glance at any side of the frame reads the voice.
vec3 frame_voice(float q, float qmax, float iy) {
    if (g_vamp <= 0.0) return vec3(0.0);
    float s = q + iy, smax = qmax + iy;
    float drive = g_vamp * min(1.0, 0.20 + 1.15 * voice_around(s, smax));
    float k = D(VOICE + 18);
    float crest = 0.5 + 0.5 * (0.65 * sin(s * k + 0.7) + 0.35 * sin(s * k * 2.3 - 1.3));
    float out_edge = drive * (D(VOICE + 14) * crest - D(VOICE + 15) * (1.0 - crest));
    return vec3(out_edge, drive * D(VOICE + 16) * crest * crest,
                drive * D(VOICE + 17) * crest * crest * crest);
}

// The focused frame's ring: W thick outside the card, with the voice's swell
// on its outer edge and its lap over the card on the inner one.
float voiced_ring(float b, float w, vec3 v) {
    float outer = max(w + v.x, 0.0), lap = v.y;
    return ring(b, outer + lap, (outer - lap) * 0.5);
}

// The material round card i: role 1 the focused card at rest, 2 the card a
// switch is filling, 3 the card it is draining. The voice rides the first two.
float frame_field(vec2 p, vec4 box, int role, float dt) {
    float q, b, qmax, iy;
    perim_rail(p, box, q, b, qmax, iy);
    float w0 = D(WF);
    vec3 v = role == 3 ? vec3(0.0) : frame_voice(q, qmax, iy);
    if (role == 1) return voiced_ring(b, w0, v);
    if (D(FLOW) < 0.5) {
        if (role == 2) {
            float s = sm(0.0, D(POUR), dt);
            float imp = D(POUR + 1) * exp(-max(dt - D(POUR + 2), 0.0) / D(POUR + 3)) * sm(0.0, D(POUR + 2), dt);
            return voiced_ring(b, (w0 + 1.0) * s - 1.0 + imp, v * s);
        }
        float s = 1.0 - sm(D(POUR + 4), D(POUR + 5), dt);
        return ring(b, (w0 + 1.0) * s - 1.0);
    }
    if (role == 3) {
        float u = clamp(dt / D(SIPHON), 0.0, 1.0);
        float qd = qmax - (qmax + iy + 14.0) * pow(u, D(SIPHON + 1));
        float bump = D(SIPHON + 2) * pow(sin(PI * min(u * 1.12, 1.0)), 0.8);
        float w = w0 + bump * exp(-pow((q - qd) / 80.0, 2.0));
        return ring(b, cap(w, q, qd, 14.0), w0 * 0.5);
    }
    float delay = D(SIPHON + 3), fill = D(SIPHON + 4);
    float u = clamp((dt - delay) / fill, 0.0, 1.0);
    float qf = -iy - 14.0 + (qmax + iy + 40.0) * ease_out(u);
    float head = 1.5 + D(SIPHON + 5) * pow(1.0 - u, 0.6);
    float behind = max(qf - q, 0.0);
    float w = w0 + head * exp(-pow((q - qf) / 60.0, 2.0))
        + D(SIPHON + 6) * (1.0 - u) * exp(-behind / 260.0) * sin(behind / 30.0);
    float meet = delay + fill * 0.8;
    w += D(SIPHON + 7) * max(pulse(dt - meet, 40.0, 0.35), -0.4) * exp(-pow((q - qmax) / 50.0, 2.0));
    w = max(w + v.x, 0.0);
    return ring(b, cap(w, q, qf, 14.0), w0 * 0.5);
}

// ---- the voice

float voice_amp(float now) {
    float since = D(VOICE), fade = D(VOICE + 1), on = D(VOICE + 2), rise = max(0.01, D(VOICE + 10));
    if (D(VOICE + 13) < 0.5) return 0.0;
    if (on > 0.5) return sm(0.0, 1.0, (now - since) / rise);
    if (fade > -1e8)
        return sm(0.0, 1.0, (fade - since) / rise) * (1.0 - sm(0.0, 1.0, (now - fade) / max(0.01, D(VOICE + 11))));
    return 0.0;
}

float level_at(float y, float top, float bottom) {
    int rows = int(D(VOICE + 13));
    float key = float(rows) * (clamp(y, top, bottom) - top) / max(1.0, bottom - top);
    int i = min(rows - 1, max(0, int(floor(key))));
    int j = min(rows - 1, i + 1);
    return mix(D(LEVELS + i), D(LEVELS + j), key - floor(key));
}

float wobble(float y, float top, float bottom, float now, float amp) {
    if (amp <= 0.0) return 0.0;
    float fade = min(D(VOICE + 12), max(1.0, floor((bottom - top) / 3.0)));
    float edge = sm(0.0, 1.0, (y - top) / fade) * sm(0.0, 1.0, (bottom - y) / fade);
    float wave = 0.5 * (1.0 + sin((y - top) * D(VOICE + 6) - now * D(VOICE + 7)));
    float belly = sin(PI * (y - top) / max(1.0, bottom - top));
    float reach = (D(VOICE + 3) + D(VOICE + 4) * level_at(y, top, bottom)) * wave
        + D(VOICE + 5) * D(LEVELS) * belly;
    return amp * edge * reach;
}

// ---- the gauges

float gauges(float y) {
    float reach = 0.0;
    for (int i = 0; i < int(D(METERS)); i++) {
        int k = GAUGES + 3 * i;
        float u = clamp((y - D(k)) / max(1.0, D(k + 1)), -1.0, 1.0);
        reach += D(k + 2) * (0.5 + 0.5 * cos(PI * u));
    }
    return reach * D(SWELL);
}

// ---- the slab

vec2 rest_edges(float side) {
    if (g_axis > 0.5) {
        // a bar: the slab fills the strip against its outer edge, its free edge
        // facing the cards, and gives the gauges' swell its air
        float lo = acr_lo(), hi = acr_hi();
        if (g_free > 0.0) return vec2(lo + 2.0, hi - 12.0);
        return vec2(lo + 12.0, hi - 2.0);
    }
    if (side == 0.0) return seam_mid() + vec2(-0.5, 0.5) * D(SW);
    if (side < 0.0) {
        float left = D(SEAM) + D(WF);
        return vec2(left - 2.0, left + D(SW));
    }
    float right = D(SEAM) + D(SEAMW) - D(WF);
    return vec2(right - D(SW), right + 2.0);
}

float g_cy, g_hh, g_top, g_bottom, g_amp, g_dt;
bool g_hop, g_flow;
// The slab's edges at the six y a fragment's field() samples read them at, its
// y - 3 up to its y + 2, taken once in mainImage: field() is inlined once at
// each sample, so working them out inside it would repeat them there.
vec2 g_edge[6];

float free_left(float side) { return 0.5 + 0.5 * side; }

vec2 slab_edges(float y) {
    float side = D(SIDE), prev = D(PREV), hold = D(HOLD);
    vec2 e = rest_edges(side);
    float wob = 0.0, left = free_left(side);
    if (g_hop) {
        vec2 e0 = rest_edges(prev), e1 = e;
        float ny = clamp(abs(y - g_cy) / g_hh, 0.0, 1.0);
        float lead = spring_v(g_dt - D(LEAD + 3) * pow(ny, 1.4), D(LEAD), D(LEAD + 1), D(LEAD + 2));
        float trail = spring_v(g_dt - (D(TRAIL + 2) + hold * exp(-pow(ny / 0.3, 2.0))), D(TRAIL), D(TRAIL + 1), 0.0);
        if (side > prev) e = vec2(e0.x + (e1.x - e0.x) * trail, e0.y + (e1.y - e0.y) * lead);
        else e = vec2(e0.x + (e1.x - e0.x) * lead, e0.y + (e1.y - e0.y) * trail);
        left = mix(free_left(prev), left, clamp(lead, 0.0, 1.0));
        float after = g_dt - hold - 0.02;
        if (after > 0.0) wob = D(WOB) * exp(-after / D(WOB + 1)) * sin(after * D(WOB + 2)) * cos(ny * PI * 1.5);
    }
    float gulp = D(GULP);
    if (g_flow && gulp > 0.0) {
        float g = sm(hold - 0.03, hold + 0.02, g_dt) * (1.0 - sm(hold + 0.10, hold + 0.22, g_dt));
        float yg = (g_hh - 40.0) * sm(hold - 0.02, hold + 0.16, g_dt);
        wob += gulp * g * exp(-pow((abs(y - g_cy) - yg) / 70.0, 2.0));
    }
    float reach = wob + wobble(y, g_top, g_bottom, g_now, g_amp) + gauges(y);
    return e + vec2(-left, 1.0 - left) * reach;
}

// The slab at p from edges already worked out: i is where p.y sits in g_edge.
float slab_edges_field(vec2 p, vec2 e, vec2 up, vec2 down) {
    float a = acr(p), l = alt(p);
    vec2 slope = (down - up) * 0.5;
    float dl = (e.x - a) / sqrt(1.0 + slope.x * slope.x);
    float dr = (a - e.y) / sqrt(1.0 + slope.y * slope.y);
    float rs = D(RS);
    float qx = max(dl, dr) + rs;
    float qy = max(g_top - l, l - g_bottom) + rs;
    return length(max(vec2(qx, qy), 0.0)) + min(max(qx, qy), 0.0) - rs;
}

// Far from the strip the slab cannot reach within a weld of p: a lower bound
// past the weld's reach leaves the smooth minimum exactly the frame's own.
float slab_far(vec2 p) {
    float a = acr(p), l = alt(p);
    float mid = g_axis < 0.5 ? seam_mid() : 0.5 * (acr_lo() + acr_hi());
    float span = g_axis < 0.5 ? D(SEAMW) * 0.5 : 0.5 * (acr_hi() - acr_lo());
    float dx = abs(a - mid) - span;
    if (dx > 60.0) return dx - 20.0;
    if (g_axis > 0.5 && (l < g_top - 40.0 || l > g_bottom + 40.0)) return 60.0;
    return -1e4;
}

float slab_field(vec2 p, int i) {
    float far = slab_far(p);
    if (far > -1e3) return far;
    return slab_edges_field(p, g_edge[i], g_edge[i - 1], g_edge[i + 1]);
}

// The slab at a sample off those six: the glass bends its probe point by up to
// its bevel, so it works its own edges out.
float slab_field_at(vec2 p) {
    float far = slab_far(p);
    if (far > -1e3) return far;
    float l = alt(p);
    return slab_edges_field(p, slab_edges(l), slab_edges(l - 1.0), slab_edges(l + 1.0));
}

// ---- the whole material

bool g_slab, g_has_old;
float g_kold;
vec4 g_old;

// The two frames a sample can meet -- the focused card's and, while a switch
// runs, the one draining away -- share one copy of the frame's material.
float field_body(vec2 p, float f) {
    int focus = int(D(FOCUS)), old = int(D(OLD));
    bool moving = g_hop || (g_flow && g_has_old);
    for (int r = 0; r < 2; r++) {
        if (r == 0 && !card_shown(focus)) continue;
        if (r == 1 && !(moving && g_has_old && old != focus)) break;
        vec4 box = r == 0 ? card(focus) : g_old;
        float m = frame_field(p, box, r == 0 ? (moving ? 2 : 1) : 3, g_dt);
        f = (r == 0 ? g_slab : g_kold > 0.05) ? smin(f, m, r == 0 ? D(WELD) : g_kold)
                                             : min(f, m);
    }
    return f;
}

float field(vec2 p, int i) { return field_body(p, g_slab ? slab_field(p, i) : 1e4); }

float field_at(vec2 p) { return field_body(p, g_slab ? slab_field_at(p) : 1e4); }

float g_shine;

#ifdef GLASS
// Glass takes no colour of its own and nothing from the mode: PANE holds its
// frost, lens, bevel, rim, haze, vibrance, contrast and edge, then the ink the
// readings are set in.
vec3 under(vec2 q) { return beneath(vec2(q.x - g_origin.x, g_h - (q.y - g_origin.y))).rgb; }

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

vec3 frosted(vec2 q, float r, float spin) {
    if (r < 0.5) return under(q);
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 12; i++) {
        float a = float(i) * 2.39996 + spin;
        sum += under(q + r * sqrt((float(i) + 0.5) / 12.0) * vec2(cos(a), sin(a)));
    }
    return sum / 12.0;
}

// What the glass sees, darkened or brightened by W toward the luminance that
// stands CONTRAST apart from the ink's, its hue kept: over what already stands
// apart from the ink it changes nothing.
vec3 legible(vec3 seen, float w) {
    float ink = luma(D3(PANE + 8)), l = luma(seen), need = D(PANE + 6);
    if (ink > 0.5) {
        float top = max(ink - need, 0.04);
        return l > top ? seen * mix(1.0, top / l, w) : seen;
    }
    float floor_l = min(ink + need, 0.96);
    return l < floor_l ? 1.0 - (1.0 - seen) * mix(1.0, (1.0 - floor_l) / max(1.0 - l, 1e-3), w) : seen;
}

// A line etched out of what lies beneath it: darker over the light, lighter
// over the dark.
vec3 etched(vec2 q) {
    vec3 u = under(q);
    return luma(u) > 0.42 ? u * 0.66 : u + (1.0 - u) * 0.36;
}

vec3 glass(vec2 p, float f, vec2 dir) {
    float bevel = D(PANE + 2);
    float depth = clamp(-f / bevel, 0.0, 1.0);
    float thick = clamp(-field_at(p - dir * bevel) / (0.5 * bevel), 0.0, 1.0);
    float edge = (1.0 - depth) * (1.0 - depth);
    vec2 bend = dir * D(PANE + 1) * edge * thick;
    float spin = 6.2832 * fract(52.9829 * fract(dot(p, vec2(0.06711, 0.00584))));
    vec3 seen = frosted(p + bend, D(PANE) * thick, spin);
    float split = edge * thick * 0.6;
    seen.r = mix(seen.r, under(p + bend * 1.3).r, split);
    seen.b = mix(seen.b, under(p + bend * 0.7).b, split);
    seen = clamp(mix(vec3(luma(seen)), seen, 1.0 + D(PANE + 5) * thick), 0.0, 1.0);
    seen += (1.0 - seen) * D(PANE + 4) * thick;
    vec3 body = legible(seen, thick * sm(0.0, 0.6, depth));
    vec2 light = normalize(vec2(-0.6, -0.8));
    float facing = dot(dir, light);
    float inside = max(-f, 0.0);
    float lip = exp(-inside / 1.2);
    float rim = D(PANE + 3);
    body *= 1.0 - D(PANE + 7) * exp(-pow((inside - 2.6) / 1.1, 2.0)) * (0.6 + 0.4 * max(-facing, 0.0));
    body += D3(SPEC_C) * lip * (pow(max(facing, 0.0), 1.5) + 0.45 * pow(max(-facing, 0.0), 2.0)) * rim;
    body += D3(SPEC_C) * 0.10 * rim * edge * max(facing, 0.0);
    body += (D3(SPEC_C) - body) * g_shine;
    return min(body, vec3(1.0));
}
#endif

void mainImage(out vec4 color, in vec2 fragCoord) {
    g_origin = vec2(D(ORIGIN), D(ORIGIN + 1));
    g_h = D(HEIGHT);
    g_axis = D(M_AXIS);
    g_strip = vec4(D(M_RECT), D(M_RECT + 1), D(M_RECT + 2), D(M_RECT + 3));
    g_slab_on = D(M_SLAB) > 0.5;
    g_rail = int(D(M_RAIL) + 0.5);
    g_free = D(M_FREE);
    vec2 p = vec2(fragCoord.x, iResolution.y - fragCoord.y) + g_origin;
    if (D(SKIP + 1) > D(SKIP) && acr(p) >= D(SKIP) && acr(p) < D(SKIP + 1)) discard;

    // The thin line round every carried card, and how near any of them p is.
    float rec = 1e4, near = 1e4;
    for (int i = 0; i < iWindowCount; i++) {
        if (!card_shown(i)) continue;
        float b = box_b(p, card(i));
        rec = min(rec, ring(b, D(RECW)));
        near = min(near, abs(b - 8.0));
    }
    g_now = iTime;
    g_raw = iTime - D(TSW);
    g_dt = 0.7 * ease_code(max(g_raw, 0.0) / max(D(SETTLE), 0.02), int(D(CURVE)));
    g_flow = g_raw >= 0.0 && g_raw < D(SETTLE) && D(FLOW) > -0.5;
    g_hop = g_flow && D(PREV) != D(SIDE);
    int focus = int(D(FOCUS)), old = int(D(OLD));
    g_has_old = card_shown(old);
    if (g_has_old) g_old = card(old);
    else if (g_flow && D(GHOST + 2) > D(GHOST)) {
        g_old = vec4(D(GHOST), D(GHOST + 1), D(GHOST + 2), D(GHOST + 3));
        g_has_old = true;
        near = min(near, abs(box_b(p, g_old) - 8.0));
    }
    g_slab = g_slab_on && (D(SIDE) == 0.0 || card_shown(focus));
    g_amp = voice_amp(g_now);
    g_vamp = card_shown(focus) ? g_amp : 0.0;
    if (g_slab) {
        float y0 = D(EXTENT), y1 = D(EXTENT + 1);
        g_cy = (y0 + y1) * 0.5;
        g_hh = max(1.0, (y1 - y0) * 0.5);
        float bob = 0.0;
        if (g_amp > 0.0)
            bob = g_amp * D(VOICE + 8) * D(LEVELS) * sin(g_now * D(VOICE + 9));
        g_top = y0 - D(INSET) - 8.0;
        g_bottom = y1 + D(INSET) + 8.0;
        vec2 mid = slab_edges(g_cy + 0.5 * g_hh);
        float squash = max(mid.y - mid.x - D(SW), 0.0) * D(SQUASH);
        g_top = y0 - D(INSET) + squash + bob;
        g_bottom = y1 + D(INSET) - squash + bob;
        g_kold = g_flow ? D(WELD) * (1.0 - sm(D(HOLD) * 0.6, D(HOLD) + 0.03, g_dt)) : 0.0;
        float al = alt(p), ac = acr(p);
        float smid = g_axis < 0.5 ? seam_mid() : 0.5 * (acr_lo() + acr_hi());
        float shalf = g_axis < 0.5 ? D(SEAMW) * 0.5 : 0.5 * (acr_hi() - acr_lo());
        if (al > g_top - 40.0 && al < g_bottom + 40.0)
            near = min(near, max(abs(ac - smid) - shalf - 10.0, 0.0));
    }

    float cr = clamp(0.5 - rec, 0.0, 1.0);
#ifdef GLASS
    vec3 c = cr > 0.0 ? etched(p) * cr : vec3(0.0);
#else
    vec3 c = D3(REC_C) * cr;
#endif
    float a = cr;
    if (near > 40.0) {
        if (a <= 0.0) discard;
        color = vec4(c, a);
        return;
    }

    // The edges slab_field() would work out for each sample, worked out once.
    if (g_slab)
        for (int k = 0; k < 6; k++) g_edge[k] = slab_edges(alt(p) - 3.0 + float(k));

    float f = field(p, 3);
    // The other five samples the fragment reads -- the shadow's, and the four the
    // normal is measured at -- in one copy of the field.
    float fs = f, sx = 0.0, sy = 0.0;
    float cov = clamp(0.5 - f, 0.0, 1.0);
    for (int k = 0; k < 5; k++) {
        if (k > 0 && cov <= 0.0) break;
        vec2 at = p + (k == 0 ? vec2(-1.0, -2.0) : k == 1 ? vec2(1.0, 0.0)
                          : k == 2 ? vec2(-1.0, 0.0) : k == 3 ? vec2(0.0, 1.0)
                          : vec2(0.0, -1.0));
        float v = field(at, k == 0 ? 1 : k == 3 ? 4 : k == 4 ? 2 : 3);
        if (k == 0) fs = v;
        else if (k == 1) sx += v;
        else if (k == 2) sx -= v;
        else if (k == 3) sy += v;
        else sy -= v;
    }
    // How brightly the voice's crests light the focused frame at p.
    float shine = 0.0;
    if (g_vamp > 0.0 && f < 0.5) {
        vec4 box = card(focus);
        float q, b, qmax, iy;
        perim_rail(p, box, q, b, qmax, iy);
        shine = frame_voice(q, qmax, iy).z * exp(-max(b - D(WF) - D(VOICE + 14), 0.0) / 4.0);
    }
    float sh = fs < 14.0 ? D(SA) * exp(-max(fs, 0.0) / 5.0) * (1.0 - cov) : 0.0;
    c = D3(SHADOW_C) * sh + c * (1.0 - sh);
    a = sh + a * (1.0 - sh);
    g_shine = shine;
    if (cov > 0.0) {
        vec2 g = vec2(sx, sy) * 0.5;
#ifdef GLASS
        vec3 m = glass(p, f, g / (length(g) + 1e-6));
#else
        vec3 light = normalize(vec3(-0.45, -0.65, 0.61));
        vec3 half_v = normalize(light + vec3(0.0, 0.0, 1.0));
        float tilt = 1.0 - clamp(-f / 2.6, 0.0, 1.0);
        vec2 n2 = g / (length(g) + 1e-6) * tilt;
        vec3 n = vec3(n2, sqrt(clamp(1.0 - tilt * tilt, 0.0, 1.0)));
        float lam = dot(n, light);
        float spec = pow(clamp(dot(n, half_v), 0.0, 1.0), 48.0) * D(KS);
        float tone = (0.80 + 0.33 * lam) * (1.0 + 0.035 * (D(HEIGHT) * 0.5 - p.y) / 720.0);
        vec3 m = D3(MAT) * tone;
        m += (D3(SPEC_C) - m) * spec;
        m += (D3(SPEC_C) - m) * shine;
#endif
        c = m * cov + c * (1.0 - cov);
        a = cov + a * (1.0 - cov);
    }
    if (a <= 0.0) discard;
    color = vec4(c, a);
}
