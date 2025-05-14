extends PaintTool;
class_name Tool_Line
# pixel tool 
var context:PaintContext;
var is_lmb_down = false;
var prev_pos = Vector2i(0,0);

func _init(new_ctx:PaintContext):
	context = new_ctx;

func lmb_down(pos):	
	context.undo_manager.action_begin("Line tool");
	prev_pos = pos; 
	#placedot(pos); 
	is_lmb_down = true;
	
func lmb_up(pos):   
	is_lmb_down = false;
	placeline(prev_pos, pos);
	context.undo_manager.action_end();

func mouseMove(pos):
	if is_lmb_down:
		#draw preview line
		context.canvas2.clear();
		preview_line(prev_pos, pos);
	
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
	context.canvas.update_canvas.call();

func preview_line(prev_pos, pos):
	context.canvas2.brush_radius = Vector2i(1,1);
	context.canvas2.brush_color = context.cur_color;
	context.canvas2.line.append(prev_pos);
	context.canvas2.line.append(pos);
	context.canvas2.draw_line.call();
	context.canvas2.update_canvas.call();
