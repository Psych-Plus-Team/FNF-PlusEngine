package backend.ui.haxecompose.foundation;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.Measure.MeasureResult;
import backend.ui.haxecompose.ui.Modifier;

class Spacer
{
	public static function compose(composer:Composer, width:Float = 0, height:Float = 0, ?modifier:Modifier):Void
	{
		composer.emit("Spacer", null, modifier != null ? modifier : Modifier.empty(), function(node)
		{
			node.measurePolicy = function(_, constraints:Constraints)
				return new MeasureResult(constraints.constrainWidth(width), constraints.constrainHeight(height));
		});
	}
}
