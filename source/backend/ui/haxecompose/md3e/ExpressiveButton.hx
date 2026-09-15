package backend.ui.haxecompose.md3e;

import backend.ui.haxecompose.foundation.Text;
import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.Layout;
import backend.ui.haxecompose.ui.Measure.MeasureResult;
import backend.ui.haxecompose.ui.Modifier;

class ExpressiveButton
{
	public static function compose(composer:Composer, label:String, onClick:Void->Void, ?modifier:Modifier, ?content:Composable):Void
	{
		var base = modifier != null ? modifier : Modifier.empty();
		var buttonModifier = base
			.paddingXY(18, 12)
			.background(ExpressiveTheme.primary, ExpressiveTokens.cornerLarge)
			.clickable(onClick);

		composer.emit("ExpressiveButton", label, buttonModifier, function(node)
		{
			node.setProp("label", label);
			node.setProp("onClick", onClick);
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var size = Layout.measureBox(n, constraints);
				return new MeasureResult(Math.max(76, size.width), Math.max(46, size.height));
			};
		}, content != null ? content : function(c) Text.compose(c, label, null, 16, ExpressiveTheme.onPrimary));
	}
}
