package psychlua.backend.actorframe;

#if LUA_ALLOWED
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import psychlua.backend.LuaUtils;

class ActorFrameTextureSource extends FlxSprite
{
	static var textureCounter:Int = 0;

	public var renderWidth:Int = 1;
	public var renderHeight:Int = 1;
	public var preserveTexture:Bool = true;
	public var targetTag:String = "hud";
	public var captureMode:String = "camera";
	public var captureEveryFrame:Bool = false;
	public var captureInterval:Float = 0;

	var captureTimer:Float = 0;
	var consumers:Array<FlxSprite> = [];
	var drawMatrix:Matrix = new Matrix();
	var drawRect:Rectangle = new Rectangle();
	var drawPoint:Point = new Point();

	public function new(width:Int, height:Int)
	{
		super();
		resizeTexture(width, height);
		active = true;
		visible = false;
	}

	public function resizeTexture(width:Int, height:Int):Void
	{
		renderWidth = Std.int(Math.max(1, width));
		renderHeight = Std.int(Math.max(1, height));
		textureCounter++;
		makeGraphic(renderWidth, renderHeight, FlxColor.TRANSPARENT, true, 'actorframe_texture_$textureCounter');
		useFramePixels = false;
		dirty = true;
		markConsumersDirty();
	}

	public function setTarget(value:String):Void
	{
		if (value == null || value.length == 0)
			return;
		targetTag = value;
	}

	public function addConsumer(sprite:FlxSprite):Void
	{
		if (sprite == null || consumers.indexOf(sprite) >= 0)
			return;
		consumers.push(sprite);
		sprite.useFramePixels = false;
		sprite.dirty = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!captureEveryFrame)
			return;

		captureTimer += elapsed;
		if (captureInterval > 0 && captureTimer < captureInterval)
			return;

		captureTimer = 0;
		captureNow();
	}

	public function captureNow():Bool
	{
		if (pixels == null)
			resizeTexture(renderWidth, renderHeight);

		var bmp:BitmapData = pixels;
		if (bmp == null)
			return false;

		drawRect.setTo(0, 0, renderWidth, renderHeight);
		bmp.fillRect(drawRect, FlxColor.TRANSPARENT);

		var ok:Bool = false;
		switch (captureMode == null ? "camera" : captureMode.toLowerCase().trim())
		{
			case "sprite" | "actor" | "object":
				ok = captureSprite(ActorFrameBackend.resolveTarget(targetTag), bmp);
			case "auto":
				var target:Dynamic = ActorFrameBackend.getActorVariable(targetTag);
				if (target != null && Std.isOfType(target, FlxSprite))
					ok = captureSprite(target, bmp);
				else
					ok = captureCamera(resolveCameraTarget(), bmp);
			default:
				ok = captureCamera(resolveCameraTarget(), bmp);
		}

		if (ok)
		{
			pixels = bmp;
			dirty = true;
			markConsumersDirty();
		}
		return ok;
	}

	function captureCamera(camera:FlxCamera, target:BitmapData):Bool
	{
		if (camera == null)
			return false;

		if (FlxG.renderBlit && camera.buffer != null)
		{
			drawRect.setTo(0, 0, Math.min(renderWidth, camera.buffer.width), Math.min(renderHeight, camera.buffer.height));
			target.copyPixels(camera.buffer, drawRect, drawPoint, null, null, true);
			return true;
		}

		if (camera.flashSprite == null)
			return false;

		var sourceWidth = Math.max(1, camera.width * camera.initialZoom * FlxG.scaleMode.scale.x);
		var sourceHeight = Math.max(1, camera.height * camera.initialZoom * FlxG.scaleMode.scale.y);
		drawMatrix.setTo(renderWidth / sourceWidth, 0, 0, renderHeight / sourceHeight, renderWidth * 0.5, renderHeight * 0.5);

		try
		{
			target.draw(camera.flashSprite, drawMatrix, null, null, drawRect, true);
			return true;
		}
		catch (_:Dynamic)
		{
			return false;
		}
	}

	function captureSprite(value:Dynamic, target:BitmapData):Bool
	{
		if (!Std.isOfType(value, FlxSprite))
			return false;

		var sprite:FlxSprite = cast value;
		if (sprite.frame != null)
		{
			sprite.frame.paint(target, drawPoint, true, false);
			return true;
		}

		if (sprite.pixels != null)
		{
			drawRect.setTo(0, 0, Math.min(renderWidth, sprite.pixels.width), Math.min(renderHeight, sprite.pixels.height));
			target.copyPixels(sprite.pixels, drawRect, drawPoint, null, null, true);
			return true;
		}
		return false;
	}

	function resolveCameraTarget():FlxCamera
	{
		var target:Dynamic = ActorFrameBackend.getActorVariable(targetTag);
		if (target != null && Std.isOfType(target, FlxCamera))
			return cast target;
		return LuaUtils.cameraFromString(targetTag);
	}

	function markConsumersDirty():Void
	{
		var alive:Array<FlxSprite> = [];
		for (sprite in consumers)
		{
			if (sprite != null && sprite.exists)
			{
				sprite.dirty = true;
				alive.push(sprite);
			}
		}
		consumers = alive;
	}

	override public function destroy():Void
	{
		consumers = [];
		super.destroy();
	}
}
#end
