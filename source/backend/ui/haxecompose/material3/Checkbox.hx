package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class Checkbox
{
	public static function compose(composer:Composer, label:String, checked:Bool, onCheckedChange:Bool->Void, ?modifier:Modifier):Void
		Material3.Checkbox(composer, label, checked, onCheckedChange, modifier);
}
