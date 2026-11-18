// kit: what the thread shader draws on. default.nix puts this file in front of
// it. It reads the layout lisp/rail-kit.lisp
// writes into iData -- the switch, bolo's turn, the four readings, the clock and
// each card's side and title -- and gives the theme the cards in output
// pixels, the voice's envelope and level history, and a three-by-five bitmap
// type for the text that travels as character codes, three to a number.
// Coordinates are the output's, y down.

float D(int i) { return iData[i >> 2][i & 3]; }
vec3 D3(int i) { return vec3(D(i), D(i + 1), D(i + 2)); }

const int K_OX = 0, K_OY = 1, K_FOCUS = 2, K_OLD = 3, K_SIDE = 4;
const int K_TSW = 5, K_FLOW = 6, K_FROM = 7, K_SETTLE = 8, K_CURVE = 9;
const int K_VSINCE = 10, K_VFADE = 11, K_VOPEN = 12, K_VRISE = 13, K_VSETTLE = 14, K_VN = 15;
const int K_BANDS = 16, K_NBANDS = 3;
const int K_LEVELS = 19, K_NLEVELS = 32;
const int K_GAUGES = 51, K_GAUGE = 5;
const int K_CLOCK = 71, K_DAY = 73, K_DATE = 74;
const int K_CARDS = 76, K_CARD = 7;
const int THEME = 132;

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

float smin(float a, float b, float k) {
    if (k <= 0.0) return min(a, b);
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sd_rbox(vec2 p, vec4 box, float r) {
    vec2 c = 0.5 * (box.xy + box.zw);
    vec2 q = abs(p - c) - (0.5 * (box.zw - box.xy) - r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// ---------------------------------------------------------------- cards
vec2 k_origin;
float k_h;

void kit_begin() {
    k_origin = vec2(D(K_OX), D(K_OY));
    k_h = iResolution.y;
}

// fragCoord as an output pixel
vec2 kit_point(vec2 fragCoord) {
    return vec2(fragCoord.x, iResolution.y - fragCoord.y) + k_origin;
}

bool card_shown(int i) { return i >= 0 && i < iWindowCount && iWindow[i].z > 0.0; }

// card i as x0 y0 x1 y1 in output pixels
vec4 card(int i) {
    vec4 w = iWindow[i];
    float top = k_h - (w.y + w.w);
    return vec4(w.x + k_origin.x, top + k_origin.y, w.x + w.z + k_origin.x, top + w.w + k_origin.y);
}

// the perimeter coordinate of the nearest edge of box b, clockwise from its
// top-left corner, and the perimeter's length in .y
vec2 perim(vec2 p, vec4 b) {
    float w = b.z - b.x, h = b.w - b.y;
    vec2 c = clamp(p, b.xy, b.zw);
    float dt = b.y - p.y, dr = p.x - b.z, db = p.y - b.w, dl = b.x - p.x;
    float m = max(max(dt, dr), max(db, dl));
    float u;
    if (m == dt) u = c.x - b.x;
    else if (m == dr) u = w + (c.y - b.y);
    else if (m == db) u = w + h + (b.z - c.x);
    else u = 2.0 * w + h + (b.w - c.y);
    return vec2(u, 2.0 * (w + h));
}

// how far round the perimeter of length per from ua to u
float pdist(float u, float ua, float per) {
    float d = mod(abs(u - ua), per);
    return min(d, per - d);
}

// ---------------------------------------------------------------- the move
// The rail names how long a focus move is drawn for (K_SETTLE) and which curve
// shapes its clock (K_CURVE), and every theme keeps the choreography it was
// drawn with by playing that choreography on this clock: a theme's own DESIGN
// seconds of it, the whole of it from the switch to the last thing it moves,
// stretched over the duration the rail asks for, so the curve is the one ease
// the move has and every part of it is drawn across that duration. A move that
// arrives mid-flight is retargeted and drawn for a shorter time, so a run of
// quick switches reads as one move and not one transition per window.
float sw_age() { return iTime - D(K_TSW); }

float ease_code(float u, int c) {
    u = clamp(u, 0.0, 1.0);
    if (c == 1) return 1.0 - (1.0 - u) * (1.0 - u);
    if (c == 2) return 1.0 - pow(1.0 - u, 3.0);
    if (c == 3) return u >= 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * u);
    return u;
}

// AGE seconds of the theme's own choreography, DESIGN being how long it was
// drawn for before the rail timed it
float move_age(float design) {
    float dur = max(D(K_SETTLE), 1.0 / 240.0);
    return design * ease_code(max(sw_age(), 0.0) / dur, int(D(K_CURVE)));
}

// ---------------------------------------------------------------- voice
float voice_env() {
    if (int(D(K_VN)) <= 0) return 0.0;
    float since = D(K_VSINCE), fade = D(K_VFADE);
    float rise = max(0.01, D(K_VRISE)), settle = max(0.01, D(K_VSETTLE));
    if (D(K_VOPEN) > 0.5) return sm(0.0, 1.0, (iTime - since) / rise);
    if (fade > -1e8)
        return sm(0.0, 1.0, (fade - since) / rise) * (1.0 - sm(0.0, 1.0, (iTime - fade) / settle));
    return 0.0;
}

// The voice's three bands, packed by rail-kit.lisp: the swell the turn is
// riding, the level it has now, and how fast it is moving. The border of the
// focused card moves with all three at once -- there is no origin and nothing
// travels round it, so a far corner is as loud as a near one the same instant,
// and the three bands give the border a shape, a beat and an attack instead of
// one uniform pump.
float v_lo() { return D(K_BANDS); }
float v_mid() { return D(K_BANDS + 1); }
float v_hi() { return D(K_BANDS + 2); }

// how far the voice reaches at perimeter point U of PER right now: a standing
// pattern, fixed in space and filled by the level, so every side of the frame
// moves together
float voice_around(float u, float per) {
    float th = 6.2832 * u / max(1.0, per);
    float stand = 0.58 + 0.42 * (0.62 * sin(3.0 * th + 0.7) + 0.38 * sin(5.0 * th - 1.3));
    float beat = 0.55 + 0.45 * sin(iTime * 12.0);
    float spark = hf(hu(int(u / 6.0), int(iTime * 26.0), 7u));
    return v_lo() * (0.60 + 0.40 * stand)
         + v_mid() * (0.30 + 0.70 * beat) * (0.55 + 0.45 * stand)
         + v_hi() * (0.20 + 0.80 * spark);
}

// the level the voice had AGE seconds ago (bolo writes about 30 a second)
float voice_level(float age) {
    int n = int(D(K_VN));
    if (n <= 0) return 0.0;
    float f = clamp(age * 30.0, 0.0, float(n - 1));
    int i = int(f);
    float a = D(K_LEVELS + i), b = D(K_LEVELS + min(i + 1, n - 1));
    return mix(a, b, f - float(i));
}

// ---------------------------------------------------------------- readings
float gauge_pct(int k) { return D(K_GAUGES + k * K_GAUGE); }

// ---------------------------------------------------------------- type
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

int glyph(int c) {
    if (c < 32 || c > 127) return 0;
    return GLYPH[c - 32];
}

// character i of the text packed from iData[base]
int char_at(int base, int i) {
    float v = D(base + i / 3);
    int k = i - (i / 3) * 3;
    float s = k == 0 ? 1.0 : (k == 1 ? 256.0 : 65536.0);
    return int(mod(floor(v / s + 0.5 / s), 256.0));
}
