package backend.ui.haxecompose.foundation;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Layout;
import backend.ui.haxecompose.ui.Modifier;

class Box
{
	public static function compose(composer:Composer, ?modifier:Modifier, ?content:Composable):Void
	{
		composer.emit("Box", null, modifier, function(node) node.measurePolicy = Layout.measureBox, content);
	}
}
