package backend.ui.haxecompose.material;

import backend.ui.md3.MD3Theme;
import flixel.util.FlxColor;

class Theme
{
	public static var primary(get, never):FlxColor;
	public static var onPrimary(get, never):FlxColor;
	public static var surface(get, never):FlxColor;
	public static var surfaceHigh(get, never):FlxColor;
	public static var onSurface(get, never):FlxColor;
	public static var outline(get, never):FlxColor;

	static inline function get_primary():FlxColor return MD3Theme.primary;
	static inline function get_onPrimary():FlxColor return MD3Theme.onPrimary;
	static inline function get_surface():FlxColor return MD3Theme.surface;
	static inline function get_surfaceHigh():FlxColor return MD3Theme.surfaceContainerHigh;
	static inline function get_onSurface():FlxColor return MD3Theme.onSurface;
	static inline function get_outline():FlxColor return MD3Theme.outlineVariant;
}
