package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class IconButton
{
	public static function compose(composer:Composer, iconName:String, onClick:Void->Void, ?modifier:Modifier):Void
		Material3.IconButton(composer, iconName, onClick, modifier);
}
