shader_type canvas_item;

uniform sampler2D viewport_texture: source_color, filter_nearest;

void fragment() {
	float pixelate_amount = 600.0;
	vec2 uv = round(
		UV * float(pixelate_amount)) / float(pixelate_amount
	);
	float alpha = 1.0;
	
	vec2 vector_from_center = uv - vec2(0.5);
	if (length(vector_from_center) <= 0.1) {
		vector_from_center *= length(vector_from_center * 10.0);
		vector_from_center /= 4.0;
	} else if (length(vector_from_center) <= 0.5) {
		//float divider = 1.0 + 3.0 *
			//pow((0.5 - length(vector_from_center)) / 0.4, 0.5);
		//vector_from_center /= divider;
	} else {
		alpha = 0.0;
	}
	
	uv = vec2(0.5) + vector_from_center;
	vec4 final_color = texture(viewport_texture, uv);
	final_color.a = alpha;
	
	COLOR = final_color;
}
