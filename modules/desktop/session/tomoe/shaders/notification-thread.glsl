const int N_PAD = 0, N_RADIUS = 1, N_RIM = 2, N_SCALE = 3;
const int N_PLATE = 4, N_ACCENT = 8, N_URGENT = 11, N_MODE = 12;
const int N_BORN = 13, N_ENTER = 14, N_EXIT_AT = 15, N_EXIT = 16, N_PULSE_AT = 17;

vec4 g_nbox;
float g_nrad, g_nrim, g_nscale, g_nprog, g_nshine, g_nurgent;
vec2 g_nbead_c, g_nbead_h;

float notif_rim_pres(vec2 p) {
    vec2 pp = thread_perim(p, g_nbox);
    float ua = thread_perim(vec2(g_nbox.x, 0.5 * (g_nbox.y + g_nbox.w)), g_nbox).x;
    float s = thread_pdist(pp.x, ua, pp.y);
    return clamp((g_nprog * pp.y * 0.5 - s) / max(1.0, 36.0 * g_nscale) + (g_nprog >= 0.999 ? 1.0 : 0.0), 0.0, 1.0);
}

float notif_rim_field(vec2 p) {
    float db = sd_rbox(p, g_nbox, g_nrad);
    float pres = notif_rim_pres(p);
    float rw = g_nrim * (1.0 + 0.70 * g_nshine) * pres;
    float ring = pres > 0.01 ? max(db - rw, -db) : 1e3;
    float bead = sd_rbox(p, vec4(g_nbead_c - g_nbead_h, g_nbead_c + g_nbead_h), g_nbead_h.x);
    return smin(ring, bead, 3.6 * g_nscale * max(pres, 0.25));
}

void mainImage(out vec4 color, in vec2 p) {
    float enter_u = clamp((iTime - D(N_BORN)) / max(0.01, D(N_ENTER)), 0.0, 1.0);
    float enter_e = 1.0 - pow(1.0 - enter_u, 3.0);
    float exit_at = D(N_EXIT_AT);
    float exit_u = exit_at > -1e5 ? clamp((iTime - exit_at) / max(0.01, D(N_EXIT)), 0.0, 1.0) : 0.0;
    float exit_e = 1.0 - pow(1.0 - exit_u, 2.0);
    float vis = enter_e * (1.0 - exit_e);
    if (vis <= 0.002) {
        discard;
    }

    float pad = D(N_PAD);
    g_nscale = max(0.25, D(N_SCALE));
    g_nrad = D(N_RADIUS);
    g_nrim = D(N_RIM);
    g_nurgent = D(N_URGENT);
    float light_mode = D(N_MODE);

    float pulse_age = iTime - D(N_PULSE_AT);
    float pulse = (pulse_age >= 0.0 && pulse_age < 0.45) ? exp(-pulse_age * 7.5) : 0.0;
    g_nshine = clamp(exp(-enter_u * 4.2) * 0.85 + pulse * 0.90 + g_nurgent * 0.28, 0.0, 1.2);
    g_nprog = exit_at > -1e5 ? (1.0 - exit_e) : clamp((enter_e - 0.04) / 0.96, 0.0, 1.0);

    g_nbox = vec4(pad, pad, iResolution.x - pad, iResolution.y - pad);
    float bh = clamp((g_nbox.w - g_nbox.y) * 0.24, 9.0 * g_nscale, 24.0 * g_nscale);
    float bw = (g_nurgent > 0.5 ? 2.8 : 2.1) * g_nscale * (1.0 + 0.30 * g_nshine);
    g_nbead_c = vec2(g_nbox.x, 0.5 * (g_nbox.y + g_nbox.w));
    g_nbead_h = vec2(bw, bh * clamp(0.45 + 0.55 * g_nprog, 0.0, 1.0));

    float db = sd_rbox(p, g_nbox, g_nrad);
    float dr = notif_rim_field(p);
    float f = min(db, dr);

    vec4 plate = D4(N_PLATE);
    vec3 accent = vec3(D(N_ACCENT), D(N_ACCENT + 1), D(N_ACCENT + 2));

    vec3 c = vec3(0.0);
    float a = 0.0;

    float d_sh = sd_rbox(p + vec2(0.0, 2.2 * g_nscale), g_nbox, g_nrad);
    if (d_sh > 0.0) {
        float sh_strength = light_mode > 0.5 ? 0.14 : 0.30;
        float sh = sh_strength * pow(clamp(1.0 - d_sh / max(1.0, pad), 0.0, 1.0), 2.1);
        a = sh + a * (1.0 - sh);
    }

    if (f > 0.0) {
        float hair = (light_mode > 0.5 ? 0.22 : 0.36) * clamp(1.0 - abs(f - 0.65 * g_nscale) / max(0.8, 0.95 * g_nscale), 0.0, 1.0);
        c *= 1.0 - hair;
        a = hair + a * (1.0 - hair);
    }

    float body_cov = clamp(0.5 - db, 0.0, 1.0);
    if (body_cov > 0.0) {
        vec4 fr = frost(p);
        vec3 bg = fr.a > 0.01 ? fr.rgb : frosted(p, 6.0 * g_nscale);
        vec3 body = mix(bg, plate.rgb, plate.a);
        float top_t = clamp((p.y - g_nbox.y) / max(1.0, g_nbox.w - g_nbox.y), 0.0, 1.0);
        body += vec3(light_mode > 0.5 ? 0.04 : 0.05) * pow(top_t, 3.0);
        float left_wash = exp(-max(0.0, p.x - g_nbox.x) / max(1.0, 72.0 * g_nscale));
        float wash_amt = g_nurgent > 0.5 ? 0.16 : 0.035;
        body = mix(body, accent, left_wash * wash_amt);
        float inner_edge = clamp(1.0 + db / max(1.0, 1.4 * g_nscale), 0.0, 1.0);
        float top_lit = smoothstep(0.45, 0.98, top_t);
        vec3 bevel = light_mode > 0.5 ? vec3(0.0) : vec3(1.0);
        float bevel_a = (light_mode > 0.5 ? 0.10 : (0.14 + 0.16 * top_lit)) * inner_edge;
        body = mix(body, bevel, bevel_a);
        c = body * body_cov + c * (1.0 - body_cov);
        a = body_cov + a * (1.0 - body_cov);
    }

    float rim_cov = clamp(0.5 - dr, 0.0, 1.0);
    if (rim_cov > 0.0) {
        vec2 slant = vec2(notif_rim_field(p + vec2(1.0, 0.0)) - dr, notif_rim_field(p + vec2(0.0, 1.0)) - dr);
        vec2 dir = slant / (length(slant) + 1e-5);
        vec3 rim_col = glass(p, dr, dir, g_nshine);
        float bead_d = sd_rbox(p, vec4(g_nbead_c - g_nbead_h, g_nbead_c + g_nbead_h), g_nbead_h.x);
        float bead_w = clamp(1.0 - max(0.0, bead_d) / max(1.0, 18.0 * g_nscale), 0.0, 1.0);
        float tint_w = g_nurgent > 0.5 ? (0.42 + 0.42 * bead_w) : (0.08 + 0.24 * bead_w);
        rim_col = mix(rim_col, accent, tint_w);
        float rim_a = rim_cov * (0.86 + 0.14 * bead_w);
        c = rim_col * rim_a + c * (1.0 - rim_a);
        a = rim_a + a * (1.0 - rim_a);
    }

    c *= vis;
    a *= vis;
    if (a <= 0.001) {
        discard;
    }
    color = vec4(c, a);
}
