package modchart.modifiers.false_paradise;

import flixel.math.FlxAngle;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class Wiggle extends Modifier {
	override public function render(curPos:Vector3D, params:RenderParams) {
		var wiggle = getPercent('wiggle', params.player);
		curPos.x += sin(params.curBeat) * wiggle * 20;
		curPos.y += sin(params.curBeat + 1) * wiggle * 20;

		setPercent('rotateZ', (sin(params.curBeat) * 0.2 * wiggle) * FlxAngle.TO_DEG);

		return curPos;
	}

	override public function shouldRun(params:RenderParams):Bool
		return getPercent('wiggle', params.player) != 0;
}
