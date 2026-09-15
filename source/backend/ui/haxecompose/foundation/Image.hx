package backend.ui.haxecompose.foundation;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.Measure.MeasureResult;
import backend.ui.haxecompose.ui.Modifier;

class Image
{
	public static function compose(composer:Composer, asset:String, width:Float, height:Float, ?modifier:Modifier):Void
	{
		composer.emit("Image", asset, modifier != null ? modifier.size(width, height) : Modifier.empty().size(width, height), function(node)
		{
			node.setProp("asset", asset);
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var w:Float = n.modifier.fixedWidth != null ? n.modifier.fixedWidth : width;
				var h:Float = n.modifier.fixedHeight != null ? n.modifier.fixedHeight : height;
				return new MeasureResult(constraints.constrainWidth(w), constraints.constrainHeight(h));
			};
		});
	}
}
