package modchart.modifiers;

import flixel.math.FlxMath;
import haxe.ds.Vector;
import modchart.core.PlayField;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.ModchartUtil;
import openfl.geom.Vector3D;

/**
 * An Path Manager for FunkinModchart
 *
 * @author TheoDev
 */
@:dontSave
class PathModifier extends Modifier {
	private var __path:Vector<PathNode>;
	private var __pathBound:Float = 1500;

	public var pathOffset:Vector3D = new Vector3D();

	public function new(pf:PlayField, path:Array<PathNode>) {
		super(pf);

		loadPath(path);
	}

	public function loadPath(newPath:Array<PathNode>) {
		__path = Vector.fromArrayCopy(newPath);
	}

	public function computePath(pos:Vector3D, params:RenderParams, percent:Float) {
		var __path_length = __path.length;
		if (__path_length <= 0)
			return pos;
		if (__path_length == 1) {
			var pathNode = __path[0];
			return new Vector3D(pathNode.x, pathNode.y, pathNode.z);
		}

		var nodeProgress = (__path_length - 1) * (Math.abs(Math.min(__pathBound, params.distance)) * (1 / __pathBound));
		var thisNodeIndex = Math.floor(nodeProgress);
		var nextNodeIndex = Math.floor(Math.min(thisNodeIndex + 1, __path_length - 1));
		var nextNodeRatio = nodeProgress - thisNodeIndex;

		var thisNode = __path[thisNodeIndex];
		var nextNode = __path[nextNodeIndex];

		return ModchartUtil.lerpVector3D(pos,
			new Vector3D(FlxMath.lerp(thisNode.x, nextNode.x, nextNodeRatio), FlxMath.lerp(thisNode.y, nextNode.y, nextNodeRatio),
				FlxMath.lerp(thisNode.z, nextNode.z, nextNodeRatio)).add(pathOffset),
			percent);
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}

@:dontSave
@:structInit
class PathNode {
	public var x:Float;
	public var y:Float;
	public var z:Float;
}
