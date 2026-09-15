package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class Tooltip
{
	public static function compose(composer:Composer, message:String, ?modifier:Modifier):Void
		Material3.Tooltip(composer, message, modifier);
}
