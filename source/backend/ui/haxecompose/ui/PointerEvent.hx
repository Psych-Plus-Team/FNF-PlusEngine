package backend.ui.haxecompose.ui;

enum PointerEventType
{
	Down;
	Move;
	Up;
	Cancel;
}

class PointerEvent
{
	public var x:Float;
	public var y:Float;
	public var type:PointerEventType;

	public function new(x:Float, y:Float, type:PointerEventType)
	{
		this.x = x;
		this.y = y;
		this.type = type;
	}
}
