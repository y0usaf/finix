const vec3 PAL[12] = vec3[12](
    vec3(0.95, 0.80, 0.28),
    vec3(0.80, 0.16, 0.12),
    vec3(0.56, 0.22, 0.15),
    vec3(0.62, 0.29, 0.47),
    vec3(0.31, 0.42, 0.69),
    vec3(0.84, 0.20, 0.24),
    vec3(0.72, 0.58, 0.20),
    vec3(0.89, 0.86, 0.84),
    vec3(0.72, 0.64, 0.64),
    vec3(0.90, 0.45, 0.62),
    vec3(0.84, 0.76, 0.78),
    vec3(0.92, 0.62, 0.74)
);

const vec3 CONF[6] = vec3[6](
    vec3(0.95, 0.78, 0.20),
    vec3(0.98, 0.50, 0.15),
    vec3(0.92, 0.18, 0.15),
    vec3(0.30, 0.50, 0.98),
    vec3(0.95, 0.40, 0.70),
    vec3(0.60, 0.95, 0.40)
);

const vec3 SPC[4] = vec3[4](
    vec3(0.80, 0.30, 0.62),
    vec3(0.20, 0.38, 0.92),
    vec3(0.62, 0.30, 0.78),
    vec3(0.90, 0.40, 0.55)
);

float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

vec2 hash2(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.xx + q.yz) * q.zy);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float density(vec2 p) {
    float n = vnoise(vec2(p.x * 3.0, 1.7)) + 0.5 * vnoise(vec2(p.x * 9.0, 5.1));
    return smoothstep(0.88, 0.36, p.y + 0.25 * (n - 0.75));
}

float snow(vec2 p, float scale, float seed, float chance, float rad, float t) {
    vec2 q = p * scale;
    vec2 id = floor(q);
    if (hash(id * 1.3 + seed) > chance) return 0.0;
    vec2 c = 0.2 + 0.6 * hash2(id + seed);
    float r = length(fract(q) - c);
    float ph = hash(id + seed + 4.0);
    float tw = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * (0.8 + 2.0 * ph) + ph * 60.0));
    float rr = max(rad, 0.9 * scale / iResolution.y);
    return smoothstep(rr, rr * 0.3, r) * tw;
}

vec3 confetti(vec2 p, float scale, float seed, float t) {
    vec2 q = p * scale;
    vec2 id = floor(q);
    if (hash(id * 1.9 + seed) > 0.16) return vec3(0.0);
    vec2 hp = hash2(id + seed);
    vec2 c = 0.25 + 0.5 * hp + 0.1 * vec2(sin(t * 0.6 + hp.x * 30.0), cos(t * 0.5 + hp.y * 30.0));
    float r = length(fract(q) - c);
    float rad = 0.12 + 0.1 * hp.y;
    float soft = hp.x > 0.7 ? 0.5 : 0.25;
    float a = smoothstep(rad, rad * soft, r);
    float s = 0.6 + 0.4 * sin(t * 1.4 + hp.x * 50.0);
    return CONF[min(int(hash(id + seed + 8.0) * 6.0), 5)] * a * s;
}

vec4 dots(vec2 p, float scale, float seed, float chance, float top, float t) {
    vec2 q = p * scale;
    vec2 id = floor(q);
    float e = hash(id * 1.1 + seed);
    if (e > chance * smoothstep(top + 0.2, top - 0.2, p.y)) return vec4(0.0);
    vec2 hp = hash2(id + seed);
    vec2 c = 0.25 + 0.5 * hp + 0.08 * vec2(sin(t * 0.9 + hp.x * 30.0), cos(t * 0.7 + hp.y * 30.0));
    float r = length(fract(q) - c);
    float rad = 0.16 + 0.14 * hp.y;
    float a = smoothstep(rad, rad * 0.4, r);
    float hc = hash(id + seed + 2.0);
    vec3 f = hc < 0.35 ? vec3(0.3, 0.45, 0.95) : (hc < 0.55 ? vec3(0.95, 0.82, 0.3) : (hc < 0.75 ? vec3(0.95, 0.88, 0.9) : PAL[min(int(hc * 12.0), 11)]));
    f *= 0.55 + 0.6 * hp.x;
    return vec4(f * a, a);
}

