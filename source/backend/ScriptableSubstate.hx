package backend;

import flixel.FlxSubState;

#if HSCRIPT_ALLOWED
class ScriptableSubstate extends MusicBeatSubstate {
	public var substateName(default, null):String;

	public function new(?name:String) {
		substateName = name != null ? name : 'ScriptableSubstate';
		super();
	}

	public static inline function overridesEnabled():Bool
		return false;

	public static function hasScript(name:String):Bool
		return scripting.ScriptedStates.hasSubstate(name, hasLaunchedMod() ? scripting.ScriptedStates.ResolveScope.LAUNCHED : scripting.ScriptedStates.ResolveScope.ANY);

	public static function tryCreate(name:String, ?fallback:FlxSubState, ?args:Array<Dynamic>):FlxSubState {
		var substate:MusicBeatSubstate = scripting.ScriptedStates.loadSubstate(name, args, hasLaunchedMod() ? scripting.ScriptedStates.ResolveScope.LAUNCHED : scripting.ScriptedStates.ResolveScope.ANY);
		return substate != null ? substate : fallback;
	}

	static inline function hasLaunchedMod():Bool
		return Mods.launchedMod != null && Mods.launchedMod.length > 0;
}
#end
