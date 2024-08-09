shader_type canvas_item;

uniform sampler2D noise: repeat_enable;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
	vec4 final_color = vec4(0.0);
	final_color.a = 1.0;
	ivec2 size = textureSize(noise, 0);
	
	vec2 uv = UV;
	
	uv = round(uv * float(size.x)) / float(size.x);
	final_color = vec4(1.0);
	final_color.a = step(
		clamp(random(uv) - random(uv + 0.5), 0.0, 1.0),
		.96
	);
	final_color.a = step(final_color.a, 0.5);
	
	uv.x += TIME * 0.001;
	vec4 noise_color = texture(noise, uv);
	final_color.rgb *= noise_color.r * 8.0;
	
	COLOR = final_color;
}
