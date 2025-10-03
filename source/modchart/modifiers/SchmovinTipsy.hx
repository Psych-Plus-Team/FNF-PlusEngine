package modchart.modifiers;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class SchmovinTipsy extends Modifier {
	override public function render(curPos:Vector3D, params:RenderParams) {
		curPos.y += sin(params.curBeat / 4 * Math.PI + params.lane) * ARROW_SIZEDIV2 * getPercent('schmovinTipsy', params.player);
		return curPos;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
