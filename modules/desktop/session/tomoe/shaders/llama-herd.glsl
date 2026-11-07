const vec3 SKY = vec3(0.969, 0.941, 0.894);
const vec3 MOUNTAIN = vec3(0.902, 0.875, 0.910);
const vec3 HILL = vec3(0.847, 0.808, 0.867);
const vec3 SUN = vec3(0.949, 0.757, 0.306);
const vec3 CLOUD = vec3(1.000, 0.992, 0.973);
const vec3 GROUND = vec3(0.863, 0.773, 0.627);
const vec3 EDGE = vec3(0.722, 0.592, 0.420);
const vec3 PEBBLE = vec3(0.780, 0.671, 0.510);
const vec3 BODY = vec3(0.851, 0.737, 0.580);
const vec3 TIP = vec3(0.478, 0.337, 0.220);
const vec3 EYE = vec3(0.180, 0.125, 0.094);
const vec3 CACTUS = vec3(0.431, 0.608, 0.353);
const vec3 BANG = vec3(0.910, 0.408, 0.290);
const vec3 PACK = vec3(0.435, 0.455, 0.502);
const vec3 PACK_LIGHT = vec3(0.663, 0.686, 0.729);
const vec3 STRAP = vec3(0.290, 0.243, 0.212);
const vec3 FLAME_HOT = vec3(0.969, 0.843, 0.455);
const vec3 FLAME = vec3(0.949, 0.639, 0.227);
const vec3 FLAME_TIP = vec3(0.910, 0.408, 0.290);
const vec3 SMOKE = vec3(0.839, 0.808, 0.863);

const float SPEED = 40.0;
const float JET_ON = 1.0;
const float JET_LIFT = 1.5;
const float PI = 3.14159265;

const int LLAMA_BODY[12] = int[12](0, 1920, 3712, 1920, 384, 384, 385, 511, 511, 510, 330, 0);
const int LLAMA_TIPS[12] = int[12](640, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 330);
const int CACTUS_ROWS[12] = int[12](24, 28, 25, 153, 155, 222, 120, 24, 24, 24, 24, 24);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

bool box(vec2 p, float x, float y, float w, float h) {
    return p.x >= x && p.x < x + w && p.y >= y && p.y < y + h;
}

bool bit(int mask, int index) {
    return ((mask >> index) & 1) == 1;
}

float scale(int i) {
    return i == 0 ? 3.0 : 2.0;
}

float stopTime(float cx) {
    return (cx - 30.0 + 40.0 + 106.0 - 12.0) / SPEED;
}

vec3 pose(int i, float t, float cx) {
    float s = scale(i);
    float lag = i == 0 ? 0.0 : (i == 1 ? 46.0 : (i == 2 ? 76.0 : 106.0));
    float w = 12.0 * s;
    float t1 = stopTime(cx);
    if (i == 3 && t >= t1) {
        float x0 = floor(cx - 30.0 - w * 0.5);
        if (t < t1 + JET_LIFT) {
            float bang = (t >= t1 + 0.35 && t < t1 + JET_ON) ? 1.0 : 0.0;
            return vec3(x0, -max(0.0, t - t1 - JET_ON - 0.2) * 8.0, bang);
        }
        float u = t - t1 - JET_LIFT;
        return vec3(x0 + 28.0 * u + 30.0 * u * u, -(4.0 + 14.0 * u + 38.0 * u * u), 0.0);
    }
    float x = SPEED * t - 40.0 - lag;
    float reach = 22.0 + w / 3.0;
    float d = x + w * 0.5 - cx;
    if (abs(d) < reach) {
        float u = (d + reach) / (2.0 * reach);
        return vec3(x, -(26.0 + s * 4.0) * 4.0 * u * (1.0 - u), 0.0);
    }
    return vec3(x, -abs(sin(PI * 2.4 * t + float(i) * 1.3)) * (3.0 + s), 0.0);
}

vec3 scenery(vec2 p, float sw, float ground, float time) {
    vec3 color = SKY;
    float q = floor(p.x / 4.0) * 4.0 + 2.0;
    float far = max(max(48.0 - abs(q - sw * 0.19) * 0.9, 38.0 - abs(q - sw * 0.47) * 0.8), 56.0 - abs(q - sw * 0.78) * 0.85);
    float near = max(max(30.0 - abs(q - sw * 0.34) * 0.7, 26.0 - abs(q - sw * 0.94) * 0.7), 24.0 - abs(q - sw * 0.06) * 0.7);
    far = floor(max(far, 0.0) / 4.0) * 4.0;
    near = floor(max(near, 0.0) / 4.0) * 4.0;
    if (p.y >= ground - far) {
        color = MOUNTAIN;
    }
    if (p.y >= ground - near) {
        color = HILL;
    }
    vec2 sun = p - vec2(sw - 58.0, 34.0);
    if (dot(sun, sun) <= 72.0) {
        color = SUN;
    }
    for (int k = 0; k < 2; k++) {
        float cx = floor(mod((k == 0 ? 30.0 : 170.0) + time * (k == 0 ? 4.0 : 6.0), sw + 40.0)) - 40.0;
        float cy = k == 0 ? 22.0 : 50.0;
        if (box(p, cx + 6.0, cy, 14.0, 4.0) || box(p, cx, cy + 4.0, 28.0, 5.0)) {
            color = CLOUD;
        }
    }
    if (p.y >= ground) {
        color = p.y < ground + 2.0 ? EDGE : GROUND;
        if (p.y >= ground + 6.0 && hash(vec2(floor(p.x / 2.0), p.y)) > 0.985) {
            color = PEBBLE;
        }
    }
    return color;
}

