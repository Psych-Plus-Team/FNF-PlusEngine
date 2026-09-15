package backend.ui.haxecompose.ui;

import flixel.util.FlxColor;

class Modifier
{
	public var paddingLeft:Float = 0;
	public var paddingTop:Float = 0;
	public var paddingRight:Float = 0;
	public var paddingBottom:Float = 0;
	public var fixedWidth:Null<Float> = null;
	public var fixedHeight:Null<Float> = null;
	public var fillWidth:Bool = false;
	public var fillHeight:Bool = false;
	public var backgroundColor:Null<FlxColor> = null;
	public var cornerRadius:Float = 0;
	public var gap:Float = 0;
	public var alpha:Float = 1;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var onClick:Void->Void = null;

	public function new() {}

	public static function empty():Modifier
		return new Modifier();

	public function copy():Modifier
	{
		var next = new Modifier();
		next.paddingLeft = paddingLeft;
		next.paddingTop = paddingTop;
		next.paddingRight = paddingRight;
		next.paddingBottom = paddingBottom;
		next.fixedWidth = fixedWidth;
		next.fixedHeight = fixedHeight;
		next.fillWidth = fillWidth;
		next.fillHeight = fillHeight;
		next.backgroundColor = backgroundColor;
		next.cornerRadius = cornerRadius;
		next.gap = gap;
		next.alpha = alpha;
		next.offsetX = offsetX;
		next.offsetY = offsetY;
		next.onClick = onClick;
		return next;
	}

	public function padding(all:Float):Modifier
	{
		var next = copy();
		next.paddingLeft = next.paddingTop = next.paddingRight = next.paddingBottom = all;
		return next;
	}

	public function paddingXY(x:Float, y:Float):Modifier
	{
		var next = copy();
		next.paddingLeft = next.paddingRight = x;
		next.paddingTop = next.paddingBottom = y;
		return next;
	}

	public function size(width:Float, height:Float):Modifier
	{
		var next = copy();
		next.fixedWidth = width;
		next.fixedHeight = height;
		return next;
	}

	public function width(width:Float):Modifier
	{
		var next = copy();
		next.fixedWidth = width;
		return next;
	}

	public function height(height:Float):Modifier
	{
		var next = copy();
		next.fixedHeight = height;
		return next;
	}

	public function fillMaxWidth():Modifier
	{
		var next = copy();
		next.fillWidth = true;
		return next;
	}

	public function fillMaxHeight():Modifier
	{
		var next = copy();
		next.fillHeight = true;
		return next;
	}

	public function background(color:FlxColor, radius:Float = 0):Modifier
	{
		var next = copy();
		next.backgroundColor = color;
		next.cornerRadius = radius;
		return next;
	}

	public function spacing(value:Float):Modifier
	{
		var next = copy();
		next.gap = value;
		return next;
	}

	public function opacity(value:Float):Modifier
	{
		var next = copy();
		next.alpha = Math.max(0, Math.min(1, value));
		return next;
	}

	public function offset(x:Float, y:Float):Modifier
	{
		var next = copy();
		next.offsetX = x;
		next.offsetY = y;
		return next;
	}

	public function clickable(onClick:Void->Void):Modifier
	{
		var next = copy();
		next.onClick = onClick;
		return next;
	}
}
