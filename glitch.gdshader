shader_type canvas_item;

uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float glitch_speed : hint_range(0.0, 10.0) = 2.0;
uniform float block_size : hint_range(1.0, 40.0) = 4.0;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White

// Classic 2D random function
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // Simulate pixel blocks
    vec2 block_uv = floor(uv * block_size) / block_size;

    // Use time to animate glitch
    float t = TIME * glitch_speed;

    // Random value per block that changes over time
    float glitch = rand(vec2(block_uv.y * 100.0, floor(t))) * glitch_intensity;

    // Horizontal glitch offset
    uv.x += glitch * 0.05;

    // Random flicker block glitch
    float flicker = rand(vec2(block_uv * floor(t))) > 0.9 ? 0.5 : 1.0;

    vec4 color = base_color * flicker;

    COLOR = vec4(color.rgb, color.a);
}
