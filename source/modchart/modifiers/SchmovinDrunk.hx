package modchart.modifiers;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class SchmovinDrunk extends Modifier {
	final thtdiv = 1 / 222;

	override public function render(curPos:Vector3D, params:RenderParams) {
		var phaseShift = params.lane * 0.5 + (params.distance * thtdiv) * Math.PI;
		curPos.x += sin(params.curBeat * .25 * Math.PI + phaseShift) * ARROW_SIZEDIV2 * getPercent('schmovinDrunk', params.player);

		return curPos;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
