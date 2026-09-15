package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class TextField
{
	public static function compose(composer:Composer, label:String, value:String, ?onClick:Void->Void, ?modifier:Modifier):Void
		Material3.TextField(composer, label, value, onClick, modifier);
}
