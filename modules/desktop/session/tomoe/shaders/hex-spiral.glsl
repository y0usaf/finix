const float PI = 3.14159265;
const float TAU = 6.28318531;
const float S3 = 0.86602540;
const vec2 CENTER = vec2(0.4, 0.58);
const int M = 29;
const int N = 13;
const int ARM = 4;
const int LOOP = 52;
const float HEX_SPEED = 0.7;
const int STREAK_K = 176;
const float STREAK_STEP = 0.057;
const int STREAK_N = 132;
const int STREAK_LOOP = 160;
const float STREAK_SPEED = 0.32;
const float CYCLE = 1.8;

const vec3 PAL[10] = vec3[10](
    vec3(1.000, 0.824, 0.122), vec3(1.000, 0.604, 0.122), vec3(1.000, 0.420, 0.369),
    vec3(1.000, 0.361, 0.784), vec3(0.706, 0.420, 1.000), vec3(0.184, 0.420, 1.000),
    vec3(0.122, 0.722, 1.000), vec3(0.122, 0.839, 0.706), vec3(0.482, 0.878, 0.165),
    vec3(0.957, 0.957, 0.957)
);

const ivec2 NEAR[7] = ivec2[7](
    ivec2(0, 0), ivec2(1, 0), ivec2(-1, 0), ivec2(0, 1), ivec2(0, -1), ivec2(1, -1), ivec2(-1, 1)
);

float hash(ivec2 c) {
    uvec2 v = uvec2(c) * uvec2(1597334673u, 3812015801u);
    uint n = (v.x ^ v.y) * 1597334673u;
    n ^= n >> 16;
    n *= 2246822519u;
    n ^= n >> 13;
    return float(n) * (1.0 / 4294967296.0);
}

int fdiv(int a, int b) {
    return int(floor(float(a) / float(b)));
}

int pmod(int a, int b) {
    return a - b * fdiv(a, b);
}

vec3 cycle(float f) {
    int a = pmod(int(floor(f)), 9);
    return mix(PAL[a], PAL[pmod(a + 1, 9)], fract(f));
}

vec2 rot(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

vec2 cart(ivec2 a) {
    return vec2(float(a.x) + 0.5 * float(a.y), S3 * float(a.y));
}

ivec2 nearest(vec2 h) {
    float y = h.y / S3;
    vec3 c = vec3(h.x - 0.5 * y, y, -h.x - 0.5 * y);
    vec3 r = floor(c + 0.5);
    vec3 d = abs(r - c);
    if (d.x > d.y && d.x > d.z) r.x = -r.y - r.z;
    else if (d.y > d.z) r.y = -r.x - r.z;
    return ivec2(r.xy);
}

float hexDist(vec2 q) {
    return max(abs(q.x), max(abs(0.5 * q.x + S3 * q.y), abs(-0.5 * q.x + S3 * q.y)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float px = 1.0 / iResolution.y;
    vec2 p = (fragCoord - CENTER * iResolution.xy) * px;
    float r = max(length(p), 1e-5);
    vec2 w = vec2(log(r), atan(p.y, p.x));

    vec2 vc = cart(ivec2(M, N));
    float k = TAU / length(vc);
    float rho = 0.5 * PI - atan(vc.y, vc.x);
    vec2 drift = cart(ivec2(1, -1));
    float tt = mod(iTime * HEX_SPEED, float(LOOP));
    vec2 hw = rot(w, -rho) / k - tt * drift;
    ivec2 base = nearest(hw);

    float jr = mod(hw.y / S3 + 0.5, float(N));
    float band = smoothstep(float(ARM) + 1.5, float(ARM) + 4.0, jr) * (1.0 - smoothstep(float(N) - 1.2, float(N), jr));

    vec3 col = vec3(0.0);
    float phase = mod(iTime, CYCLE) * 9.0 / CYCLE;

    float c = float(STREAK_K) * STREAK_STEP / TAU;
    float ct = sqrt(1.0 + c * c);
    float dth = TAU / float(STREAK_N);
    float ts = mod(iTime * STREAK_SPEED, float(STREAK_LOOP) * STREAK_STEP);
    float sig = w.x - ts - c * w.y;
    int is0 = int(floor(sig / STREAK_STEP));
    int it0 = int(floor(w.y / dth));
    for (int o = 0; o < 9; o++) {
        int it = it0 + o % 3 - 1;
        int is = is0 + o / 3 - 1;
        int q = fdiv(it, STREAK_N);
        ivec2 id = ivec2(pmod(is + STREAK_K * q, STREAK_LOOP), it - q * STREAK_N);
        float h0 = hash(id);
        float h1 = hash(id + ivec2(7, 131));
        float h2 = hash(id + ivec2(53, 17));
        if (h0 > 0.8) continue;
        float sm = (float(is) + 0.5 + 0.8 * (h1 - 0.5)) * STREAK_STEP;
        vec2 dir = rot(vec2(c, 1.0) / ct, 0.6 * (h2 - 0.5));
        float tc = (float(it) + 0.5 + 0.6 * (h2 - 0.5)) * dth;
        vec2 d = vec2(sig - sm + c * (w.y - tc), w.y - tc);
        float len = (0.22 + 0.22 * h1) * dth * ct;
        float th = (0.2 + 0.08 * h2) * STREAK_STEP / ct;
        float a = clamp(dot(d, dir), -len, len);
        float dist = (length(d - dir * a) - th) * r / px;
        float cover = clamp(0.5 - dist, 0.0, 1.0) * smoothstep(0.6, 2.0, th * r / px);
        int pick = int(h0 * 16.0) % 13;
        vec3 sc = pick > 8 ? PAL[9] : cycle(float(pick) - phase);
        col = mix(col, sc * (0.7 + 0.3 * h2), cover * band);
    }

    float key[7];
    int ord[7];
    vec2 outward = rot(vec2(1.0, 0.0), -rho);
    for (int i = 0; i < 7; i++) {
        key[i] = dot(cart(NEAR[i]), outward);
        ord[i] = i;
    }
    for (int i = 1; i < 7; i++) {
        for (int j = i; j > 0 && key[ord[j - 1]] > key[ord[j]]; j--) {
            int t = ord[j];
            ord[j] = ord[j - 1];
            ord[j - 1] = t;
        }
    }

    int wrap = (M + N) * LOOP;
    for (int i = 0; i < 7; i++) {
        ivec2 cell = base + NEAR[ord[i]];
        if (pmod(cell.y, N) >= ARM) continue;
        int id = pmod(cell.x * N - cell.y * M, wrap);
        float h0 = hash(ivec2(id, 911));
        float h1 = hash(ivec2(id, 37));
        vec2 wc = rot(cart(cell) + tt * drift, rho) * k;
        float rc = exp(wc.x);
        vec2 sc = rc * vec2(cos(wc.y), sin(wc.y));
        float scale = k * rc;
        vec2 q = rot(p - sc, -(wc.y + rho)) / scale;
        float size = 0.5 * (0.88 + 0.36 * h1);
        float dist = (hexDist(q) - size) * scale / px;
        float fade = smoothstep(3.0, 9.0, size * scale / px);
        float cover = clamp(0.5 - dist, 0.0, 1.0) * fade;
        float rim = clamp(0.5 - dist - max(1.0, 0.03 * size * scale / px), 0.0, 1.0);
        vec3 hc = cycle(h0 * 9.0 - phase);
        col = mix(col, hc * rim, cover);
    }

    fragColor = vec4(col, 1.0);
}
