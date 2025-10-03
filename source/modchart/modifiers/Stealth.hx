package modchart.modifiers;

import flixel.FlxG;
import flixel.math.FlxMath;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.Visuals;
import modchart.core.util.ModchartUtil;
import openfl.geom.Vector3D;

class Stealth extends Modifier {
	public function new(pf) {
		super(pf);

		setPercent('alpha', 1, -1);

		setPercent('suddenStart', 5, -1);
		setPercent('suddenEnd', 3, -1);
		setPercent('suddenGlow', 1, -1);

		setPercent('hiddenStart', 5, -1);
		setPercent('hiddenEnd', 3, -1);
		setPercent('hiddenGlow', 1, -1);
	}

	private inline function computeSudden(data:Visuals, params:RenderParams) {
		final player = params.player;

		final sudden = getPercent('sudden', player);

		if (sudden == 0)
			return;

		final start = getPercent('suddenStart', player) * 100;
		final end = getPercent('suddenEnd', player) * 100;
		final glow = getPercent('suddenGlow', player);

		final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 1, 0);

		if (glow != 0)
			data.glow += Math.max(0, (1 - alpha) * sudden * 2) * glow;
		data.alpha *= alpha * sudden;
	}

	private inline function computeHidden(data:Visuals, params:RenderParams) {
		final player = params.player;

		final hidden = getPercent('hidden', player);

		if (hidden == 0)
			return;

		final start = getPercent('hiddenStart', player) * 100;
		final end = getPercent('hiddenEnd', player) * 100;
		final glow = getPercent('hiddenGlow', player);

		final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 0, 1);

		if (glow != 0)
			data.glow += Math.max(0, (1 - alpha) * hidden * 2) * glow;
		data.alpha *= alpha * hidden;
	}

	override public function visuals(data:Visuals, params:RenderParams) {
		final player = params.player;
		final lane = params.lane;

		final vMod = params.isTapArrow ? 'stealth' : 'dark';
		final visibility = getPercent(vMod, player) + getPercent(vMod + Std.string(lane), player);
		data.alpha = ((getPercent('alpha', player) + getPercent('alpha' + Std.string(lane), player)) * (1 - ((Math.max(0.5, visibility) - 0.5) * 2)));
		data.glow += visibility * 2;

		// sudden & hidden
		if (params.isTapArrow) // non receptor
		{
			computeSudden(data, params);
			computeHidden(data, params);
		}

		return data;
	}

	override public function shouldRun(params:RenderParams):Bool
		return true;
}
