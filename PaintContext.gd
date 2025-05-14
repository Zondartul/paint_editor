extends Node
class_name PaintContext

var canvas:PaintCanvas;
var canvas2:PaintCanvas;
var cur_color:Color = Color.BLACK
var pos:Vector2i;
var undo_manager:UndoManager;
