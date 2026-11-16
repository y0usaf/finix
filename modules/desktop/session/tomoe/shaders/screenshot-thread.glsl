float D(int i) { return iData[i >> 2][i & 3]; }
vec4 D4(int i) { return vec4(D(i), D(i + 1), D(i + 2), D(i + 3)); }

const int VEIL = 0, SHINE = 4, LINE = 8, TINT = 12;
const int RADIUS = 16, KNOT = 17, SLACK = 18, SWING = 19, LIFT = 20, LENS = 21, RIM = 22;
const int COARSE = 4, SEGMENTS = 24;

vec3 under(vec2 p) { return beneath(p).rgb; }

float segment(vec2 p, vec2 q0, vec2 q1) {
    vec2 s = q1 - q0;
    float h = clamp(dot(p - q0, s) / max(dot(s, s), 1e-4), 0.0, 1.0);
    return length(p - (q0 + s * h));
}

vec2 bezier(vec2 a, vec2 b, vec2 c, vec2 d, float t) {
    float s = 1.0 - t;
    return s * s * s * a + 3.0 * s * s * t * b + 3.0 * s * t * t * c + t * t * t * d;
}

vec4 string_at(vec2 p, vec2 a, vec2 end, vec2 e, vec2 v) {
    vec2 chord = e - a;
    float d = length(chord);
    float rest = D(SLACK) * 0.5 * length(iResolution.xy);
    float span = max(rest, d);
    float floor_y = D(RADIUS) + 2.0;
    float rise = sqrt(max(a.y - floor_y, 0.0)) + sqrt(max(e.y - floor_y, 0.0));
    float sag = min(min(sqrt(max(0.0, 3.0 * d * (span - d) / 8.0)), 0.35 * d), 0.25 * rise * rise);
    vec2 bow = -v * D(SWING);
    float most = 0.3 * max(d, 1.0);
    if (length(bow) > most) bow *= most / length(bow);
    vec2 hang = vec2(0.0, -sag);
    vec2 c1 = a + chord / 3.0 + (4.0 / 3.0) * (hang + 0.6 * bow);
    vec2 c2 = a + 2.0 * chord / 3.0 + (4.0 / 3.0) * (hang + bow);
    float reach = D(RADIUS) + 1.0;
    vec2 lo = min(min(a, end), min(c1, c2)) - reach;
    vec2 hi = max(max(a, end), max(c1, c2)) + reach;
    if (any(lessThan(p, lo)) || any(greaterThan(p, hi))) return vec4(1e9, 0.0, 0.0, 1.0);
    float spread = max(segment(c1, a, end), segment(c2, a, end));
    if (segment(p, a, end) > reach + spread) return vec4(1e9, 0.0, 0.0, 1.0);
    float bend = max(length(a - 2.0 * c1 + c2), length(c1 - 2.0 * c2 + end));
    float slack = 3.0 * bend / (4.0 * float(COARSE * COARSE));
    float near = 1e9;
    vec2 q0 = a;
    for (int i = 1; i <= COARSE; i++) {
        vec2 q1 = bezier(a, c1, c2, end, float(i) / float(COARSE));
        near = min(near, segment(p, q0, q1));
        q0 = q1;
    }
    if (near > reach + slack) return vec4(1e9, 0.0, 0.0, 1.0);
    float best = 1e9;
    vec2 facing = vec2(0.0, 1.0);
    q0 = a;
    for (int i = 1; i <= SEGMENTS; i++) {
        vec2 q1 = bezier(a, c1, c2, end, float(i) / float(SEGMENTS));
        vec2 s = q1 - q0;
        float h = clamp(dot(p - q0, s) / max(dot(s, s), 1e-4), 0.0, 1.0);
        vec2 off = p - (q0 + s * h);
        float dist = length(off);
        if (dist < best) {
            best = dist;
            facing = dist > 1e-3 ? off / dist : normalize(vec2(-s.y, s.x) + 1e-6);
        }
        q0 = q1;
    }
    return vec4(best, 0.0, facing);
}

