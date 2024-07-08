shader_type canvas_item;

uniform sampler2D viewport_texture: source_color;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	if (uv.x < 0.5){
		uv.x /= 4.0;
		uv.x += 0.375;
	}
	else {
		uv.x -= 0.5;
		
		float x = uv.x * 2.0;
		float x_shrinkage = pow(x, 3);
		uv.x /= 4.0 - 3.0 * x_shrinkage;
		
		uv.x += 0.5;
	}
	
	
	float y_growage = pow(SCREEN_UV.x, .2);
	uv.y -= 0.5;
	uv.y /= y_growage;
	uv.y += 0.5;
	
	vec4 final_color = texture(viewport_texture, uv);
	COLOR = final_color;
}
