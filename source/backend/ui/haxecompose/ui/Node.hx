package backend.ui.haxecompose.ui;

import backend.ui.haxecompose.ui.Measure.MeasureResult;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxDestroyUtil;

typedef MeasurePolicy = Node->Constraints->MeasureResult;

class Node
{
	public var type(default, null):String;
	public var key(default, null):String;
	public var modifier:Modifier = Modifier.empty();
	public var children:Array<Node> = [];
	public var props:Map<String, Dynamic> = [];
	public var measurePolicy:MeasurePolicy;
	public var native:Dynamic;

	public var x:Float = 0;
	public var y:Float = 0;
	public var renderX:Float = 0;
	public var renderY:Float = 0;
	public var width:Float = 0;
	public var height:Float = 0;
	public var needsMeasure:Bool = true;
	public var needsDraw:Bool = true;

	var nextChildren:Array<Node> = [];

	public function new(type:String, key:String)
	{
		this.type = type;
		this.key = key;
	}

	public function beginCompose(modifier:Modifier):Void
	{
		if (this.modifier != modifier)
		{
			this.modifier = modifier;
			invalidateMeasure();
		}
		nextChildren = [];
	}

	public function appendChild(child:Node):Void
	{
		nextChildren.push(child);
	}

	public function endCompose():Void
	{
		children = nextChildren;
	}

	public function setProp(name:String, value:Dynamic):Void
	{
		if (props.exists(name) && props.get(name) == value)
			return;
		props.set(name, value);
		invalidateMeasure();
		invalidateDraw();
	}

	public function invalidateMeasure():Void
	{
		needsMeasure = true;
		needsDraw = true;
	}

	public function invalidateDraw():Void
	{
		needsDraw = true;
	}

	public function measure(constraints:Constraints):MeasureResult
	{
		var result = measurePolicy != null ? measurePolicy(this, constraints) : Layout.measureBox(this, constraints);
		width = result.width;
		height = result.height;
		needsMeasure = false;
		return result;
	}

	public function place(x:Float, y:Float):Void
	{
		if (this.x != x || this.y != y)
			needsDraw = true;
		this.x = x;
		this.y = y;
	}

	public function dispose():Void
	{
		for (child in children)
			child.dispose();
		children = [];
		if (Std.isOfType(native, FlxSprite))
			native = FlxDestroyUtil.destroy(cast native);
		else if (Std.isOfType(native, FlxText))
			native = FlxDestroyUtil.destroy(cast native);
		else
			native = null;
	}
}
