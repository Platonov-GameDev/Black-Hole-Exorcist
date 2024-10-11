shader_type canvas_item;

uniform sampler2D viewport_texture: source_color, filter_nearest;
uniform float edge_distance = 0.1;
uniform float space_distortion = 1.0;

void fragment() {
	float pixelate_amount = 600.0;
	//vec2 uv = round(
		//UV * float(pixelate_amount)) / float(pixelate_amount
	//);
	vec2 uv = UV;
	float alpha = 1.0;
	
	vec2 vector_from_center = uv - vec2(0.5);
	
	float distance_to_edge = 
		 edge_distance - length(vector_from_center);
	//if (abs(distance_to_edge) < 0.1) {
		//vector_from_center = normalize(vector_from_center) * (
			//length(vector_from_center)
			//+ distance_to_edge * 2.0 * edge_distance
		//);
	//} else if (sign(distance_to_edge) > 0.0) {
		//vector_from_center = normalize(vector_from_center) * (
			//length(vector_from_center)
			//+ 0.1 * 2.0 * edge_distance
		//);
	//}
	if (length(vector_from_center) > 0.5) {
		alpha = 0.0;
	}
	
	vector_from_center = normalize(vector_from_center)
		* (pow(length(vector_from_center) - distance_to_edge, space_distortion) + distance_to_edge);
	
	uv = vec2(0.5) + vector_from_center;
	
	vec4 final_color = texture(viewport_texture, uv);
	final_color.a = alpha;
	
	COLOR = final_color;
}
