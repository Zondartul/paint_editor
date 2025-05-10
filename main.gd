extends Control

var cur_tool = null
@onready var n_img:TextureRect = $BC_middle/BC_center/TextureRect
@onready var lbl_status:Label = $BC_bottom/P/BC/lblStatus

func _ready():
	print("hi")

func _process(delta:float)->void:
	update_status();

func update_status():
	var str_status = "Tool: " + get_cur_tool_str()
	lbl_status.text = str_status;
	
func get_cur_tool_str():
	if not cur_tool:
		return "None";
	else:
		return cur_tool.name;

func clear_image():
	print("image cleared")

func set_tool(tool_name):
	if tool_name == "brush":
		cur_tool = {"name":tool_name};
	else:
		print("unknown tool ["+tool_name+"]")
		return;
	print("tool set to "+tool_name);

func _on_btn_clear_pressed() -> void:
	clear_image();
	
func _on_btn_brush_pressed() -> void:
	set_tool("brush")
