extends PaintTool;
class_name Tool_Fill
# pixel tool 
var context:PaintContext;

# Status: works, but it's slow
# needs profiling. Probably due to the "sets" being slow (godot arrays? linked lists?)
# Alternative: replace sets with a color-coded image (mask) the same size as original image.

func _init(new_ctx:PaintContext):
	context = new_ctx;

func lmb_down(pos): 
	fill(pos, context.cur_color);
	context.canvas.update_canvas.call();
	print("tool_fill: filled at "+str(pos))

var open_set = []
var admit_set = []
var deny_set = []

var initial_color = Color.BLACK;

func read_pixel(pos): return context.canvas.canvas_image.get_pixel(pos.x, pos.y);
func is_pixel_in_range(pos): return Rect2i(Vector2i(0,0), context.canvas.canvas_image.get_size()).has_point(pos);

func is_in_set(S:Array, val): return S.count(val) != 0;
func add_to_set(S:Array, val): if not is_in_set(S, val): S.append(val);
func remove_from_set(S:Array, val): S.erase(val);
	
func is_valid_pixel(pos): #future idea: admit gradients (compare against neighbor pixels)
	if not is_pixel_in_range(pos): return false;
	if read_pixel(pos) == initial_color: return true
	return false;

func add_neighbor_helper(pos2):
	if is_pixel_in_range(pos2):
		if not is_in_set(admit_set, pos2) and not is_in_set(deny_set, pos2):
			add_to_set(open_set, pos2);
	

func add_neighbors(pos):
	#for x in range(pos.x-1, pos.x+1+1):
	#	for y in range(pos.y-1, pos.y+1+1):
	#		var pos2 = Vector2i(x,y);
	add_neighbor_helper(pos+Vector2i(-1,0))
	add_neighbor_helper(pos+Vector2i(+1,0))
	add_neighbor_helper(pos+Vector2i(0,-1))
	add_neighbor_helper(pos+Vector2i(0,+1))

func clear_sets():
	open_set = []
	admit_set = []
	deny_set = []

func fill(pos, col):
	pos = Vector2i(pos);
	initial_color = context.canvas.canvas_image.get_pixel(pos.x, pos.y);
	admit_set.append(pos);
	add_neighbors(pos);
	while not open_set.is_empty():
		var prev_open_set = open_set.duplicate();
		for pos2 in prev_open_set:
			if(is_valid_pixel(pos2)):
				add_to_set(admit_set, pos2);
				add_neighbors(pos2);
			else:
				add_to_set(deny_set, pos2);
			remove_from_set(open_set, pos2);
	for pos2 in admit_set:
		context.canvas.canvas_image.set_pixel(pos2.x, pos2.y, col);
	clear_sets();
