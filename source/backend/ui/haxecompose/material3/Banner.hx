package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class Banner
{
	public static function compose(composer:Composer, message:String, ?actionLabel:String, ?onAction:Void->Void, ?modifier:Modifier):Void
		Material3.Banner(composer, message, actionLabel, onAction, modifier);
}
