package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;
import flixel.util.FlxColor;

class Text
{
	public static function compose(composer:Composer, text:String, ?modifier:Modifier, size:Int = 16, ?color:FlxColor):Void
		Material3.TextLabel(composer, text, modifier, size, color);
}
