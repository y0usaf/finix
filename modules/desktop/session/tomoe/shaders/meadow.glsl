const float PI = 3.14159265;

const vec3 PAL[8] = vec3[8](
    vec3(0.95, 0.80, 0.18),
    vec3(0.88, 0.14, 0.12),
    vec3(0.96, 0.52, 0.12),
    vec3(0.30, 0.45, 0.95),
    vec3(0.92, 0.36, 0.62),
    vec3(0.80, 0.22, 0.20),
    vec3(0.98, 0.90, 0.35),
    vec3(0.70, 0.40, 0.90)
);

const vec3 CONF[6] = vec3[6](
    vec3(0.95, 0.78, 0.20),
    vec3(0.98, 0.50, 0.15),
    vec3(0.92, 0.18, 0.15),
    vec3(0.30, 0.50, 0.98),
    vec3(0.95, 0.40, 0.70),
    vec3(0.60, 0.95, 0.40)
);

float F;
float AA;
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
    return 0.5 + 0.5 * cos(6.2832 * (t + vec3(0.0, 0.33, 0.67)));
}

vec3 hsv(float h, float s, float v) {
    vec3 k = clamp(abs(fract(h + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    return v * mix(vec3(1.0), k, s);
}

float topEdge(float x) {
    return 0.46 + 0.09 * vnoise(vec2(x * 4.0, 3.3)) + 0.05 * vnoise(vec2(x * 13.0, 8.1));
}

vec3 ground(vec2 p) {
    vec2 q = p + hash2(vec2(F, 7.0)) * 40.0;
    float n1 = vnoise(q * vec2(70.0, 20.0));
    float n2 = vnoise(q * vec2(150.0, 55.0));
    float n3 = vnoise(q * 9.0);
    vec3 dk = vec3(0.01, 0.045, 0.03);
    vec3 md = vec3(0.04, 0.17, 0.065);
    vec3 lt = vec3(0.17, 0.36, 0.1);
    vec3 tl = vec3(0.03, 0.26, 0.22);
    vec3 g = mix(dk, md, smoothstep(0.2, 0.8, n1 * 0.6 + n3 * 0.5));
    g = mix(g, tl, smoothstep(0.5, 0.9, n3) * 0.5);
    g = mix(g, lt, smoothstep(0.6, 0.95, n2) * 0.6);
    return g * (0.4 + 0.6 * (1.0 - clamp(p.y / 0.7, 0.0, 1.0)));
}

void petals(inout vec3 col, vec2 d, float R, float n, float q, float k0, float rot, vec3 base, float fm, float amax, vec2 sid) {
    float r = length(d);
    float an = (atan(d.y, d.x) + rot) * n / 6.2832;
    float pn = floor(an);
    float u = an - pn - 0.5;
    float len = k0 + (1.0 - k0) * pow(max(cos(PI * u), 0.0), q);
    float e = R * len - r;
    float m = smoothstep(-AA, AA, e);
    if (m <= 0.0) return;
    float rho = r / R;
    float ph = hash(vec2(pn, sid.x * 0.37 + sid.y * 0.91 + R * 91.0));
    vec3 fl = 0.6 * film(rho * 0.8 + ph * 0.6 + hf(sid, 5.0) + F * 0.07);
    vec3 pc = mix(base * (0.6 + 0.5 * ph), fl, fm * (0.4 + 0.6 * rho) * (0.5 + ph));
    float rim = smoothstep(R * 0.12, 0.0, e);
    pc += rim * 0.4;
    col = mix(col, pc * BR, m * (amax + 0.25 * rim));
}

void flower(inout vec3 col, vec2 d, float R, vec2 sid) {
    float r = length(d);
    if (r > R * 1.05) return;
    float tp = hash(sid + 9.9);
    float h1 = hash(sid + 1.7);
    float big = smoothstep(0.035, 0.07, R);
    float rot = 6.2832 * hf(sid, 6.0);
    float rc = 0.2;
    vec3 cen = vec3(0.98, 0.78, 0.15);
    if (big > 0.5) {
        tp = tp < 0.35 ? 0.0 : tp < 0.7 ? 0.2 : tp < 0.85 ? 0.1 : 0.5;
    }
    if (tp < 0.06) {
        vec3 base = hsv(0.94 + 0.08 * h1, 0.85, 0.8);
        petals(col, d, R, 7.0 + floor(3.0 * h1), 1.5, 0.15, rot, base, 0.5, 0.7, sid);
        petals(col, d, R * 0.66, 6.0 + floor(3.0 * h1), 1.2, 0.2, rot + 0.5, base * 1.2, 0.6, 0.7, sid + 5.0);
        rc = 0.09;
    } else if (tp < 0.2) {
        vec3 base = mix(vec3(0.96, 0.94, 0.88), vec3(0.86, 0.80, 0.96), step(0.5, hash(sid + 2.2)));
        petals(col, d, R, 9.0 + floor(5.0 * h1), 1.0, 0.35, rot, base, 0.25, 0.62, sid);
    } else if (tp < 0.34) {
        petals(col, d, R, 5.0 + floor(4.0 * h1), 0.9, 0.4, rot, vec3(0.92, 0.9, 0.98), 0.55, 0.62, sid);
        cen = vec3(0.55, 0.6, 0.2);
    } else if (tp < 0.65) {
        petals(col, d, R, 5.0 + floor(2.0 * h1), 0.8, 0.3, rot, PAL[int(hash(sid + 3.3) * 7.99)], 0.2, 0.62, sid);
        rc = 0.24;
    } else if (tp < 0.77) {
        float ds = R * 0.22;
        vec2 gid = floor(d / ds);
        vec2 cp = (gid + 0.25 + 0.5 * hf2(gid + sid, 20.0)) * ds;
        float rr = ds * (0.3 + 0.2 * hf(gid + sid, 21.0));
        float hue = mix(0.0, 0.95, step(0.5, hash(sid + 12.0))) + 0.09 * floor(3.0 * hash(sid + 13.0)) + 0.03 * hf(gid + sid, 22.0);
        float lump = R * (0.85 + 0.15 * sin(atan(d.y, d.x) * 5.0 + 6.0 * h1));
        col = mix(col, hsv(hue, 0.9, 0.3) * BR, smoothstep(lump + AA, lump - AA, r) * 0.9);
        float a = smoothstep(rr + AA, rr - AA, length(d - cp)) * step(length(cp), lump);
        col = mix(col, hsv(hue, 0.85, 0.6 + 0.4 * hf(gid + sid, 23.0)) * BR, a);
        return;
    } else {
        petals(col, d, R, 16.0, 1.8, 0.3, rot, hsv(0.72 + 0.2 * h1, 0.55, 0.9), 0.3, 0.62, sid);
    }
    float cd = smoothstep(R * rc + AA, R * rc - AA, r);
    col = mix(col, cen * (0.8 + 0.4 * hf(sid, 7.0)) * BR, cd * 0.95);
}

void flowerLayer(inout vec3 col, vec2 p, float c, float y0, float y1, float L, float dens, float br) {
    BR = br;
    if (p.y < y0 - c || p.y > y1 + c) return;
    vec2 cell = floor(p / c);
    for (int j = 1; j >= -1; j--) {
        for (int i = -1; i <= 1; i++) {
            vec2 id = cell + vec2(float(i), float(j));
            float cy = (id.y + 0.5) * c;
            if (cy < y0 || cy > y1) continue;
            vec2 sid = id + L * 113.0;
            float cx = (id.x + 0.5) * c;
            float lim = topEdge(cx) + 0.1;
            float pr = dens * (1.0 - smoothstep(lim - 0.16, lim + 0.04, cy));
            float h0 = hash(sid);
            float pop = step(0.88, hf(sid, 9.0)) * step(L, 2.5);
            if (h0 > pr && pop < 0.5) continue;
            vec2 off = 0.1 + 0.8 * mix(hash2(sid + 3.1), vec2(hf(sid, 1.0), hf(sid, 2.0)), 0.8);
            vec2 d = p - (id + off) * c;
            float R = c * mix(0.3, 0.75, hash(sid + 7.7)) * (L > 3.5 ? 0.85 : 1.0) * (1.0 + 0.25 * (hf(sid, 3.0) - 0.5));
            if (L > 0.5 && hash(sid + 4.4) < 0.6 && d.y < 0.0 && d.y > -c * 1.4) {
                float bx = d.x - 0.15 * c * sin(d.y / c * 3.0 + 6.0 * h0);
                float sw = c * 0.03 + AA;
                float sa = smoothstep(sw, sw - AA, abs(bx));
                col = mix(col, vec3(0.06, 0.32, 0.12) * (0.7 + 0.6 * hash(sid + 5.5)), sa * 0.85);
            }
            flower(col, d, R, sid);
        }
    }
}

void leafLayer(inout vec3 col, vec2 p, float c, float y0, float y1, float L) {
    if (p.y < y0 - c || p.y > y1 + c) return;
    vec2 cell = floor(p / c);
    for (int j = 1; j >= -1; j--) {
        for (int i = -1; i <= 1; i++) {
            vec2 id = cell + vec2(float(i), float(j));
            vec2 sid = id + L * 71.0;
            if (hash(sid) > 0.4) continue;
            vec2 off = 0.1 + 0.8 * mix(hash2(sid + 3.1), hf2(sid, 1.0), 0.7);
            vec2 d = p - (id + off) * c;
            float th = 6.2832 * hf(sid, 2.0);
            vec2 e = vec2(cos(th) * d.x + sin(th) * d.y, -sin(th) * d.x + cos(th) * d.y);
            float Ln = c * mix(0.45, 0.9, hash(sid + 1.0));
            float Wd = Ln * mix(0.18, 0.32, hash(sid + 2.0));
            float t = e.x / Ln;
            float w = Wd * max(1.0 - t * t, 0.0) * (1.0 - 0.3 * t);
            float dist = w - abs(e.y);
            if (abs(t) > 1.0 || dist < -AA) continue;
            float m = smoothstep(-AA, AA, dist);
            vec3 lc = mix(vec3(0.03, 0.17, 0.07), vec3(0.22, 0.46, 0.13), hash(sid + 3.0));
            lc = mix(lc, vec3(0.05, 0.4, 0.35), step(0.8, hash(sid + 4.0)));
            lc *= 0.75 + 0.5 * smoothstep(0.0, 1.0, abs(e.y) / max(w, 1e-4));
            lc += 0.35 * smoothstep(AA * 1.5, 0.0, abs(e.y));
            col = mix(col, lc, m * 0.7);
        }
    }
}

void spikes(inout vec3 col, vec2 p) {
    float c = 0.2;
    float cx = floor(p.x / c);
    for (int i = -1; i <= 1; i++) {
        float id = cx + float(i);
        vec2 sid = vec2(id, 91.0);
        if (hash(sid) > 0.5) continue;
        float x0 = (id + 0.2 + 0.6 * mix(hash(sid + 1.0), hf(sid, 1.0), 0.4)) * c;
        float yb = 0.12 + 0.22 * hash(sid + 2.0);
        float yt = 0.5 + 0.3 * hash(sid + 3.0) + 0.04 * (hf(sid, 2.0) - 0.5);
        float t = (p.y - yb) / (yt - yb);
        if (t < 0.0 || t > 1.0) continue;
        float w = c * 0.2 * mix(0.6, 1.0, hash(sid + 4.0)) * (1.0 - pow(t, 1.3));
        float dx = p.x - x0 - 0.008 * sin(p.y * 40.0 + F);
        if (abs(dx) > w + 0.01) continue;
        float ds = 0.011;
        vec2 gid = floor(vec2(dx, p.y) / ds);
        vec2 cc = (gid + 0.15 + 0.7 * hf2(gid + sid, 4.0)) * ds;
        float rr = ds * 0.6 * (0.6 + 0.8 * hf(gid + sid, 5.0));
        float inside = step(abs(cc.x), w);
        float dd = length(vec2(dx, p.y) - cc);
        float a = smoothstep(rr + AA, rr - AA, dd) * inside * step(hf(gid + sid, 6.0), 0.96);
        float blue = step(0.5, hash(sid + 6.0));
        float hue = mix(0.86 + 0.1 * hf(gid + sid, 7.0), 0.6 + 0.07 * hf(gid + sid, 7.0), blue);
        vec3 dc = hsv(hue, 0.8, 0.7 + 0.3 * hf(gid + sid, 8.0));
        dc = mix(dc, film(hf(gid + sid, 9.0) + F * 0.07), 0.2);
        col = mix(col * mix(1.0, 0.7, inside), dc, a);
    }
}

void tulips(inout vec3 col, vec2 p) {
    float c = 0.17;
    float cx = floor(p.x / c);
    for (int i = -1; i <= 1; i++) {
        float id = cx + float(i);
        vec2 sid = vec2(id, 53.0);
        if (hash(sid) > 0.3) continue;
        vec2 hc = vec2((id + 0.2 + 0.6 * mix(hash(sid + 1.0), hf(sid, 1.0), 0.5)) * c, 0.3 + 0.35 * mix(hash(sid + 2.0), hf(sid, 2.0), 0.3));
        float hw = 0.018 + 0.01 * hash(sid + 3.0);
        vec2 d = p - hc;
        if (d.y < 0.0 && d.y > -hc.y + 0.05) {
            float sa = smoothstep(0.004 + AA, 0.004 - AA, abs(d.x - 0.01 * sin(d.y * 20.0)));
            col = mix(col, vec3(0.2, 0.5, 0.2), sa * 0.9);
        }
        float hh = hw * 1.7;
        float t = d.y / hh;
        if (t < -1.0 || t > 1.0) continue;
        float w = hw * sqrt(max(1.0 - t * t, 0.0)) * (1.0 - 0.45 * max(t, 0.0));
        float dist = w - abs(d.x);
        float m = smoothstep(-AA, AA, dist);
        vec3 tc = mix(vec3(0.95, 0.2, 0.1), vec3(0.98, 0.7, 0.15), smoothstep(-0.6, 0.8, t));
        tc = mix(tc, film(t * 0.5 + hf(sid, 5.0) + F * 0.07), 0.4);
        tc += smoothstep(hw * 0.2, 0.0, dist) * 0.4;
        col = mix(col, tc, m * 0.8);
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    F = floor(mod(floor(iTime * 100.0 / 7.0), 17.0));
    AA = 1.0 / iResolution.y;
    vec2 p = fragCoord / iResolution.y;
    vec3 col = vec3(0.0);

    float gm = smoothstep(-0.03, 0.05, topEdge(p.x) + 0.06 * (vnoise(p * 30.0 + F * 3.7) - 0.5) - p.y);
    col = mix(col, ground(p), gm);

    flowerLayer(col, p, 0.02, 0.38, 0.66, 0.0, 0.8, 0.4);
    flowerLayer(col, p, 0.03, 0.27, 0.58, 1.0, 0.75, 0.5);
    leafLayer(col, p, 0.07, 0.0, 0.62, 0.0);
    flowerLayer(col, p, 0.045, 0.22, 0.54, 5.0, 0.7, 0.65);
    flowerLayer(col, p, 0.06, 0.1, 0.48, 2.0, 0.7, 0.8);
    spikes(col, p);
    tulips(col, p);
    flowerLayer(col, p, 0.07, -0.05, 0.3, 6.0, 0.75, 0.95);
    flowerLayer(col, p, 0.1, 0.02, 0.4, 3.0, 0.6, 1.0);
    leafLayer(col, p, 0.1, 0.0, 0.4, 1.0);
    flowerLayer(col, p, 0.18, -0.1, 0.4, 4.0, 0.35, 1.0);

    col = pow(col, vec3(1.15));

    float lo = 1.0 - smoothstep(0.45, 0.8, p.y);
    float gu = max(1.0, floor(iResolution.y / 900.0));
    vec2 g = floor(fragCoord / gu);
    float hd = hf(g, 0.0);
    float dens = mix(0.05, 0.04, lo);
    float dust = step(1.0 - dens, hd) * (0.2 + 0.8 * pow(hf(g, 1.0), 1.5));
    col += vec3(dust);
    vec2 bc = floor(fragCoord / (gu * 3.0));
    vec2 bo = (hf2(bc, 2.0) * 0.6 + 0.2) * gu * 3.0 + bc * gu * 3.0;
    float bd = length(fragCoord - bo);
    float ba = smoothstep(1.8 * gu, 0.6 * gu, bd) * step(hf(bc, 3.0), mix(0.25, 0.035, lo));
    col = mix(col, vec3(1.0), ba * 0.9);

    float cc = 0.03;
    vec2 cell = floor(p / cc);
    vec2 co = (cell + 0.2 + 0.6 * hf2(cell, 10.0)) * cc;
    float cr = cc * (0.08 + 0.12 * hf(cell, 11.0));
    float ca = smoothstep(cr + AA, cr - AA, length(p - co)) * step(hf(cell, 12.0), mix(0.2, 0.05, lo));
    col = mix(col, CONF[int(hf(cell, 13.0) * 5.99)], ca);

    fragColor = vec4(col, 1.0);
}
