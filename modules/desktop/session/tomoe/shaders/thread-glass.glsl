float D(int i) { return iData[i >> 2][i & 3]; }
vec4 D4(int i) { return vec4(D(i), D(i + 1), D(i + 2), D(i + 3)); }

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

vec2 thread_perim(vec2 p, vec4 b) {
    float w = b.z - b.x, h = b.w - b.y;
    vec2 c = clamp(p, b.xy, b.zw);
    float db = b.y - p.y, dr = p.x - b.z, dt = p.y - b.w, dl = b.x - p.x;
    float m = max(max(dt, dr), max(db, dl));
    float u;
    if (m == dt) u = c.x - b.x;
    else if (m == dr) u = w + (b.w - c.y);
    else if (m == db) u = w + h + (b.z - c.x);
    else u = 2.0 * w + h + (c.y - b.y);
    return vec2(u, 2.0 * (w + h));
}

float thread_pdist(float u, float ua, float per) {
    float d = mod(abs(u - ua), per);
    return min(d, per - d);
}
