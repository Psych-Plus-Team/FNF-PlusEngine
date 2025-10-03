package modchart.core;

import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import modchart.Modifier;
import modchart.core.macros.ModifiersMacro;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.Visuals;
import modchart.core.util.ModchartUtil;
import modchart.modifiers.*;
import modchart.modifiers.false_paradise.*;
import openfl.geom.Vector3D;

@:structInit
@:publicFields
class ModifierOutput {
	var pos:Vector3D;
	var visuals:Visuals;
}

@:allow(modchart.Modifier)
final class ModifierGroup {
	/**
	 * A `List` containing all compiled `Modifier` classes.
	 * 
	 * This list is generated at compile time using `ModifiersMacro.get()`.
	 * It provides a collection of all available modifiers for use in the system.
	 */
	public static final COMPILED_MODIFIERS = ModifiersMacro.get();

	/**
	 * A 2D array storing percentage values, indexed by hashed string keys.
	 * 
	 * **Usage Notes:**
	 * - Do not access `percents` directly, as all keys are hashed into 16-bit integers.
	 * - Use `getPercent(name, player)` to retrieve a value.
	 * - Use `setPercent(name, value, player)` to modify values safely.
	 * 
	 * **Hashing Mechanism:**
	 * - Keys are automatically converted to lowercase and hashed into a 16-bit integer.
	 * - This ensures efficient storage and retrieval while avoiding direct string key lookups.
	 */
	public var percents(default, never):PercentArray = new PercentArray();

	/**
	 * A `StringMap` that maps modifier names/identifiers to their corresponding `Modifier` class.
	 * **Note**: This is not actually used internally-
	 */
	public var modifiers(default, never):StringMap<Modifier> = new StringMap();

	/**
	 * The current `PlayField` instance.
	 * 
	 * When set, all stored modifiers are updated to reference the new `PlayField` instance.
	 */
	public var playfield(default, set):PlayField;

	public function set_playfield(newPlayfield:PlayField) {
		for (i in 0...__modifierCount) {
			@:privateAccess __sortedModifiers[i].pf = newPlayfield;
		}
		return playfield = newPlayfield;
	}

	@:noCompletion private var __modifierRegistrery:StringMap<Class<Modifier>> = new StringMap();

	@:noCompletion private var __sortedModifiers:Vector<Modifier> = new Vector<Modifier>(32);
	@:noCompletion private var __modifierCount:Int = 0;
	@:noCompletion private var __sortedIDs:Vector<String> = new Vector<String>(32);
	@:noCompletion private var __idCount:Int = 0;

	// @:noCompletion private var cache:ModifierCache = new ModifierCache();

	inline private function __loadModifiers() {
		for (cls in COMPILED_MODIFIERS) {
			var name = Type.getClassName(cls);
			name = name.substring(name.lastIndexOf('.') + 1, name.length);
			__modifierRegistrery.set(name.toLowerCase(), cast cls);
		}
	}

	public function new(playfield:PlayField) {
		this.playfield = playfield;

		__loadModifiers();
	}

	public inline function postRender() {
		// @:privateAccess cache.clear();
	}

	/**
	 * Computes the transformed position and visual properties of an arrow based on active modifiers.
	 * 
	 * @param pos The initial `Vector3D` position of the arrow.
	 * @param data The `ArrowData` containing arrow properties such as lane, player, and timing.
	 * @param posDiff (Optional) A positional offset applied to the arrow.
	 * @param allowVis (Optional) If `true`, visual modifications will be applied.
	 * @param allowPos (Optional) If `true`, positional transformations will be applied.
	 * @return A `ModifierOutput` structure containing the modified position and visuals.
	 * 
	 * **Processing Steps:**
	 * - Retrieves the current song position and beat.
	 * - Iterates through all active modifiers, applying transformations if conditions are met.
	 * - Adjusts the `z` position based on `Config.Z_SCALE` and projects the final position.
	 * - (Caching is currently disabled but could be re-enabled for optimization.)
	 */
	public inline function getPath(pos:Vector3D, data:ArrowData, ?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true):ModifierOutput {
		var visuals:Visuals = {};

		/*var cacheParams:CacheInstance = {
				lane: data.lane,
				player: data.player,
				pos: data.distance + posDiff,
				isArrow: data.isTapArrow,
				hitten: data.hitten
			};
			var possibleCache = @:privateAccess cache.load(cacheParams);
			if (possibleCache != null) {
				return possibleCache;
		}*/

		if (!allowVis && !allowPos)
			return {pos: pos, visuals: visuals};

		final songPos = Adapter.instance.getSongPosition();
		final beat = Adapter.instance.getCurrentBeat();

		final args:RenderParams = {
			songTime: songPos,
			curBeat: beat,
			hitTime: data.hitTime + posDiff,
			distance: data.distance + posDiff,
			lane: data.lane,
			player: data.player,
			isTapArrow: data.isTapArrow
		}

		for (i in 0...__modifierCount) {
			final mod = __sortedModifiers[i];

			if (!mod.shouldRun(args))
				continue;

			if (allowPos)
				pos = mod.render(pos, args);
			if (allowVis)
				visuals = mod.visuals(visuals, args);
		}
		pos.z *= 0.001 * Config.Z_SCALE;
		pos = ModchartUtil.project(pos);
		final output:ModifierOutput = {
			pos: pos,
			visuals: visuals
		};

		// cache.save(cacheParams, output);
		return output;
	}

