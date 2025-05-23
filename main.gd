extends Control

const script_paint_context = preload("PaintContext.gd")
const script_paint_tool = preload("PaintTool.gd")
const script_paint_canvas = preload("res://canvas.gd")
const script_undo_manager = preload("res://UndoManager.gd")
const script_tool_pixel = preload("tool_pixel.gd")
const script_tool_fill = preload("tool_fill.gd")
const script_tool_line = preload("tool_line.gd")
const script_tool_selbox = preload("tool_sel_box.gd")

const shader_checkerboard = preload("res://checkerboard.gdshader")
const shader_texture = preload("res://simple_texture.gdshader")

var tool:PaintTool = null;
@onready var n_background:ColorRect = $BC_middle/BC_center/Background
@onready var n_img:PaintCanvas = $BC_middle/BC_center/Background/Canvas
@onready var n_img2:PaintCanvas = $BC_middle/BC_center/Background/Canvas_preview
@onready var lbl_status:Label = $BC_bottom/P/BC/lblStatus
@onready var n_undo_list:ItemList = $BC_middle/BC_left/P_actions/BC/undo_list
@onready var n_sb_zoom:SpinBox = $BC_top/P/BC/P_zoom/BC/sb_zoom
@onready var n_grid = $BC_middle/BC_center/Background/grid
var ctx:PaintContext;

var cur_file_path:String
var image_size:Vector2i = Vector2i(512,512);

func _ready():
	ctx = PaintContext.new();
	ctx.canvas = n_img;
	ctx.canvas2 = n_img2;
	ctx.undo_manager = UndoManager.new(ctx);
	ctx.undo_manager.undo_stack_changed.connect(_on_UndoManager_stack_changed);
	apply_fix_sb_enter_means_next();
	init_background();
	set_background("checkerboard", Color.WHITE, Color.LIGHT_GRAY, load("res://data/wizardtower.png"));
	print("hi")

func _process(delta:float)->void:
	update_status();
	# shader hot reload (for debug)
	#var shader_mat:ShaderMaterial = n_grid.material;
	#shader_mat.shader = ResourceLoader.load("res://grid.gdshader", "", ResourceLoader.CACHE_MODE_REPLACE); #temp: hot load the shader


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
	ctx.undo_manager.clear();
	print("image cleared")

func set_tool(tool_name):
	if tool_name == "pixel":	tool = Tool_Pixel.new(ctx);
	elif tool_name == "fill":	tool = Tool_Fill.new(ctx);
	elif tool_name == "line":	tool = Tool_Line.new(ctx);
	elif tool_name == "sel_box": tool = Tool_SelBox.new(ctx);
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
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_wheel_up(event.position);
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_wheel_down(event.position);
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
func canvas_restart(): if tool: tool.restart();

func _on_color_picker_color_changed(color: Color) -> void:
	ctx.cur_color = color;
	$BC_middle/BC_right/P_color/BC/BoxContainer/btnColorPicker.color = color;
	$BC_middle/BC_right/P_color/BC/C/ColorPicker.color = color;

func _on_btn_color_picker_color_changed(color: Color) -> void:
	ctx.cur_color = color;
	$BC_middle/BC_right/P_color/BC/BoxContainer/btnColorPicker.color = color;
	$BC_middle/BC_right/P_color/BC/C/ColorPicker.color = color;


func _on_file_index_pressed(index: int) -> void:
	if index == 0: # New...
		print("New file")
		$pop_new_file.show();
	if index == 1: # Open...
		print("Open file")
		$fd_open.show();
	if index == 2: # Save
		print("Save file")
		if(cur_file_path == ""):
			$fd_save_as.show();
		else:
			SaveFile(cur_file_path);
	if index == 3: # Save As
		print("Save As")
		$fd_save_as.show();


func _on_edit_index_pressed(index: int) -> void:
	if index == 0: #Undo
		print("Undo")
		ctx.undo_manager.undo();
	if index == 1: #Redo
		print("Redo")
		ctx.undo_manager.redo();
	if index == 2: #Canvas size
		print("Canvas size")

func resize_canvas(new_size):
	image_size = new_size;
	var BG = $BC_middle/BC_center/Background
	resize_canvas_nodes(new_size); 
	for canvas in BG.get_children():
		if canvas is PaintCanvas:
			canvas.clear();
	canvas_restart();
	resize_canvas_nodes(new_size); # too many side effects, got to fix it again!

