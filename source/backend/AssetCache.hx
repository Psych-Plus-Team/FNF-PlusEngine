package backend;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flash.media.Sound;

@:access(openfl.display.BitmapData)
class AssetCache
{
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static var localTrackedAssets:Array<String> = [];
	public static var missingBitmapCache:Map<String, Bool> = [];

	public static function remember(key:String):Void
	{
		if (key != null)
			localTrackedAssets.push(key);
	}

	public static function resetLocalTracking():Void
	{
		localTrackedAssets = [];
		missingBitmapCache = [];
	}

	public static function cacheBitmap(cacheKey:String, bitmap:BitmapData, allowGPU:Bool):FlxGraphic
	{
		if (bitmap == null)
			return null;

		if (allowGPU)
			cacheBitmapOnGPU(bitmap);
		#if android
		else
		{
			bitmap = backend.TextureOptimizer.optimize(bitmap);
		}
		#end

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, cacheKey);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;
		currentTrackedAssets.set(cacheKey, graphic);
		remember(cacheKey);
		return graphic;
	}

	static function cacheBitmapOnGPU(bitmap:BitmapData):Void
	{
		if (!ClientPrefs.data.cacheOnGPU || bitmap == null || bitmap.image == null || FlxG.stage == null || FlxG.stage.context3D == null)
			return;

		try
		{
			bitmap.lock();
			bitmap.image.premultiplied = true;

			var texture = bitmap.getTexture(FlxG.stage.context3D);
			if (texture != null && bitmap.image != null)
				bitmap.disposeImage();
		}
		catch (e:Dynamic)
		{
			trace('GPU cache upload failed for bitmap: $e');
		}
	}

	public static function cacheSound(cacheKey:String, sound:Sound):Sound
	{
		if (sound != null)
			currentTrackedSounds.set(cacheKey, sound);
		remember(cacheKey);
		return currentTrackedSounds.get(cacheKey);
	}

	public static function destroyGraphic(graphic:FlxGraphic):Bool
	{
		if (graphic == null)
			return false;

		if (graphic.useCount > 0)
			return false;

		if (graphic.bitmap != null && graphic.bitmap.__texture != null)
		{
			try
			{
				graphic.bitmap.__texture.dispose();
				graphic.bitmap.__texture = null;
			}
			catch (e:Dynamic)
			{
				trace('GPU texture dispose failed: $e');
			}
		}
		FlxG.bitmap.remove(graphic);

		return true;
	}
}

