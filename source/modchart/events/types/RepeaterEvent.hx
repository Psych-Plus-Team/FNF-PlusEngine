package modchart.events.types;

import modchart.events.Event;

class RepeaterEvent extends Event {
	var end:Float;

	public function new(beat:Float, length:Float, callback:Event->Void, parent:EventManager) {
		super(beat, callback, parent);

		end = beat + length;
	}

	override function update(curBeat:Float):Void {
		if (fired)
			return;

		if (curBeat < end) {
			callback(this);
			fired = false;
		} else if (curBeat >= end) {
			fired = true;
		}
	}
}
