shader_type canvas_item;

uniform sampler2D noise;

void fragment() {
	vec4 final_color = vec4(0.0);
	vec4 orange_color = vec4(1., 0.216, 0.039, 1.0);
	vec4 blue_color = vec4(0.,0.784,0.961, 1.0);
	vec4 white_color = vec4(1.0);
	
	vec2 coords = (UV - vec2(0.5)) * 2.0;
	
	float angle = atan(coords.y, coords.x) + PI - TIME * 0.25;
	float d = length(coords);
	vec2 noise_uv = UV;
	noise_uv.x += TIME;
	vec4 noise_color = texture(noise, noise_uv);
	
	float edge_1 = 1.0 + sin(tan((angle * 9.0 + TIME * 2.0) * 0.5) * 10.0) / PI;
	float edge_2 = (sin(angle * 16.0 + d * 40.0 + sin(angle * 30.0 + TIME * 4.0) / PI + noise_color.r * 10.0) - d * 5.0 + 4.0);
	
	final_color += orange_color * step(edge_1, edge_2);
	final_color += blue_color * step(edge_1, edge_2 - 1.0);
	final_color.rgb -= white_color.rgb * step(1.0 , step(d + sin(TIME * 5.0 + angle + sin(TIME * 500.0) + noise_color.r * 0.1) * 0.01, 0.1));
	
	COLOR = final_color;
}
