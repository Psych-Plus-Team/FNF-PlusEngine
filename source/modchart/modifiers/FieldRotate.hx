package modchart.modifiers;

import flixel.FlxG;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.ModchartUtil;
import openfl.geom.Vector3D;

class FieldRotate extends Rotate {
	override public function getOrigin(curPos:Vector3D, params:RenderParams):Vector3D {
		var x:Float = (WIDTH * 0.5) - ARROW_SIZE - 54 + ARROW_SIZE * 1.5;
		switch (params.player) {
			case 0:
				x -= WIDTH * 0.5 - ARROW_SIZE * 2 - 100;
			case 1:
				x += WIDTH * 0.5 - ARROW_SIZE * 2 - 100;
		}
		x -= 56;

		return new Vector3D(x, HEIGHT * 0.5);
	}

	override public function getRotateName():String
		return 'fieldRotate';

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
