shader_type canvas_item;
uniform vec4 skin_color : source_color = vec4(0.973, 0.788, 0.678, 1.0);
uniform bool hide_body = false;

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	// Keep the eyes and dark outline; recolor the shared body's skin only.
	if (pixel.r > 0.35) {
		float shade = pixel.r < 0.80 ? 0.76 : (pixel.r < 0.92 ? 0.89 : 1.0);
		pixel.rgb = skin_color.rgb * shade;
	}
	COLOR = pixel;
	if (hide_body) { COLOR.a = 0.0; }
}
