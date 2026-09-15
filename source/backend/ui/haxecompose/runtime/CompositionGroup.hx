package backend.ui.haxecompose.runtime;

class CompositionGroup
{
	public final key:String;
	public var dirty(default, null):Bool = false;

	public function new(key:String)
	{
		this.key = key;
	}

	public function observeState(state:Dynamic):Void
	{
		StateDependencyRegistry.register(state, this);
	}

	public function invalidate():Void
	{
		if (dirty)
			return;

		dirty = true;
		Recomposer.instance.schedule(this);
	}

	public function clearDirty():Void
	{
		dirty = false;
	}
}
