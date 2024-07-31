shader_type canvas_item;

uniform sampler3D white_streaks_noise: repeat_enable;
uniform sampler3D orange_streaks_noise: repeat_enable;
uniform float speed = 1;

void fragment() {
	vec4 final_color = vec4(0.0);
	
	vec4 orange_background = vec4(0.0);
	vec4 orange_streaks_coords = vec4(UV.x + mod(TIME * speed / 10.0, 1.0), UV.y, mod(TIME / 10.0, 1.0), 1.0);
	vec4 orange_streaks = textureProj(orange_streaks_noise, orange_streaks_coords);
	orange_background.rgb = vec3(1., 0.216, 0.039);
	orange_background.a = step((orange_streaks.r + orange_streaks.g + orange_streaks.b) / 3.0, 1.0 - UV.y * 0.5 - 0.2);
	
	vec4 white_streaks_coords = vec4(UV.x + mod(TIME * speed / 10.0, 1.0), UV.y, mod(TIME / 10.0, 1.0), 1.0);
	vec4 white_streaks = textureProj(white_streaks_noise, white_streaks_coords);
	white_streaks.a = step((white_streaks.r + white_streaks.g + white_streaks.b) / 3.0, UV.y * 0.2 + 0.3);
	white_streaks.rgb = vec3(1., 0.988, 0.98);
	white_streaks *= white_streaks.a;
	
	final_color = orange_background;
	final_color += white_streaks;
	
	COLOR = final_color;
}
