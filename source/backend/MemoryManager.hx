package backend;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;
import haxe.Timer;
#if sys
import sys.FileSystem;
#end

/**
 * Advanced memory management system, specially optimized for Android.
 * Allows assets to be released dynamically to reduce RAM usage.
 */
class MemoryManager
{
	private static inline final AGGRESSIVE_CLEANUP_COOLDOWN:Float = 2.0;
	private static inline final COLLECTION_COOLDOWN:Float = 3.0;
	#if android
	private static inline final MIN_ALLOCATION_GROWTH_BYTES:Float = 8 * 1024 * 1024;
	private static inline final MIN_RELEASED_ASSETS:Int = 4;
	private static inline final MIN_USEFUL_RECLAIM_BYTES:Float = 2 * 1024 * 1024;
	#else
	private static inline final MIN_ALLOCATION_GROWTH_BYTES:Float = 32 * 1024 * 1024;
	private static inline final MIN_RELEASED_ASSETS:Int = 12;
	private static inline final MIN_USEFUL_RECLAIM_BYTES:Float = 8 * 1024 * 1024;
	#end
	private static inline final MAX_COLLECTION_BACKOFF:Float = 2.5;
	private static inline final COLLECTION_BACKOFF_STEP:Float = 0.5;
	private static var lastAggressiveCleanupTime:Float = -9999;
	private static var lastCollectionTime:Float = -9999;
	private static var pendingRequestGCCount:Int = -1;

	public static var collectionPending(default, null):Bool = false;
	public static var pendingCollectionReason(default, null):String = '';
	public static var pendingReleasedAssets(default, null):Int = 0;
	public static var collectionBackoff(default, null):Float = 1.0;
	public static var lastCollectionEfficiency(default, null):Float = 0.0;
	public static var lastCollectionDecision(default, null):String = 'automatic GC only';

	#if android
	private static var isAndroid:Bool = true;
	#else
	private static var isAndroid:Bool = false;
	#end

	/**
	 * Removes a specific image from all caches (OpenFL, FlxG, and Paths tracking)
	 * @param path Path to the image without the file extension (e.g., "stages/philly/sky")
	 * @param removeInstantly If true, destroys the graphic immediately. If false, marks it for later destruction
	 */
	public static function removeImageFromMemory(path:String, removeInstantly:Bool = true):Void
	{
		if (path == null || path == '')
			return;

		// Add the extension if you don't have it
		var imagePath:String = path;
		if (!imagePath.endsWith('.png'))
			imagePath = 'images/$path.png';

		// Search OpenFL assets
		var foundPath:String = Paths.getPath(imagePath, IMAGE);

		// Clear the OpenFL Assets Cache
		if (Assets.cache.hasBitmapData(foundPath))
			Assets.cache.removeBitmapData(foundPath);

		// Search the FlxG cache
		var graphic:FlxGraphic = FlxG.bitmap.get(foundPath);
		if (graphic == null)
		{
			// Try the mods path
			#if MODS_ALLOWED
			foundPath = Paths.modsImages(path);
			graphic = FlxG.bitmap.get(foundPath);
			#end
		}

		if (graphic != null)
		{
			// Remove from Paths tracking
			if (Paths.currentTrackedAssets.exists(foundPath))
				Paths.currentTrackedAssets.remove(foundPath);

			Paths.forgetAsset(foundPath);

			// Mark for destruction
			graphic.persist = false;
			graphic.destroyOnNoUse = true;

			if (removeInstantly)
			{
				FlxG.bitmap.remove(graphic);
				graphic.destroy();
			}
		}
	}

	/**
	 * Removes multiple images from memory at once
	 * @param paths Array of image paths
	 * @param removeInstantly If true, destroys the graphics immediately
	 */
	public static function removeImagesFromMemory(paths:Array<String>, removeInstantly:Bool = true):Void
	{
		if (paths == null)
			return;

		for (path in paths)
			removeImageFromMemory(path, removeInstantly);
	}

