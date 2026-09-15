package backend.ui.haxecompose.backend;

import backend.ui.haxecompose.ui.Node;
import openfl.display.Sprite;

class OpenFLRenderer implements Renderer
{
	public final host:Sprite;

	public function new(host:Sprite)
	{
		this.host = host;
	}

	public function render(root:Node, width:Float, height:Float):Void
	{
		// Placeholder backend. The runtime/layout tree is backend-agnostic; drawing can be filled in when we need non-Flixel targets.
	}
}
