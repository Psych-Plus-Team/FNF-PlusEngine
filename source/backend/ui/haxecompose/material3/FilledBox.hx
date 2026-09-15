package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Modifier;

class FilledBox
{
	public static function compose(composer:Composer, ?modifier:Modifier, ?content:Composable):Void
		Material3.FilledBox(composer, modifier, content);
}
