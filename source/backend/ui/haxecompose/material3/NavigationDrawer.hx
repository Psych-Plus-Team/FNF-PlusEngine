package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class NavigationDrawer
{
	public static function compose(composer:Composer, items:Array<String>, selectedIndex:Int, onSelect:Int->String->Void, ?modifier:Modifier):Void
		Material3.NavigationDrawer(composer, items, selectedIndex, onSelect, modifier);
}
