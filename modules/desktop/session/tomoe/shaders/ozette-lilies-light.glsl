const vec3 DOT = vec3(0.106, 0.196, 0.176);
const float DOTW = 0.16;
const float GRID = 44.0;
const vec3 LAV = vec3(0.776, 0.651, 0.949);
const vec3 LIME = vec3(0.804, 0.886, 0.416);
const vec3 MUSTARD = vec3(0.922, 0.761, 0.227);
const float PAD = 0.55;
const vec3 PAGE = vec3(0.882, 0.922, 0.969);
const vec3 PAPER = vec3(0.965, 0.976, 0.988);
const vec3 PINK = vec3(0.949, 0.608, 0.812);
const float SPEED = 0.03;

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

vec3 pad(vec3 col, vec2 p, vec2 c, float r, float turn, vec3 hue) {
    vec2 d = p - c;
    float ang = atan(d.y, d.x) - turn;
    float notch = smoothstep(0.1, 0.13, abs(mod(ang + 3.14159, 6.28318) - 3.14159));
    float px = 1.5 / iResolution.y;
    float m = (1.0 - smoothstep(r - px, r + px, length(d))) * notch;
    vec3 c2 = mix(col, hue, PAD);
    return mix(col, c2, m);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.y;
    float a = iResolution.x / iResolution.y;
    float t = iTime * SPEED;
    vec3 col = mix(PAPER, PAGE, 1.0 - uv.y);
    vec2 g = mod(fragCoord, GRID) - 0.5 * GRID;
    col = mix(col, DOT, DOTW * (1.0 - smoothstep(1.2, 2.0, length(g))));
    col = pad(col, uv, vec2(a * 0.12 + 0.03 * sin(t * 1.3), 0.78 + 0.03 * cos(t * 1.1)), 0.26, 0.6
        + 0.2 * sin(t), LAV);
    col = pad(col, uv, vec2(a * 0.36 + 0.04 * cos(t * 0.9), 0.12 + 0.03 * sin(t * 1.4)), 0.2, 2.2
        + 0.2 * cos(t * 0.8), MUSTARD);
    col = pad(col, uv, vec2(a * 0.62 + 0.03 * sin(t * 1.2 + 2.0), 0.9
        + 0.02 * cos(t * 1.6)), 0.17, 4.0 + 0.2 * sin(t * 1.1), LIME);
    col = pad(col, uv, vec2(a * 0.84 + 0.04 * cos(t * 1.0 + 1.0), 0.3
        + 0.03 * sin(t * 0.7)), 0.3, 5.1 + 0.2 * cos(t * 0.9), PINK);
    col = pad(col, uv, vec2(a * 0.97 + 0.02 * sin(t * 1.5), 0.82 + 0.03 * sin(t * 1.2)), 0.12, 1.4
        + 0.2 * sin(t * 1.3), LAV);
    col += (hash(fragCoord + fract(iTime)) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
