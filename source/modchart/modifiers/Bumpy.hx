package modchart.modifiers;

import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import openfl.geom.Vector3D;

class Bumpy extends Modifier {
	public function new(pf) {
		super(pf);

		var stuff = ['', 'Angle'];
		for (i in 0...stuff.length) {
			setPercent('bumpy' + stuff[i] + 'Mult', 1, -1);
			setPercent('bumpy' + stuff[i] + 'XMult', 1, -1);
			setPercent('bumpy' + stuff[i] + 'YMult', 1, -1);
			setPercent('bumpy' + stuff[i] + 'ZMult', 1, -1);
		}
	}

	function applyBumpy(curPos:Vector3D, params:RenderParams, axis:String, realAxis:String) {
		final receptorName = Std.string(params.lane);
		final player = params.player;
		var distance = params.distance;

		var offset = getPercent('bumpy' + axis + 'Offset', player) + getPercent('bumpy' + axis + receptorName + 'Offset', player);
		var period = getPercent('bumpy' + axis + 'Period', player) + getPercent('bumpy' + axis + receptorName + 'Period', player);
		var mult = getPercent('bumpy' + axis + 'Mult', player) + getPercent('bumpy' + axis + receptorName + 'Mult', player);

		var shift = 0.;

		var scrollSpeed = getScrollSpeed();

		var bumpyMath = 40 * sin(((distance * 0.01) + (100.0 * offset) / ((period * (mult * 24.0)) +
			24.0)) / ((scrollSpeed * mult) / 2)) * (getKeyCount() / 2.0);

		// var bumpyMath = (40 * sin((distance + (100.0 * offset)) / ((period * (mult*24.0)) + 24.0)));

		shift += (getPercent('bumpy' + axis, player) + getPercent('bumpy' + axis + receptorName, player)) * bumpyMath;

		switch (realAxis) {
			case 'x':
				curPos.x += shift;
			case 'y':
				curPos.y += shift;
			case 'z':
				curPos.z += shift;
		}
	}

	public function applyAngle(vis:Visuals, params:RenderParams, axis:String, realAxis:String) {
		final receptorName = Std.string(params.lane);
		final player = params.player;
		var distance = params.distance;

		var offset = getPercent('bumpyAngle' + axis + 'Offset', player) + getPercent('bumpyAngle' + axis + receptorName + 'Offset', player);
		var period = getPercent('bumpyAngle' + axis + 'Period', player) + getPercent('bumpyAngle' + axis + receptorName + 'Period', player);
		var mult = getPercent('bumpyAngle' + axis + 'Mult', player) + getPercent('bumpyAngle' + axis + receptorName + 'Mult', player);

		var shift = 0.;

		var scrollSpeed = getScrollSpeed();

		var bumpyMath = 40 * sin(((distance * 0.01) + (100.0 * offset) / ((period * (mult * 24.0)) +
			24.0)) / ((scrollSpeed * mult) / 2)) * (getKeyCount() / 2.0);

		shift += (getPercent('bumpyAngle' + axis, player) + getPercent('bumpyAngle' + axis + receptorName, player)) * bumpyMath;

		switch (realAxis) {
			case 'x':
				vis.angleX += shift;
			case 'y':
				vis.angleY += shift;
			case 'z':
				vis.angleZ += shift;
		}
	}

	override public function render(curPos:Vector3D, params:RenderParams) {
		// var player = params.player;
		// var distance = params.distance;
		// var bumpyX = (40 * sin((distance + (100.0 * getPercent('bumpyXOffset', player))) / ((getPercent('bumpyXPeriod', player) * 24.0) + 24.0)));
		// var bumpyY = (40 * sin((distance + (100.0 * getPercent('bumpyYOffset', player))) / ((getPercent('bumpyYPeriod', player) * 24.0) + 24.0)));
		// var bumpyZ = (40 * sin((distance + (100.0 * getPercent('bumpyZOffset', player))) / ((getPercent('bumpyZPeriod', player) * 24.0) + 24.0)));

		// curPos.x += bumpyX * getPercent('bumpyX', player);
		// curPos.y += bumpyY * getPercent('bumpyY', player);
		// curPos.z += bumpyZ * (getPercent('bumpy', player) + getPercent('bumpyZ', player));

		applyBumpy(curPos, params, '', 'z');
		applyBumpy(curPos, params, 'x', 'x');
		applyBumpy(curPos, params, 'y', 'y');
		applyBumpy(curPos, params, 'z', 'z');

		return curPos;
	}

	override public function visuals(data:Visuals, params:RenderParams) {
		applyAngle(data, params, '', 'z');
		applyAngle(data, params, 'x', 'x');
		applyAngle(data, params, 'y', 'y');
		applyAngle(data, params, 'z', 'z');

		return data;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
