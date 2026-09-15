package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.md3.MD3Theme;
import flixel.util.FlxColor;

class MaterialTheme
{
	public static var colorScheme(default, null):ColorScheme = new ColorScheme();

	public static function compose(composer:Composer, content:Composable):Void
	{
		if (content != null)
			content(composer);
	}
}

class ColorScheme
{
	public function new() {}

	public var primary(get, never):FlxColor;
	public var onPrimary(get, never):FlxColor;
	public var primaryContainer(get, never):FlxColor;
	public var onPrimaryContainer(get, never):FlxColor;
	public var secondaryContainer(get, never):FlxColor;
	public var onSecondaryContainer(get, never):FlxColor;
	public var surface(get, never):FlxColor;
	public var surfaceContainer(get, never):FlxColor;
	public var surfaceContainerHigh(get, never):FlxColor;
	public var onSurface(get, never):FlxColor;
	public var onSurfaceVariant(get, never):FlxColor;
	public var outline(get, never):FlxColor;
	public var outlineVariant(get, never):FlxColor;
	public var error(get, never):FlxColor;
	public var onError(get, never):FlxColor;

	inline function get_primary():FlxColor return MD3Theme.primary;
	inline function get_onPrimary():FlxColor return MD3Theme.onPrimary;
	inline function get_primaryContainer():FlxColor return MD3Theme.primaryContainer;
	inline function get_onPrimaryContainer():FlxColor return MD3Theme.onPrimaryContainer;
	inline function get_secondaryContainer():FlxColor return MD3Theme.secondaryContainer;
	inline function get_onSecondaryContainer():FlxColor return MD3Theme.onSecondaryContainer;
	inline function get_surface():FlxColor return MD3Theme.surface;
	inline function get_surfaceContainer():FlxColor return MD3Theme.surfaceContainer;
	inline function get_surfaceContainerHigh():FlxColor return MD3Theme.surfaceContainerHigh;
	inline function get_onSurface():FlxColor return MD3Theme.onSurface;
	inline function get_onSurfaceVariant():FlxColor return MD3Theme.onSurfaceVariant;
	inline function get_outline():FlxColor return MD3Theme.outline;
	inline function get_outlineVariant():FlxColor return MD3Theme.outlineVariant;
	inline function get_error():FlxColor return MD3Theme.error;
	inline function get_onError():FlxColor return MD3Theme.onError;
}
