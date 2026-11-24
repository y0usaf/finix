const int VEIL = 0, RIM = 4, SWELL = 5, PACE = 6, BEAD_HX = 7, BEAD_HY = 8, DOT = 9, DOT_SWELL = 10, INK = 11;

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
@MARKS@
}