	/**
	 * Removes a specific character from the character map and frees up its memory
	 * @param characterName Character name (e.g., "bf", "dad", "gf")
	 * @param removeInstantly If true, destroys the graphic immediately
	 */
	public static function removeCharacterFromMemory(characterName:String, removeInstantly:Bool = true):Void
	{
		if (PlayState.instance == null || characterName == null)
			return;

		var imageFile:String = null;
		var char:objects.Character = null;

		// Search on Boyfriend Map
		if (PlayState.instance.boyfriendMap.exists(characterName))
		{
			char = PlayState.instance.boyfriendMap.get(characterName);
			PlayState.instance.boyfriendGroup.remove(char, true);
			PlayState.instance.boyfriendMap.remove(characterName);
		}
		// Search on Dad Map
		else if (PlayState.instance.dadMap.exists(characterName))
		{
			char = PlayState.instance.dadMap.get(characterName);
			PlayState.instance.dadGroup.remove(char, true);
			PlayState.instance.dadMap.remove(characterName);
		}
		// Search on GF Map
		else if (PlayState.instance.gfMap.exists(characterName))
		{
			char = PlayState.instance.gfMap.get(characterName);
			PlayState.instance.gfGroup.remove(char, true);
			PlayState.instance.gfMap.remove(characterName);
		}

		// If we find the character, destroy it and release its image
		if (char != null)
		{
			imageFile = char.imageFile;
			char.kill();
			char.destroy();

			if (imageFile != null && imageFile != '')
				removeImageFromMemory(imageFile, removeInstantly);
		}
	}

	/**
	 * Clears unused UI assets (pixel UI vs. normal UI)
	 */
	public static function clearUnusedUI():Void
	{
		#if android
		if (PlayState.instance == null)
			return;

		if (!PlayState.isPixelStage)
		{
			// Clear the UI pixel if we are in normal stage
			Assets.cache.clear('assets/shared/images/pixelUI');
			removeImageFromMemory('pixelUI/arrows-pixels');
			removeImageFromMemory('pixelUI/arrows-pixels-ends');
			removeImageFromMemory('pixelUI/NOTE_assets');
		}
		else
		{
			// Clear the normal UI if we are in pixel stage
			removeImageFromMemory('NOTE_assets');
			removeImageFromMemory('noteSplashes');
		}
		#end
	}

	/**
	 * Remove unused preloaded characters
	 */
	public static function clearPreloadedCharacters():Void
	{
		#if android
		// A death character that is rarely used
		removeCharacterFromMemory('bf-dead', true);

		// Menu logo
		removeImageFromMemory('logoBumpin', true);
		#end
	}

	/**
	 * Aggressive memory cleanup for Android.
	 * Avoids forced GC during gameplay transitions because it causes visible frame spikes.
	 */
	public static function aggressiveCleanup():Void
	{
		#if android
		var now:Float = Timer.stamp();
		if (now - lastAggressiveCleanupTime < AGGRESSIVE_CLEANUP_COOLDOWN)
			return;
		lastAggressiveCleanupTime = now;

		// Clear Paths caches
		Paths.clearUnusedMemory();

		// Clear unused UI
		clearUnusedUI();

		// Clear Preloaded Characters
		clearPreloadedCharacters();
		#end
	}

	/**
	 * Requests a collection without running it in the caller's frame.
	 * The request is consumed at a safe state boundary by runPendingCollection().
	 */
	public static function requestCollection(reason:String = 'asset purge', releasedAssets:Int = 0):Void
	{
		#if cpp
		var gcCount:Int = MemoryUtil.getRootGCCollectionCount();
		if (collectionPending && gcCount >= 0 && pendingRequestGCCount >= 0 && gcCount > pendingRequestGCCount)
			pendingReleasedAssets = 0; // An automatic GC already consumed the older release hints.
		if (gcCount >= 0)
			pendingRequestGCCount = gcCount;
		#end

		collectionPending = true;
		pendingCollectionReason = (reason == null || reason.length == 0) ? 'unspecified' : reason;
		if (releasedAssets > 0)
			pendingReleasedAssets += releasedAssets;
	}

