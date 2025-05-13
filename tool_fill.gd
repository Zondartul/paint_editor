extends PaintTool;
class_name Tool_Fill
# pixel tool 
var context:PaintContext;

# Status: works, but it's slow
# needs profiling. Probably due to the "sets" being slow (godot arrays? linked lists?)
# Alternative: replace sets with a color-coded image (mask) the same size as original image.

var premade_mask = null;

func _init(new_ctx:PaintContext):
	context = new_ctx;
	
	generate_mask();
	premade_mask = Mask;
	Mask = Mask.duplicate();
	

func lmb_down(pos): 
	fill(pos, context.cur_color);
	context.canvas.update_canvas.call();
	print("tool_fill: filled at "+str(pos))

var open_set = []
var admit_set = []
#var deny_set = []

var initial_color = Color.BLACK;

func read_pixel(pos): return context.canvas.canvas_image.get_pixel(pos.x, pos.y);
func is_pixel_in_range(pos): return Rect2i(Vector2i(0,0), context.canvas.canvas_image.get_size()).has_point(pos);

#func is_in_set(S:Array, val): return S.count(val) != 0;
#func add_to_set(S:Array, val): if not is_in_set(S, val): S.append(val);
#func remove_from_set(S:Array, val): S.erase(val);
	
func is_valid_pixel(pos): #future idea: admit gradients (compare against neighbor pixels)
	#if not is_pixel_in_range(pos): return false;
	if read_pixel(pos) == initial_color: return true
	return false;

func add_neighbor_helper(pos2):
	if mask_get(pos2) == CODE_BLANK:
		#add_to_set(open_set, pos2);
		open_set.append(pos2);
		mask_set(pos2, CODE_OPEN);
	#if is_pixel_in_range(pos2):
	#	if not is_in_set(admit_set, pos2) and not is_in_set(deny_set, pos2):
	#		add_to_set(open_set, pos2);
	

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
#	deny_set = []

var Mask:PackedByteArray
var mask_pad:int = 1
var mask_padded_width:int
var mask_padded_height:int
var mask_inner_width:int
var mask_inner_height:int

const CODE_BLANK = 0;
const CODE_OPEN = 1;
const CODE_ADMIT = 2;
const CODE_DENY = 3;

func mask_set(pos, code):  Mask[mask_padded_width*(pos.y+mask_pad) + (pos.x+mask_pad)] = code;
func mask_get(pos): return Mask[mask_padded_width*(pos.y+mask_pad) + (pos.x+mask_pad)];
func mask_set_nopad(pos, code): Mask[mask_padded_width*pos.y + pos.x] = code;

func generate_mask():
	mask_inner_width = context.canvas.canvas_image.get_width();
	mask_inner_height = context.canvas.canvas_image.get_height();
	mask_padded_width = mask_inner_width + 2*mask_pad;
	mask_padded_height = mask_inner_height+2*mask_pad;	
	Mask.resize(mask_padded_width*mask_padded_height);
	Mask.fill(CODE_BLANK);
	
	##fill mask pad
	for y in range(0, mask_padded_height):
		for x in range(0, mask_padded_width):
			if(x < mask_pad) or (x>= mask_padded_width-mask_pad)\
			or(y < mask_pad) or (y>= mask_padded_height-mask_pad):
				mask_set_nopad(Vector2i(x,y), CODE_DENY);

func fill_init():
	clear_sets();
	Mask = premade_mask.duplicate()

var step = 0;
var total_visited = 0;
func print_stats():
	step = step+1;
	var size = open_set.size()
	total_visited = total_visited + size;
	var sq:int = sqrt(total_visited);
	print("step "+str(step)+": open_set["+str(size)\
	+" pts], total = "+str(total_visited)\
	+" ("+str(sq)+"x"+str(sq)+")")
	#context.canvas.update_canvas.call();
	#await context.canvas.get_tree().process_frame;
	
func apply_admit_pixels(col):
	for pos2 in admit_set:
		context.canvas.canvas_image.set_pixel(pos2.x, pos2.y, col);

func fill(pos, col):
	fill_init();
	pos = Vector2i(pos);
	initial_color = read_pixel(pos);
	open_set.append(pos);
	#admit_set.append(pos);
	#add_neighbors(pos);
	while not open_set.is_empty():
		#print_stats();
		var prev_open_set = open_set.duplicate();
		open_set = [];
		for pos2 in prev_open_set:
			if(is_valid_pixel(pos2)):
				#add_to_set(admit_set, pos2);
				mask_set(pos2, CODE_ADMIT);
				add_neighbors(pos2);
				#add_to_set(admit_set, pos2);
				admit_set.append(pos2);
			else:
				#add_to_set(deny_set, pos2);
				mask_set(pos2, CODE_DENY);
	apply_admit_pixels(col);
