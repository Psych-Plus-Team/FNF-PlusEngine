package backend.ui.haxecompose.runtime;

typedef StateWatcher = Void->Void;

class MutableState<T>
{
	var _value:T;
	var watchers:Array<StateWatcher> = [];

	public var version(default, null):Int = 0;
	public var value(get, set):T;

	public function new(initial:T)
	{
		_value = initial;
	}

	inline function get_value():T
	{
		StateObserver.onRead(this);
		return _value;
	}

	function set_value(next:T):T
	{
		if (_value == next)
			return _value;

		_value = next;
		version++;
		Recomposer.instance.metrics.stateInvalidations++;
		StateObserver.onWrite(this);
		for (watcher in watchers.copy())
			if (watcher != null)
				watcher();
		return _value;
	}

	public function observe(watcher:StateWatcher):Void
	{
		if (watcher != null && !watchers.contains(watcher))
			watchers.push(watcher);
	}

	public function removeObserver(watcher:StateWatcher):Void
	{
		watchers.remove(watcher);
	}
}

class State
{
	public static function mutableStateOf<T>(initial:T):MutableState<T>
		return new MutableState<T>(initial);
}
