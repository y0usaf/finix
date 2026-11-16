float D(int i) { return iData[i >> 2][i & 3]; }
vec4 D4(int i) { return vec4(D(i), D(i + 1), D(i + 2), D(i + 3)); }

const int VEIL = 0, RIM = 4, SWELL = 5, PACE = 6, BEAD_HX = 7, BEAD_HY = 8, DOT = 9, DOT_SWELL = 10, INK = 11;

vec3 under(vec2 q) { return beneath(q).rgb; }

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

vec3 frosted(vec2 q, float r) {
    float spin = 6.2832 * fract(52.9829 * fract(dot(q, vec2(0.06711, 0.00584))));
    vec2 disc[9] = vec2[9](vec2(0.389, 0.000), vec2(0.120, 0.370), vec2(-0.315, 0.228),
                           vec2(-0.315, -0.228), vec2(0.120, -0.370), vec2(0.666, 0.470),
                           vec2(0.046, 0.816), vec2(-0.665, 0.470), vec2(-0.665, -0.470));
    vec3 sum = vec3(0.0);
    float c = cos(spin), s = sin(spin);
    for (int i = 0; i < 9; i++) {
        vec2 o = vec2(disc[i].x * c - disc[i].y * s, disc[i].x * s + disc[i].y * c);
        sum += under(q + r * o);
    }
    return sum / 9.0;
}

vec3 glass(vec2 p, float f, vec2 dir, float shine) {
    float depth = clamp(-f / 6.0, 0.0, 1.0);
    float lens = 13.0 * (1.0 - depth) * (1.0 - depth);
    vec3 seen = frosted(p - dir * lens, 7.0);
    seen = seen * 0.90 + vec3(0.07) + vec3(0.22) * clamp(shine, 0.0, 1.0);
    float lit = dot(dir, vec2(0.45, -0.89));
    float rim = clamp(1.0 + f / 1.7, 0.0, 1.0);
    seen = mix(seen, vec3(1.0), (0.28 + 0.60 * clamp(lit, 0.0, 1.0)) * rim);
    seen = mix(seen, vec3(0.0), clamp(-lit, 0.0, 1.0) * rim * 0.22);
    seen = mix(seen, vec3(1.0), clamp(1.0 + f / 4.0, 0.0, 1.0) * 0.10);
    return seen;
}

vec3 ink_of(vec2 c) {
    float lum = dot(under(c), vec3(0.3, 0.59, 0.11));
    return lum > 0.5 ? vec3(0.09) : vec3(0.94, 0.93, 0.90);
}

vec2 g_lo, g_hi, g_wlo, g_whi, g_bead;
float g_swell;
bool g_beaded;

float field(vec2 p) {
    vec2 a = p - 0.5 * (g_lo + g_hi), h = 0.5 * (g_hi - g_lo);
    vec2 q = abs(a) - h;
    float inner = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
    float r = min(min(g_wlo.x, g_wlo.y), min(g_whi.x, g_whi.y));
    float ring = max(sd_rbox(p, vec4(g_lo - g_wlo, g_hi + g_whi), r), -inner);
    if (!g_beaded) return ring;
    float hx = D(BEAD_HX) + 6.0 * g_swell, hy = D(BEAD_HY) + 2.0 * g_swell;
    float bead = sd_rbox(p, vec4(g_bead - vec2(hx, hy), g_bead + vec2(hx, hy)), min(hy, 12.0));
    return smin(ring, bead, 6.0);
}

vec4 thread_selector(vec2 p) {
    vec4 live = iSelection[0], sprung = iSelection[1], speed = iSelection[2];
    bool selected = iSelection[3].x > 0.5;
    vec4 veil = D4(VEIL);
    vec4 dim = vec4(veil.rgb * veil.a, veil.a);
    if (!selected) {
        return dim;
    }
    g_lo = min(live.xy, live.zw);
    g_hi = max(live.xy, live.zw);
    vec2 vlo = vec2(sprung.x <= sprung.z ? speed.x : speed.z, sprung.y <= sprung.w ? speed.y : speed.w);
    vec2 vhi = vec2(sprung.x <= sprung.z ? speed.z : speed.x, sprung.y <= sprung.w ? speed.w : speed.y);
    vec2 slo = clamp(abs(vlo) / D(PACE), 0.0, 1.0), shi = clamp(abs(vhi) / D(PACE), 0.0, 1.0);
    g_wlo = D(RIM) + D(SWELL) * slo;
    g_whi = D(RIM) + D(SWELL) * shi;
    g_swell = max(max(slo.x, slo.y), max(shi.x, shi.y));

    float hy = D(BEAD_HY);
    g_beaded = g_hi.x - g_lo.x > 2.0 * D(BEAD_HX) + 24.0;
    g_bead = vec2(0.5 * (g_lo.x + g_hi.x), g_lo.y - hy);
    if (g_lo.y < 2.0 * hy + 4.0) g_bead.y = g_hi.y + hy;

    bool inside = all(greaterThanEqual(p, g_lo)) && all(lessThan(p, g_hi));
    vec4 base = inside ? vec4(0.0) : dim;

    float f = field(p);
    if (f > 12.0) {
        return base;
    }
    vec2 slant = vec2(field(p + vec2(1.0, 0.0)) - f, field(p + vec2(0.0, 1.0)) - f);
    vec2 dir = slant / (length(slant) + 1e-5);

    vec3 c = base.rgb;
    float a = base.a;
    float sh = f > 0.0 ? 0.16 * pow(clamp(1.0 - f / 10.0, 0.0, 1.0), 2.0) : 0.0;
    float hair = 0.34 * clamp(1.0 - abs(f - 0.6) / 0.9, 0.0, 1.0);
    if (!inside) {
        c *= 1.0 - sh;
        a = sh + a * (1.0 - sh);
        c *= 1.0 - hair;
        a = hair + a * (1.0 - hair);
    }
    float cov = clamp(0.5 - f, 0.0, 1.0);
    if (cov > 0.0) {
        c = mix(c, glass(p, f, dir, g_swell), cov);
        a = cov + a * (1.0 - cov);
    }
    if (g_beaded && cov > 0.25) {
        float rr = D(DOT) + D(DOT_SWELL) * g_swell;
        float dd = length(p - g_bead) - rr;
        if (dd < 1.0) {
            float da = clamp(0.5 - dd, 0.0, 1.0) * (0.35 + 0.65 * g_swell);
            c = mix(c, ink_of(g_bead), da);
        }
    }
    return vec4(c, a);
}

void mainImage(out vec4 color, in vec2 p) {
    color = thread_selector(p);
    vec4 ink = D4(INK);
    float marks = marked(p) * ink.a;
    if (marks > 0.0)
        color = vec4(ink.rgb * marks + color.rgb * (1.0 - marks),
                     marks + color.a * (1.0 - marks));
}
