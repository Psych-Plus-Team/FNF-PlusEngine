package backend.ui.haxecompose.material;

import backend.ui.haxecompose.foundation.Text;
import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.Layout;
import backend.ui.haxecompose.ui.Measure.MeasureResult;
import backend.ui.haxecompose.ui.Modifier;

class Button
{
	public static function compose(composer:Composer, onClick:Void->Void, ?modifier:Modifier, ?content:Composable):Void
	{
		var buttonModifier = (modifier != null ? modifier : Modifier.empty()).paddingXY(16, 10).background(Theme.primary, 16).clickable(onClick);
		composer.emit("Button", null, buttonModifier, function(node)
		{
			node.setProp("onClick", onClick);
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var size = Layout.measureBox(n, constraints);
				return new MeasureResult(Math.max(64, size.width), Math.max(40, size.height));
			};
		}, content != null ? content : function(c) Text.compose(c, "Button", null, 15, Theme.onPrimary));
	}
}
