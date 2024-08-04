shader_type canvas_item;

uniform sampler2D viewport_texture: source_color, filter_nearest;

void fragment() {
	vec2 uv = UV;
	
	vec2 vector_from_center = uv - vec2(0.5);
	if (length(vector_from_center) <= 0.1) {
		vector_from_center *= length(vector_from_center * 10.0);
		vector_from_center /= 4.0;
	} else if (length(vector_from_center) <= 0.5) {
		float divider = 1.0 + 3.0 *
			pow((0.5 - length(vector_from_center)) / 0.4, 0.5);
		vector_from_center /= divider;
	} else {
		vector_from_center = normalize(vector_from_center) * 0.5;
	}
	
	uv = vec2(0.5) + vector_from_center;
	
	vec4 final_color = texture(viewport_texture, uv);
	COLOR = final_color;
}
