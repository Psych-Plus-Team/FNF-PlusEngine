package backend.ui.haxecompose.runtime;

class Recomposer
{
	public static final instance:Recomposer = new Recomposer();

	public var invalidated(default, null):Bool = true;
	public var recompositionCount(default, null):Int = 0;
	public final metrics:ComposeMetrics = new ComposeMetrics();

	var pending:Array<CompositionGroup> = [];

	public function new() {}

	public function invalidate():Void
	{
		invalidated = true;
	}

	public function shouldCompose():Bool
		return invalidated || pending.length > 0;

	public function markComposed():Void
	{
		if (invalidated || pending.length > 0)
		{
			recompositionCount++;
			metrics.recompositions++;
		}
		for (group in pending)
			group.clearDirty();
		pending = [];
		invalidated = false;
	}

	public function schedule(group:CompositionGroup):Void
	{
		if (group != null && !pending.contains(group))
			pending.push(group);
		invalidated = true;
	}
}
