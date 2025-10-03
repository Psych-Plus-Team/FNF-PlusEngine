package modchart.modifiers;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class Transform extends Modifier {
	override public function render(curPos:Vector3D, params:RenderParams) {
		var receptorName = Std.string(params.lane);
		var player = params.player;

		curPos.x += getPercent('x', player) + getPercent('x' + receptorName, player) + getPercent('xoffset', player)
			+ getPercent('xoffset' + receptorName, player);
		curPos.y += getPercent('y', player) + getPercent('y' + receptorName, player) + getPercent('yoffset', player)
			+ getPercent('yoffset' + receptorName, player);
		curPos.z += getPercent('z', player) + getPercent('z' + receptorName, player) + getPercent('zoffset', player)
			+ getPercent('zoffset' + receptorName, player);

		return curPos;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
