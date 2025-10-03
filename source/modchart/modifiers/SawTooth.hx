package modchart.modifiers;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class SawTooth extends Modifier {
	override public function render(curPos:Vector3D, params:RenderParams) {
		var player = params.player;
		final period = 1 + getPercent("sawtoothPeriod", player);
		curPos.x += (getPercent('sawtooth',
			player) * ARROW_SIZE) * ((0.5 / period * params.distance) / ARROW_SIZE - Math.floor((0.5 / period * params.distance) / ARROW_SIZE));

		return curPos;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
