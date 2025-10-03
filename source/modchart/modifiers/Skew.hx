package modchart.modifiers;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.Visuals;
import modchart.core.util.ModchartUtil;
import openfl.geom.Vector3D;

class Skew extends Modifier {
	override public function visuals(data:Visuals, params:RenderParams):Visuals {
		var receptorName = Std.string(params.lane);
		var player = params.player;
		final x = getPercent('skewX', player) + getPercent('skewX' + receptorName, player);
		final y = getPercent('skewY', player) + getPercent('skewY' + receptorName, player);

		data.skewX += x;
		data.skewY += y;

		return data;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
