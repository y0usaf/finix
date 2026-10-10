const float PI = 3.14159265;
const float TW = 1.25;

const vec4 H[24] = vec4[24](
    vec4(820.0, 480.0, 95.0, 0.0),
    vec4(485.0, 485.0, 44.0, 1.0),
    vec4(108.0, 372.0, 40.0, 10.0),
    vec4(826.0, 150.0, 22.0, 6.0),
    vec4(470.0, 355.0, 42.0, 7.0),
    vec4(600.0, 355.0, 42.0, 7.0),
    vec4(670.0, 295.0, 34.0, 7.0),
    vec4(718.0, 408.0, 42.0, 0.0),
    vec4(555.0, 542.0, 36.0, 4.0),
    vec4(600.0, 625.0, 42.0, 5.0),
    vec4(650.0, 662.0, 36.0, 5.0),
    vec4(550.0, 668.0, 30.0, 5.0),
    vec4(840.0, 650.0, 58.0, 9.0),
    vec4(150.0, 600.0, 33.0, 3.0),
    vec4(245.0, 630.0, 34.0, 3.0),
    vec4(300.0, 578.0, 36.0, 8.0),
    vec4(350.0, 605.0, 32.0, 4.0),
    vec4(415.0, 648.0, 30.0, 4.0),
    vec4(695.0, 715.0, 70.0, 2.0),
    vec4(950.0, 730.0, 56.0, 2.0),
    vec4(390.0, 745.0, 48.0, 2.0),
    vec4(25.0, 725.0, 44.0, 2.0),
    vec4(190.0, 740.0, 36.0, 3.0),
    vec4(905.0, 505.0, 34.0, 5.0)
);

const vec3 CONF[6] = vec3[6](
    vec3(0.95, 0.78, 0.20),
    vec3(0.98, 0.50, 0.15),
    vec3(0.92, 0.18, 0.15),
    vec3(0.30, 0.50, 0.98),
    vec3(0.95, 0.40, 0.70),
    vec3(0.95, 0.9, 0.4)
);

float F;
float AA;
float PX;
float BR;

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

float hf(vec2 id, float s) {
    return hash(id + vec2(s * 7.31, F * 31.7 + s * 1.7));
}

