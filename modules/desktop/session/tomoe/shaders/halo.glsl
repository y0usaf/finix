// halo: morph's cast material with no centre slab at all.
//
// The deck's seam carries nothing: every card stands its own frame, and the
// readings ride the focused card. On that card's top edge, at the end nearer the
// seam, a capsule the height of a line of type is welded to the frame by the
// same smooth minimum that welds morph's slab to its frames -- the CROWN. It
// holds the clock, the day and date and the four gauges, each gauge's load
// swelling the crown's rim by a welded bump and running a filled hairline of its
// own under its value. Every other card keeps a thin darker line. The focused
// card wears a five pixel frame of the same cast material, so focus is as
// unmistakable as morph's.
//
// A focus change siphons: the old frame drains back into the crown, its front
// running from the far side toward it, the crown hops to the new card on two
// springs -- a stiff leading centre and a loose trailing one, so mid-flight it
// stretches into a long thin capsule -- and the new frame fills out of it both
// ways round the card. Within a column the crown does not move: the cards scroll
// under it at the top of the column. A quick switch only pours, one frame
// thinning as the other swells in.
//
// bolo's turn is the centrepiece: the whole focused frame is the speech
// waveform. Spikes stand off its outer edge at once all the way round, their
// reach the level being spoken over a slower swell, the material brightening
// toward its glow colour with the level,
// and the crown's head a small live trace. It dies away over the settle when the
// turn ends. Only the focused frame moves.
//
// Everything comes from iData (laid out by rail-kit.lisp and rail-halo.lisp),
// the cards from iWindow, and time from iTime, which the rail holds once nothing
// moves. Coordinates below are the output's, y down.

const int T_MAT = THEME, T_LINE = THEME + 3, T_SHADOW = THEME + 6, T_SHINE = THEME + 9;
const int T_LO = THEME + 12, T_INK = THEME + 15, T_DIM = THEME + 18, T_TRACK = THEME + 21;
const int T_GLOW = THEME + 24, T_FRAME = THEME + 27, T_LINEW = THEME + 28, T_RAD = THEME + 29;
const int T_HH = THEME + 30, T_PAD = THEME + 31, T_CLOCKW = THEME + 32, T_DATEW = THEME + 33;
const int T_GW = THEME + 34, T_INSET = THEME + 38, T_TRACE = THEME + 39, T_BUMP = THEME + 40;
const int T_SX = THEME + 41, T_SY = THEME + 42, T_EX = THEME + 43, T_EY = THEME + 44;
const int T_HAIR = THEME + 45, T_SHADE = THEME + 46;
// a bar: which one this surface is (0 the card's crown, 1 the top bar, 2 the
// bottom, 3 the frames alone), its rect and the blocks it carries
const int H_MODE = THEME + 47, H_RECT = THEME + 48, H_BLOCKS = THEME + 52;

const float DESIGN = 0.46;       // seconds the siphon was drawn for
const float CROWN_WELD = 9.0;    // px the crown welds to its frame
const float CROWN_SPRING = 0.10; // s the crown waits before it hops
const float TRACE_BARS = 34.0;   // bars in the crown's live trace

vec3 g_mat, g_line, g_shadow, g_shine, g_lo, g_ink, g_dim, g_track, g_glow;
float g_frame, g_linew, g_rad, g_hh, g_pad, g_clockw, g_datew, g_gw[4];
float g_inset, g_trace, g_bump, g_hair, g_shade;
vec2 g_start, g_end;
float g_vo;                      // the voice's level right now, envelope and all
float g_dt;                      // the move's age in the theme's own seconds
float g_raw;                     // seconds since the switch, 0 before one
bool g_switch;                   // a switch is in flight
int g_focus, g_old;

vec4 g_crown;                    // the capsule, wherever it is this instant
float g_stretch;                 // how far it is stretched in flight
bool g_focus_shown, g_old_shown, g_changed;

// ---- the crown

float crown_width() {
    float w = 2.0 * g_pad + g_clockw + g_datew;
    for (int k = 0; k < 4; k++)
        if (gauge_shown(k)) w += (k == 3) ? g_gw[3] : g_gw[0];
    return w;
}

