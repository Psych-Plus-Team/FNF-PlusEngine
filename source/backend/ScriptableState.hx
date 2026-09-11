package backend;

import flixel.FlxState;

#if HSCRIPT_ALLOWED
class ScriptableState extends MusicBeatState {
	public var stateName(default, null):String;

	public function new(?name:String) {
		stateName = name != null ? name : 'ScriptableState';
		super(false, stateName);
	}

	public static inline function overridesEnabled():Bool
		return false;

	public static function hasScript(name:String):Bool
		return scripting.ScriptedStates.hasState(name, hasLaunchedMod() ? scripting.ScriptedStates.ResolveScope.LAUNCHED : scripting.ScriptedStates.ResolveScope.ANY);

	public static function tryCreate(name:String, ?fallback:FlxState, ?args:Array<Dynamic>):FlxState {
		var state:MusicBeatState = scripting.ScriptedStates.loadState(name, args, hasLaunchedMod() ? scripting.ScriptedStates.ResolveScope.LAUNCHED : scripting.ScriptedStates.ResolveScope.ANY);
		return state != null ? state : fallback;
	}

	public static function tryOverride(state:FlxState):Null<FlxState> {
		return null;
	}

	static inline function hasLaunchedMod():Bool
		return Mods.launchedMod != null && Mods.launchedMod.length > 0;
}
#end
