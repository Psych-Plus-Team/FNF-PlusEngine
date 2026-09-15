package backend.ui.haxecompose.flixel;

import backend.ui.haxecompose.backend.FlixelRenderer;
import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

class FlixelComposeHost extends FlxSpriteGroup
{
	public final composer:Composer;
	public final renderer:FlixelRenderer;

	var content:Composable;

	public function new(content:Composable)
	{
		super();
		this.content = content;
		composer = new Composer();
		renderer = new FlixelRenderer(this);
	}

	override function update(elapsed:Float):Void
	{
		renderer.animationTime += elapsed;
		if (renderer.animationTime > 64)
			renderer.animationTime %= 64;
		var composed = false;
		if (composer.root == null || composer.recomposer.shouldCompose())
			composed = composer.compose(content);

		if (composed)
			renderer.render(composer.root, FlxG.width, FlxG.height);
		else if (renderer.hasActiveAnimations)
			renderer.renderAnimations();

		renderer.updateInput();
		super.update(elapsed);
	}

	public function invalidate():Void
	{
		composer.recomposer.invalidate();
	}
}