vec3 llama(vec2 p, vec2 o, float s, bool air, vec3 color) {
    vec2 c = floor((p - o) / s);
    if (c.x < 0.0 || c.y < 0.0 || c.x > 11.0 || c.y > 11.0) {
        return color;
    }
    int row = int(c.y);
    int col = int(c.x);
    int body = LLAMA_BODY[row];
    int tips = LLAMA_TIPS[row];
    if (air && row == 10) {
        body = 0;
        tips = 330;
    }
    if (air && row == 11) {
        tips = 0;
    }
    if (row == 2 && col == 8) {
        return EYE;
    }
    if (bit(body, col)) {
        return BODY;
    }
    if (bit(tips, col)) {
        return TIP;
    }
    return color;
}

vec3 jetpack(vec2 p, vec2 o, float s, float flame, vec3 color) {
    vec2 c = floor((p - o) / s);
    if (c.x == 4.0 && c.y >= 7.0 && c.y <= 9.0) {
        color = STRAP;
    }
    if (c.x >= 2.0 && c.x <= 5.0 && c.y >= 4.0 && c.y <= 6.0) {
        color = (c.y == 4.0 && c.x >= 3.0 && c.x <= 4.0) ? PACK_LIGHT : PACK;
    }
    if (c.x == 1.0 && c.y == 5.0) {
        color = STRAP;
    }
    float dx = o.x + s - 1.0 - p.x;
    if (flame > 0.0 && dx >= 0.0 && dx < flame) {
        float inset = dx >= flame - 2.0 ? 1.0 : 0.0;
        if (p.y >= o.y + 5.0 * s - 1.0 + inset && p.y < o.y + 6.0 * s + 1.0 - inset) {
            color = dx < 2.0 ? FLAME_HOT : (dx < flame - 2.0 ? FLAME : FLAME_TIP);
        }
    }
    return color;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float px = max(1.0, floor(iResolution.y / 180.0));
    float sw = floor(iResolution.x / px);
    float sh = ceil(iResolution.y / px);
    float ground = sh - 34.0;
    vec2 p = vec2(floor(fragCoord.x / px), floor((iResolution.y - fragCoord.y) / px));
    vec2 pf = vec2(fragCoord.x, iResolution.y - fragCoord.y) / px;
    float cx = floor(sw * 0.5);
    float period = (sw + 116.0) / SPEED + 1.0;
    float t = mod(iTime, period);
    float t1 = stopTime(cx);
    vec3 color = scenery(p, sw, ground, iTime);
    for (int r = 0; r < 12; r++) {
        if (p.y == ground - 24.0 + float(r * 2) || p.y == ground - 23.0 + float(r * 2)) {
            if (p.x >= cx - 8.0 && p.x < cx + 8.0 && bit(CACTUS_ROWS[r], int(floor((p.x - cx + 8.0) / 2.0)))) {
                color = CACTUS;
            }
        }
    }
    for (int i = 3; i >= 0; i--) {
        float s = scale(i);
        vec3 at = pose(i, t, cx);
        vec2 o = vec2(at.x, ground - 12.0 * s + at.y);
        bool jet = i == 3 && t >= t1 + JET_ON;
        bool flying = jet && t >= t1 + JET_LIFT;
        if (flying) {
            for (int k = 1; k < 10; k++) {
                float tk = t - float(k) * 0.06;
                if (tk < t1 + JET_LIFT) {
                    break;
                }
                vec3 past = pose(3, tk, cx);
                float size = max(2.0, 7.0 - floor(float(k) / 2.0));
                vec2 puff = vec2(past.x + s - 10.0 - size * 0.5, ground - 12.0 * s + past.y + 5.5 * s - size * 0.5);
                if (box(pf, puff.x, puff.y, size, size)) {
                    color = SMOKE;
                }
            }
        }
        color = llama(pf, o, s, at.y < -3.0 || jet, color);
        if (jet) {
            float flame = t >= t1 + JET_ON + 0.2 ? 4.0 + mod(floor(iTime * 20.0), 3.0) + (flying ? 5.0 : 0.0) : 0.0;
            color = jetpack(pf, o, s, flame, color);
        }
        if (at.z > 0.5) {
            float bx = o.x + 9.0 * s;
            if (box(pf, bx, o.y - 14.0, 2.0, 6.0) || box(pf, bx, o.y - 6.0, 2.0, 2.0)) {
                color = BANG;
            }
        }
    }
    fragColor = vec4(color, 1.0);
}
