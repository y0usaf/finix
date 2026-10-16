const float TAU = 6.28318531;
const float RIBS = 18.0;
const float DRIFT = 0.18;
const float DISPERSE = 0.05;
const float FLASH_PERIOD = 7.0;
const float WANDER = 61.0;
const float TWIST_PERIOD = 43.0;
const vec3 BASE_A = vec3(0.60, 0.68, 0.73);
const vec3 BASE_B = vec3(0.69, 0.66, 0.70);

float shade(float u, float aa) {
    float acc = 0.0;
    for (int k = -1; k <= 1; k++) {
        float d = fract(u + float(k) * aa * 0.35);
        acc += 0.86 + 0.14 * smoothstep(0.0, 1.0, d) + 0.32 * exp((d - 1.0) / 0.05) - 0.20 * exp(-d / 0.07);
    }
    return acc / 3.0;
}

vec3 flame(float k) {
    vec3 cyan = vec3(0.25, 0.85, 1.0);
    vec3 blue = vec3(0.35, 0.45, 1.0);
    vec3 pink = vec3(1.0, 0.25, 0.75);
    vec3 orange = vec3(1.0, 0.62, 0.25);
    vec3 yellow = vec3(1.0, 0.93, 0.45);
    vec3 c = mix(cyan, blue, smoothstep(-0.30, -0.12, k));
    c = mix(c, pink, smoothstep(-0.12, -0.02, k));
    c = mix(c, orange, smoothstep(0.0, 0.10, k));
    return mix(c, yellow, smoothstep(0.08, 0.35, k));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float aspect = iResolution.x / iResolution.y;
    vec2 p = fragCoord / iResolution.y;
    float t = iTime;

    vec2 c = vec2(aspect + 0.45 + 0.3 * sin(TAU * t / WANDER), 0.3 + 0.9 * sin(TAU * t / (WANDER * 0.71)));
    vec2 q = p - c;
    float r = length(q);
    float th = atan(q.y, -q.x);
    float twist = 0.35 * sin(TAU * t / TWIST_PERIOD);
    float bend = 0.035 * sin(2.1 * p.y + 1.3 * p.x + 0.11 * t);

    float u = RIBS * (r + twist * th / TAU + bend) - DRIFT * t;
    float aa = fwidth(u);
    vec3 s = vec3(shade(u - DISPERSE, aa), shade(u, aa), shade(u + DISPERSE, aa));

    vec3 base = mix(BASE_A, BASE_B, smoothstep(-0.2, 1.2, p.y + 0.3 * sin(p.x * 0.9 + 0.07 * t)));
    vec3 col = base * s;

    float rib = floor(u);
    float d = fract(u);
    float reach = 0.30 + 0.12 * sin(rib * 0.61 + t * 1.3) + 0.08 * sin(rib * 1.7 - t * 0.7);
    float tipY = reach * (0.35 + 0.65 * pow(1.0 - abs(2.0 * d - 1.0), 0.8));
    float k = p.y - tipY;
    float sweep = 0.5 + 0.5 * sin(TAU * t / FLASH_PERIOD - 3.5 * p.x / max(aspect, 1.0) + 0.9 * p.y);
    float flash = smoothstep(0.62, 0.97, sweep);
    vec3 hot = flame(k) * (0.82 + 0.25 * d);
    col = mix(col, hot * s, flash * (0.65 + 0.35 * d));

    vec2 v = fragCoord / iResolution.xy - 0.5;
    col *= 1.0 - 0.15 * dot(v, v);
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
