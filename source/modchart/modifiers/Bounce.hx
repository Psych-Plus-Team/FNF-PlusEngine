package modchart.modifiers;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class Bounce extends Modifier {
	override public function render(curPos:Vector3D, params:RenderParams) {
		var player = params.player;
		var speed = getPercent('bounceSpeed', player);
		var offset = getPercent('bounceOffset', player);

		var bounce = Math.abs(sin((params.curBeat + offset) * (1 + speed) * Math.PI)) * ARROW_SIZE;

		curPos.x += bounce * getPercent('bounceX', player);
		curPos.y += bounce * (getPercent('bounce', player) + getPercent('bounceY', player));
		curPos.z += bounce * getPercent('bounceZ', player);

		return curPos;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
