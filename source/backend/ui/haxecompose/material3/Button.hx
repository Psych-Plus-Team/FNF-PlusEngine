package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class Button
{
	public static function compose(composer:Composer, text:String, onClick:Void->Void, ?modifier:Modifier):Void
		Material3.Button(composer, text, onClick, Filled, modifier);
}
