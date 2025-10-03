package modchart;

import flixel.FlxG;
import flixel.math.FlxMath;
import modchart.Manager;
import modchart.core.PlayField;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.Visuals;
import openfl.geom.Vector3D;

using StringTools;

class Modifier {
	private var pf:PlayField;

	public function new(pf:PlayField) {
		this.pf = pf;
	}

	// @:overridable
	public function render(curPos:Vector3D, params:RenderParams) {
		return curPos;
	}

	// @:overridable
	public function visuals(data:Visuals, params:RenderParams):Visuals {
		return data;
	}

	// @:settable
	public function shouldRun(params:RenderParams):Bool
		return false;

	public inline function setPercent(name:String, value:Float, player:Int = -1) {
		pf.setPercent(name, value, player);
	}

	public inline function getPercent(name:String, player:Int):Float {
		return pf.getPercent(name, player);
	}

	private inline function getKeyCount(player:Int = 0):Int {
		return Adapter.instance.getKeyCount();
	}

	private inline function getPlayerCount():Int {
		return Adapter.instance.getPlayerCount();
	}

	// Helpers Functions
	private inline function getScrollSpeed():Float
		return Adapter.instance.getCurrentScrollSpeed();

	public inline function getReceptorY(lane:Int, player:Int)
		return Adapter.instance.getDefaultReceptorY(lane, player);

	public inline function getReceptorX(lane:Int, player:Int)
		return Adapter.instance.getDefaultReceptorX(lane, player);

	public function getManager():PlayField
		return pf;

	private var WIDTH:Float = FlxG.width;
	private var HEIGHT:Float = FlxG.height;
	private var ARROW_SIZE(get, never):Float;
	private var ARROW_SIZEDIV2(get, never):Float;

	private inline function get_ARROW_SIZE():Float
		return Manager.ARROW_SIZE;

	private inline function get_ARROW_SIZEDIV2():Float
		return Manager.ARROW_SIZEDIV2;

	private inline function sin(rad:Float):Float
		return ModchartUtil.sin(rad);

	private inline function cos(rad:Float):Float
		return ModchartUtil.cos(rad);

	private inline function tan(rad:Float):Float
		return ModchartUtil.tan(rad);

	public function toString():String {
		var classn:String = Type.getClassName(Type.getClass(this));
		classn = classn.substring(classn.lastIndexOf('.') + 1);
		return 'Modifier[$classn]';
	}
}
