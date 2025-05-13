extends Control

const script_paint_context = preload("PaintContext.gd")
const script_paint_tool = preload("PaintTool.gd")
const script_paint_canvas = preload("res://canvas.gd")
const script_tool_pixel = preload("tool_pixel.gd")
const script_tool_fill = preload("tool_fill.gd")

var tool:PaintTool = null;
@onready var n_img:PaintCanvas = $BC_middle/BC_center/Background/Canvas
@onready var lbl_status:Label = $BC_bottom/P/BC/lblStatus
var ctx:PaintContext;

func _ready():
	ctx = PaintContext.new();
	ctx.canvas = n_img;
	print("hi")

func _process(delta:float)->void:
	update_status();

func update_status():
	var str_status = "Tool: " + get_cur_tool_str()
	lbl_status.text = str_status;
	
func get_cur_tool_str():
	if not tool:
		return "None";
	else:
		return tool.name;

func clear_image():
	n_img.clear();
	print("image cleared")

func set_tool(tool_name):
	if tool_name == "pixel":	tool = Tool_Pixel.new(ctx);
	if tool_name == "fill":		tool = Tool_Fill.new(ctx);
	else:
		print("unknown tool ["+tool_name+"]")
		return;
	print("tool set to "+tool_name);

func _on_btn_clear_pressed() -> void:
	clear_image();
	
func _on_btn_brush_pressed() -> void:	set_tool("brush")
func _on_btn_pixel_pressed() -> void:	set_tool("pixel")
func _on_btn_fill_pressed() -> void:	set_tool("fill")
func _on_btn_erase_pressed() -> void:	set_tool("eraser")
func _on_btn_sel_box_pressed() -> void:	set_tool("sel_box")
func _on_btn_sel_wand_pressed() -> void:	set_tool("sel_wand")
func _on_btn_line_pressed() -> void:	set_tool("line")


func _on_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				canvas_lmb_down(event.position);
			if event.button_index == MOUSE_BUTTON_RIGHT:
				canvas_rmb_down(event.position);
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				canvas_mmb_down(event.position);
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				canvas_lmb_up(event.position);
			if event.button_index == MOUSE_BUTTON_RIGHT:
				canvas_rmb_up(event.position);
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				canvas_mmb_up(event.position);
	if event is InputEventMouseMotion:
		canvas_mouse_move(event.position);

func _on_canvas_mouse_entered() -> void:
	canvas_mouse_enter();

func _on_canvas_mouse_exited() -> void:
	canvas_mouse_exit();

func canvas_lmb_down(pos): if tool: tool.lmb_down(pos);
func canvas_rmb_down(pos): if tool: tool.rmb_down(pos);
func canvas_mmb_down(pos): if tool: tool.mmb_down(pos);
func canvas_lmb_up(pos): if tool: tool.lmb_up(pos);
func canvas_rmb_up(pos): if tool: tool.rmb_up(pos);
func canvas_mmb_up(pos): if tool: tool.mmb_up(pos);
func canvas_mouse_move(pos): if tool: tool.mouseMove(pos);
func canvas_mouse_enter(): pass
func canvas_mouse_exit(): pass


func _on_color_picker_color_changed(color: Color) -> void:
	ctx.cur_color = color;
	$BC_middle/BC_right/P_color/BC/BoxContainer/btnColorPicker.color = color;
	$BC_middle/BC_right/P_color/BC/C/ColorPicker.color = color;

func _on_btn_color_picker_color_changed(color: Color) -> void:
	ctx.cur_color = color;
	$BC_middle/BC_right/P_color/BC/BoxContainer/btnColorPicker.color = color;
	$BC_middle/BC_right/P_color/BC/C/ColorPicker.color = color;
