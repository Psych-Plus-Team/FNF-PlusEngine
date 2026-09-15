package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Modifier;

class Card
{
	public static function compose(composer:Composer, ?modifier:Modifier, ?content:Composable):Void
		Material3.Card(composer, modifier, content);
}
