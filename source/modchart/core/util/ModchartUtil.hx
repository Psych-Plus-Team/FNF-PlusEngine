package modchart.core.util;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import haxe.ds.Vector;
import modchart.core.Quanterion;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

using StringTools;

@:keep class ModchartUtil {
	// pain (we need this if we want support for sprite sheet packer)
	inline public static function getFrameAngle(spr:FlxSprite):Float {
		return switch (spr.frame.angle) {
			case ANGLE_90: 90;
			case ANGLE_NEG_90: -90;
			case ANGLE_270: 270;
			default: 0; // ANGLE_0
		}
	}

	// NO MORE GIMBAL LOCK
	inline public static function rotate3DVector(vec:Vector3D, angleX:Float, angleY:Float, angleZ:Float):Vector3D {
		if (angleX == 0 && angleY == 0 && angleZ == 0)
			return vec;

		final RAD = FlxAngle.TO_RAD;
		final quatX = Quaternion.fromAxisAngle(Vector3D.X_AXIS, angleX * RAD);
		final quatY = Quaternion.fromAxisAngle(Vector3D.Y_AXIS, angleY * RAD);
		final quatZ = Quaternion.fromAxisAngle(Vector3D.Z_AXIS, angleZ * RAD);

		var finalQuat:Quaternion;
		// pain
		switch (Config.ROTATION_ORDER) {
			case X_Y_Z:
				finalQuat = quatX.multiply(quatY.multiply(quatZ));
			case X_Z_Y:
				finalQuat = quatX.multiply(quatZ.multiply(quatY));
			case Y_X_Z:
				finalQuat = quatY.multiply(quatX.multiply(quatZ));
			case Y_Z_X:
				finalQuat = quatY.multiply(quatZ.multiply(quatX));
			case Z_X_Y:
				finalQuat = quatZ.multiply(quatX.multiply(quatY));
			case Z_Y_X:
				finalQuat = quatZ.multiply(quatY.multiply(quatX));
			case X_Y_X:
				finalQuat = quatX.multiply(quatY.multiply(quatX));
			case X_Z_X:
				finalQuat = quatX.multiply(quatZ.multiply(quatX));
			case Y_X_Y:
				finalQuat = quatY.multiply(quatX.multiply(quatY));
			case Y_Z_Y:
				finalQuat = quatY.multiply(quatZ.multiply(quatY));
			case Z_X_Z:
				finalQuat = quatZ.multiply(quatX.multiply(quatZ));
			case Z_Y_Z:
				finalQuat = quatZ.multiply(quatY.multiply(quatZ));
		}
		return finalQuat.rotateVector(vec);
	}

	// 90 degrees as default
	static var fov:Float = Math.PI / 2;
	static var near:Int = 0;
	static var far:Int = 1;
	static var range:Int = -1;

	// Based on schmovin's perspective projection math
	inline static public function project(pos:Vector3D, ?origin:Vector3D) {
		final fov = Math.PI / 2;

		var originalZ = pos.z;

		if (origin == null)
			origin = new Vector3D(FlxG.width / 2, FlxG.height / 2);
		pos.decrementBy(origin);

		final worldZ = Math.min(pos.z - 1, 0); // bound to 1000 z

		final halfFovTan = 1 / ModchartUtil.tan(fov * .5);
		final rangeDivision = 1 / range;

		final projectionScale = (near + far) * rangeDivision;
		final projectionOffset = 2 * near * (far * rangeDivision);
		final projectionZ = projectionScale * worldZ + projectionOffset;

		final projectedPos = new Vector3D(pos.x * halfFovTan, pos.y * halfFovTan, projectionZ * projectionZ, projectionZ);
		projectedPos.project();
		projectedPos.incrementBy(origin);

		projectedPos.w = (projectedPos.z - 1) * 1000;
		return projectedPos;
	}

	inline static public function buildHoldVertices(upper:Array<Vector3D>, lower:Array<Vector3D>) {
		return [
			upper[0].x, upper[0].y,
			upper[1].x, upper[1].y,
			lower[0].x, lower[0].y,
			lower[1].x, lower[1].y
		];
	}

	inline static public function getHoldUVT(arrow:FlxSprite, subs:Int) {
		var frameAngle = -ModchartUtil.getFrameAngle(arrow);

		var uv = new DrawData<Float>(8 * subs, true, []);

		var frameUV = arrow.frame.uv;
		var frameWidth = frameUV.width - frameUV.x;
		var frameHeight = frameUV.height - frameUV.y;

		var subDivided = 1.0 / subs;

		// if the frame doesnt have rotation, we skip the rotated uv shit
		if ((frameAngle % 360) == 0) {
			for (curSub in 0...subs) {
				var uvOffset = subDivided * curSub;
				var subIndex = curSub * 8;

				uv[subIndex] = uv[subIndex + 4] = frameUV.x;
				uv[subIndex + 2] = uv[subIndex + 6] = frameUV.width;
				uv[subIndex + 1] = uv[subIndex + 3] = frameUV.y + uvOffset * frameHeight;
				uv[subIndex + 5] = uv[subIndex + 7] = frameUV.y + (uvOffset + subDivided) * frameHeight;
			}
			return uv;
		}

		var angleRad = frameAngle * (Math.PI / 180);
		var cosA = ModchartUtil.cos(angleRad);
		var sinA = ModchartUtil.sin(angleRad);

		var uCenter = frameUV.x + frameWidth * .5;
		var vCenter = frameUV.y + frameHeight * .5;

		// my brain is not braining anymore
		// i give up
		for (curSub in 0...subs) {
			var uvOffset = subDivided * curSub;
			var subIndex = curSub * 8;

			// uv coords before rotation
			var uvCoords = [
				[frameUV.x, frameUV.y + uvOffset * frameHeight], // tl
				[frameUV.width, frameUV.y + uvOffset * frameHeight], // tr
				[frameUV.x, frameUV.y + (uvOffset + subDivided) * frameHeight], // bl
				[frameUV.width, frameUV.y + (uvOffset + subDivided) * frameHeight] // br
			];

			// apply rotation
			for (i in 0...4) {
				var u = uvCoords[i][0] - uCenter; // x
				var v = uvCoords[i][1] - vCenter; // y

				var uRot = u * cosA - v * sinA;
				var vRot = u * sinA + v * cosA;

				uv[subIndex + i * 2] = uRot + uCenter;
				uv[subIndex + i * 2 + 1] = vRot + vCenter;
			}
		}

		return uv;
	}

	// gonna keep this shits inline cus are basic functions
	public static inline function getHalfPos():Vector3D {
		return new Vector3D(Manager.ARROW_SIZEDIV2, Manager.ARROW_SIZEDIV2, 0, 0);
	}

	public inline static function sign(x:Int)
		return x == 0 ? 0 : x > 0 ? 1 : -1;

	public inline static function clamp(n:Float, l:Float, h:Float) {
		if (n < l)
			return l;
		if (n > h)
			return h;
		return n;
	}

	public static inline function sin(num:Float)
		return FlxMath.fastSin(num);

	public static inline function cos(num:Float)
		return FlxMath.fastCos(num);

	public static inline function tan(num:Float)
		return sin(num) / cos(num);

	inline public static function lerpVector3D(start:Vector3D, end:Vector3D, ratio:Float) {
		if (ratio == 0)
			return start;
		if (ratio == 1)
			return end;

		final diff = end.subtract(start);
		diff.scaleBy(ratio);

		return start.add(diff);
	}

	public static function coolTextFile(path:String):Array<String> {
		var trim:String;
		return [
			for (line in openfl.utils.Assets.getText(path).split("\n"))
				if ((trim = line.trim()) != "" && !trim.startsWith("#")) trim
		];
	}
}