vec4 leaves(vec2 p, float scale, float seed, float dens, float bright, float t) {
    if (dens <= 0.0) return vec4(0.0);
    vec2 q = p * scale;
    bool one = scale > 12.0;
    vec2 i0 = one ? floor(q) : floor(q) - 1.0 + step(0.5, fract(q));
    int span = one ? 0 : 1;
    float aa = 2.0 * scale / iResolution.y;
    vec3 pc = vec3(0.0);
    float cover = 0.0;
    for (int j = 0; j <= span; j++) {
        for (int i = 0; i <= span; i++) {
            vec2 id = i0 + vec2(float(i), float(j));
            float e = hash(id + seed * 3.1);
            if (e > dens) continue;
            vec2 hp = hash2(id + seed);
            vec2 c = id + 0.3 + 0.4 * hp;
            float hz = hash(id * 0.9 + seed + 7.7);
            float ang = (hp.x - 0.5) * 2.6 + 1.57 + 0.12 * sin(t * 0.7 + hz * 30.0 + c.x * 0.2);
            vec2 dir = vec2(cos(ang), sin(ang));
            vec2 d = q - c;
            float L = one ? 0.3 + 0.15 * hz : 0.35 + 0.35 * hz;
            float W = 0.12 + 0.12 * hp.y;
            float u = dot(d, dir) / L;
            if (abs(u) > 1.0) continue;
            float v = dot(d, vec2(-dir.y, dir.x));
            float w = W * pow(1.0 - u * u, 0.8);
            float edge = smoothstep(w, w - aa, abs(v));
            if (edge <= 0.0) continue;
            float k = hz * hz;
            vec3 f = mix(vec3(0.05, 0.085, 0.045), vec3(0.28, 0.33, 0.17), k) * bright;
            f *= 0.75 + 0.5 * smoothstep(-w, w, v);
            f *= 1.0 - 0.35 * smoothstep(0.03, 0.0, abs(v));
            f += vec3(0.1, 0.13, 0.08) * smoothstep(w * 0.7, w, abs(v)) * k;
            pc = pc * (1.0 - edge) + f * edge;
            cover += edge * (1.0 - cover);
        }
    }
    return vec4(pc, cover);
}

vec4 stems(vec2 p, float cols, float seed, float top, float bright, float t) {
    float q = p.x * cols;
    float i0 = floor(q);
    float px = cols / iResolution.y;
    vec3 pc = vec3(0.0);
    float cover = 0.0;
    for (int k = -1; k <= 1; k++) {
        float id = i0 + float(k);
        vec2 r = hash2(vec2(id, seed));
        if (r.x > 0.75) continue;
        float hz = hash(vec2(id, seed + 5.0));
        float h = top * (0.2 + 0.8 * hz * hz);
        if (p.y > h + 0.03) continue;
        float u = p.y / h;
        float cx = id + 0.2 + 0.6 * r.y + (r.y - 0.5) * 1.6 * u * u + 0.25 * sin(t * 0.8 + id * 3.0 + u * 2.0) * u * u;
        float d = abs(q - cx);
        float wd = max(px * (1.0 - 0.5 * u), 0.02) * 1.3;
        float line = smoothstep(wd, wd * 0.3, d) * step(p.y, h);
        vec3 f = mix(vec3(0.10, 0.15, 0.07), vec3(0.32, 0.38, 0.2), hz) * bright;
        float a = line;
        pc = pc * (1.0 - a) + f * a;
        cover += a * (1.0 - cover);
        vec2 bd = vec2(q - cx, (p.y - h) * cols);
        float br = 0.14 + 0.1 * r.y;
        float bud = smoothstep(br, br * 0.6, length(bd * vec2(1.0, 0.7)));
        vec3 bc = r.x < 0.3 ? PAL[min(int(hz * 12.0), 11)] : vec3(0.3, 0.38, 0.2);
        bc *= bright * (0.7 + 0.5 * smoothstep(-br, br, bd.x));
        pc = pc * (1.0 - bud) + bc * bud;
        cover += bud * (1.0 - cover);
    }
    return vec4(pc, cover);
}

