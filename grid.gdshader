shader_type canvas_item;

uniform float res_x = 512;
uniform float res_y = 512;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 cell = vec2(res_x, res_y);
    vec2 pos = UV * cell;
    
    float thickness = 0.0625;
    float line_x = mod(pos.x, 1.0) < thickness ? 1.0 : 0.0;
    float line_y = mod(pos.y, 1.0) < thickness ? 1.0 : 0.0;
    
    float grid = max(line_x, line_y);
    vec3 inverted_color = 1.0 - texture(screen_texture, SCREEN_UV).xyz;
	vec4 inv_col4 = vec4(inverted_color.xyz, 1.0);
    COLOR = mix(vec4(0.0), inv_col4, grid);
}