func resize_canvas_nodes(new_size):
	var BG = $BC_middle/BC_center/Background
	BG.custom_minimum_size = new_size;
	BG.size = new_size;
	for canvas in BG.get_children():
		if canvas is TextureRect:
			canvas.picture_size = new_size;
			canvas.custom_minimum_size = new_size;
			#print(canvas.name +": resizing "+str(new_size)+"...");
			canvas.size = new_size;
			#print(canvas.name + " resized to "+str(canvas.size))
			canvas.position = Vector2i(0,0);


func new_file(settings):
	resize_canvas(settings.size);
	recenter_bg();
	ctx.undo_manager.clear();

func _on_pop_new_file_btn_accept_pressed() -> void:
	var new_size = Vector2i(
		$pop_new_file/BC/BC/sb_canvas_x.value,
		$pop_new_file/BC/BC/sb_canvas_y.value)
	new_file({"size":new_size})
	cur_file_path = "";

func _on_pop_new_file_btn_cancel_pressed() -> void:
	pass # Replace with function body.

func _on_fd_save_as_file_selected(path: String) -> void:
	cur_file_path = path;
	SaveFile(path);

func SaveFile(path:String):
	ctx.canvas.canvas_image.save_png(path);
	print("saved file as ["+path+"]");


func _on_fd_open_file_selected(path: String) -> void:
	cur_file_path = path;
	OpenFile(path);

func OpenFile(path:String):
	ctx.canvas.canvas_image.load(path);
	var size = ctx.canvas.canvas_image.get_size();
	print("resize everything to "+str(size))
	image_size = size;
	var BG = $BC_middle/BC_center/Background
	for canvas in BG.get_children():
		canvas.picture_size = size;
		if(canvas != ctx.canvas):
			canvas.clear();
		canvas.update_canvas.call();
	resize_grid();
	resize_canvas_nodes(size);
	recenter_bg();
	ctx.undo_manager.clear();
	print("loaded file ["+path+"]")

func apply_fix_sb_enter_means_next():
	var arr_sbs = [$pop_new_file/BC/BC/sb_canvas_x, $pop_new_file/BC/BC/sb_canvas_y];
	for sb in arr_sbs:
		var le:LineEdit = sb.get_line_edit();
		le.text_submitted.connect(_on_sb_enter_pressed);

func _on_sb_enter_pressed(_text):
	var event_press_tab = InputEventAction.new();
	event_press_tab.action = "ui_focus_next"
	event_press_tab.pressed = true
	Input.parse_input_event(event_press_tab);

func _on_UndoManager_stack_changed(stack:Array, head:int):
	print("Stack changed:");
	#print_undo_manager_stack(stack, head);
	populate_undo_list(stack, head);

func print_undo_manager_stack(stack:Array, head:int):
	for i in range(0, stack.size()):
		var S = "";
		if(i == head): S = S + "--> ";
		else: S = S + "    ";
		S = S + str(i)+": "+stack[i].name;
		print(S);
	for i in range(stack.size(), head):
		print(str(i)+"    : ...");
	if(head >= stack.size()):
		print("--> "+str(head)+": ...");

func populate_undo_list(stack, head):
	n_undo_list.clear()
	for item in stack:
		n_undo_list.add_item(item.name);
	if(head == -1):
		n_undo_list.deselect_all()
	else:
		n_undo_list.select(head);


func _on_undo_list_item_selected(index: int) -> void:
	ctx.undo_manager.jump_to(index);

func _input(event:InputEvent)->void:
	if event.is_action("ui_undo", true) and event.is_pressed():
		ctx.undo_manager.undo();
		get_viewport().set_input_as_handled();
	if event.is_action("ui_redo", true) and event.is_pressed():
		ctx.undo_manager.redo();
		get_viewport().set_input_as_handled();
		
var cur_zoom = 100;
var zoom_db_steps = 3.0;
var zoom_max = 10000; #percent
var zoom_min = 10; #percent
var zoom_anchor:Vector2;
var zoom_prev_scale:Vector2;

func zoom_val_next(val):
	var db = zoom_db_steps*log(val)/log(10);
	var new_db = round(db+1);
	var new_val = 10.0**(new_db/zoom_db_steps);
	new_val = min(new_val, zoom_max);
	return new_val;

func zoom_val_prev(val):
	var db = zoom_db_steps*log(val)/log(10);
	var new_db = round(db-1);
	var new_val = 10.0**(new_db/zoom_db_steps);
	new_val = max(new_val, zoom_min);
	return new_val;

func read_zoom_widget():
	cur_zoom = clamp(n_sb_zoom.value, zoom_min, zoom_max);
	n_sb_zoom.value = cur_zoom;

func write_zoom_widget():
	n_sb_zoom.set_value_no_signal(cur_zoom);