vec3 glass(vec2 p, vec2 facing, float dist, float radius, vec3 back) {
    float cover = clamp(radius + 0.5 - dist, 0.0, 1.0);
    if (cover <= 0.0) return back;
    float n = clamp(dist / radius, 0.0, 1.0);
    float bend = sqrt(max(0.0, 1.0 - n * n));
    vec3 seen = under(p - facing * n * radius * D(LENS) * (1.0 - bend));
    seen = mix(seen, D4(TINT).rgb, D4(TINT).a);
    seen = mix(seen, vec3(1.0), D(LIFT) * bend);
    float lit = smoothstep(0.38, 0.0, abs(n - 0.5)) * max(0.0, facing.y);
    seen = mix(seen, D4(SHINE).rgb, D4(SHINE).a * lit);
    float rim = smoothstep(radius - 1.6, radius - 0.3, dist);
    seen = mix(seen, D4(LINE).rgb, D4(LINE).a * rim);
    return mix(back, seen, cover);
}

void mainImage(out vec4 color, in vec2 p) {
    vec4 live = iSelection[0], sprung = iSelection[1], speed = iSelection[2];
    bool selected = iSelection[3].x > 0.5;
    vec2 lo = min(live.xy, live.zw), hi = max(live.xy, live.zw);
    vec2 slo = min(sprung.xy, sprung.zw), shi = max(sprung.xy, sprung.zw);
    vec2 vlo = vec2(sprung.x <= sprung.z ? speed.x : speed.z, sprung.y <= sprung.w ? speed.y : speed.w);
    vec2 vhi = vec2(sprung.x <= sprung.z ? speed.z : speed.x, sprung.y <= sprung.w ? speed.w : speed.y);
    vec2 size = iResolution.xy;

    bool inside = selected && all(greaterThanEqual(p, lo)) && all(lessThan(p, hi));
    vec4 veil = D4(VEIL);
    vec4 layer = inside ? vec4(0.0) : vec4(veil.rgb * veil.a, veil.a);
    if (selected) {
        vec2 outside = max(lo - p, p - hi);
        float edge = max(outside.x, outside.y);
        float rim = D(RIM);
        vec4 line = vec4(0.0);
        if (edge >= 0.0 && edge < rim) line = D4(SHINE) * vec4(1.0, 1.0, 1.0, 0.8);
        else if (edge >= rim && edge < rim + 1.0) line = D4(LINE);
        layer = vec4(line.rgb * line.a, line.a) + layer * (1.0 - line.a);
    }

    vec2 a0 = vec2(0.0, size.y), a1 = size, a2 = vec2(0.0), a3 = vec2(size.x, 0.0);
    vec2 e0 = vec2(lo.x, hi.y), e1 = hi, e2 = lo, e3 = vec2(hi.x, lo.y);
    float radius = D(RADIUS), knot = D(KNOT);
    vec4 h0 = string_at(p, a0, e0, vec2(slo.x, shi.y), vec2(vlo.x, vhi.y));
    vec4 h1 = string_at(p, a1, e1, shi, vhi);
    vec4 h2 = string_at(p, a2, e2, slo, vlo);
    vec4 h3 = string_at(p, a3, e3, vec2(shi.x, slo.y), vec2(vhi.x, vlo.y));
    float k0 = length(p - e0), k1 = length(p - e1), k2 = length(p - e2), k3 = length(p - e3);
    float strings = min(min(h0.x, h1.x), min(h2.x, h3.x));
    float knots = min(min(k0, k1), min(k2, k3));
    if (strings > radius + 1.0 && knots > knot + 1.0) {
        color = layer;
        return;
    }

    vec3 col = layer.rgb + under(p) * (1.0 - layer.a);
    col = glass(p, h0.zw, h0.x, radius, col);
    col = glass(p, h1.zw, h1.x, radius, col);
    col = glass(p, h2.zw, h2.x, radius, col);
    col = glass(p, h3.zw, h3.x, radius, col);
    col = glass(p, (p - e0) / max(k0, 1e-3), k0, knot, col);
    col = glass(p, (p - e1) / max(k1, 1e-3), k1, knot, col);
    col = glass(p, (p - e2) / max(k2, 1e-3), k2, knot, col);
    col = glass(p, (p - e3) / max(k3, 1e-3), k3, knot, col);
    color = vec4(col, 1.0);
}
