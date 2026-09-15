package backend.ui.haxecompose.ui;

class HitTest
{
	public static function hitTest(node:Node, x:Float, y:Float, parentX:Float = 0, parentY:Float = 0, ?result:Array<Node>):Array<Node>
	{
		if (result == null)
			result = [];
		if (node == null)
			return result;

		var absX = parentX + node.x;
		var absY = parentY + node.y;
		var inside = x >= absX && y >= absY && x <= absX + node.width && y <= absY + node.height;
		if (!inside)
			return result;

		result.push(node);
		for (child in node.children)
			hitTest(child, x, y, absX, absY, result);
		return result;
	}
}
