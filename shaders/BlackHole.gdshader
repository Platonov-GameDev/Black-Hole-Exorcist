shader_type canvas_item;

uniform sampler2D noise;
uniform float size = 10.0;
uniform float opacity = 1.0;
uniform float time = 0.0;

void fragment() {
	vec4 final_color = vec4(0.0);
	vec4 orange_color = vec4(1., 0.216, 0.039, 1.0);
	vec4 blue_color = vec4(0.,0.784,0.961, 1.0);
	vec4 white_color = vec4(1.0);
	
	vec2 coords = (UV - vec2(0.5)) / 2.0;
	
	float angle = atan(coords.y, coords.x) + PI - time * 0.25;
	float d = length(coords) * 80.0 / size;
	vec2 noise_uv = UV;
	noise_uv.x += time;
	vec4 noise_color = texture(noise, noise_uv);
	
	float edge_1 = 1.0 + sin(
		tan((angle * 3.0 + time * 2.0) * 0.5) * 10.0
	) / PI;
	float edge_2 = (sin(
		angle * 8.0
		+ d * size
		+ sin(angle * 30.0 + time * 4.0) / PI
		+ noise_color.r * 10.0
	) - d * 5.0 + size / 3.0);
	
	final_color += orange_color * step(edge_1, edge_2);
	final_color.rgb -= white_color.rgb * step(edge_1, edge_2 - 1.5);
	final_color.a *= opacity;
	
	COLOR = final_color;
}
