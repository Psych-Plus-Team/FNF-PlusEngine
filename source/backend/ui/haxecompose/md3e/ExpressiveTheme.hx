package backend.ui.haxecompose.md3e;

import flixel.util.FlxColor;

class ExpressiveTheme
{
	public static var enabled(default, null):Bool = false;

	public static var primary:FlxColor = ExpressiveTokens.primary;
	public static var onPrimary:FlxColor = ExpressiveTokens.onPrimary;
	public static var secondary:FlxColor = ExpressiveTokens.secondary;
	public static var surface:FlxColor = ExpressiveTokens.surface;
	public static var surfaceVariant:FlxColor = ExpressiveTokens.surfaceVariant;
	public static var onSurface:FlxColor = ExpressiveTokens.onSurface;
	public static var outline:FlxColor = ExpressiveTokens.outline;

	public static function use(content:Void->Void):Void
	{
		var previous = enabled;
		enabled = true;
		if (content != null)
			content();
		enabled = previous;
	}
}
