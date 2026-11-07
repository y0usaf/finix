const vec3 BASE_BOTTOM = vec3(0.063, 0.051, 0.09);
const vec3 BASE_TOP = vec3(0.098, 0.075, 0.129);
const vec3 DOT = vec3(0.804, 0.886, 0.416);
const float DOTW = 0.08;
const float GRID = 44.0;
const float HUE = 0.13;
const vec3 LAV = vec3(0.776, 0.651, 0.949);
const vec3 LIME = vec3(0.804, 0.886, 0.416);
const vec3 MUSTARD = vec3(0.922, 0.761, 0.227);
const vec3 PINK = vec3(0.949, 0.608, 0.812);
const vec3 PLUM = vec3(0.173, 0.129, 0.251);
const float PLUMW = 0.6;
const float RING = 0.004;
const float RIPPLE = 0.25;
const float SPEED = 0.02;

float blob(vec2 uv, vec2 c, float r) {
    vec2 d = uv - c;
    return exp(-dot(d, d) / (r * r));
}

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i
        + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float s = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        s += a * noise(p);
        p = mat2(1.6, 1.2, -1.2, 1.6) * p;
        a *= 0.5;
    }
    return s;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.y;
    float t = iTime * SPEED;
    vec2 w = uv + 0.18 * vec2(fbm(uv * 1.3 + vec2(t, 0.0)), fbm(uv * 1.3 + vec2(3.1, -t))) - 0.09;
    float a = iResolution.x / iResolution.y;
    vec3 col = mix(BASE_TOP, BASE_BOTTOM, smoothstep(0.0, 1.0, 1.0 - uv.y));
    col = mix(col, LAV, HUE * 1.0 * blob(w, vec2(a * (0.22 + 0.04 * sin(t * 0.7)), 0.72), 0.55));
    col = mix(col, PINK, HUE * 0.75 * blob(w, vec2(a * (0.78 + 0.03 * cos(t * 0.6)), 0.78), 0.48));
    col = mix(col, MUSTARD, HUE * 0.55
        * blob(w, vec2(a * (0.58 + 0.04 * sin(t * 0.5 + 2.0)), 0.08), 0.42));
    col = mix(col, LIME, HUE * 0.6 * blob(w, vec2(a * (0.92 + 0.02 * sin(t * 0.8)), 0.2), 0.4));
    col = mix(col, PLUM, PLUMW * blob(w, vec2(a * 0.45, 0.45 + 0.05 * sin(t * 0.4)), 0.6));
    float r = 0.0;
    vec2 cs[3] = vec2[3](
        vec2(0.3 * a, 0.35),
        vec2(0.7 * a, 0.62),
        vec2(0.52 * a, 0.18)
    );
    for (int i = 0; i < 3; i++) {
        float d = length(w - cs[i]);
        r += sin(d * 38.0 - iTime * RIPPLE + float(i) * 2.1) * exp(-d * 2.2);
    }
    col += RING * r;
    vec2 g = mod(fragCoord, GRID) - 0.5 * GRID;
    float pip = 1.0 - smoothstep(1.1, 1.9, length(g));
    col = mix(col, DOT, DOTW * pip * (0.6 + 0.4 * fbm(uv * 2.0 - t)));
    col += (hash(fragCoord + fract(iTime)) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
