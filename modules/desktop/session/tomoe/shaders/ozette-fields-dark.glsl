const vec3 DOT = vec3(0.804, 0.886, 0.416);
const float DOTW = 0.1;
const float GRID = 44.0;
const vec3 LAV = vec3(0.776, 0.651, 0.949);
const vec3 LIME = vec3(0.561, 0.878, 0.824);
const vec3 MUSTARD = vec3(0.624, 0.706, 1.0);
const vec3 PAGE = vec3(0.082, 0.067, 0.114);
const vec3 PAPER = vec3(0.114, 0.09, 0.153);
const vec3 PINK = vec3(0.949, 0.608, 0.812);
const float SPEED = 0.02;
const float STRENGTH = 0.3;

float field(vec2 p, vec2 c, float r) {
    return 1.0 - smoothstep(r * 0.82, r * 1.12, length(p - c));
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
    float a = iResolution.x / iResolution.y;
    float t = iTime * SPEED;
    vec2 w = uv + 0.22 * vec2(fbm(uv * 0.9 + vec2(t, 1.7)), fbm(uv * 0.9 + vec2(5.2, -t))) - 0.11;
    vec3 col = mix(PAPER, PAGE, 1.0 - uv.y);
    col = mix(col, LAV, STRENGTH * field(w, vec2(a * (0.2 + 0.05 * sin(t * 2.1)), 0.66), 0.62));
    col = mix(col, MUSTARD, STRENGTH * field(w, vec2(a * (0.5 + 0.04 * cos(t * 1.7)), 0.02), 0.5));
    col = mix(col, PINK, STRENGTH
        * field(w, vec2(a * (0.74 + 0.04 * sin(t * 1.9 + 1.0)), 0.86), 0.55));
    col = mix(col, LIME, STRENGTH * field(w, vec2(a * (0.96 + 0.03 * cos(t * 2.3)), 0.24), 0.48));
    col = mix(col, LAV, STRENGTH * 0.7
        * field(w, vec2(a * (0.38 + 0.03 * sin(t * 1.3)), 1.08), 0.36));
    vec2 g = mod(fragCoord, GRID) - 0.5 * GRID;
    col = mix(col, DOT, DOTW * (1.0 - smoothstep(1.1, 1.9, length(g))));
    col += (hash(fragCoord + fract(iTime)) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
