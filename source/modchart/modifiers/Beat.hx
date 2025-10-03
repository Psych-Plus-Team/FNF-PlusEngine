package modchart.modifiers;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class Beat extends Modifier {
	public function new(pf) {
		super(pf);
	}

	static var fAccelTime = 0.2;
	static var fTotalTime = 0.5;

	@:dox(hide)
	@:noCompletion private inline function beatMath(params:RenderParams, offset:Float, speed:Float, mult:Float):Float {
		var curBeat = speed * (params.curBeat + offset) + fAccelTime;

		if (curBeat < 0)
			return 0;

		curBeat -= Math.floor(curBeat);
		curBeat += 1;
		curBeat -= Math.floor(curBeat);

		if (curBeat >= fTotalTime)
			return 0;

		var fAmount:Float;

		if (curBeat < fAccelTime) {
			fAmount = FlxMath.remapToRange(curBeat, 0.0, fAccelTime, 0.0, 1.0);
			fAmount *= fAmount;
		} else {
			fAmount = FlxMath.remapToRange(curBeat, fAccelTime, fTotalTime, 1.0, 0.0);
			fAmount = 1 - (1 - fAmount) * (1 - fAmount);
		}

		if (Math.floor(curBeat) % 2 != 0)
			fAmount *= -1;

		var fShift = 20 * fAmount * sin((params.distance * 0.01 * mult) + (Math.PI * .5));
		return fShift;
	}

	@:dox(hide)
	@:noCompletion private inline function computeBeat(curPos:Vector3D, params:RenderParams, axis:String, realAxis:String) {
		final receptorName = Std.string(params.lane);
		final player = params.player;

		final amount = getPercent('beat' + axis, player) + getPercent('beat' + axis + receptorName, player);

		if (amount == 0)
			return curPos;

		final offset = getPercent('beat' + axis + 'Offset', player) + getPercent('beat' + axis + receptorName + 'Offset', player);
		final speed = getPercent('beat' + axis + 'Speed', player) + getPercent('beat' + axis + receptorName + 'Speed', player);
		final mult = getPercent('beat' + axis + 'Mult', player) + getPercent('beat' + axis + receptorName + 'Mult', player);

		var shift = beatMath(params, offset, 1 + speed, 1 + mult);

		switch (realAxis) {
			case 'x':
				curPos.x += shift;
			case 'y':
				curPos.y += shift;
			case 'z':
				curPos.z += shift;
		}

		return curPos;
	}

	override public function render(curPos:Vector3D, params:RenderParams) {
		computeBeat(curPos, params, '', 'x');
		computeBeat(curPos, params, 'x', 'x');
		computeBeat(curPos, params, 'y', 'y');
		computeBeat(curPos, params, 'z', 'z');

		return curPos;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