vec2 hf2(vec2 id, float s) {
    return hash2(id + vec2(s * 7.31, F * 31.7 + s * 1.7));
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec3 film(float t) {
    vec3 w = abs(fract(t + vec3(0.0, 0.33, 0.67)) * 2.0 - 1.0);
    return w * w * (3.0 - 2.0 * w);
}

vec3 hsv(float h, float s, float v) {
    vec3 k = clamp(abs(fract(h + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    return v * mix(vec3(1.0), k, s);
}

float topEdge(float x) {
    return 0.55 + 0.1 * vnoise(vec2(x * 3.0, 3.3)) + 0.06 * vnoise(vec2(x * 11.0, 8.1)) - 0.06 * exp(-pow((x - 0.25) * 6.0, 2.0));
}

vec3 foliage(vec2 p) {
    vec2 q = p + hash2(vec2(F, 7.0)) * 40.0;
    float n1 = vnoise(q * vec2(90.0, 30.0));
    float n2 = vnoise(q * vec2(220.0, 90.0));
    float n3 = vnoise(q * 7.0);
    vec3 g = mix(vec3(0.008, 0.03, 0.02), vec3(0.05, 0.18, 0.08), smoothstep(0.3, 0.8, n1 * 0.6 + n3 * 0.5));
    g = mix(g, vec3(0.02, 0.12, 0.11), smoothstep(0.55, 0.9, n3) * 0.5);
    g = mix(g, vec3(0.1, 0.26, 0.08), smoothstep(0.7, 0.95, n2) * 0.45);
    return g;
}

void petals(inout vec3 col, vec2 d, float R, float n, float q, float k0, float rot, vec3 base, float fm, float amax, vec2 sid) {
    float r = length(d);
    if (r > R + AA) return;
    float an = (atan(d.y, d.x) + rot) * n / 6.2832;
    float pn = floor(an);
    float u = an - pn - 0.5;
    float len = k0 + (1.0 - k0) * pow(max(cos(PI * u), 0.0), q);
    float e = R * len - r;
    float m = smoothstep(-AA, AA, e);
    if (m <= 0.0) return;
    float rho = r / R;
    float ph = hash(vec2(pn, sid.x * 0.37 + sid.y * 0.91 + R * 91.0));
    vec3 fl = 0.65 * film(rho * 0.8 + ph * 0.6 + hf(sid, 5.0) + F * 0.07);
    vec3 pc = mix(base * (0.55 + 0.55 * ph), fl, fm * (0.3 + 0.7 * rho) * (0.5 + ph));
    pc *= 0.55 + 0.6 * smoothstep(0.0, 0.8, rho);
    float vein = smoothstep(0.06, 0.0, abs(u)) * 0.18 * (1.0 - rho);
    float rim = smoothstep(R * 0.1, 0.0, e);
    pc += rim * 0.45 + vein;
    col = mix(col, pc * BR, m * (amax + 0.3 * rim));
}

void stamens(inout vec3 col, vec2 d, float R, vec3 c, vec2 sid) {
    float r = length(d);
    if (r > R * 0.5) return;
    float k = 14.0;
    float an = atan(d.y, d.x) * k / 6.2832;
    float pn = floor(an + 0.5);
    float ang = pn * 6.2832 / k;
    float rr = R * (0.2 + 0.1 * hash(vec2(pn, sid.x)));
    vec2 sp = rr * vec2(cos(ang), sin(ang));
    float dd = length(d - sp);
    float a = smoothstep(R * 0.045 + AA, R * 0.02, dd);
    col = mix(col, c * BR, a);
}

void stem(inout vec3 col, vec2 d, float R, float len, vec2 sid) {
    if (d.y > 0.0 || d.y < -len) return;
    float sw = 0.0025 + R * 0.025;
    float x = d.x - 0.02 * sin(d.y * 7.0 + 6.0 * hash(sid));
    float a = smoothstep(sw + AA, sw - AA, abs(x));
    col = mix(col, vec3(0.07, 0.3, 0.1) * (0.8 + 0.5 * hash(sid + 1.0)), a * 0.9);
}

void bloom(inout vec3 col, vec2 d, float R, float ty, vec2 sid) {
    bool pk = ty > 9.5;
    if (pk) ty = 1.0;
    float r = length(d);
    float rot = 6.2832 * hf(sid, 6.0);
    float h1 = hash(sid + 1.7);
    float hj = hf(sid, 8.0);
    if (ty < 0.5) {
        petals(col, d, R, 8.0, 0.8, 0.3, rot, hsv(0.97 + 0.03 * hj, 0.8, 0.75), 0.25, 0.85, sid);
        petals(col, d, R * 0.7, 7.0, 0.8, 0.3, rot + 0.4, hsv(0.78 + 0.08 * hj, 0.45, 0.95), 0.25, 0.75, sid + 3.0);
        petals(col, d, R * 0.4, 6.0, 1.2, 0.2, rot + 0.9, vec3(0.9, 0.5, 0.9), 0.3, 0.8, sid + 6.0);
        col = mix(col, vec3(1.0, 0.8, 0.3) * BR, smoothstep(R * 0.08 + AA, R * 0.08 - AA, r));
    } else if (ty < 1.5) {
        float hh = R * 1.2;
        vec3 lo = mix(vec3(0.9, 0.12, 0.05), hsv(0.9 + 0.08 * hj, 0.7, 0.75), pk ? 1.0 : 0.0);
        vec3 hi = mix(vec3(1.0, 0.6, 0.15), hsv(0.93, 0.35, 1.0), pk ? 1.0 : 0.0);
        for (int k = 0; k < 3; k++) {
            float ox = (float(k) - 1.0) * R * 0.5;
            float tk = (d.y + 0.3 * R) / (hh * (k == 1 ? 1.0 : 0.85));
            if (tk < -1.0 || tk > 1.0) continue;
            float lean = (float(k) - 1.0) * 0.35 * R * max(tk, 0.0);
            float w = R * (k == 1 ? 0.62 : 0.52) * (1.0 - pow(abs(tk), 1.8));
            float dist = w - abs(d.x - ox - lean);
            float m = smoothstep(-AA, AA, dist);
            float g = smoothstep(-1.0, 1.0, tk);
            vec3 tc = mix(lo, hi, g * (0.6 + 0.4 * float(k == 1)));
            tc = mix(tc, film(tk * 0.4 + h1 + F * 0.07) * 0.8, 0.22);
            tc *= 0.6 + 0.5 * smoothstep(w * 0.9, 0.0, abs(d.x - ox - lean));
            tc += smoothstep(R * 0.08, 0.0, dist) * 0.4;
            col = mix(col, tc * BR, m * 0.88);
        }
    } else if (ty < 2.5) {
        vec3 base = mix(vec3(0.95, 0.93, 1.05), vec3(1.15, 0.85, 0.95), step(0.7, h1));
        petals(col, d, R, 5.0 + floor(2.0 * hj), 0.7, 0.3, rot, base, 0.3, 0.62, sid);
        petals(col, d, R * 0.62, 6.0, 0.9, 0.3, rot + 0.5, base * vec3(0.9, 0.95, 1.0), 0.35, 0.5, sid + 5.0);
        col = mix(col, vec3(1.0, 0.75, 0.2) * BR, smoothstep(R * 0.16 + AA, R * 0.12, r) * 0.9);
        stamens(col, d, R, vec3(1.0, 0.85, 0.4), sid);
    } else if (ty < 3.5) {
        vec3 base = hsv(0.9 + 0.07 * h1, 0.5, 0.95);
        petals(col, d, R, 8.0 + floor(3.0 * hj), 0.8, 0.25, rot, base, 0.55, 0.7, sid);
        petals(col, d, R * 0.55, 7.0, 0.8, 0.3, rot + 0.4, base * 1.1, 0.5, 0.6, sid + 4.0);
        col = mix(col, vec3(1.0, 0.85, 0.25) * BR, smoothstep(R * 0.12 + AA, R * 0.1 - AA, r));
    } else if (ty < 4.5) {
        petals(col, d, R, 6.0 + floor(3.0 * hj), 0.8, 0.35, rot, hsv(0.15 + 0.02 * h1, 0.85, 1.0), 0.3, 0.72, sid);
        col = mix(col, vec3(0.9, 0.45, 0.1) * BR, smoothstep(R * 0.22 + AA, R * 0.2 - AA, r));
    } else if (ty < 5.5) {
        petals(col, d, R, 9.0, 1.2, 0.35, rot, hsv(0.99, 0.9, 0.6), 0.25, 0.8, sid);
        petals(col, d, R * 0.7, 8.0, 1.2, 0.35, rot + 0.3, hsv(0.0, 0.95, 0.75), 0.25, 0.8, sid + 2.0);
        petals(col, d, R * 0.4, 7.0, 1.2, 0.35, rot + 0.7, hsv(0.02, 0.9, 0.9), 0.3, 0.85, sid + 4.0);
    } else if (ty < 6.5) {
        vec2 e = vec2(d.x, d.y);
        float t = e.y / (R * 1.6);
        if (t > -1.0 && t < 1.0) {
            float w = R * 0.8 * sqrt(max(1.0 - t * t, 0.0)) * (1.0 + 0.4 * t);
            float m = smoothstep(-AA, AA, w * (1.0 - 0.0) - abs(e.x) - (t > 0.0 ? t * R * 0.6 : 0.0));
            vec3 bc = mix(vec3(0.15, 0.5, 0.15), vec3(0.85, 0.2, 0.2), smoothstep(-0.3, 0.9, t));
            col = mix(col, bc * BR, m * 0.9);
        }
    } else if (ty < 7.5) {
        float an = atan(d.y, d.x);
        float sp = abs(fract(an * 40.0 / 6.2832 + 0.5 * hash(vec2(floor(an * 40.0 / 6.2832), sid.x))) - 0.5) * 2.0;
        float ext = R * (0.9 + 0.5 * hash(vec2(floor(an * 40.0 / 6.2832), sid.y)));
        float edge = ext - r;
        float w = (1.0 - r / ext) * 0.9;
        float m = step(sp, w) * smoothstep(-AA, AA, edge);
        vec3 sc = mix(vec3(0.03, 0.12, 0.16), vec3(0.5, 0.75, 0.95), smoothstep(0.3, 1.0, r / ext));
        col = mix(col, sc * BR, m * 0.9);
        col = mix(col, vec3(0.02, 0.07, 0.08), smoothstep(R * 0.4 + AA, R * 0.4 - AA, r) * 0.95);
    } else if (ty < 8.5) {
        petals(col, d, R, 7.0, 0.9, 0.3, rot, hsv(0.78 + 0.05 * h1, 0.45, 0.85), 0.5, 0.7, sid);
        petals(col, d, R * 0.5, 6.0, 0.9, 0.3, rot + 0.5, hsv(0.85, 0.5, 0.95), 0.4, 0.6, sid + 4.0);
        col = mix(col, vec3(0.95, 0.8, 0.3) * BR, smoothstep(R * 0.1 + AA, R * 0.08 - AA, r));
    } else {
        petals(col, d, R, 11.0, 1.0, 0.45, rot, hsv(0.97, 0.8, 0.7), 0.3, 0.85, sid);
        petals(col, d, R * 0.7, 9.0, 1.0, 0.45, rot + 0.3, hsv(0.02, 0.8, 0.9), 0.3, 0.8, sid + 2.0);
        petals(col, d, R * 0.4, 8.0, 1.0, 0.45, rot + 0.6, hsv(0.95, 0.5, 1.0), 0.3, 0.8, sid + 4.0);
    }
}

void heroes(inout vec3 col, vec2 p, float tile, int i0, int i1) {
    float mir = mod(tile, 2.0);
    float lx = p.x - tile * TW;
    if (mir > 0.5) lx = TW - lx;
    for (int i = i0; i < i1; i++) {
        vec4 h = H[i];
        float ty = h.w;
        vec2 c0 = vec2(h.x, 800.0 - h.y) / 800.0;
        float lim = h.z / 800.0 * 1.5 + 0.04;
        bool st = ty == 1.0 || ty == 10.0 || ty == 6.0;
        if (abs(lx - c0.x) > lim) continue;
        if (st ? p.y > c0.y + lim : abs(p.y - c0.y) > lim) continue;
        vec2 sid = vec2(float(i) * 3.7, tile * 5.1 + 1.0);
        vec2 c = c0 + (hf2(sid, 1.0) - 0.5) * 0.05;
        float R = h.z / 800.0 * (1.0 + 0.25 * (hf(sid, 2.0) - 0.5));
        vec2 d = vec2(lx, p.y) - c;
        if (mir > 0.5) d.x = -d.x;
        if (st) stem(col, d, R, c.y, sid);
        if (length(d) > R * 1.3 + 0.02) continue;
        BR = 1.0;
        bloom(col, d, R, ty, sid);
    }
}

void heroesAll(inout vec3 col, vec2 p, float tile, int i0, int i1) {
    float fx = fract(p.x / TW);
    if (fx < 0.2) heroes(col, p, tile - 1.0, i0, i1);
    if (fx > 0.8) heroes(col, p, tile + 1.0, i0, i1);
    heroes(col, p, tile, i0, i1);
}

void plumePass(inout vec3 col, vec2 p, float ax, float w, float ds, float hue, float off, vec2 sid) {
    float dx = p.x - ax;
    vec2 q = vec2(dx, p.y) + off * ds;
    vec2 gid = floor(q / ds);
    vec2 cc = (gid + 0.3 + 0.4 * hf2(gid + sid, 4.0)) * ds - off * ds;
    float rr = ds * 0.3 * (0.6 + 0.8 * hf(gid + sid, 5.0));
    float inside = step(abs(cc.x), w) * step(hf(gid + sid, 6.0), 0.92);
    float dd = length(vec2(dx, p.y) - cc);
    float a = smoothstep(rr + AA, rr - AA, dd) * inside;
    float h = hash(gid + sid);
    vec3 dc = hsv(hue + 0.05 * (hf(gid + sid, 7.0) - 0.5), 0.65 + 0.3 * hf(gid + sid, 10.0), 0.5 + 0.5 * hf(gid + sid, 8.0));
    dc = mix(dc, vec3(1.0, 0.9, 0.95), step(0.92, h) * 0.6);
    col = mix(col, dc, a);
}

void plume(inout vec3 col, vec2 p, vec2 b, vec2 t, float W, float hue, float sp, vec2 sid) {
    float y = (p.y - b.y) / (t.y - b.y);
    if (y < 0.0 || y > 1.0) return;
    AA = PX * 1.5;
    float ax = mix(b.x, t.x, y);
    float w = W * pow(1.0 - y, 0.8) * (0.8 + 0.4 * vnoise(vec2(p.y * 25.0, sid.x + F * 3.1)));
    if (abs(p.x - ax) > w + 0.012) return;
    col *= mix(1.0, 0.6, step(abs(p.x - ax), w));
    plumePass(col, p, ax, w, 0.0075 * sp, hue, 0.0, sid);
    plumePass(col, p, ax, w, 0.0056 * sp, hue + 0.03, 0.37, sid + 9.0);
}

vec3 tinyColor(float h, vec2 sid, out vec3 cen) {
    cen = vec3(1.0, 0.8, 0.25);
    float j = hf(sid, 14.0);
    if (h < 0.1) {
        return hsv(0.6 + 0.06 * j, 0.75, 0.9);
    } else if (h < 0.22) {
        cen = vec3(1.0, 0.7, 0.2);
        return vec3(0.95, 0.93, 0.88);
    } else if (h < 0.48) {
        cen = vec3(0.9, 0.4, 0.1);
        return hsv(0.145 + 0.025 * j, 0.9, 1.0);
    } else if (h < 0.58) {
        return hsv(0.9 + 0.07 * j, 0.55, 0.9);
    } else if (h < 0.69) {
        cen = vec3(0.3, 0.1, 0.05);
        return hsv(0.99 + 0.02 * j, 0.95, 0.75);
    } else if (h < 0.94) {
        return hsv(0.08 + 0.03 * j, 0.9, 1.0);
    }
    return hsv(0.76 + 0.08 * j, 0.55, 0.9);
}

void crowd(inout vec3 col, vec2 p, float c, float y0, float y1, float L, float dens, float br, float sz, float soft, float fix) {
    BR = br;
    AA = PX * soft;
    if (p.y < y0 - c || p.y > y1 + c) return;
    vec2 cell = floor(p / c - 0.5);
    for (int j = 1; j >= 0; j--) {
        for (int i = 0; i <= 1; i++) {
            vec2 id = cell + vec2(float(i), float(j));
            float cy = (id.y + 0.5) * c;
            if (cy < y0 || cy > y1) continue;
            vec2 sid = id + L * 113.0;
            float h0 = hash(sid);
            float pop = step(0.97, hf(sid, 9.0));
            if (h0 > dens && pop < 0.5) continue;
            float cx = (id.x + 0.5) * c;
            float lim = topEdge(cx) + 0.14;
            float pr = dens * (1.0 - smoothstep(lim - 0.2, lim + 0.02, cy)) * smoothstep(0.1, 0.4, vnoise(vec2(cx, cy) * 7.0 + L * 17.0));
            if (h0 > pr && pop < 0.5) continue;
            vec2 off = 0.06 + 0.88 * mix(hash2(sid + 3.1), vec2(hf(sid, 1.0), hf(sid, 2.0)), 0.8);
            vec2 d = p - (id + off) * c;
            float rs = hash(sid + 7.7);
            float R = c * sz * mix(0.2, 1.0, rs * rs * rs) * (1.0 + 0.3 * (hf(sid, 3.0) - 0.5));
            float r = length(d);
            if (r > R * 1.1) continue;
            float pn = smoothstep(0.25, 0.75, vnoise(vec2(cx, cy) * 3.5 + L * 9.0));
            float tp = fix >= 0.0 ? fix : clamp(pn + (hash(sid + 9.9) - 0.5) * 0.3, 0.0, 0.999);
            vec3 cen;
            vec3 base = tinyColor(tp, sid, cen);
            float rot = 6.2832 * hf(sid, 6.0);
            if (R * iResolution.y < 4.0) {
                float m = smoothstep(R + AA, R - AA, r);
                col = mix(col, base * br * (0.7 + 0.5 * hash(sid + 2.0)), m * 0.9);
            } else {
                if (R * iResolution.y > 14.0 && hash(sid + 4.4) < 0.5) {
                    vec2 sd = d + vec2(0.0, R * 0.2);
                    stem(col, sd, R, c * 2.5, sid);
                }
                if (fix >= 0.0) {
                    petals(col, d, R, 9.0, 0.9, 0.4, rot, base, 0.1, 0.85, sid);
                    col = mix(col, vec3(1.0, 0.75, 0.2) * br, smoothstep(R * 0.26 + AA, R * 0.22 - AA, r));
                } else {
                    petals(col, d, R, 5.0, 0.7, 0.45, rot, base, 0.25, 0.7, sid);
                    col = mix(col, cen * br, smoothstep(R * 0.2 + AA, R * 0.16 - AA, r) * 0.9);
                }
            }
        }
    }
}

void leaves(inout vec3 col, vec2 p, float c, float y0, float y1, float L, float amt, float soft, float wid) {
    AA = PX * soft;
    if (p.y < y0 - c || p.y > y1 + c) return;
    vec2 cell = floor(p / c - 0.5);
    for (int j = 1; j >= 0; j--) {
        for (int i = 0; i <= 1; i++) {
            vec2 id = cell + vec2(float(i), float(j));
            vec2 sid = id + L * 71.0;
            if (hash(sid) > amt) continue;
            vec2 off = 0.25 + 0.5 * mix(hash2(sid + 3.1), hf2(sid, 1.0), 0.7);
            if ((id.y + off.y) * c > topEdge((id.x + off.x) * c) + 0.05) continue;
            vec2 d = p - (id + off) * c;
            float th = 6.2832 * hf(sid, 2.0);
            vec2 e = vec2(cos(th) * d.x + sin(th) * d.y, -sin(th) * d.x + cos(th) * d.y);
            float Ln = c * mix(0.35, 0.72, hash(sid + 1.0));
            float Wd = Ln * mix(0.08, 0.22, hash(sid + 2.0)) * wid;
            float t = e.x / Ln;
            float w = Wd * max(1.0 - t * t, 0.0) * (1.0 - 0.3 * t);
            float dist = w - abs(e.y);
            if (abs(t) > 1.0 || dist < -AA) continue;
            float m = smoothstep(-AA, AA, dist);
            vec3 lc = mix(vec3(0.02, 0.1, 0.05), vec3(0.16, 0.36, 0.1), hash(sid + 3.0));
            lc = mix(lc, vec3(0.04, 0.3, 0.28), step(0.8, hash(sid + 4.0)));
            lc *= 0.6 + 0.6 * smoothstep(0.0, 1.0, abs(e.y) / max(w, 1e-4));
            lc += 0.15 * smoothstep(AA * 1.5, 0.0, abs(e.y));
            col = mix(col, lc, m * 0.95);
        }
    }
}

void blades(inout vec3 col, vec2 p, float c, float y1) {
    float cx = floor(p.x / c);
    for (int i = -1; i <= 1; i++) {
        float id = cx + float(i);
        vec2 sid = vec2(id, 33.0);
        if (hash(sid) > 0.8) continue;
        float top = y1 * (0.25 + 0.75 * pow(hash(sid + 1.0), 2.0));
        float x0 = (id + 0.5) * c + 0.01 * (hf(sid, 1.0) - 0.5);
        float t = p.y / top;
        if (t < 0.0 || t > 1.0) continue;
        float lean = 0.06 * (hash(sid + 2.0) - 0.5) * t * t + 0.004 * sin(p.y * 30.0 + id);
        float dx = p.x - x0 - lean;
        float w = 0.0016 * (1.0 - 0.7 * t);
        float a = smoothstep(w + AA, w - AA, abs(dx));
        vec3 bc = mix(vec3(0.05, 0.25, 0.08), vec3(0.45, 0.55, 0.15), hash(sid + 3.0));
        col = mix(col, bc, a * 0.85);
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    F = floor(mod(floor(iTime * 100.0 / 7.0), 17.0));
    PX = 1.0 / iResolution.y;
    AA = PX;
    vec2 p = fragCoord / iResolution.y;
    vec3 col = vec3(0.008, 0.01, 0.016);

    float edge = topEdge(p.x) + 0.05 * (vnoise(p * 30.0 + F * 3.7) - 0.5);
    float gm = smoothstep(-0.02, 0.06, edge - p.y);
    col = mix(col, foliage(p), gm);

    float tile = floor(p.x / TW);
    float tj = hash(vec2(tile, 17.0));

    crowd(col, p, 0.008, 0.3, 0.8, 7.0, 1.0, 0.8, 0.45, 2.5, -1.0);
    leaves(col, p, 0.07, 0.0, 0.66, 0.0, 0.9, 2.5, 1.0);
    crowd(col, p, 0.02, 0.3, 0.7, 1.0, 0.9, 0.85, 0.55, 1.8, -1.0);
    leaves(col, p, 0.1, 0.0, 0.6, 2.0, 0.8, 1.8, 1.0);
    plume(col, p, vec2(0.29, 0.2), vec2(0.28, 0.74), 0.058, 0.92, 1.0, vec2(1.0, 4.0));
    plume(col, p, vec2(0.16, 0.2), vec2(0.17, 0.5), 0.05, 0.9, 1.0, vec2(3.0, 5.0));
    plume(col, p, vec2(0.02, 0.1), vec2(0.04, 0.68), 0.085, 0.6, 1.9, vec2(5.0, 9.0));
    plume(col, p, vec2(1.08, 0.55), vec2(1.1, 0.7), 0.022, 0.62, 1.0, vec2(7.0, 2.0));
    AA = PX * 1.5;
    heroesAll(col, p, tile, 0, 8);
    crowd(col, p, 0.011, -0.05, 0.55, 8.0, 1.0, 0.8, 0.5, 1.3, -1.0);
    crowd(col, p, 0.028, 0.15, 0.62, 2.0, 0.85, 0.75, 0.6, 1.4, -1.0);
    AA = PX;
    blades(col, p, 0.016, 0.75);
    crowd(col, p, 0.045, 0.05, 0.5, 3.0, 0.7, 0.9, 0.55, 1.1, -1.0);
    crowd(col, p, 0.034, 0.2, 0.52, 9.0, 0.6, 0.95, 0.5, 1.2, 0.15);
    AA = PX;
    heroesAll(col, p, tile, 8, 24);
    crowd(col, p, 0.065, -0.05, 0.3, 4.0, 0.5, 1.0, 0.5, 1.0, -1.0);

    col = mix(vec3(dot(col, vec3(0.3, 0.55, 0.15))), col, 0.82);
    col = pow(col, vec3(1.1));

    float lo = 1.0 - smoothstep(0.45, 0.8, p.y);
    float gu = max(1.0, floor(iResolution.y / 900.0));
    vec2 g = floor(fragCoord / gu);
    float hd = hf(g, 0.0);
    if (hd > 0.95) col += vec3(0.05 + 0.75 * pow(hf(g, 1.0), 4.0));

    vec2 bc = floor(fragCoord / (gu * 4.0));
    if (hf(bc, 3.0) < mix(0.12, 0.02, lo)) {
        vec2 bo = (hf2(bc, 2.0) * 0.6 + 0.2 + bc) * gu * 4.0;
        col = mix(col, vec3(1.0), smoothstep(1.6 * gu, 0.5 * gu, length(fragCoord - bo)) * 0.8);
    }

    vec2 mc = floor(fragCoord / (gu * 2.3));
    if (hf(mc, 6.0) < mix(0.06, 0.04, lo)) {
        vec2 mo = (hf2(mc, 4.0) * 0.6 + 0.2 + mc) * gu * 2.3;
        float mr = (0.5 + 0.8 * hf(mc, 5.0)) * gu;
        col = mix(col, vec3(1.0), smoothstep(mr + gu * 0.6, mr, length(fragCoord - mo)) * (0.3 + 0.6 * hf(mc, 7.0)));
    }

    float cc = 0.035;
    vec2 cell = floor(p / cc);
    if (hf(cell, 12.0) < mix(0.2, 0.06, lo)) {
        vec2 co = (cell + 0.2 + 0.6 * hf2(cell, 10.0)) * cc;
        float cr = cc * (0.06 + 0.1 * hf(cell, 11.0));
        col = mix(col, CONF[int(hf(cell, 13.0) * 5.99)], smoothstep(cr + AA, cr - AA, length(p - co)));
    }

    fragColor = vec4(col, 1.0);
}