func _on_sb_zoom_value_changed(value: float) -> void:
	print("zoom val changed");
	zoom_anchor = get_screen_center_anchor();
	read_zoom_widget();
	apply_new_zoom();

func _on_btn_zoom_in_pressed() -> void:
	zoom_anchor = get_screen_center_anchor();
	cur_zoom = zoom_val_next(cur_zoom);
	write_zoom_widget();
	apply_new_zoom();

func _on_btn_zoom_out_pressed() -> void:
	zoom_anchor = get_screen_center_anchor();
	cur_zoom = zoom_val_prev(cur_zoom);
	write_zoom_widget();
	apply_new_zoom();


func _on_btn_zoom_rst_pressed() -> void:
	zoom_anchor = get_screen_center_anchor();
	cur_zoom = 100;
	write_zoom_widget();
	apply_new_zoom();

func _on_btn_zoom_fit_pressed() -> void:
	zoom_anchor = get_screen_center_anchor();
	cur_zoom = zoom_val_fit();
	write_zoom_widget();
	apply_new_zoom();

func apply_new_zoom():
	var new_scale = cur_zoom / 100.0; #convert from percent
	zoom_prev_scale = n_background.scale;
	n_background.scale = Vector2(new_scale, new_scale);
	resize_grid();
	if(zoom_val_fit() >= cur_zoom):
		recenter_bg();
	else:
		move_bg_to_anchor();

func zoom_val_fit():
	var n_bg_container:Control = $BC_middle/BC_center
	var ext_height:float = n_bg_container.size.y;
	var ext_width:float = n_bg_container.size.x;
	var int_height:float = n_background.size.y;
	var int_width:float = n_background.size.x;
	var ratio_y = ext_height / int_height; #int_height / ext_height;
	var ratio_x = ext_width / int_width; #int_width / ext_width;
	#print("dbg: zoom_val_fit: ratio_y "+str(ratio_y)+", ratio_x "+str(ratio_x));
	var ratio = min(ratio_y, ratio_x) * 100.0; #convert to percentage
	return ratio;

func recenter_bg():
	var bg_center = (n_background.scale*n_background.size)/2.0;
	var cont_center = $BC_middle/BC_center.size/2.0;
	var diff = cont_center - bg_center;
	#print("recenter by moving to "+str(diff))
	n_background.position = diff;
	#var new_bg_center = n_background.position + (n_background.scale*n_background.size)/2.0;
	#print("cont center: "+str(cont_center)+", bg center: "+str(bg_center));

func move_bg_to_anchor():
	var prev_anchor_global = n_background.position + zoom_prev_scale * zoom_anchor;
	var new_anchor_global = n_background.position + n_background.scale * zoom_anchor;
	#print("scale: prev "+str(zoom_prev_scale)+", new "+str(n_background.scale))
	#print("anchor: prev "+str(prev_anchor_global)+", new "+str(new_anchor_global));
	var diff = prev_anchor_global - new_anchor_global;
	n_background.position += diff;

func get_screen_center_anchor():
	var cont:Control = $BC_middle/BC_center;
	var cont_center = cont.size/2.0;
	var M1 = cont.get_global_transform();
	var M2inv = n_background.get_global_transform().affine_inverse();
	var offset_local = M2inv * M1 * cont_center;
	return offset_local;

func zoom_wheel_up(pos):
	zoom_anchor = pos;
	cur_zoom = zoom_val_next(cur_zoom);
	write_zoom_widget();
	apply_new_zoom();

func zoom_wheel_down(pos):
	zoom_anchor = pos;
	cur_zoom = zoom_val_prev(cur_zoom);
	write_zoom_widget();
	apply_new_zoom();
	
func _on_view_index_pressed(index: int) -> void:
	var view_menu:PopupMenu = $BC_top/P/BC/MenuBar/View
	if view_menu.is_item_checkable(index):
		view_menu.set_item_checked(index, not view_menu.is_item_checked(index));
	if index == 0: # Smooth pixels
		if view_menu.is_item_checked(0):
			set_smooth_pixels(true);
		else:
			set_smooth_pixels(false);
	elif index == 1: # Show grid
		if view_menu.is_item_checked(1):
			n_grid.show();
		else:
			n_grid.hide();
	elif index == 2: # Background...
		$pop_background.show();

func set_smooth_pixels(val):
	for canvas in n_background.get_children():
		if canvas is TextureRect:
			if val:
				canvas.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE;
			else:
				canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;

const min_grid_pixels = 16.0;
const grid_resize_factor = 4;