vec4 blooms(vec2 p, float scale, float seed, float top, float dens, float haze, float t) {
    if (p.y > top + 0.3 + 1.0 / scale) return vec4(0.0);
    vec2 q = p * scale;
    bool one = scale > 12.0;
    vec2 i0 = one ? floor(q) : floor(q) - 1.0 + step(0.5, fract(q));
    int span = one ? 0 : 1;
    float aa = 5.0 * scale / iResolution.y;
    vec3 pc = vec3(0.0);
    float cover = 0.0;
    float bestZ = -1.0;
    for (int j = 0; j <= span; j++) {
        for (int i = 0; i <= span; i++) {
            vec2 id = i0 + vec2(float(i), float(j));
            float e = hash(id + seed * 3.1);
            float need = dens * smoothstep(top + 0.22, top - 0.3, (id.y + 0.5) / scale);
            if (e > need) continue;
            vec2 hp = hash2(id + seed);
            vec2 c = id + (one ? 0.3 : 0.35) + (one ? 0.4 : 0.3) * hp;
            float hz = hash(id * 0.9 + seed + 7.7);
            float hk = hash(id.yx * 1.9 + seed + 5.0);
            float hc0 = hash(id * 0.63 + seed + 31.0);
            c += 0.07 * vec2(sin(t * 0.8 + hz * 6.283 + c.y * 0.6), cos(t * 0.6 + hp.x * 6.283));
            c.x += 0.08 * sin(t * 0.7 + c.x * 0.35 + c.y * 0.5);
            float rad = (0.2 + 0.4 * hz * hz) * (hk > 0.75 ? 1.25 : (hk > 0.5 ? 0.8 : 1.0));
            if (one) rad = min(rad, 0.36);
            vec2 d = q - c;
            float len2 = dot(d, d);
            if (len2 > rad * rad * 1.05) continue;
            float n = hk < 0.5 ? 5.0 + floor(hz * 4.0) : (hk < 0.75 ? 9.0 : 6.0);
            float sharp = hk < 0.5 ? 0.45 : (hk < 0.75 ? 0.35 : 0.8);
            float floorR = hk < 0.5 ? 0.6 : (hk < 0.75 ? 0.78 : 0.5);
            float a = atan(d.y, d.x) + t * 0.15 * (hz - 0.5) + hp.y * 6.283;
            float pl = 0.78 + 0.3 * hash(vec2(mod(floor(a * n / 6.28318 + 0.5), n), id.x + id.y * 31.0 + seed));
            float lobe = 0.5 + 0.5 * cos(n * a);
            float rr = rad * mix(floorR, 1.0, pow(lobe, sharp)) * pl * (one ? 1.0 : 0.96 + 0.08 * vnoise(vec2(a * 3.0, hc0)));
            float len = sqrt(len2);
            float edge = smoothstep(rr, rr - aa, len);
            if (edge <= 0.0) continue;
            float hc = hc0;
            vec3 base = PAL[min(int(hc * 12.0), 11)];
            vec3 heart = hk < 0.5 ? vec3(0.95, 0.75, 0.2) : base * 0.6;
            float veins = 0.5 + 0.5 * cos(n * 2.0 * a + 3.0 * len);
            float rim = smoothstep(rr * 0.6, rr, len);
            vec3 f = base * (0.5 + 0.55 * lobe) * (0.85 + 0.2 * veins);
            f += base * 0.45 * rim + 0.08 * rim;
            f = mix(f, heart, smoothstep(rad * 0.25, rad * 0.12, len));
            f = mix(f, f * 0.55 + 0.35 * vec3(0.9, 0.85, 0.88), 0.45 * smoothstep(rr * 0.55, rr, len) * step(0.7, hz));
            f *= (0.9 + 0.2 * sin(t * 1.3 + hc * 40.0)) * (one ? 1.0 : 0.65 + 0.7 * vnoise(d * 16.0 + hc * 50.0));
            f = mix(f * 1.3, vec3(0.02, 0.05, 0.06), haze);
            float al = edge * (0.7 + 0.25 * smoothstep(0.0, rr, len));
            if (hz > bestZ) {
                pc = pc * (1.0 - al) + f * al;
                bestZ = hz;
            } else {
                pc += f * al * (1.0 - cover);
            }
            cover += al * (1.0 - cover);
        }
    }
    return vec4(pc, cover);
}

