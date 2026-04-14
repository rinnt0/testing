shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_intensity : hint_range(0.0, 0.3) = 0.08;
uniform float scanline_density : hint_range(50.0, 500.0) = 160.0;
uniform float scanline_speed : hint_range(0.0, 1.0) = 0.03;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 tex_color = texture(SCREEN_TEXTURE, uv);

    // Slow gentle drift
    float animated_y = uv.y + TIME * scanline_speed;
    float line = sin(animated_y * scanline_density) * 0.5 + 0.5;

    float factor = 1.0 - scanline_intensity * line;

    COLOR = vec4(tex_color.rgb * factor, tex_color.a);
}