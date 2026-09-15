package backend.ui.haxecompose.runtime;

import backend.ui.haxecompose.ui.Node;

class ComposeDebug
{
	public static function dumpTree(node:Node, indent:String = ""):String
	{
		if (node == null)
			return "";

		var label = indent + node.type + " " + node.key + " (" + Std.int(node.width) + "x" + Std.int(node.height) + ")";
		if (node.props.exists("text"))
			label += " \"" + Std.string(node.props.get("text")) + "\"";

		var lines = [label];
		for (child in node.children)
			lines.push(dumpTree(child, indent + "  "));
		return lines.join("\n");
	}

	public static function dumpDependencies():String
		return StateDependencyRegistry.dump();
}
