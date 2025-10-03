package modchart.modifiers;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class ZigZag extends Modifier {
	override public function render(curPos:Vector3D, params:RenderParams) {
		final zigzag = getPercent('zigZag', params.player);

		if (zigzag == 0)
			return curPos;

		var theta = -params.distance / ARROW_SIZE * Math.PI;
		var outRelative = Math.acos(cos(theta + Math.PI / 2)) / Math.PI * 2 - 1;

		curPos.x += outRelative * ARROW_SIZEDIV2 * zigzag;

		return curPos;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
