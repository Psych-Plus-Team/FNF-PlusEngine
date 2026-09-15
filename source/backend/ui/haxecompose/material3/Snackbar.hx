package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class Snackbar
{
	public static function compose(composer:Composer, message:String, ?actionLabel:String, ?onAction:Void->Void, ?modifier:Modifier):Void
		Material3.Snackbar(composer, message, actionLabel, onAction, modifier);
}
