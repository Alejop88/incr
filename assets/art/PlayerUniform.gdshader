shader_type canvas_item;
uniform vec4 skin_color : source_color = vec4(0.91, 0.71, 0.56, 1.0);
uniform vec4 body_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 body_size = vec2(140.0, 280.0);
uniform int facing = 0;

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	vec2 local = (UV - body_region.xy) / body_region.zw;
	float y = local.y * body_size.y;
	float x = local.x;
	if (pixel.r > 0.35) {
		float shade = pixel.r < 0.80 ? 0.76 : (pixel.r < 0.92 ? 0.89 : 1.0);
		vec3 color = skin_color.rgb;
		bool profile = facing == 1 || facing == 2;
		bool torso = profile ? (x > 0.36 && x < 0.74) : (x > 0.27 && x < 0.73);
		if (y >= 120.0 && y < 180.0) {
			color = vec3(0.92, 0.90, 0.82); // White shirt and sleeves.
			if (torso) { color = vec3(0.18, 0.20, 0.24); } // Waistcoat.
			if (facing == 0 && x > 0.44 && x < 0.56) {
				color = y < 144.0 ? vec3(0.92, 0.90, 0.82) : vec3(0.18, 0.20, 0.24);
			}
			if (facing == 0 && y >= 132.0 && y < 144.0 && x > 0.36 && x < 0.64) {
				color = vec3(0.45, 0.15, 0.15); // Fixed burgundy bow tie.
			}
		} else if (y >= 180.0 && (torso || y >= 204.0)) {
			color = vec3(0.18, 0.20, 0.24); // Trousers.
			if (y < 198.0 && torso && facing != 3) {
				color = vec3(0.92, 0.90, 0.82); // Short white apron.
			}
		}
		pixel.rgb = color * shade;
	}
	COLOR = pixel;
}
