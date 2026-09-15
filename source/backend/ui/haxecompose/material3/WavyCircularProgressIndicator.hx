package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.Measure.MeasureResult;
import backend.ui.haxecompose.ui.Modifier;
import backend.ui.md3.MD3Theme;

class WavyCircularProgressIndicator
{
	public static function compose(composer:Composer, progress:Null<Float> = null, ?modifier:Modifier):Void
	{
		composer.emit("WavyCircularProgressIndicator", null, modifier != null ? modifier : Modifier.empty().size(42, 42), function(node)
		{
			node.setProp("progress", progress == null ? null : Math.max(0, Math.min(1, progress)));
			node.setProp("color", MD3Theme.primary);
			node.setProp("trackColor", MD3Theme.surfaceVariant);
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var size = n.modifier.fixedWidth != null ? n.modifier.fixedWidth : 42;
				return new MeasureResult(constraints.constrainWidth(size), constraints.constrainHeight(size));
			};
		});
	}
}
