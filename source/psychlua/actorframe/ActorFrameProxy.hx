package psychlua.actorframe;

#if LUA_ALLOWED
import flixel.FlxSprite;
import psychlua.LuaUtils;

class ActorFrameProxy extends FlxSprite
{
	public var targetTag:String;
	public var target:FlxSprite;
	public var followTransform:Bool = false;
	public var followVisuals:Bool = true;

	public function new()
	{
		super();
		active = true;
	}

	public function setTarget(value:Dynamic, ?tag:String):Bool
	{
		targetTag = tag;
		target = Std.isOfType(value, FlxSprite) ? cast value : null;
		if (target == null)
			return false;

		copyTargetVisuals();
		if (followTransform)
			copyTargetTransform();
		return true;
	}

	override public function update(elapsed:Float):Void
	{
		if (targetTag != null)
		{
			var resolved:Dynamic = ActorFrameBackend.getActorVariable(targetTag);
			if (resolved == null)
				resolved = LuaUtils.getObjectDirectly(targetTag);
			if (Std.isOfType(resolved, FlxSprite) && resolved != target)
				target = cast resolved;
		}

		if (target != null)
		{
			if (followVisuals)
				copyTargetVisuals();
			if (followTransform)
				copyTargetTransform();
		}
		super.update(elapsed);
	}

	function copyTargetVisuals():Void
	{
		if (target == null)
			return;

		if (target.frames != null && frames != target.frames)
			frames = target.frames;
		else if (target.graphic != null && graphic != target.graphic)
			loadGraphic(target.graphic);

		if (target.animation != null && target.animation.curAnim != null && animation != null)
		{
			var animName = target.animation.curAnim.name;
			if (animation.getByName(animName) != null)
				animation.play(animName, true, false, target.animation.curAnim.curFrame);
		}

		frame = target.frame;
		origin.copyFrom(target.origin);
		offset.copyFrom(target.offset);
		antialiasing = target.antialiasing;
	}

	function copyTargetTransform():Void
	{
		if (target == null)
			return;

		x = target.x;
		y = target.y;
		angle = target.angle;
		alpha = target.alpha;
		visible = target.visible;
		scale.copyFrom(target.scale);
		scrollFactor.copyFrom(target.scrollFactor);
		color = target.color;
		flipX = target.flipX;
		flipY = target.flipY;
		blend = target.blend;
		shader = target.shader;
	}
}
#end
