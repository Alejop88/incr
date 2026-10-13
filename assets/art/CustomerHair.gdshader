shader_type canvas_item;
uniform vec2 pixel_grid = vec2(0.0);
uniform bool bald_front = false;
uniform vec4 atlas_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 hair_color : source_color = vec4(0.35, 0.18, 0.08, 1.0);
void fragment() {
	vec2 sample_uv = UV;
	if (pixel_grid.x > 0.0) {
		vec2 local_uv = clamp((UV - atlas_region.xy) / atlas_region.zw, vec2(0.0), vec2(0.99999));
		sample_uv = atlas_region.xy + (floor(local_uv * pixel_grid) + vec2(0.5)) / pixel_grid * atlas_region.zw;
	}
	vec4 pixel = texture(TEXTURE, sample_uv);
	if (bald_front) {
		float head_x = (sample_uv.x - atlas_region.x) / atlas_region.z;
		if (head_x > 0.12 && head_x < 0.88) { pixel.a = 0.0; }
	}
	if (pixel_grid.x > 0.0) {
		pixel.a = step(0.5, pixel.a);
	}
	float light = pixel.r;
	vec3 color = light < 0.15 ? hair_color.rgb * 0.25 : hair_color.rgb * (light < 0.65 ? 0.85 : 1.25);
	COLOR = vec4(color, pixel.a);
}
