package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class Badge
{
	public static function compose(composer:Composer, text:String, ?modifier:Modifier):Void
		Material3.Badge(composer, text, modifier);
}