vec4 spikes(vec2 p, float cols, float seed, float top, float dens, float bright, float t) {
    if (p.y > top + 0.02) return vec4(0.0);
    float q = p.x * cols;
    float i0 = floor(q);
    float aa = 2.0 * cols / iResolution.y;
    vec3 pc = vec3(0.0);
    float cover = 0.0;
    for (int k = -1; k <= 1; k++) {
        float id = i0 + float(k);
        vec2 r = hash2(vec2(id, seed));
        if (r.x > dens) continue;
        float tip = top * (0.5 + 0.5 * hash(vec2(id, seed + 3.0)));
        if (p.y > tip + 0.01) continue;
        float h = clamp(p.y / tip, 0.0, 1.0);
        float cx = id + 0.2 + 0.6 * r.y;
        cx += (0.3 * sin(t * 0.8 + id * 5.3) + 0.15 * sin(t * 1.9 + id * 2.1 + p.y * 5.0)) * h * h;
        float d = q - cx;
        float y0 = tip * 0.4;
        float up = step(y0, p.y);
        float u = clamp((p.y - y0) / (tip - y0), 0.0, 1.0);
        float rag = 0.55 + 0.9 * vnoise(vec2(id * 5.0 + seed, p.y * cols * 9.0)) + 0.25 * sin(d * 9.0 + p.y * 40.0);
        float hw = (0.36 * sin(3.14159 * pow(u, 0.6)) + 0.04) * rag * (r.y > 0.5 ? 1.0 : 0.7);
        float body = smoothstep(hw, hw - aa, abs(d)) * up;
        float stem = smoothstep(0.03, 0.01, abs(d)) * (1.0 - up);
        if (body + stem <= 0.0) continue;
        vec2 lp = vec2(d, p.y * cols) * 11.0;
        vec2 fid = floor(lp) + id * 13.0;
        vec2 fc = fract(lp) - (0.3 + 0.4 * hash2(fid));
        float fh = hash(fid + 3.0);
        float fl = smoothstep(0.3 + 0.1 * fh, 0.08, length(fc));
        vec3 sc = SPC[min(int(hash(vec2(id, seed + 9.0)) * 4.0), 3)];
        vec3 f = sc * (0.6 + 0.8 * fh) * (0.5 + 0.5 * fl) * (0.8 + 0.5 * u) * bright;
        float ab = body * mix(0.7, 1.0, fl);
        float a = max(ab, stem);
        pc = pc * (1.0 - a) + f * ab + vec3(0.08, 0.13, 0.06) * stem * bright;
        cover += a * (1.0 - cover);
    }
    return vec4(pc, cover);
}

