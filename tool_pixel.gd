extends PaintTool;
class_name Tool_Pixel
# pixel tool 
var context:PaintContext;
var is_lmb_down = false;
var prev_pos = Vector2i(0,0);

func _init(new_ctx:PaintContext):
	context = new_ctx;

func lmb_down(pos):	prev_pos = pos; placedot(pos); is_lmb_down = true;
func lmb_up(pos):   is_lmb_down = false;

func mouseMove(pos):
	if is_lmb_down:
		placeline(prev_pos, pos);
	prev_pos = pos;
	
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
	
