package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class Switch
{
	public static function compose(composer:Composer, checked:Bool, onCheckedChange:Bool->Void, ?label:String, ?modifier:Modifier):Void
		Material3.Switch(composer, checked, onCheckedChange, label, modifier);
}
