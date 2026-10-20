shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float scanline_intensity : hint_range(0.0, 0.3) = 0.05;
uniform float scanline_density : hint_range(50.0, 500.0) = 180.0;
uniform float scanline_speed : hint_range(0.0, 1.0) = 0.02;
uniform float ps1_strength : hint_range(0.0, 1.0) = 0.65;
uniform float ps1_color_levels : hint_range(2.0, 64.0) = 32.0;
uniform float ps1_dither_strength : hint_range(0.0, 1.0) = 0.55;
uniform float ps1_rgb_split : hint_range(0.0, 2.0) = 0.45;
uniform vec2 ps1_resolution = vec2(320.0, 180.0);

float bayer2(vec2 point) {
	return mod(point.x * 2.0 + point.y * 3.0, 4.0);
}

float bayer4(vec2 point) {
	vec2 low_bits = mod(point, 2.0);
	vec2 high_bits = floor(point * 0.5);
	return (bayer2(high_bits) * 4.0 + bayer2(low_bits)) / 16.0;
}

void fragment() {
	vec2 pixel_position = floor(SCREEN_UV * ps1_resolution);
	vec2 snapped_uv = (pixel_position + vec2(0.5)) / ps1_resolution;
	vec2 sample_uv = mix(SCREEN_UV, snapped_uv, ps1_strength);
	vec2 rgb_offset = vec2(ps1_rgb_split / ps1_resolution.x, 0.0) * ps1_strength;

	float red = texture(SCREEN_TEXTURE, sample_uv - rgb_offset).r;
	float green = texture(SCREEN_TEXTURE, sample_uv).g;
	float blue = texture(SCREEN_TEXTURE, sample_uv + rgb_offset).b;
	vec3 color = vec3(red, green, blue);

	float dither = (bayer4(pixel_position) - 0.46875) * ps1_dither_strength * ps1_strength;
	float levels = max(ps1_color_levels - 1.0, 1.0);
	vec3 quantized = floor(clamp(color + dither / levels, 0.0, 1.0) * levels + 0.5) / levels;
	color = mix(color, quantized, ps1_strength);

	float scanline = sin((SCREEN_UV.y + TIME * scanline_speed) * scanline_density) * 0.5 + 0.5;
	color *= 1.0 - scanline_intensity * scanline;

	COLOR = vec4(color, texture(SCREEN_TEXTURE, sample_uv).a);
}
