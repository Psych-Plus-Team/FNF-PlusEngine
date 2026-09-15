package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class RadioButton
{
	public static function compose(composer:Composer, label:String, selected:Bool, onSelect:Void->Void, ?modifier:Modifier):Void
		Material3.RadioButton(composer, label, selected, onSelect, modifier);
}
