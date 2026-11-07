const float BODY = 0.3;
const vec3 DOT = vec3(0.106, 0.196, 0.176);
const float DOTW = 0.08;
const vec3 GLINT = vec3(1.0);
const float GRID = 44.0;
const vec3 LAV = vec3(0.776, 0.651, 0.949);
const vec3 LIME = vec3(0.804, 0.886, 0.416);
const float LINES = 0.75;
const vec3 MUSTARD = vec3(0.922, 0.761, 0.227);
const vec3 PAGE = vec3(0.882, 0.922, 0.969);
const vec3 PAPER = vec3(0.965, 0.976, 0.988);
const vec3 PINK = vec3(0.949, 0.608, 0.812);
const float SCALE = 4.5;
const float SPEED = 0.03;

float caustic(vec2 p, float t) {
    vec2 q = p;
    for (int i = 0; i < 3; i++) {
        q += 0.6 * vec2(sin(q.y * 1.7 + t + float(i)), sin(q.x * 1.5 - t * 0.8 - float(i)));
    }
    float f = sin(q.x * 2.0) + sin(q.y * 2.0);
    return exp(-abs(f) * 5.0);
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
    vec3 col = mix(PAPER, PAGE, 1.0 - uv.y);
    float h = fbm(uv * 0.8 + vec2(t * 0.05, -t * 0.03));
    vec3 tint = mix(LAV, PINK, smoothstep(0.35, 0.65, h + 0.25 * sin(uv.x / a * 3.0 + t * 0.1)));
    tint = mix(tint, LIME, smoothstep(0.55, 0.75, fbm(uv * 0.6 - vec2(t * 0.04, 2.0))));
    tint = mix(tint, MUSTARD, 0.6 * smoothstep(0.6, 0.8, fbm(uv * 0.7 + vec2(4.0, t * 0.03))));
    col = mix(col, tint, BODY);
    float c = caustic(uv * SCALE + vec2(0.0, 7.0), t);
    col = mix(col, GLINT, clamp(c, 0.0, 1.0) * LINES);
    vec2 g = mod(fragCoord, GRID) - 0.5 * GRID;
    col = mix(col, DOT, DOTW * (1.0 - smoothstep(1.1, 1.9, length(g))));
    col += (hash(fragCoord + fract(iTime)) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