func resize_grid():
	var new_grid_size = image_size;
	var grid_cell_pixels = n_background.scale;
	var grid_scale = 1.0;
	while(min(grid_cell_pixels.x, grid_cell_pixels.y) <= min_grid_pixels):
		#print("grid_cell_pixels: "+str(grid_cell_pixels))
		# new_grid_size /= grid_resize_factor;
		grid_cell_pixels *= grid_resize_factor;
		grid_scale *= grid_resize_factor;
	var shader_mat:ShaderMaterial = n_grid.material;
	shader_mat.set_shader_parameter("res_x", new_grid_size.x);
	shader_mat.set_shader_parameter("res_y", new_grid_size.y);
	shader_mat.set_shader_parameter("grid_scale", grid_scale);
	shader_mat.set_shader_parameter("pixel_scale", n_background.scale);
	#print("new grid resolution: "+str(new_grid_size));
	
#background settings
var bg_type = "";
var bg_col1 = Color.WHITE
var bg_col2 = Color.GRAY
var bg_image = null;
var bg_mat_checkerboard;
var bg_mat_texture;

func init_background():
	bg_mat_checkerboard = ShaderMaterial.new();
	bg_mat_checkerboard.shader = shader_checkerboard;
	bg_mat_texture = ShaderMaterial.new();
	bg_mat_texture.shader = shader_texture;

func set_background(type:String, col1:Color, col2:Color, img):
	bg_type = type;
	bg_col1 = col1;
	bg_col2 = col2;
	bg_image = img;
	if type == "none":
		n_background.material = null;
		n_background.color = Color.TRANSPARENT;
	elif type == "single_color":
		n_background.material = null;
		n_background.color = bg_col1;
	elif type == "checkerboard":
		n_background.material = bg_mat_checkerboard;
		bg_mat_checkerboard.set_shader_parameter("color1", col1);
		bg_mat_checkerboard.set_shader_parameter("color2", col2);
	elif type == "image":
		n_background.material = bg_mat_texture;
		bg_mat_texture.set_shader_parameter("texture_albedo", bg_image);
	write_widget_background();
	
@onready var n_bg_type = $pop_background/BC/opt_background
@onready var n_lbl_col1 = $pop_background/BC/grid/lbl_col1
@onready var n_bg_col1 = $pop_background/BC/grid/cp_col1
@onready var n_lbl_col2 = $pop_background/BC/grid/lbl_col2
@onready var n_bg_col2 = $pop_background/BC/grid/cp_col2
@onready var n_lbl_image = $pop_background/BC/grid/lbl_image
@onready var n_bg_image = $pop_background/BC/grid/btn_image

func read_widget_background():
	bg_type = ["none", "single_color", "checkerboard", "image"][n_bg_type.selected]
	bg_col1 = n_bg_col1.color;
	bg_col2 = n_bg_col2.color;
	bg_image = n_bg_image.texture_normal;
	set_background(bg_type, bg_col1, bg_col2, bg_image);
	
func write_widget_background():
	n_bg_type.select({"none":0, "single_color":1, "checkerboard":2, "image":3}[bg_type]);
	n_bg_col1.color = bg_col1;
	n_bg_col2.color = bg_col2;
	n_bg_image.texture_normal = bg_image;
	
	var widget_visibility = {
		"none":[0,0,0],
		"single_color":[1,0,0],
		"checkerboard":[1,1,0],
		"image":[0,0,1]
	};
	var vis = widget_visibility[bg_type];
	n_lbl_col1.visible = vis[0];
	n_bg_col1.visible = vis[0];
	n_lbl_col2.visible = vis[1];
	n_bg_col2.visible = vis[1];
	n_lbl_image.visible = vis[2];
	n_bg_image.visible = vis[2];

func _on_opt_background_item_selected(_index: int) -> void:
	read_widget_background();
func _on_background_cp_col_1_color_changed(_color: Color) -> void:
	read_widget_background();
func _on_cp_col_2_color_changed(_color: Color) -> void:
	read_widget_background();

func _on_background_btn_image_pressed() -> void:
	$fd_select_image.show();

func _on_fd_select_image_file_selected(path: String) -> void:
	var img = Image.new()
	var err:Error = img.load(path);
	if err == OK:
		n_bg_image.texture_normal = ImageTexture.create_from_image(img);
		read_widget_background();
	else:
		show_error("Could not load image: "+error_string(err))

func show_error(message: String):
	var alert = AcceptDialog.new()
	alert.dialog_text = message
	alert.title = "Error"
	alert.connect("confirmed", alert.queue_free)
	get_tree().root.add_child(alert)
	alert.popup_centered()
