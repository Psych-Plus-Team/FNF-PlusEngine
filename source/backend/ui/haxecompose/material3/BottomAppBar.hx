package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class BottomAppBar
{
	public static function compose(composer:Composer, actions:Array<String>, ?fabIcon:String, ?onAction:Int->String->Void, ?onFab:Void->Void,
			?modifier:Modifier):Void
		Material3.BottomAppBar(composer, actions, fabIcon, onAction, onFab, modifier);
}