// the crown seated on B's top edge: its seam-side end fixed g_inset in from the
// edge that faces the seam, its voice growing the far end
vec4 crown_seated(vec4 b, float side) {
    float w = crown_width() + g_trace * g_vo;
    float hh = g_hh + 2.5 * g_vo;
    // the crown's middle sits a frame and a half-height above the card's top
    // edge, less the six it laps back into the frame
    float cy = b.y - g_frame - g_hh + 8.0;
    if (side > 0.0) {
        float x0 = b.x + g_inset;
        return vec4(x0, cy - hh, x0 + w, cy + hh);
    }
    float x1 = b.z - g_inset;
    return vec4(x1 - w, cy - hh, x1, cy + hh);
}

// the crown in flight: two centres on two springs, the capsule spanning them
vec4 crown_flying() {
    float lead = spring(g_dt - CROWN_SPRING, 78.0, 0.72);
    float trail = spring(g_dt - CROWN_SPRING - 0.018, 52.0, 0.62);
    vec2 a = mix(g_start, g_end, lead);
    vec2 b = mix(g_start, g_end, trail);
    float w = crown_width() + g_trace * g_vo;
    float x0 = min(a.x, b.x) - 0.5 * w;
    float x1 = max(a.x, b.x) + 0.5 * w;
    g_stretch = clamp((x1 - x0 - w) / 700.0, 0.0, 1.0);
    float hh = g_hh * (1.0 - 0.35 * g_stretch) + 2.5 * g_vo;
    float cy = 0.5 * (a.y + b.y);
    return vec4(x0, cy - hh, x1, cy + hh);
}

// The crown itself: one capsule whose rim swells smoothly over each gauge by as
// much as the gauge carries, so its shape is round everywhere -- the ends round,
// the swell round, nothing squared off against anything else.
float crown_field(vec2 p) {
    float x = g_crown.x + g_pad + g_clockw + g_datew;
    float swell = 0.0;
    for (int k = 0; k < 4; k++) {
        if (!gauge_shown(k)) continue;
        float w = (k == 3) ? g_gw[3] : g_gw[0];
        float t = clamp((p.x - (x + 6.0)) / max(1.0, w - 12.0), 0.0, 1.0);
        float hump = sin(PI * t);
        float bh = 2.0 + g_bump * clamp(gauge_pct(k) / 100.0, 0.0, 1.0);
        swell = max(swell, hump * bh);
        x += w;
    }
    float hh = 0.5 * (g_crown.w - g_crown.y) + swell;
    vec2 c0 = 0.5 * (g_crown.xy + g_crown.zw);
    vec2 q = abs(p - c0) - vec2(0.5 * (g_crown.z - g_crown.x) - hh, hh);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - hh;
}

// ---- the frames

// the focused card's frame at P: a ring hugging the card, its outer edge the
// voice, present where the fill's front has reached. The voice moves the whole
// frame at once -- louder speech standing further off every side, its crests
// where they are -- so a far corner is as loud as the near one. LV is how loud
// the voice is there.
float focus_field(vec2 p, out float lv) {
    lv = 0.0;
    vec4 box = card(g_focus);
    vec2 pc = perim(p, box);
    float ua = perim(vec2(g_end.x, box.y), box).x;
    float s = pdist(pc.x, ua, pc.y);
    // a siphon fills the new frame out of the crown both ways; a pour, hard on
    // the heels of another switch, only swells it in
    float fill = 1.0;
    if (g_switch) fill = D(K_FLOW) < 0.5 ? ease_out((g_dt - 0.05) / 0.12)
                                         : ease_out((g_dt - 0.16) / 0.24);
    float pres = clamp((fill * pc.y * 0.5 - s) / 60.0 + (fill >= 1.0 ? 1.0 : 0.0), 0.0, 1.0);
    float level = voice_env() * min(1.0, voice_around(s, pc.y));
    float spk = abs(sin(s / 7.0 + sin(s / 31.0 - iTime * 9.0) * 2.0));
    float reach = 6.0 + 15.0 * spk * (0.55 + 0.45 * sin(s / 47.0 - iTime * 23.0));
    float w = (g_frame + level * reach) * pres;
    lv = level * pres;
    if (pres <= 0.01) return 1e4;
    float d = sd_rbox(p, box, g_rad);
    return max(d - w, -d);
}

