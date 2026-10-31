const float LENS = 0.028;
const float SPREAD = 0.0016;
const float VIGNETTE = 0.30;
const float SHEEN = 0.035;
const float RIM = 0.32;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 size = iResolution.xy;
    vec2 uv = fragCoord / size;
    vec2 c = uv - 0.5;
    float rim = smoothstep(RIM, 0.5, max(abs(c.x), abs(c.y)));
    vec2 bend = c * LENS * rim;
    float spread = SPREAD * rim;
    vec3 col;
    col.r = texture(iChannel0, uv + bend + vec2(spread, 0.0)).r;
    col.g = texture(iChannel0, uv + bend).g;
    col.b = texture(iChannel0, uv + bend - vec2(spread, 0.0)).b;
    col *= 1.0 - VIGNETTE * rim;
    float sweep = 0.5 + 0.5 * sin(uv.x * 2.4 + uv.y * 1.3 - iTime * 0.6);
    col += SHEEN * rim * sweep;
    fragColor = vec4(col, 1.0);
}
