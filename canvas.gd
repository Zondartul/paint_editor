# Does low-level image editing stuff, like putting pixels on the bitmap.
# this script based on example script from:
# 	https://codeberg.org/sossees/simplest-paint-in-godot-4
# licensed with MIT License:
# 	https://codeberg.org/sosasees/mit-license/raw/branch/2021/LICENSE
extends TextureRect

@export var picture_size : Vector2i = Vector2i(512, 512)
@export var padding : int = 64
@export var brush_radius : Vector2i = Vector2i(4, 4)
@export var line_tween_points : int = 128
@export var brush_color : Color = Color('020202')

var canvas_image : Image
var canvas_texture : ImageTexture
var brush_image : Image

var update_canvas : Callable = func() -> void:
	canvas_texture = ImageTexture.create_from_image(canvas_image)
	texture = canvas_texture

var line : PackedVector2Array

@warning_ignore("shadowed_variable_base_class")
var draw_dot : Callable = func(position:Vector2i) -> void:
	canvas_image.fill_rect(
		Rect2i(position - brush_radius, brush_radius*2),
		brush_color
	)
var draw_line : Callable = func() -> void:
	for i in line_tween_points: # could be changed to a parallel for loop
		draw_dot.call(
			lerp( line[-1], line[-2], float(i+1)/(line_tween_points+1) )
		)


func _ready() -> void:
	canvas_image = Image.create(
		picture_size.x + padding*2, picture_size.y + padding*2,
		false, Image.FORMAT_RGBA8
	)
	update_canvas.call()


func _gui_input(event) -> void:
	if (event is InputEventMouse and event.get_button_mask() == 1) \
			or event is InputEventScreenDrag:
		line.append( event.get_position() )
		if line.size() > 0:
			draw_dot.call(line[-1])
			if line.size() > 1:
				draw_line.call()
		update_canvas.call()
	else:
		line.clear()
