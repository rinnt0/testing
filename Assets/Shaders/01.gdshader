shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// --- Blur ---
uniform float blur_strength : hint_range(0.0, 10.0) = 2.0;
uniform float blur_radius : hint_range(0.0, 1.0) = 0.4;

// --- Chromatic Aberration ---
uniform float ca_strength : hint_range(0.0, 10.0) = 2.0;
uniform float ca_radius : hint_range(0.0, 1.0) = 0.2;

// --- Glitch / Jitter ---
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float glitch_radius : hint_range(0.0, 1.0) = 0.4;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = SCREEN_UV;
    vec2 dir = uv - center;
    float dist = length(dir);

    // Independent edge factors per effect
    float blur_edge   = smoothstep(blur_radius,   1.0, dist);
    float ca_edge     = mix(1.0, dist, ca_radius);
    float glitch_edge = smoothstep(glitch_radius, 1.0, dist);

    // Jitter
    float jitter = (random(vec2(TIME, uv.y)) - 0.5) * glitch_intensity * glitch_edge;
    vec2 glitch_uv = vec2(uv.x + jitter, uv.y);

    // Gaussian blur — 9-tap kernel applied around the (jittered) UV
    float pixel_size = blur_strength * 0.001 * blur_edge;
    vec4 blurred = vec4(0.0);
    float weights[9] = float[](
        0.0625, 0.125, 0.0625,
        0.125,  0.25,  0.125,
        0.0625, 0.125, 0.0625
    );
    int i = 0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(float(x), float(y)) * pixel_size;
            blurred += texture(SCREEN_TEXTURE, glitch_uv + offset) * weights[i];
            i++;
        }
    }

    // Chromatic aberration on top of the blurred result
    float shift = ca_strength * 0.01 * ca_edge;
    float r = texture(SCREEN_TEXTURE, glitch_uv + (dir * shift)).r;
    float b = texture(SCREEN_TEXTURE, glitch_uv - (dir * shift)).b;

    // Blend CA channels into the blurred color
    vec4 color = blurred;
    color.r = mix(blurred.r, r, ca_edge);
    color.b = mix(blurred.b, b, ca_edge);

    COLOR = vec4(color.rgb, 1.0);
}