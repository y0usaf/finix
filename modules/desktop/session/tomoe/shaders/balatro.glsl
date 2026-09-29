#define HEX(c) (vec3(((c) >> 16) & 0xff, ((c) >> 8) & 0xff, (c) & 0xff) / 255.0)
#define COLOR_1 HEX(0xde443b)
#define COLOR_2 HEX(0x006bb4)
#define COLOR_3 HEX(0x162325)
#define CONTRAST 3.5
#define LIGHTING 0.4
#define SPIN_AMOUNT 0.25
#define SPIN_ROTATION -2.0
#define SPEED 7.0

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float diagonal = length(iResolution.xy);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / diagonal;
    float radius = length(uv);
    float angle = atan(uv.y, uv.x) + 302.2 + 0.2 * SPIN_ROTATION
                - 20.0 * (SPIN_AMOUNT * radius + 1.0 - SPIN_AMOUNT);
    uv = radius * vec2(cos(angle), sin(angle)) * 30.0;
    float t = iTime * SPEED;
    vec2 uv2 = vec2(uv.x + uv.y);
    for (int i = 0; i < 5; i++) {
        uv2 += sin(max(uv.x, uv.y)) + uv;
        uv += 0.5 * vec2(cos(5.1123314 + 0.353 * uv2.y + t * 0.131121), sin(uv2.x - 0.113 * t));
        uv -= cos(uv.x + uv.y) - sin(uv.x * 0.711 - uv.y);
    }
    float contrast = 0.25 * CONTRAST + 0.5 * SPIN_AMOUNT + 1.2;
    float paint = clamp(length(uv) * 0.035 * contrast, 0.0, 2.0);
    float c1 = max(0.0, 1.0 - contrast * abs(1.0 - paint));
    float c2 = max(0.0, 1.0 - contrast * abs(paint));
    float c3 = 1.0 - min(1.0, c1 + c2);
    float light = (LIGHTING - 0.2) * max(c1 * 5.0 - 4.0, 0.0) + LIGHTING * max(c2 * 5.0 - 4.0, 0.0);
    vec3 color = (0.3 / CONTRAST) * COLOR_1
               + (1.0 - 0.3 / CONTRAST) * (COLOR_1 * c1 + COLOR_2 * c2 + COLOR_3 * c3) + light;
    fragColor = vec4(color, 1.0);
}
