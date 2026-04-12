shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float scanline_density : hint_range(100.0, 2000.0) = 480.0;
uniform float scanline_speed : hint_range(-5.0, 5.0) = 0.2;

void fragment() {
    vec2 uv = UV;

    vec4 tex_color = texture(TEXTURE, uv);

    // Slight vertical shift over time
    float animated_y = uv.y + TIME * scanline_speed;

    float line = sin(animated_y * scanline_density) * 0.5 + 0.5;

    float factor = 1.0 - scanline_intensity * line;

    COLOR = vec4(tex_color.rgb * factor, tex_color.a);
}
