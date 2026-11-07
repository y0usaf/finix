const vec3 SHELL = vec3(0.914, 0.898, 0.863);
const vec3 PUTTY = vec3(0.800, 0.780, 0.730);
const vec3 GRAPHITE = vec3(0.160, 0.160, 0.155);
const vec3 ORANGE = vec3(0.930, 0.360, 0.110);
const vec2 LIGHT = vec2(-0.6, 0.8);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

const float ROWS = 46.0;
const float SPEED = 1.0;
const float BPM = 128.0;
const float WAVE = 1.5;
const float RIPPLE = 0.7;
const float RIPPLE_SPEED = 0.7;

float base(vec2 c, float t, float aspect) {
    float s = t * 0.5;
    vec2 a = vec2(aspect * (0.22 + 0.08 * sin(s * 0.37)), 0.30 + 0.12 * cos(s * 0.41));
    vec2 b = vec2(aspect * (0.78 + 0.08 * cos(s * 0.29)), 0.70 + 0.10 * sin(s * 0.47));
    float wa = sin(length(c - a) * 18.0 - t * WAVE);
    float wb = sin(length(c - b) * 14.0 - t * WAVE * 0.8);
    return 0.5 + 0.25 * (wa + wb);
}

float ripples(vec2 c, float t, float aspect) {
    float every = 120.0 / BPM;
    float life = 4.0 * every;
    float n = floor(t / every);
    float age = t - n * every;
    float r = 0.0;
    for (int k = 0; k < 4; k++) {
        float m = n - float(k);
        float tm = age + float(k) * every;
        float x = tm / life;
        vec2 o = vec2(hash(vec2(m, 3.7)) * aspect, hash(vec2(m, 9.1)));
        float d = length(c - o) - tm * RIPPLE_SPEED;
        float env = smoothstep(0.0, 0.04, x) * (1.0 - smoothstep(0.2, 1.0, x));
        r += (mod(m, 2.0) < 0.5 ? 1.0 : 0.7) * env * exp(-d * d * 120.0);
    }
    return RIPPLE * r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float t = iTime * SPEED;
    float aspect = iResolution.x / iResolution.y;
    float pitch = floor(iResolution.y / ROWS);
    vec2 off = 0.5 * mod(iResolution.xy, pitch);
    vec2 cell = floor((fragCoord - off) / pitch);
    vec2 center = (cell + 0.5) * pitch + off;
    vec2 p = center / iResolution.y;
    float f = clamp(base(p, t, aspect) * 0.95 + ripples(p, t, aspect), 0.0, 1.0);
    float hs = 0.5 * floor(pitch * (0.12 + 0.60 * f * f) + 0.5);
    vec2 q = fragCoord - center;
    vec2 aq = abs(q);
    float dist = max(aq.x, aq.y);
    vec2 dir = aq.x > aq.y ? vec2(sign(q.x), 0.0) : vec2(0.0, sign(q.y));
    vec2 l = normalize(LIGHT);
    vec2 sv = fragCoord / iResolution.xy;
    vec3 panel = SHELL * mix(0.94, 1.02, 0.55 * sv.y + 0.45 * (1.0 - sv.x));
    float rim = smoothstep(hs + 2.5, hs, dist) * dot(dir, -l);
    panel *= 1.0 + 0.10 * rim;
    float glow = smoothstep(0.86, 0.98, f);
    vec3 backing = mix(GRAPHITE, ORANGE, glow);
    float lit = clamp(dot(dir, -l), 0.0, 1.0);
    vec3 wall = mix(GRAPHITE * 0.7, PUTTY * 0.8, lit);
    vec3 hole = mix(backing, wall, step(hs - max(1.0, hs * 0.22), dist) * (0.4 + 0.6 * lit));
    float inside = 1.0 - step(hs, dist);
    vec3 color = mix(panel, hole, inside);
    color += (hash(fragCoord) - 0.5) * 0.012;
    fragColor = vec4(color, 1.0);
}
