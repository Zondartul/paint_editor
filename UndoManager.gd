extends Node
class_name UndoManager
var context:PaintContext;

var steps = [];
var head = 0;
var backlash = "do";

signal undo_stack_changed(stack, head);

func _init(new_ctx:PaintContext):
	context = new_ctx;

func checkpoint(comment:String):
	var snap = {"name":comment, "data":context.canvas.canvas_image.duplicate()}
	if(steps.size() >= head): 
		print("UndoMgr: removing last "+str(steps.size() - head)+" steps");
		steps.resize(head);
	steps.append(snap);
	head = head+1;
	backlash = "do";
	undo_stack_changed.emit(steps, head);

func undo():
	if head:
		if backlash == "do":
			checkpoint("<backlash>");
			backlash = "undo";
			head = head-1;
		var snap = steps[head-1];
		apply_snap(snap);
		head = head-1;
		print("Undo "+snap.name);
		undo_stack_changed.emit(steps, head);
	else:
		print("Nothing to undo");

func redo():
	if(head < steps.size()):
		if backlash == "undo":
			head = head+1;
			backlash = "do";
		var cur_snap = steps[head-1];
		print("Redo "+cur_snap.name);
		head = head+1;
		var snap = steps[head-1];
		apply_snap(snap);
		if(snap.name == "<backlash>"):
			steps.resize(head-1);
			head = head-1;
		undo_stack_changed.emit(steps, head);
	else:
		print("Nothing to redo");

func apply_snap(snap):
	context.canvas.canvas_image = snap.data;
	context.canvas.update_canvas.call();
