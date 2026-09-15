package backend.ui.haxecompose.ui;

import backend.ui.haxecompose.ui.Measure.MeasureResult;

class Layout
{
	public static function measureBox(node:Node, constraints:Constraints):MeasureResult
	{
		var mod = node.modifier;
		var inner = constraints.inset(mod.paddingLeft + mod.paddingRight, mod.paddingTop + mod.paddingBottom);
		var maxW:Float = 0;
		var maxH:Float = 0;

		for (child in node.children)
		{
			var childSize = child.measure(inner);
			child.place(mod.paddingLeft, mod.paddingTop);
			maxW = Math.max(maxW, childSize.width);
			maxH = Math.max(maxH, childSize.height);
		}

		var width = mod.fixedWidth != null ? mod.fixedWidth : maxW + mod.paddingLeft + mod.paddingRight;
		var height = mod.fixedHeight != null ? mod.fixedHeight : maxH + mod.paddingTop + mod.paddingBottom;
		if (mod.fillWidth)
			width = constraints.maxWidth;
		if (mod.fillHeight)
			height = constraints.maxHeight;
		return new MeasureResult(constraints.constrainWidth(width), constraints.constrainHeight(height));
	}

	public static function measureColumn(node:Node, constraints:Constraints):MeasureResult
	{
		var mod = node.modifier;
		var inner = constraints.inset(mod.paddingLeft + mod.paddingRight, mod.paddingTop + mod.paddingBottom);
		var y = mod.paddingTop;
		var maxW:Float = 0;

		for (i in 0...node.children.length)
		{
			var child = node.children[i];
			var childSize = child.measure(inner);
			child.place(mod.paddingLeft, y);
			y += childSize.height + (i < node.children.length - 1 ? mod.gap : 0);
			maxW = Math.max(maxW, childSize.width);
		}

		var width = mod.fixedWidth != null ? mod.fixedWidth : maxW + mod.paddingLeft + mod.paddingRight;
		var height = mod.fixedHeight != null ? mod.fixedHeight : y + mod.paddingBottom;
		if (mod.fillWidth)
			width = constraints.maxWidth;
		if (mod.fillHeight)
			height = constraints.maxHeight;
		return new MeasureResult(constraints.constrainWidth(width), constraints.constrainHeight(height));
	}

	public static function measureRow(node:Node, constraints:Constraints):MeasureResult
	{
		var mod = node.modifier;
		var inner = constraints.inset(mod.paddingLeft + mod.paddingRight, mod.paddingTop + mod.paddingBottom);
		var x = mod.paddingLeft;
		var maxH:Float = 0;

		for (i in 0...node.children.length)
		{
			var child = node.children[i];
			var childSize = child.measure(inner);
			child.place(x, mod.paddingTop);
			x += childSize.width + (i < node.children.length - 1 ? mod.gap : 0);
			maxH = Math.max(maxH, childSize.height);
		}

		var width = mod.fixedWidth != null ? mod.fixedWidth : x + mod.paddingRight;
		var height = mod.fixedHeight != null ? mod.fixedHeight : maxH + mod.paddingTop + mod.paddingBottom;
		if (mod.fillWidth)
			width = constraints.maxWidth;
		if (mod.fillHeight)
			height = constraints.maxHeight;
		return new MeasureResult(constraints.constrainWidth(width), constraints.constrainHeight(height));
	}
}
