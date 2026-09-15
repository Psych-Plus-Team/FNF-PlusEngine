package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;
import flixel.util.FlxColor;

class Icon
{
	public static function compose(composer:Composer, name:String, ?modifier:Modifier, size:Int = 24, ?color:FlxColor):Void
		Material3.Icon(composer, name, modifier, size, color);
}
