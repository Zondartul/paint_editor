shader_type canvas_item;
uniform sampler2D texture_albedo : source_color;

void fragment() {
    COLOR = texture(texture_albedo, UV);
}