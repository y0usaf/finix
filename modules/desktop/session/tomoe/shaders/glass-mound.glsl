const vec3 PAPER = vec3(0.972, 0.976, 0.976);
const vec3 MIST = vec3(0.955, 0.962, 0.968);
const vec3 INK = vec3(0.09, 0.11, 0.15);
const vec3 SLATE = vec3(0.22, 0.27, 0.34);
const vec3 TEAL = vec3(0.07, 0.32, 0.43);
const vec3 LILAC = vec3(0.87, 0.76, 0.96);
const float IOR = 1.33;
const float SPREAD = 0.045;
const float SPEED = 0.5;
const float RING = 1.35;
const float TUBE = 0.33;
const float SINK = -1.0;
const float TILT = 1.0;
const float SWAY = 0.35;
const float FOG_TOP = -0.2;
const float FOG_BOTTOM = -1.1;
const float SOFT = 0.05;
const float BEND = 0.7;

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float map(vec3 p, float t) {
    vec3 q = p - vec3(0.0, SINK, 0.0);
    q.xz *= rot(0.35 * sin(t * 0.21));
    q.yz *= rot(TILT + SWAY * sin(t * 0.17));
    q.xy *= rot(0.12 * sin(t * 0.31));
    float a = atan(q.z, q.x);
    float tube = TUBE * (1.0 + 0.28 * sin(a * 2.0 + t * 0.7) + 0.12 * sin(a * 3.0 - t * 0.5));
    float ring = RING * (1.0 + 0.08 * sin(a * 2.0 - t * 0.4));
    float d = length(vec2(length(q.xz) - ring, q.y)) - tube;
    d += 0.04 * sin(2.1 * p.x + t) * sin(1.7 * p.y - 0.8 * t) * sin(1.9 * p.z + 1.1 * t);
    return d * 0.8;
}

vec3 normal(vec3 p, float t) {
    vec2 e = vec2(0.002, 0.0);
    return normalize(vec3(map(p + e.xyy, t) - map(p - e.xyy, t),
                          map(p + e.yxy, t) - map(p - e.yxy, t),
                          map(p + e.yyx, t) - map(p - e.yyx, t)));
}

float band(float x, float c, float w) {
    float k = (x - c) / w;
    return exp(-k * k);
}

vec3 env(vec3 d) {
    vec3 c = PAPER;
    float x = d.x + 0.5 * d.z;
    c = mix(c, LILAC, 0.9 * band(d.y, -0.07, 0.06));
    c = mix(c, INK, 0.95 * band(d.y, 0.12, 0.13));
    c = mix(c, TEAL, band(d.y, 0.34, 0.2) * smoothstep(-0.9, 0.1, x));
    c = mix(c, SLATE, 0.7 * band(d.y, 0.3, 0.14) * smoothstep(0.1, -0.9, x));
    c = mix(c, LILAC, 0.45 * band(d.y, 0.52, 0.06));
    c = mix(c, PAPER, 0.85 * band(x, -0.5, 0.12) * smoothstep(0.15, 0.4, d.y));
    return c;
}

vec3 shade(vec3 p, vec3 rd, float t) {
    vec3 n = normal(p, t);
    float c = max(dot(-rd, n), 0.0);
    float f = 0.25 + 0.75 * pow(1.0 - c, 2.0);
    vec3 through;
    for (int k = 0; k < 3; k++) {
        through[k] = env(normalize(rd - n * (BEND + (float(k) - 1.0) * SPREAD * 1.5)))[k];
    }
    vec3 col = mix(through, env(reflect(rd, n)), f);
    return mix(col, MIST, smoothstep(FOG_TOP, FOG_BOTTOM, p.y));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime * SPEED;
    vec3 ro = vec3(0.0, 0.5, 6.0);
    vec3 fw = normalize(vec3(0.0, 0.5, 0.0) - ro);
    vec3 rt = normalize(cross(fw, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(rt, fw);
    vec3 rd = normalize(uv.x * rt + uv.y * up + 1.6 * fw);
    float s = 0.0;
    float near = 1e9;
    float at = 0.0;
    bool hit = false;
    for (int i = 0; i < 110; i++) {
        float d = map(ro + rd * s, t);
        if (d < near) { near = d; at = s; }
        if (d < 0.001) { hit = true; break; }
        s += d;
        if (s > 12.0) break;
    }
    vec3 col = PAPER;
    if (hit) {
        col = shade(ro + rd * s, rd, t);
    } else if (near < SOFT) {
        float a = 1.0 - smoothstep(0.0, SOFT, near);
        col = mix(PAPER, shade(ro + rd * at, rd, t), 0.55 * a * a);
    }
    col = mix(PAPER, col, smoothstep(0.0, 0.14, fragCoord.y / iResolution.y));
    fragColor = vec4(col, 1.0);
}
