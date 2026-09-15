package backend.ui.haxecompose.foundation;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Layout;
import backend.ui.haxecompose.ui.Modifier;

class Column
{
	public static function compose(composer:Composer, ?modifier:Modifier, ?content:Composable):Void
	{
		composer.emit("Column", null, modifier, function(node) node.measurePolicy = Layout.measureColumn, content);
	}
}
