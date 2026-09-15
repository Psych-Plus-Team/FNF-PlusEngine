package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class Slider
{
	public static function compose(composer:Composer, value:Float, onValueChange:Float->Void, min:Float = 0, max:Float = 1, ?modifier:Modifier):Void
		Material3.Slider(composer, value, min, max, onValueChange, modifier);
}
