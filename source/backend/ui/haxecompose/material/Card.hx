package backend.ui.haxecompose.material;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Layout;
import backend.ui.haxecompose.ui.Modifier;

class Card
{
	public static function compose(composer:Composer, ?modifier:Modifier, ?content:Composable):Void
	{
		var cardModifier = (modifier != null ? modifier : Modifier.empty()).padding(12).background(Theme.surfaceHigh, 12);
		composer.emit("Card", null, cardModifier, function(node) node.measurePolicy = Layout.measureBox, content);
	}
}
