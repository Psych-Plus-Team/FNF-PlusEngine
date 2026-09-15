package backend.ui.haxecompose.foundation;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.Measure.MeasureResult;
import backend.ui.haxecompose.ui.Modifier;
import flixel.util.FlxColor;

class Text
{
	public static function compose(composer:Composer, text:String, ?modifier:Modifier, size:Int = 16, color:FlxColor = FlxColor.WHITE):Void
	{
		composer.emit("Text", text, modifier, function(node)
		{
			node.setProp("text", text);
			node.setProp("size", size);
			node.setProp("color", color);
			node.measurePolicy = function(n, constraints:Constraints)
			{
				var label = Std.string(n.props.get("text"));
				var fontSize:Int = n.props.get("size");
				var w = Math.min(constraints.maxWidth, Math.max(1, label.length * fontSize * 0.58));
				var h = Math.max(1, fontSize * 1.35);
				if (n.modifier.fixedWidth != null)
					w = n.modifier.fixedWidth;
				if (n.modifier.fixedHeight != null)
					h = n.modifier.fixedHeight;
				return new MeasureResult(constraints.constrainWidth(w), constraints.constrainHeight(h));
			};
		});
	}
}
