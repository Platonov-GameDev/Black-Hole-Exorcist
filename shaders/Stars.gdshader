shader_type canvas_item;

uniform float scroll_speed = 1.0;
uniform float zoom = 1.0;
uniform float player_x;
uniform sampler2D noise: repeat_enable;

void fragment() {
	vec4 final_color = vec4(0.0);
	
	final_color.a = 1.0;
	
	vec2 uv = UV;
	uv.x += player_x * scroll_speed * 0.1;
	uv /= zoom;
	
	vec4 noise_color = texture(noise, uv / 300.0);
	final_color = vec4(1.0);
	final_color.a = step(noise_color.r + noise_color.g + noise_color.b, .01);
	
	COLOR = final_color;
}
