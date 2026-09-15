package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class AlertDialog
{
	public static function compose(composer:Composer, title:String, text:String, confirmLabel:String, onConfirm:Void->Void, ?dismissLabel:String,
			?onDismiss:Void->Void, ?modifier:Modifier):Void
		Material3.AlertDialog(composer, title, text, confirmLabel, onConfirm, dismissLabel, onDismiss, modifier);
}
