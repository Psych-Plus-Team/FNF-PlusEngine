package modchart.events.types;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxEase;
import modchart.events.Event;

typedef AddData = {
	var startBeat:Float;
	var endBeat:Float;

	var beatLength:Float;

	var ease:EaseFunction;
}

class AddEvent extends Event {
	public var data:AddData;

	public function new(mod:String, beat:Float, len:Float, target:Float, ease:EaseFunction, player:Int, parent:EventManager) {
		this.name = mod;
		this.player = player;

		this.data = {
			startBeat: beat,
			endBeat: beat + len,
			beatLength: len,
			ease: ease != null ? ease : FlxEase.linear
		};

		this.target = target;

		super(beat, (_) -> {}, parent, true);
	}

	var additionPerc:Null<Float> = null;

	override function update(curBeat:Float) {
		if (fired)
			return;

		if (curBeat < data.endBeat) {
			if (additionPerc == null)
				additionPerc = getModPercent(name, player);

			var progress = (curBeat - data.startBeat) / (data.endBeat - data.startBeat);
			// maybe we should make it use bound?
			var out = FlxMath.lerp(additionPerc, additionPerc + target, data.ease(progress)); // it "adds" value to the perc instead of rewrite it
			setModPercent(name, out, player);
			fired = false;
		} else if (curBeat >= data.endBeat) {
			fired = true;

			// we're using the ease function bc it may dont return 1
			setModPercent(name, data.ease(1) * (additionPerc + target), player);
		}
	}
}
