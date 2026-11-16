// kit: what the halo, thread, grain and lumen shaders share. default.nix puts
// this file in front of each of them. It reads the layout lisp/rail-kit.lisp
// writes into iData -- the switch, bolo's turn, the four readings, the clock and
// each card's side and title -- and gives the theme the cards in output
// pixels, the voice's envelope and level history, and a three-by-five bitmap
// type for the text that travels as character codes, three to a number.
// Coordinates are the output's, y down.

float D(int i) { return iData[i >> 2][i & 3]; }
vec3 D3(int i) { return vec3(D(i), D(i + 1), D(i + 2)); }

const int K_OX = 0, K_OY = 1, K_FOCUS = 2, K_OLD = 3, K_SIDE = 4;
const int K_TSW = 5, K_FLOW = 6, K_FROM = 7, K_SETTLE = 8;
const int K_VSINCE = 9, K_VFADE = 10, K_VOPEN = 11, K_VRISE = 12, K_VSETTLE = 13, K_VN = 14;
const int K_LEVELS = 15, K_NLEVELS = 32;
const int K_GAUGES = 47, K_GAUGE = 5;
const int K_CLOCK = 67, K_DAY = 69, K_DATE = 70;
const int K_CARDS = 72, K_CARD = 5;
const int THEME = 112;

#define PI 3.14159265358979

float sm(float a, float b, float x) {
    float u = clamp((x - a) / (b - a), 0.0, 1.0);
    return u * u * (3.0 - 2.0 * u);
}

float ease_out(float u) {
    u = clamp(u, 0.0, 1.0);
    return 1.0 - (1.0 - u) * (1.0 - u) * (1.0 - u);
}

float spring(float t, float w, float z) {
    if (t <= 0.0) return 0.0;
    float wd = w * sqrt(1.0 - z * z);
    return 1.0 - exp(-z * w * t) * (cos(wd * t) + z * w / wd * sin(wd * t));
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

float card_side(int i) { return D(K_CARDS + i * K_CARD); }

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

// ---------------------------------------------------------------- switch
float sw_age() { return iTime - D(K_TSW); }
bool sw_on() { return D(K_TSW) > -1e5 && sw_age() >= 0.0 && sw_age() < D(K_SETTLE) + 0.5; }

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
float gauge_trend(int k) { return D(K_GAUGES + k * K_GAUGE + 1); }
bool gauge_shown(int k) { return gauge_pct(k) >= 0.0; }

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

// how many characters of the text at base, up to n, before trailing spaces
int text_len(int base, int n) {
    int len = 0;
    for (int i = 0; i < 15; i++) {
        if (i >= n) break;
        int c = char_at(base, i);
        if (c != 32 && c != 0) len = i + 1;
    }
    return len;
}

// whether p is on a lit cell of the text at base, its first cell's top-left at
// at, each cell s pixels, advancing 4 cells a character; .x the hit, and the
// character index the cell belongs to in idx
bool text_hit(vec2 p, vec2 at, float s, int base, int n, out int idx) {
    vec2 q = (p - at) / s;
    idx = -1;
    if (q.x < 0.0 || q.y < 0.0 || q.y >= 5.0) return false;
    int ci = int(floor(q.x / 4.0));
    if (ci >= n) return false;
    int col = int(floor(q.x)) - ci * 4;
    if (col > 2) return false;
    int row = int(floor(q.y));
    idx = ci;
    return (glyph(char_at(base, ci)) & (1 << (row * 3 + col))) != 0;
}

float text_width(int n, float s) { return (4.0 * float(n) - 1.0) * s; }
