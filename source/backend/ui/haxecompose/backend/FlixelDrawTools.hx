package backend.ui.haxecompose.backend;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.DrawStyle;
import flixel.util.FlxSpriteUtil.LineStyle;

class FlixelDrawTools
{
	static var drawStyle:DrawStyle = {smoothing: false};
	static var strokeStyle:LineStyle = {thickness: 1, color: FlxColor.WHITE};

	public static function prepareCanvas(sprite:FlxSprite, width:Int, height:Int):Void
	{
		width = Std.int(Math.max(1, width));
		height = Std.int(Math.max(1, height));
		if (sprite.pixels == null || sprite.pixels.width != width || sprite.pixels.height != height)
			sprite.makeGraphic(width, height, FlxColor.TRANSPARENT, true);
		else
		{
			sprite.pixels.fillRect(sprite.pixels.rect, FlxColor.TRANSPARENT);
			sprite.dirty = true;
		}
	}

	public static function fill(sprite:FlxSprite, color:FlxColor):Void
	{
		if (sprite != null && sprite.pixels != null)
		{
			sprite.pixels.fillRect(sprite.pixels.rect, color);
			sprite.dirty = true;
		}
	}

	public static function roundRect(sprite:FlxSprite, x:Float, y:Float, width:Float, height:Float, radius:Float, color:FlxColor):Void
	{
		FlxSpriteUtil.drawRoundRect(sprite, x, y, width, height, radius, radius, color, null, drawStyle);
	}

	public static function roundRectOutline(sprite:FlxSprite, x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float,
			color:FlxColor):Void
	{
		FlxSpriteUtil.drawRoundRect(sprite, x, y, width, height, radius, radius, FlxColor.TRANSPARENT, lineStyle(color, thickness), drawStyle);
	}

	public static function circle(sprite:FlxSprite, x:Float, y:Float, radius:Float, color:FlxColor):Void
	{
		FlxSpriteUtil.drawCircle(sprite, x, y, radius, color, null, drawStyle);
	}

	public static function line(sprite:FlxSprite, startX:Float, startY:Float, endX:Float, endY:Float, thickness:Float, color:FlxColor):Void
	{
		FlxSpriteUtil.drawLine(sprite, startX, startY, endX, endY, lineStyle(color, thickness), drawStyle);
	}

	public static function arc(sprite:FlxSprite, cx:Float, cy:Float, radius:Float, startDeg:Float, sweepDeg:Float, thickness:Float, color:FlxColor):Void
	{
		var steps = Std.int(Math.max(8, Std.int(Math.abs(sweepDeg) / 10)));
		var prevX = cx + Math.cos(startDeg * Math.PI / 180) * radius;
		var prevY = cy + Math.sin(startDeg * Math.PI / 180) * radius;
		FlxSpriteUtil.beginDraw(FlxColor.TRANSPARENT, lineStyle(color, thickness));
		FlxSpriteUtil.flashGfx.moveTo(prevX, prevY);
		for (i in 1...(steps + 1))
		{
			var angle = (startDeg + sweepDeg * (i / steps)) * Math.PI / 180;
			var nextX = cx + Math.cos(angle) * radius;
			var nextY = cy + Math.sin(angle) * radius;
			FlxSpriteUtil.flashGfx.lineTo(nextX, nextY);
			prevX = nextX;
			prevY = nextY;
		}
		FlxSpriteUtil.endDraw(sprite, drawStyle);
	}

	public static function wavyLine(sprite:FlxSprite, startX:Float, endX:Float, centerY:Float, amplitude:Float, wavelength:Float, phase:Float,
			thickness:Float, color:FlxColor):Void
	{
		if (endX <= startX)
			return;

		var step = Math.max(3, wavelength / 8);
		var prevX = startX;
		var prevY = centerY + Math.sin((prevX / wavelength) * Math.PI * 2 + phase) * amplitude;
		var nextX = startX + step;
		FlxSpriteUtil.beginDraw(FlxColor.TRANSPARENT, lineStyle(color, thickness));
		FlxSpriteUtil.flashGfx.moveTo(prevX, prevY);
		while (nextX < endX)
		{
			var nextY = centerY + Math.sin((nextX / wavelength) * Math.PI * 2 + phase) * amplitude;
			FlxSpriteUtil.flashGfx.lineTo(nextX, nextY);
			prevX = nextX;
			prevY = nextY;
			nextX += step;
		}

		var finalY = centerY + Math.sin((endX / wavelength) * Math.PI * 2 + phase) * amplitude;
		FlxSpriteUtil.flashGfx.lineTo(endX, finalY);
		FlxSpriteUtil.endDraw(sprite, drawStyle);
	}

	public static function wavyArc(sprite:FlxSprite, cx:Float, cy:Float, radius:Float, startDeg:Float, sweepDeg:Float, thickness:Float,
			color:FlxColor, phase:Float):Void
	{
		var steps = Std.int(Math.max(12, Std.int(Math.abs(sweepDeg) / 12)));
		FlxSpriteUtil.beginDraw(FlxColor.TRANSPARENT, lineStyle(color, thickness));
		for (i in 0...(steps + 1))
		{
			var t = i / steps;
			var angleDeg = startDeg + sweepDeg * t;
			var waveRadius = radius + Math.sin(t * Math.PI * 5 + phase) * 2.2;
			var angle = angleDeg * Math.PI / 180;
			var nextX = cx + Math.cos(angle) * waveRadius;
			var nextY = cy + Math.sin(angle) * waveRadius;
			if (i > 0)
				FlxSpriteUtil.flashGfx.lineTo(nextX, nextY);
			else
				FlxSpriteUtil.flashGfx.moveTo(nextX, nextY);
		}
		FlxSpriteUtil.endDraw(sprite, drawStyle);
	}

	static inline function lineStyle(color:FlxColor, thickness:Float):LineStyle
	{
		strokeStyle.color = color;
		strokeStyle.thickness = thickness;
		return strokeStyle;
	}
}
