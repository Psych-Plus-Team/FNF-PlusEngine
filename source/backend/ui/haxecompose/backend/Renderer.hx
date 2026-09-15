package backend.ui.haxecompose.backend;

import backend.ui.haxecompose.ui.Node;

interface Renderer
{
	public function render(root:Node, width:Float, height:Float):Void;
}
