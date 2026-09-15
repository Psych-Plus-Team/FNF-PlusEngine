package backend.ui.haxecompose.ui;

class Constraints
{
	public var minWidth:Float;
	public var maxWidth:Float;
	public var minHeight:Float;
	public var maxHeight:Float;

	public function new(minWidth:Float = 0, maxWidth:Float = 100000, minHeight:Float = 0, maxHeight:Float = 100000)
	{
		this.minWidth = minWidth;
		this.maxWidth = maxWidth;
		this.minHeight = minHeight;
		this.maxHeight = maxHeight;
	}

	public function inset(horizontal:Float, vertical:Float):Constraints
	{
		return new Constraints(0, Math.max(0, maxWidth - horizontal), 0, Math.max(0, maxHeight - vertical));
	}

	public function constrainWidth(width:Float):Float
		return Math.max(minWidth, Math.min(maxWidth, width));

	public function constrainHeight(height:Float):Float
		return Math.max(minHeight, Math.min(maxHeight, height));
}
