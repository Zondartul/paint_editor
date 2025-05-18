shader_type canvas_item;

uniform float res_x = 512;
uniform float res_y = 512;
uniform float grid_scale = 1.0;
uniform vec2 pixel_scale = vec2(1.0,1.0);
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 cell = vec2(res_x, res_y);
    vec2 pos = UV * cell / grid_scale;
    vec2 UV_next = UV + vec2(dFdx(UV.x), dFdy(UV.y));
	vec2 pos_next = UV_next * cell / grid_scale;
	
	//float thickness = 1.0/16.0;
	//float line_x = mod(pos.x, 1.0) <= thickness ? 1.0 : 0.0;
    //float line_y = mod(pos.y, 1.0) <= thickness ? 1.0 : 0.0;
    float line_x = int(pos.x) < int(pos_next.x) ? 1.0 : 0.0;
	float line_y = int(pos.y) < int(pos_next.y) ? 1.0 : 0.0;
	
    float grid = max(line_x, line_y);
    vec3 inverted_color = 1.0 - texture(screen_texture, SCREEN_UV).xyz;
	vec4 inv_col4 = vec4(inverted_color.xyz, 1.0);
    COLOR = mix(vec4(0.0), inv_col4, grid);
}
