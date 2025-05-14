extends PaintTool;
class_name Tool_SelBox;
# pixel tool 
var context:PaintContext;
var is_lmb_down = false;
var prev_pos:Vector2i = Vector2i(0,0);

var is_something_selected = false;
var selected_region = null;
var region_pos = Vector2i(0,0);
# when nothing is selected:
#  click-drag selects something (copies it to canvas2)
# when something is selected:
#  ctrl-C pressed - copy selection to clipboard, end tool.
#  anything else - cut from canvas1, then:
#  - left-click-drag:
#  -- on body: moves selection
#  -- on edge: scales selection
#  -- on corner: rotates selection?
#  - right-click: paste from canvas2 to canvas1.
#  - ctrl-X cuts selection (end tool, keep snippet in clipboard)
# when not using this tool and something is in clipboard:
#  ctrl-V inserts something to canvas2, selects it without touching canvas1.

func _init(new_ctx:PaintContext):
	context = new_ctx;

func reset():
	is_something_selected = false;
	selected_region = null;
	context.canvas2.clear();

func lmb_down(pos):	
	if not is_something_selected:
		context.undo_manager.action_begin("Box select");
	prev_pos = pos; 
	is_lmb_down = true;
	
func lmb_up(pos:Vector2i):   
	is_lmb_down = false;
	if not is_something_selected:
		var R = Rect2i(prev_pos, pos-prev_pos);
		selected_region = context.canvas.canvas_image.get_region(R);
		region_pos = R.position;
		context.canvas2.canvas_image.blit_rect(context.canvas.canvas_image, R, region_pos);
		context.canvas2.update_canvas.call();
		context.undo_manager.action_end();
		is_something_selected = true;
	else:
		pass
		
func rmb_up(pos):
	if is_something_selected:
		context.undo_manager.action_begin("Paste selection");
		var R = Rect2i(Vector2i(0,0), selected_region.get_size());
		context.canvas.canvas_image.blit_rect(selected_region, R, region_pos);
		context.canvas.update_canvas.call();
		is_something_selected = false;
		context.canvas2.clear();
		context.undo_manager.action_end();

func mouseMove(pos:Vector2i):
	if is_lmb_down:
		if not is_something_selected:
			#draw preview line
			context.canvas2.clear();
			preview_box(Rect2i(prev_pos, pos-prev_pos));
			context.canvas2.update_canvas.call();
		else:
			#offset thing by move-diff
			var diff:Vector2i = pos-prev_pos;
			prev_pos = pos;
			region_pos = region_pos+diff;
			context.canvas2.clear();
			var R = Rect2i(Vector2i(0,0), selected_region.get_size());
			var R_moved = R; R_moved.position = region_pos;
			preview_box(R_moved);
			context.canvas2.canvas_image.blit_rect(selected_region, R, region_pos);
			context.canvas2.update_canvas.call();
			
	
func placedot(pos):
	#context.canvas.brush_radius = Vector2i(1,1);
	#context.canvas.draw_dot.call(pos);
	context.canvas.canvas_image.set_pixel(pos.x, pos.y, context.cur_color)
	context.canvas.update_canvas.call();

func placeline(prev_pos, pos):
	context.canvas.brush_radius = Vector2i(1,1);
	context.canvas.brush_color = context.cur_color;
	context.canvas.line.append(prev_pos);
	context.canvas.line.append(pos);
	context.canvas.draw_line.call();

func preview_line(prev_pos, pos):
	context.canvas2.brush_radius = Vector2i(1,1);
	context.canvas2.brush_color = context.cur_color;
	context.canvas2.line.append(prev_pos);
	context.canvas2.line.append(pos);
	context.canvas2.draw_line.call();

func preview_box(R:Rect2i):
	var vA = R.position;
	var vC = R.end;
	var vB = Vector2i(vC.x, vA.y);
	var vD = Vector2i(vA.x, vC.y);
	var lines = [[vA, vB], [vB, vC], [vC, vD], [vD, vA]];
	for line in lines:
		preview_line(line[0], line[1]);
