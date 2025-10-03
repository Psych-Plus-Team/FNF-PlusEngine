package modchart.modifiers;

import flixel.FlxG;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.ModchartUtil;
import openfl.geom.Vector3D;

class LocalRotate extends Modifier {
	override public function render(curPos:Vector3D, params:RenderParams) {
		var rotateName = getRotateName();
		var player = params.player;

		var angleX = getPercent(rotateName + 'X', player);
		var angleY = getPercent(rotateName + 'Y', player);
		var angleZ = getPercent(rotateName + 'Z', player);

		if (angleX == 0 && angleY == 0 && angleZ == 0)
			return curPos;

		final origin:Vector3D = getOrigin(curPos, params);
		final diff = curPos.subtract(origin);
		final out = ModchartUtil.rotate3DVector(diff, angleX, angleY, angleZ);
		curPos.copyFrom(origin.add(out));
		return curPos;
	}

	public function getOrigin(curPos:Vector3D, params:RenderParams):Vector3D {
		var fixedLane = Math.round(getKeyCount(params.player) * .5);
		return new Vector3D(getReceptorX(fixedLane, params.player), getReceptorY(fixedLane, params.player));
	}

	public function getRotateName():String
		return 'localRotate';

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
