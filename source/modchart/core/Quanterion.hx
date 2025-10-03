package modchart.core;

import modchart.core.util.ModchartUtil;
import openfl.geom.Vector3D;

@:publicFields
final class Quaternion {
	var x:Float;
	var y:Float;
	var z:Float;
	var w:Float;

	function new(x:Float, y:Float, z:Float, w:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	function multiply(q:Quaternion):Quaternion {
		return new Quaternion(w * q.x
			+ x * q.w
			+ y * q.z
			- z * q.y, w * q.y
			- x * q.z
			+ y * q.w
			+ z * q.x, w * q.z
			+ x * q.y
			- y * q.x
			+ z * q.w,
			w * q.w
			- x * q.x
			- y * q.y
			- z * q.z);
	}

	function rotateVector(v:Vector3D):Vector3D {
		var qVec = new Quaternion(v.x, v.y, v.z, 0);
		var qConj = new Quaternion(-x, -y, -z, w);
		var result = this.multiply(qVec).multiply(qConj);
		return new Vector3D(result.x, result.y, result.z);
	}

	static function fromAxisAngle(axis:Vector3D, angleRad:Float):Quaternion {
		var sinHalfAngle = ModchartUtil.sin(angleRad * .5);
		var cosHalfAngle = ModchartUtil.cos(angleRad * .5);
		return new Quaternion(axis.x * sinHalfAngle, axis.y * sinHalfAngle, axis.z * sinHalfAngle, cosHalfAngle);
	}
}
