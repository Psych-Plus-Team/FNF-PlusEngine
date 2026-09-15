package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class Menu
{
	public static function compose(composer:Composer, items:Array<String>, onSelect:Int->String->Void, ?modifier:Modifier):Void
		Material3.Menu(composer, items, onSelect, modifier);
}
