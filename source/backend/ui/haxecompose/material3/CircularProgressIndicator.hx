package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.Measure.MeasureResult;
import backend.ui.haxecompose.ui.Modifier;

class CircularProgressIndicator
{
	public static function compose(composer:Composer, progress:Null<Float> = null, ?modifier:Modifier):Void
	{
		composer.emit("MD3CircularProgressIndicator", null, modifier != null ? modifier : Modifier.empty().size(36, 36), function(node)
		{
			node.setProp("progress", progress == null ? null : Math.max(0, Math.min(1, progress)));
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var size = n.modifier.fixedWidth != null ? n.modifier.fixedWidth : 36;
				return new MeasureResult(constraints.constrainWidth(size), constraints.constrainHeight(size));
			};
		});
	}
}
