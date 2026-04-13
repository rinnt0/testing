shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float blur_strength : hint_range(0.0, 10.0) = 2.0;
uniform float blur_radius : hint_range(0.0, 1.0) = 0.4;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.2;

// Simple random function for the jitter
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = SCREEN_UV;
    vec2 dir = uv - center;
    float dist = length(dir);

    // Calculate how much "glitch" to apply based on distance from center
    // This makes the edges much more unstable than the center
    float edge_factor = smoothstep(blur_radius, 1.0, dist);
    
    // Create a jitter effect using time and random noise
    float jitter = (random(vec2(TIME, uv.y)) - 0.5) * glitch_intensity * edge_factor;
    
    // Chromatic Aberration: Shift RGB channels differently
    float shift = blur_strength * 0.01 * edge_factor;
    
    // Apply horizontal jitter to the UVs
    vec2 glitch_uv = vec2(uv.x + jitter, uv.y);

    // Sample channels with different offsets for that "glitchy" fringe
    float r = texture(SCREEN_TEXTURE, glitch_uv + (dir * shift)).r;
    float g = texture(SCREEN_TEXTURE, glitch_uv).g;
    float b = texture(SCREEN_TEXTURE, glitch_uv - (dir * shift)).b;

    vec4 color = vec4(r, g, b, 1.0);
    
    // Optional: Add very subtle scanlines at the edges
    float scanline = sin(uv.y * 800.0) * 0.04 * edge_factor;
    color.rgb -= scanline;

    COLOR = color;
}