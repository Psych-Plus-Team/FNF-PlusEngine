package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class FloatingActionButton
{
	public static function compose(composer:Composer, label:String, onClick:Void->Void, ?modifier:Modifier, ?iconName:String):Void
		Material3.FloatingActionButton(composer, label, onClick, modifier, iconName);
}
