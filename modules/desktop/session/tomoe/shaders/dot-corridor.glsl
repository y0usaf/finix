const float TAU = 6.28318531;
const float FOCAL = 0.92;
const float WIDE = 2.4;
const float LW = 0.2;
const float DY = 0.41;
const float RAD = 0.19;
const float YMAX = 16.0;
const float ZOOM = 1.1;
const float HUE_PERIOD = 1.8;
const float SIDES = 13.0;
const int BAND = 5;
const int LOOP = 1000;

float hash(ivec2 c) {
    uvec2 v = uvec2(c) * uvec2(1597334673u, 3812015801u);
    uint n = (v.x ^ v.y) * 1597334673u;
    n ^= n >> 16;
    n *= 2246822519u;
    n ^= n >> 13;
    return float(n) * (1.0 / 4294967296.0);
}

int pmod(int a, int b) {
    return a - b * int(floor(float(a) / float(b)));
}

vec3 hsv(float h, float s, float v) {
    vec3 k = clamp(abs(fract(h + vec3(0.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    return v * mix(vec3(1.0), k, s);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float px = 1.0 / max(0.5 * iResolution.y * FOCAL, 0.5 * iResolution.x / WIDE);
    vec2 s = max(abs(fragCoord - 0.5 * iResolution.xy) * px, vec2(1e-6, 0.0));
    vec3 col = vec3(0.0);
    float alpha = 0.0;

    float shift = mod(iTime * ZOOM, float(LOOP) * LW);
    float spin = fract(iTime / HUE_PERIOD);
    float w = log(s.x) - shift;
    float u = s.y / s.x;
    int c0 = int(floor(w / LW + 0.5));
    int imax = int(YMAX / DY);

    for (int dc = 2; dc >= -2; dc--) {
        int c = c0 + dc;
        int cc = pmod(c, LOOP);
        float lift = 0.5 * float(cc & 1);
        int i0 = int(floor(u / DY - lift + 0.5));
        for (int di = -1; di <= 1; di++) {
            int i = i0 + di;
            if (i < 0 || i > imax) continue;
            ivec2 id = ivec2(cc, i);
            float h0 = hash(id);
            float h1 = hash(id + ivec2(4099, 17));
            float h2 = hash(id + ivec2(31, 7919));
            float h3 = hash(id + ivec2(613, 3));
            if (h2 > 0.9) continue;
            float sx = exp((float(c) + 0.3 * (h3 - 0.5)) * LW + shift);
            vec2 centre = sx * vec2(1.0, (float(i) + lift + 0.3 * (fract(h3 * 7.0) - 0.5)) * DY);
            float rho = max(RAD * (0.5 + 0.5 * h1) * sx, 0.6 * px);
            vec2 q = s - centre;
            float len = length(q);
            if (len > rho + px) continue;
            float sector = TAU / SIDES;
            float a = mod(atan(q.y, q.x) + h0 * TAU, sector) - 0.5 * sector;
            float dist = (len * cos(a) - rho * cos(0.5 * sector)) / px;
            float cover = clamp(0.5 - dist, 0.0, 1.0);
            float sat = h2 < 0.1 ? 0.0 : (h2 < 0.2 ? 0.35 : 0.92);
            float val = h2 > 0.82 ? 0.55 : 1.0;
            float hue = hash(ivec2(cc / BAND, int(h0 * 4.0) + 101));
            col += (1.0 - alpha) * cover * hsv(hue + spin, sat, val);
            alpha += (1.0 - alpha) * cover;
        }
    }

    fragColor = vec4(col, 1.0);
}
