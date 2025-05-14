extends Node
class_name UndoManager
var context:PaintContext;

var actions = [];
var head = -1; #always points to "current action"
var cur_action = null;
var doing_action = false;
var backlash = "do";

## undoing the current action jumps to the "before" state (same as "after" of previous)
##  and previous action becomes current action.
## redoing the next action makes next action the current action and jumps to its "after" state

signal undo_stack_changed(stack, head);

func _init(new_ctx:PaintContext):
	context = new_ctx;
	clear();

func clear():
	actions = [];
	head = -1;
	undo_stack_changed.emit(actions, head);

#var counter = 1

func action_begin(comment:String):
	assert(not doing_action)
	doing_action = true;
	#comment = comment+"_"+str(counter); counter = counter+1;
	var state = context.canvas.canvas_image.duplicate();
	cur_action = {"name":comment, "before":state, "after":null}

func action_end():
	assert(doing_action);
	doing_action = false;
	var state = context.canvas.canvas_image.duplicate();
	cur_action.after = state;
	if backlash == "undo": head = head-1; #always true?
	if(head < actions.size()-1):
		#remove further actions, rewrite history
		print("UndoMgr: removing the last "+str(actions.size() - (head))+" actions")
		print("Resize to "+str(head+1))
		actions.resize(head+1);
	head = head+1;
	actions.append(cur_action);
	backlash = "do";
	undo_stack_changed.emit(actions, head);

func action_cancel():
	assert(doing_action);
	doing_action = false;
	cur_action = null;

#func checkpoint(comment:String):
#	var snap = {"name":comment, "data":context.canvas.canvas_image.duplicate()}
#	if(steps.size() >= head): 
#		print("UndoMgr: removing last "+str(steps.size() - head)+" steps");
#		steps.resize(head);
#	steps.append(snap);
#	head = head+1;
#	backlash = "do";
#	undo_stack_changed.emit(steps, head);

func undo():
	assert(not doing_action)
	if head != -1:
		if backlash == "undo":
			if head > 0:
				head = head-1;
			else:
				print("Nothing to undo");
				return;
		backlash = "undo";
		var snap = actions[head];
		#print("head "+str(head)+"/ activate "+snap.name+".before")
		apply_snap(snap.before);
		print("Undo "+snap.name);
		undo_stack_changed.emit(actions, head);
	else:
		print("Nothing to undo");

func redo():
	assert(not doing_action)
	if(head < actions.size()):
		if head == -1: head = 0;
		if backlash == "do":
			if(head+1 < actions.size()):
				head = head+1;
			else:
				print("Nothing to redo");
				return;
		backlash = "do";
		var snap = actions[head];
		#print("head "+str(head)+"/ activate "+snap.name+".after")
		apply_snap(snap.after);
		print("Redo "+snap.name);
		undo_stack_changed.emit(actions, head);
	else:
		print("Nothing to redo");
		

func apply_snap(snap):
	context.canvas.canvas_image = snap.duplicate();
	context.canvas.update_canvas.call();
	
func jump_to(new_head):
	assert(not doing_action);
	head = new_head;
	var snap = actions[head];
	#print("head "+str(head)+"/ activate "+snap.name+".after")
	apply_snap(snap.after);
