package backend.ui.haxecompose.runtime;

class Effects
{
	public static function launchedEffect(composer:Composer, key:String, effect:Void->Void):Void
	{
		var ran = composer.remember(function() return new Map<String, Bool>());
		if (!ran.exists(key))
		{
			ran.set(key, true);
			if (effect != null)
				effect();
		}
	}
}
