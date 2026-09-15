package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class MessageBox
{
	public static function compose(composer:Composer, title:String, message:String, ?actionLabel:String = "OK", ?onAction:Void->Void,
			?modifier:Modifier):Void
		Material3.MessageBox(composer, title, message, actionLabel, onAction, modifier);
}
