package backend.ui.haxecompose.runtime;

class StateDependencyRegistry
{
	static var dependencies:Map<String, Array<CompositionGroup>> = [];

	static function keyFor(state:Dynamic):String
		return Std.string(state);

	public static function register(state:Dynamic, group:CompositionGroup):Void
	{
		if (state == null || group == null)
			return;

		var key = keyFor(state);
		var groups = dependencies.get(key);
		if (groups == null)
		{
			groups = [];
			dependencies.set(key, groups);
		}
		if (!groups.contains(group))
			groups.push(group);
	}

	public static function invalidate(state:Dynamic):Void
	{
		var groups = dependencies.get(keyFor(state));
		if (groups == null)
			return;

		for (group in groups.copy())
			if (group != null)
				group.invalidate();
	}

	public static function clearGroup(group:CompositionGroup):Void
	{
		if (group == null)
			return;

		for (key in dependencies.keys())
		{
			var groups = dependencies.get(key);
			if (groups != null)
			{
				groups.remove(group);
				if (groups.length == 0)
					dependencies.remove(key);
			}
		}
	}

	public static function dump():String
	{
		var lines:Array<String> = [];
		for (key in dependencies.keys())
		{
			var groups = dependencies.get(key);
			lines.push(key + " -> " + (groups != null ? groups.map(group -> group.key).join(", ") : ""));
		}
		return lines.join("\n");
	}
}
