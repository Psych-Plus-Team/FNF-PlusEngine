package modchart.events;

import haxe.ds.StringMap;
import modchart.core.PlayField;
import modchart.core.util.ModchartUtil;
import modchart.events.types.*;

@:allow(modchart.events.Event)
class EventManager {
	private var table:StringMap<Array<Array<Event>>> = new StringMap();
	private var eventList:Array<Event> = [];

	private var pf:PlayField;

	public function new(pf:PlayField) {
		this.pf = pf;
	}

	public function add(event:Event) {
		if (event.name != null) {
			final lwr = event.name.toLowerCase();
			var player = event.player;

			var entry = table.get(lwr);
			if (entry == null)
				table.set(lwr, entry = []);
			if (entry[player] == null)
				entry[player] = [];

			entry[player].push(event);
		}

		eventList.push(event);

		sortEvents();
	}

	public function update(curBeat:Float) {
		for (ev in eventList) {
			ev.active = false;

			if (ev.beat >= curBeat)
				continue;

			ev.active = true;
			ev.update(curBeat);
		}
	}

	public function getLastEventBefore(event:Event):Event {
		final playerEvents = table.get(event.name.toLowerCase());
		if (playerEvents == null) {
			return null;
		}

		final eventList = playerEvents[event.player];
		if (eventList == null) {
			return null;
		}

		final lastIndex = eventList.indexOf(event);
		if (lastIndex > 0) {
			final possibleEvent = eventList[lastIndex - 1];
			return possibleEvent != null ? possibleEvent : null;
		}

		return null;
	}

	private function sortEvents() {
		for (modTab in table.iterator()) {
			if (modTab == null)
				continue;
			for (events in modTab)
				if (events != null && events.length > 0)
					events.sort(__sortFunction);
		}
		eventList.sort(__sortFunction);
	}

	@:noCompletion
	private final __sortFunction:(Event, Event) -> Int = (a, b) -> {
		return Math.floor(a.beat - b.beat);
	};
}
