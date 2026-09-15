package backend.ui.haxecompose.md3e;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.Measure.MeasureResult;
import backend.ui.haxecompose.ui.Modifier;

class WavyProgressIndicator
{
	public static function compose(composer:Composer, progress:Null<Float> = null, ?modifier:Modifier):Void
	{
		var base = modifier != null ? modifier : Modifier.empty();
		var indicatorModifier = base.background(ExpressiveTheme.surfaceVariant, ExpressiveTokens.cornerFull);

		composer.emit("WavyProgressIndicator", "progress", indicatorModifier, function(node)
		{
			var safeProgress = progress == null ? null : Math.max(0, Math.min(1, progress));
			node.setProp("progress", safeProgress);
			node.setProp("color", ExpressiveTheme.secondary);
			node.setProp("trackColor", ExpressiveTheme.surfaceVariant);
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var width = n.modifier.fixedWidth != null ? n.modifier.fixedWidth : Math.min(140, constraints.maxWidth);
				var height = n.modifier.fixedHeight != null ? n.modifier.fixedHeight : 8;
				return new MeasureResult(constraints.constrainWidth(width), constraints.constrainHeight(height));
			};
		});
	}
}
