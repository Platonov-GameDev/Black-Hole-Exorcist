shader_type canvas_item;

uniform sampler2D viewport_texture: source_color, filter_nearest;
uniform float edge_distance = 0.1;

void fragment() {
	vec2 uv = UV;
	float alpha = 1.0;
	
	vec2 vector_from_center = uv - vec2(0.5);
	
	float distance_to_edge = 
		 edge_distance - length(vector_from_center);
	if (length(vector_from_center) > 0.5) {
		alpha = 0.0;
	}
	
	vector_from_center = normalize(vector_from_center)
		* pow(
			length(vector_from_center * (1.0 / edge_distance)),
			1.0 - abs(distance_to_edge) * (1.2 + 0.8 * sign(distance_to_edge)))
		/ (1.0 / edge_distance);
	
	uv = vec2(0.5) + vector_from_center;
	
	vec4 final_color = texture(viewport_texture, uv);
	final_color.a = alpha;
	
	COLOR = final_color;
}
