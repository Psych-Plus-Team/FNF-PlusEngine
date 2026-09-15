package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Modifier;
import flixel.util.FlxColor;

class Surface
{
	public static function compose(composer:Composer, ?modifier:Modifier, ?color:FlxColor, radius:Float = 0, ?content:Composable):Void
		Material3.Surface(composer, modifier, color, radius, content);
}