// the frame of the card focus left, draining back into the crown: its front
// runs from the far side toward the crown
float old_field(vec2 p) {
    if (!g_old_shown || !g_changed) return 1e4;
    vec4 box = card(g_old);
    vec2 pc = perim(p, box);
    float ua = perim(vec2(g_start.x, box.y), box).x;
    float s = pdist(pc.x, ua, pc.y);
    float drain = D(K_FLOW) < 0.5 ? 1.0 - ease_out(clamp(g_dt / 0.10, 0.0, 1.0))
                                  : 1.0 - pow(ease_out(clamp(g_dt / 0.18, 0.0, 1.0)), 1.7);
    float pres = D(K_FLOW) < 0.5 ? drain
                                 : clamp((drain * pc.y * 0.5 - s) / 50.0, 0.0, 1.0);
    if (pres <= 0.01) return 1e4;
    float d = sd_rbox(p, box, g_rad);
    float w = (g_frame + 2.5 * (1.0 - pres)) * pres;
    return max(d - w, -d);
}

float field(vec2 p, out float lv) {
    float f = 1e4;
    lv = 0.0;
    if (g_focus_shown) f = focus_field(p, lv);
    f = min(f, old_field(p));
    if (D(H_MODE) > 2.5) return f;
    return smin(f, crown_field(p), CROWN_WELD);
}

float rect_cov(vec2 p, vec4 b) {
    vec2 q = vec2(max(b.x - p.x, p.x - b.z), max(b.y - p.y, p.y - b.w));
    return clamp(0.5 - max(q.x, q.y), 0.0, 1.0);
}

bool bar_gauge(int kind) {
    return kind == 2 || kind == 3 || kind == 4 || kind == 5 ||
           kind == 8 || kind == 9 || kind == 10 || kind == 11;
}

// the gauge's slot among the readings, counted from the blocks before it
int bar_slot(int upto) {
    int k = 0;
    for (int j = 0; j < upto; j++)
        if (bar_gauge(int(D(H_BLOCKS + 1 + j * 5)))) k++;
    return k;
}

// HALO on a bar: the crown is the bar, one capsule along the strip's outer
// edge, each gauge's load welding a bump into its free edge and running a
// filled hairline of its own under its number
vec4 halo_bar(vec2 p) {
    vec4 r = vec4(D(H_RECT), D(H_RECT + 1), D(H_RECT + 2), D(H_RECT + 3));
    if (p.x < r.x || p.x >= r.z || p.y < r.y || p.y >= r.w) return vec4(0.0);
    bool top = D(H_MODE) < 1.5;
    float inner = top ? r.w - 12.0 : r.y + 12.0;
    vec4 crown = top ? vec4(r.x + 2.0, r.y + 2.0, r.z - 2.0, r.w - 12.0)
                     : vec4(r.x + 2.0, r.y + 12.0, r.z - 2.0, r.w - 2.0);
    float f = sd_rbox(p, crown, min(0.5 * (crown.w - crown.y), g_rad));
    int nb = int(D(H_BLOCKS));
    for (int i = 0; i < 8; i++) {
        if (i >= nb) break;
        int b0 = H_BLOCKS + 1 + i * 5;
        vec4 br = vec4(D(b0 + 1), D(b0 + 2), D(b0 + 3), D(b0 + 4));
        if (br.z <= br.x) break;
        if (!bar_gauge(int(D(b0)))) continue;
        int slot = bar_slot(i);
        if (slot > 3) continue;
        float bh = 2.0 + g_bump * clamp(gauge_pct(slot) / 100.0, 0.0, 1.0);
        vec4 bump = top ? vec4(br.x + 10.0, inner - bh, br.z - 10.0, inner)
                        : vec4(br.x + 10.0, inner, br.z - 10.0, inner + bh);
        f = smin(f, sd_rbox(p, bump, 4.0), 5.0);
    }
    float cov = clamp(0.5 - f, 0.0, 1.0);
    if (cov <= 0.0) return vec4(0.0);
    float lit = clamp((p.y - crown.y) / max(1.0, crown.w - crown.y), 0.0, 1.0);
    vec3 m = mix(g_mat, g_shine, 0.10 * (1.0 - lit));
    m = mix(m, g_lo, lit * 0.18);
    float yy = top ? crown.y + 6.0 : crown.w - 8.0;
    for (int i = 0; i < 8; i++) {
        if (i >= nb) break;
        int b0 = H_BLOCKS + 1 + i * 5;
        vec4 br = vec4(D(b0 + 1), D(b0 + 2), D(b0 + 3), D(b0 + 4));
        if (br.z <= br.x) break;
        if (!bar_gauge(int(D(b0)))) continue;
        int slot = bar_slot(i);
        if (slot > 3) continue;
        float x0 = br.x + 12.0, x1 = br.z - 12.0;
        m = mix(m, g_track, rect_cov(p, vec4(x0, yy, x1, yy + 2.0)));
        float fx = mix(x0, x1, clamp(gauge_pct(slot) / 100.0, 0.0, 1.0));
        m = mix(m, g_ink, rect_cov(p, vec4(x0, yy, fx, yy + 2.0)));
    }
    return vec4(m, cov);
}