vec4 bursts(vec2 p, float scale, float seed, float lo, float hi, float t) {
    if (p.y < lo - 0.15 || p.y > hi + 0.15) return vec4(0.0);
    vec2 q = p * scale;
    vec2 i0 = floor(q) - 1.0 + step(0.5, fract(q));
    float px = scale / iResolution.y;
    vec3 pc = vec3(0.0);
    float cover = 0.0;
    for (int j = 0; j <= 1; j++) {
        for (int i = 0; i <= 1; i++) {
            vec2 id = i0 + vec2(float(i), float(j));
            if (hash(id + seed) > 0.18) continue;
            vec2 hp = hash2(id + seed * 2.0);
            vec2 c = id + 0.35 + 0.3 * hp;
            if (c.y / scale < lo || c.y / scale > hi) continue;
            vec2 d = q - c;
            float R = 0.55 + 0.1 * hp.x;
            float r = length(d);
            if (r > R) continue;
            float n = 22.0;
            float a = (atan(d.y, d.x) + 0.15 * sin(t * 0.5 + hp.y * 20.0)) * n / 6.28318 + 0.5;
            float k = floor(a);
            float da = abs(fract(a) - 0.5) * 6.28318 / n * r;
            float Lk = R * (0.55 + 0.45 * hash(vec2(k, id.x + id.y * 7.0)));
            float wd = max(0.03 * (1.0 - r / Lk), px) + px;
            float s = smoothstep(wd, wd * 0.2, da) * step(r, Lk);
            float core = smoothstep(0.1, 0.03, r);
            float al = max(s, core);
            vec3 f = mix(vec3(0.015, 0.04, 0.05), vec3(0.14, 0.32, 0.38), pow(r / Lk, 1.5)) * (1.0 + 0.5 * core);
            pc = pc * (1.0 - al) + f * al;
            cover += al * (1.0 - cover);
        }
    }
    return vec4(pc, cover);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float t = iTime;
    vec2 p = fragCoord / iResolution.y;
    p.x -= 0.5 * iResolution.x / iResolution.y;

    vec3 col = mix(vec3(0.003, 0.007, 0.012), vec3(0.016, 0.026, 0.03), smoothstep(0.9, 0.35, p.y));
    col += 0.008 * (hash(floor(fragCoord * 0.6)) + hash(floor(fragCoord * 0.6) + 17.0));
    col += vec3(0.85, 0.9, 0.95) * 1.2 * snow(p, 130.0, 1.0, 0.3, 0.32, t);
    col += vec3(1.0) * 1.4 * snow(p, 70.0, 5.0, 0.22, 0.3, t);

    float fd = density(p);
    float mott = vnoise(p * 16.0 + 0.05 * t);
    float streak = vnoise(vec2(p.x * 70.0 + sin(t * 0.7 + p.y * 6.0) * p.y * 2.0, p.y * 5.0));
    vec3 ground = mix(vec3(0.035, 0.055, 0.03), vec3(0.1, 0.14, 0.07), mott * streak);
    vec3 hue = 0.5 + 0.5 * cos(6.28318 * (mott * 1.7 + streak * 0.6 + vec3(0.0, 0.33, 0.67)));
    ground += hue * hue * 0.2 * smoothstep(0.35, 0.7, mott) * smoothstep(0.2, 0.6, streak);
    col = mix(col, ground, fd * fd);

    vec2 pw = p + 0.03 * (vec2(vnoise(p * 6.0 + 3.0), vnoise(p * 6.0 + 9.0)) - 0.5);
    vec4 b = bursts(p, 6.0, 3.0, 0.4, 0.8, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = spikes(p, 9.0, 7.0, 0.9, 0.35, 0.6, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = leaves(pw, 15.0, 8.0, fd, 1.2, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = stems(p, 9.0, 9.0, 0.78, 0.9, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = blooms(pw, 20.0, 10.0, 0.66, 1.0, 0.3, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = dots(pw, 70.0, 41.0, 0.8, 0.66, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = spikes(p, 6.0, 11.0, 0.82, 0.35, 1.3, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = leaves(pw, 8.0, 12.0, fd, 1.4, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = blooms(pw, 9.0, 13.0, 0.58, 0.9, 0.0, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = dots(pw, 45.0, 43.0, 0.5, 0.5, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = blooms(pw, 5.0, 15.0, 0.48, 0.7, 0.0, t);
    col = col * (1.0 - b.a) + b.rgb;
    b = blooms(pw, 3.3, 17.0, 0.34, 0.4, 0.0, t);
    col = col * (1.0 - b.a) + b.rgb;

    col += 0.55 * vec3(0.9, 0.95, 1.0) * snow(p, 120.0, 21.0, 0.12, 0.3, t);
    col += confetti(p, 34.0, 31.0, t);

    vec2 vc = fragCoord / iResolution.xy - 0.5;
    col *= 1.0 - 0.5 * dot(vc, vc);
    col += (hash(fragCoord) - 0.5) / 255.0;
    fragColor = vec4(col, 1.0);
}
