package modchart.modifiers.false_paradise;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.ModchartUtil;
import openfl.geom.Vector3D;

class Spiral extends Modifier {
	override public function render(curPos:Vector3D, params:RenderParams) {
		var player = params.player;
		var PI = Math.PI;
		var centerX = WIDTH * .5;
		var centerY = HEIGHT * .5;
		var radiusOffset = -params.distance * .25;
		var crochet = Adapter.instance.getStaticCrochet();
		var radius = radiusOffset + getPercent('spiralDist', player) * params.lane;
		var outX = centerX + cos(-params.distance / crochet * PI + params.curBeat * (PI * .25)) * radius;
		var outY = centerY + sin(-params.distance / crochet * PI - params.curBeat * (PI * .25)) * radius;

		return ModchartUtil.lerpVector3D(curPos, new Vector3D(outX, outY, radius / (centerY * 4) - 1, 0), getPercent('spiral', player));
	}

	override public function shouldRun(params:RenderParams):Bool
		return getPercent('spiral', params.player) != 0;
}