// a bounded rectangle's coverage at P, anti-aliased over a pixel


void mainImage(out vec4 color, in vec2 fragCoord) {
    kit_begin();
    vec2 p = kit_point(fragCoord);
    color = vec4(0.0);

    g_mat = D3(T_MAT); g_line = D3(T_LINE); g_shadow = D3(T_SHADOW); g_shine = D3(T_SHINE);
    g_lo = D3(T_LO); g_ink = D3(T_INK); g_dim = D3(T_DIM); g_track = D3(T_TRACK);
    g_glow = D3(T_GLOW);
    g_frame = D(T_FRAME); g_linew = D(T_LINEW); g_rad = D(T_RAD); g_hh = D(T_HH);
    g_pad = D(T_PAD); g_clockw = D(T_CLOCKW); g_datew = D(T_DATEW);
    for (int k = 0; k < 4; k++) g_gw[k] = D(T_GW + k);
    g_inset = D(T_INSET); g_trace = D(T_TRACE); g_bump = D(T_BUMP); g_hair = D(T_HAIR);
    g_shade = D(T_SHADE);
    g_start = vec2(D(T_SX), D(T_SY));
    g_end = vec2(D(T_EX), D(T_EY));

    if (D(H_MODE) > 0.5 && D(H_MODE) < 2.5) {
        color = halo_bar(p);
        if (color.a <= 0.0) discard;
        return;
    }

    g_focus = int(D(K_FOCUS));
    g_old = int(D(K_OLD));
    g_focus_shown = card_shown(g_focus);
    g_old_shown = card_shown(g_old) && g_old != g_focus;
    g_raw = iTime - D(K_TSW);
    g_dt = move_age(DESIGN);
    g_switch = D(K_TSW) > -1e5 && g_raw >= 0.0 && g_raw < D(K_SETTLE) && D(K_FLOW) > -0.5;
    g_changed = g_switch && g_old >= 0 && g_old != g_focus;
    g_vo = voice_env() * voice_level(0.0);
    g_stretch = 0.0;

    // the crown: on its card, or in flight, or -- with no card holding focus --
    // where the rail puts the readings, top centre
    float side = 0.0;
    if (g_focus_shown) {
        side = card_side(g_focus);
        if (side == 0.0)
            side = (0.5 * (card(g_focus).x + card(g_focus).z) < k_origin.x + 0.5 * iResolution.x)
                ? -1.0 : 1.0;
    }
    if (g_switch) g_crown = crown_flying();
    else if (g_focus_shown) g_crown = crown_seated(card(g_focus), side);
    else g_crown = vec4(g_end.x - 0.5 * crown_width(), g_end.y - g_hh,
                        g_end.x + 0.5 * crown_width(), g_end.y + g_hh);
    // never let the crown run off the top of the screen: a card against the top
    // edge gets its crown a few pixels lower, still welded to its frame
    float top = k_origin.y + 0.5 - (g_crown.y - g_bump - 2.0);
    if (top > 0.0) { g_crown.y += top; g_crown.w += top; }

    // the thin line round every card the cast does not cover
    float line = 0.0;
    for (int i = 0; i < 8; i++) {
        if (!card_shown(i) || i == g_focus) continue;
        if (i == g_old && g_changed) continue;
        float d = sd_rbox(p, card(i), g_rad);
        if (d < -2.0 || d > 4.0) continue;
        line = max(line, clamp(1.25 - abs(d - 0.5 * g_linew), 0.0, 1.0) * (g_linew / 1.5));
    }

    float lv, spare;
    float f = field(p, lv);
    float loud = lv;
    if (f > 14.0 && line <= 0.0) discard;

    // soft contact shadow, then the cast material
    float sh = f > 0.0 ? pow(clamp(1.0 - f / 9.0, 0.0, 1.0), 2.0) * 0.55 * g_shade : 0.0;
    vec3 c = g_line * line;
    float a = line;
    vec2 g = vec2(field(p + vec2(1.0, 0.0), spare) - field(p - vec2(1.0, 0.0), spare),
                  field(p + vec2(0.0, 1.0), spare) - field(p - vec2(0.0, 1.0), spare)) * 0.5;
    if (sh > 0.0) {
        c = g_shadow * sh + c * (1.0 - sh);
        a = sh + a * (1.0 - sh);
    }
    float cov = clamp(0.5 - f, 0.0, 1.0);
    if (cov > 0.0) {
        vec2 n = g / (length(g) + 1e-6);
        float lit = clamp(0.45 * n.x + 0.89 * n.y, -1.0, 1.0);
        float rim = clamp(1.0 + f / 2.2, 0.0, 1.0) * (f < 0.5 ? 1.0 : 0.0);
        vec3 m = mix(g_mat, g_glow, clamp(loud * 1.6, 0.0, 1.0));
        m = mix(m, g_lo, clamp(-lit, 0.0, 1.0) * rim * 0.9);
        m = mix(m, g_shine, clamp(lit, 0.0, 1.0) * rim * 0.42);
        c = m * cov + c * (1.0 - cov);
        a = cov + a * (1.0 - cov);
    }

    // inside the crown, once it is seated: the gauges' hairlines and bolo's trace
    float capsule = sd_rbox(p, g_crown, 0.5 * (g_crown.w - g_crown.y));
    if (g_stretch < 0.02 && capsule < 0.5) {
        float hx = g_crown.x + g_pad + g_clockw + g_datew;
        float yy = g_crown.w - g_hair;
        for (int k = 0; k < 4; k++) {
            if (!gauge_shown(k)) continue;
            float w = (k == 3) ? g_gw[3] : g_gw[0];
            float x0 = hx + 12.0, x1 = hx + w - 14.0;
            c = mix(c, g_track, rect_cov(p, vec4(x0, yy, x1, yy + 2.0)));
            float fx = mix(x0, x1, clamp(gauge_pct(k) / 100.0, 0.0, 1.0));
            c = mix(c, g_ink, rect_cov(p, vec4(x0, yy, fx, yy + 2.0)));
            hx += w;
        }
        if (g_vo > 0.02 && g_focus_shown) {
            float extra = g_trace * g_vo;
            float cy = 0.5 * (g_crown.y + g_crown.w);
            float dir = side < 0.0 ? -1.0 : 1.0;
            float inner = side < 0.0 ? g_crown.x + g_pad + extra : g_crown.z - g_pad - extra;
            for (int i = 0; i < 34; i++) {
                float lev = voice_level(float(i) / 30.0);
                float hgt = 2.0 + 18.0 * lev;
                float x = inner + dir * (14.0 + 4.0 * float(i));
                float bar = rect_cov(p, vec4(x - 1.0, cy - 0.5 * hgt, x + 1.0, cy + 0.5 * hgt));
                c = mix(c, g_ink, bar * g_vo * (1.0 - float(i) / TRACE_BARS));
            }
        }
    }

    if (a <= 0.0) discard;
    color = vec4(c, a);
}