	/**
	 * Runs a requested collection only outside gameplay and only when enough
	 * heap growth has accumulated since the last collection or enough cached
	 * assets were released. Heap growth is pressure, not guaranteed garbage.
	 * Returns true when a collection ran.
	 */
	public static function runPendingCollection(force:Bool = false):Bool
	{
		#if cpp
		if (!collectionPending)
			return false;

		if (FlxG.state != null && Std.isOfType(FlxG.state, states.PlayState))
		{
			lastCollectionDecision = 'deferred during gameplay';
			return false;
		}

		if (MemoryUtil.supportsRootGCStats() && pendingRequestGCCount >= 0)
		{
			var currentGCCount:Int = MemoryUtil.getRootGCCollectionCount();
			if (currentGCCount > pendingRequestGCCount)
			{
				// The runtime already collected after the most recent request. Do not
				// force another pass based on cache-release hints it already observed.
				pendingReleasedAssets = 0;
				pendingRequestGCCount = currentGCCount;
			}
		}

		var now:Float = Timer.stamp();
		var effectiveCooldown:Float = COLLECTION_COOLDOWN * collectionBackoff;
		if (!force && now - lastCollectionTime < effectiveCooldown)
		{
			lastCollectionDecision = 'deferred by cooldown';
			return false;
		}

		var allocationGrowth:Float = Math.max(0, MemoryUtil.getGCCurrentMemory() - MemoryUtil.getGCMemory());
		var releasedAssets:Int = pendingReleasedAssets;
		var effectiveGrowthThreshold:Float = MIN_ALLOCATION_GROWTH_BYTES * collectionBackoff;
		if (!force && allocationGrowth < effectiveGrowthThreshold && releasedAssets < MIN_RELEASED_ASSETS)
		{
			collectionPending = false;
			lastCollectionDecision = 'skipped: ' + formatMegabytes(allocationGrowth) + ' MB growth, '
				+ releasedAssets + ' assets released';
			pendingCollectionReason = '';
			pendingReleasedAssets = 0;
			pendingRequestGCCount = -1;
			return false;
		}

		var reason:String = pendingCollectionReason;
		collectionPending = false;
		pendingCollectionReason = '';
		pendingReleasedAssets = 0;
		pendingRequestGCCount = -1;
		var heapBefore:Float = MemoryUtil.getGCCurrentMemory();
		MemoryUtil.collect(true);
		lastCollectionTime = Timer.stamp();
		var freedBytes:Float = MemoryUtil.lastCollectionFreedBytes;
		lastCollectionEfficiency = heapBefore > 0 ? freedBytes / heapBefore * 100.0 : 0.0;
		if (!force)
		{
			if (freedBytes < MIN_USEFUL_RECLAIM_BYTES)
				collectionBackoff = Math.min(MAX_COLLECTION_BACKOFF, collectionBackoff + COLLECTION_BACKOFF_STEP);
			else if (freedBytes >= MIN_USEFUL_RECLAIM_BYTES * 2)
				collectionBackoff = Math.max(1.0, collectionBackoff - COLLECTION_BACKOFF_STEP);
		}
		lastCollectionDecision = 'collected: ' + reason + ', ' + releasedAssets + ' assets ('
			+ formatMegabytes(freedBytes) + ' MB, '
			+ formatMilliseconds(MemoryUtil.lastCollectionDurationMs) + ' ms, '
			+ formatPercentage(lastCollectionEfficiency) + '%, backoff x' + collectionBackoff + ')';
		return true;
		#else
		collectionPending = false;
		pendingCollectionReason = '';
		pendingReleasedAssets = 0;
		pendingRequestGCCount = -1;
		lastCollectionDecision = 'unsupported target';
		return false;
		#end
	}

	private static inline function formatMegabytes(bytes:Float):String
	{
		return Std.string(Math.round(bytes / 1024 / 1024 * 10) / 10);
	}

	private static inline function formatMilliseconds(value:Float):String
	{
		return Std.string(Math.round(value * 100) / 100);
	}

	private static inline function formatPercentage(value:Float):String
	{
		return Std.string(Math.round(value * 10) / 10);
	}

	/**
	 * Retrieves the current memory usage in MB (only on systems that support it)
	 */
	public static function getMemoryUsage():Float
	{
		#if cpp
		return openfl.system.System.totalMemoryNumber / 1024 / 1024;
		#else
		return 0;
		#end
	}

	/**
	 * Reports memory usage in the console (useful for debugging)
	 */
	public static function reportMemoryUsage():Void
	{
		#if android
		var memoryMB:Float = getMemoryUsage();
		trace('MemoryManager: Current Memory Usage: ${Math.round(memoryMB)}MB');
		#end
	}

	/**
	 * Clears all loaded shaders (very useful on Android, where shaders consume a lot of RAM)
	 */
	public static function clearShaders():Void
	{
		#if android
		if (PlayState.instance == null)
			return;

		// Clear stage shaders
		if (PlayState.instance.camGame != null && PlayState.instance.camGame.filters != null)
			PlayState.instance.camGame.filters = [];

		if (PlayState.instance.camHUD != null && PlayState.instance.camHUD.filters != null)
			PlayState.instance.camHUD.filters = [];

		if (PlayState.instance.camOther != null && PlayState.instance.camOther.filters != null)
			PlayState.instance.camOther.filters = [];
		#end
	}

	/**
	 * Automatic memory monitoring for Android
	 * Runs an automatic cleanup if memory usage exceeds the specified threshold
	 * @param thresholdMB Threshold in MB (default 500MB)
	 */
	public static function autoMonitor(thresholdMB:Float = 500):Void
	{
		#if android
		var currentMemory:Float = getMemoryUsage();

		if (currentMemory > thresholdMB)
			aggressiveCleanup();
		#end
	}
}

