package modchart.core.util;

class Constants {}

enum abstract RotationOrder(String) from String to String {
	final X_Y_Z = "x_y_z";
	final X_Z_Y = "x_z_y";
	final Y_X_Z = "y_x_z";
	final Y_Z_X = "y_z_x";
	final Z_X_Y = "z_x_y";
	final Z_Y_X = "z_y_x";

	final X_Y_X = "x_y_x";
	final X_Z_X = "x_z_x";
	final Y_X_Y = "y_x_y";
	final Y_Z_Y = "y_z_y";
	final Z_X_Z = "z_x_z";
	final Z_Y_Z = "z_y_z";
}

@:structInit
class RenderParams {
	public var songTime:Float;
	public var hitTime:Float;
	public var distance:Float;
	public var curBeat:Float;

	public var lane:Int = 0;
	public var player:Int = 0;
	public var isTapArrow:Bool = false;
}

@:structInit
class ArrowData {
	public var hitTime:Float = 0;
	public var distance:Float = 0;

	public var lane:Int = 0;
	public var player:Int = 0;

	public var hitten:Bool = false;
	public var isTapArrow:Bool = false;

	private var __holdSubdivisionOffset:Float = .0;
}

@:structInit
class Visuals {
	public var scaleX:Float = 1;
	public var scaleY:Float = 1;
	public var alpha:Float = 1;
	public var glow:Float = 0;
	public var glowR:Float = 1;
	public var glowG:Float = 1;
	public var glowB:Float = 1;
	public var angleX:Float = 0;
	public var angleY:Float = 0;
	public var angleZ:Float = 0;
	public var skewX:Float = 0;
	public var skewY:Float = 0;
}

@:publicFields
@:structInit
class HoldSegment {
	var origin:Vector3D;
	var left:Vector3D;
	var right:Vector3D;
}

@:publicFields
@:structInit
class Node {
	public var input:Array<String> = [];
	public var output:Array<String> = [];
	public var func:NodeFunction = (_, o) -> _;
}

@:publicFields
@:structInit
class ModAlias {
	public var parent:String;
	public var alias:String;
}

/*
	abstract ModScheme(Dynamic) from Dynamic from String from Array<String> to Dynamic {
	public inline function get():ModScheme
	{
		return this is String ? [this] : this;
	}
	}
 */
// (InputModPercents, PlayerNumber) -> OutputModPercents
typedef NodeFunction = (Array<Float>, Int) -> Array<Float>;
