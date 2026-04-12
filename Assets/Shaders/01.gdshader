shader_type canvas_item;

// Declare the screen texture uniform
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float blur_strength : hint_range(0.0, 10.0) = 2.0;
uniform float blur_radius : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 center = vec2(0.5, 0.5); // Center of the screen
    vec2 uv = SCREEN_UV; // Use SCREEN_UV for texture coordinates
    vec2 dir = uv - center;
    float dist = length(dir);

    // Apply blur based on distance from center
    float blur_amount = smoothstep(0.0, blur_radius, dist) * blur_strength;

    // Sample the texture with an offset to create a blur effect
    vec4 color = texture(SCREEN_TEXTURE, uv);
    for (float i = 0.0; i < 10.0; i++) {
        vec2 offset = dir * (i / 10.0) * blur_amount;
        color += texture(SCREEN_TEXTURE, uv + offset);
    }
    color /= 10.0;

    COLOR = color;
}