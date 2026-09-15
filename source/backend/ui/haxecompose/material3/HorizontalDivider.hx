package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class HorizontalDivider
{
	public static function compose(composer:Composer, ?modifier:Modifier):Void
		Material3.Divider(composer, modifier);
}
