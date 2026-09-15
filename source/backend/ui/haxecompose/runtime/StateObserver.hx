package backend.ui.haxecompose.runtime;

class StateObserver
{
	public static var currentGroup:CompositionGroup = null;

	public static function onRead(state:Dynamic):Void
	{
		if (currentGroup != null)
			currentGroup.observeState(state);
	}

	public static function onWrite(state:Dynamic):Void
	{
		StateDependencyRegistry.invalidate(state);
	}
}