	public inline function registerModifier(name:String, modifier:Class<Modifier>) {
		var lowerName = name.toLowerCase();
		if (__modifierRegistrery.get(lowerName) != null) {
			trace('There\'s already a modifier with name "$name" registered !');
			return;
		}
		__modifierRegistrery.set(lowerName, modifier);
	}

	public inline function addScriptedModifier(name:String, instance:Modifier)
		__addModifier(name, instance);

	public inline function addModifier(name:String) {
		var lowerName = name.toLowerCase();
		if (modifiers.exists(lowerName))
			return;

		var modifierClass:Null<Class<Modifier>> = __modifierRegistrery.get(lowerName);
		if (modifierClass == null) {
			trace('$name modifier was not found !');

			return;
		}
		var newModifier = Type.createInstance(modifierClass, [playfield]);
		__addModifier(lowerName, newModifier);
	}

	public inline function setPercent(name:String, value:Float, player:Int = -1) {
		var key = name.toLowerCase();

		var possiblePercs = percents.get(key);
		var generate = possiblePercs == null;
		var percs = generate ? __getPercentTemplate() : possiblePercs;

		if (player == -1)
			for (_ in 0...percs.length)
				percs[_] = value;
		else
			percs[player] = value;

		// if the percent list already was generated, we dont need to set it again
		if (generate)
			percents.set(key, percs);
	}

	public inline function getPercent(name:String, player:Int):Float {
		final percs = percents.get(name.toLowerCase());

		if (percs != null)
			return percs[player];
		return 0;
	}

	@:noCompletion
	inline private function __addModifier(name:String, modifier:Modifier) {
		modifiers.set(name, modifier);
		@:privateAccess modifier.pf = playfield;

		// update modifier identificators
		if (__idCount > (__sortedIDs.length - 1)) {
			final oldIDs = __sortedIDs.copy();
			__sortedIDs = new Vector<String>(oldIDs.length + 8);

			for (i in 0...oldIDs.length)
				__sortedIDs[i] = oldIDs[i];
		}
		__sortedIDs[__idCount++] = name;

		// update modifier list
		if (__modifierCount > (__sortedModifiers.length - 1)) {
			final oldMods = __sortedModifiers.copy();
			__sortedModifiers = new Vector<Modifier>(oldMods.length + 8);

			for (i in 0...oldMods.length)
				__sortedModifiers[i] = oldMods[i];
		}
		__sortedModifiers[__modifierCount++] = modifier;
	}

	@:noCompletion
	inline private function __getPercentTemplate():Vector<Float> {
		final vector = new Vector<Float>(Adapter.instance.getPlayerCount());
		for (i in 0...vector.length)
			vector[i] = 0;
		return vector;
	}
}

// for some reason, is laggier than generating new parths every frame
/*
	final class ModifierCache {
	public var outputs:ObjectMap<CacheInstance, ModifierOutput> = new ObjectMap();

		private inline function unpackA(packed:Int):Int {
			return packed & 0xFFFF;
		}

		private inline function unpackB(packed:Int):Int {
			return packed >>> 16;
	}
	public function new() {}

	private inline function save(params:CacheInstance, output:ModifierOutput) {
		outputs.set(params, output);
	}

	private inline function load(params:CacheInstance):Null<ModifierOutput> {
		return outputs.get(params);
	}

	private inline function clear() {
		outputs.clear();
	}
	}

	@:structInit
	final class CacheInstance {
	public var lane:Int;
	public var player:Int;

	public var pos:Float;
	public var isA:Bool;
	public var hit:Bool;

	public function new(lane:Int, player:Int, pos:Float, isArrow:Bool, hitten:Bool) {
		this.lane = lane;
		this.player = player;
		this.pos = pos;
		this.isA = isArrow;
		this.hit = hitten;
	}

	inline public function compare(shit:CacheInstance):Bool {
		return (shit.lane == lane && shit.player == player && shit.pos == pos && isA == shit.isA && hit == shit.hit);
	}
	}
 */
// basicly 2d vector with string hashing
// used to store modifier values
final class PercentArray {
	private var vector:Vector<Vector<Float>>;

	public function new() {
		vector = new Vector<Vector<Float>>(Std.int(Math.pow(2, 16))); // preallocate by max 16-bit integer
	}

	private var __lastHashedKey:Int = -1;
	private var __lastKey:String = '';

	// hash the key to a 16-bit integer
	@:noCompletion inline private function __hashKey(key:String):Int {
		if (key == __lastKey)
			return __lastHashedKey;

		var hash:Int = 0;
		for (i in 0...key.length) {
			// hash computation
			hash = ((hash << 5) - hash) + Std.int(key.charCodeAt(i));
		}
		__lastKey = key;
		return __lastHashedKey = (hash & 0xFFFF); // 16-bit hash
	}

	// hash handlers
	inline public function set(key:String, value:Vector<Float>):Void
		vector.set(__hashKey(key), value);

	inline public function get(key:String):Vector<Float>
		return vector.get(__hashKey(key));
}
