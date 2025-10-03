package modchart.modifiers;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class Invert extends Modifier {
	override public function render(curPos:Vector3D, params:RenderParams) {
		final player = params.player;
		final invert = -(params.lane % 2 - 0.5) * 2;
		final flip = (params.lane - 1.5) * -2;

		curPos.x += ARROW_SIZE * (invert * getPercent('invert', player) + flip * getPercent('flip', player));

		return curPos;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
