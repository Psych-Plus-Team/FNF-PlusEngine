package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Modifier;

class Scaffold
{
	public static function compose(composer:Composer, ?modifier:Modifier, ?topBar:Composable, ?content:Composable):Void
		Material3.Scaffold(composer, modifier, topBar, content);
}
