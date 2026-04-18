shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 3.0) = 1.4;
uniform float vignette_radius : hint_range(0.1, 1.0) = 0.55;
uniform float vignette_softness : hint_range(0.01, 0.8) = 0.45;
uniform float fisheye_strength : hint_range(0.0, 0.3) = 0.055;
uniform float fisheye_falloff : hint_range(1.0, 8.0) = 3.5;

void fragment() {
    vec2 centered = UV - 0.5;
    float dist = length(centered);

    // Vignette alpha — 0 in the middle, dark at edges
    float vig = smoothstep(vignette_radius, vignette_radius - vignette_softness, dist);
    float darkness = (1.0 - vig) * vignette_strength * 0.55;

    // Fisheye just shifts where the darkness samples from
    float warp = 1.0 + fisheye_strength * pow(dist, fisheye_falloff);
    vec2 warped = centered * warp;
    float warped_dist = length(warped);
    float corner_push = smoothstep(vignette_radius, vignette_radius - vignette_softness, warped_dist);
    darkness = max(darkness, (1.0 - corner_push) * vignette_strength * 0.4);

    COLOR = vec4(0.0, 0.0, 0.0, clamp(darkness, 0.0, 1.0));
}