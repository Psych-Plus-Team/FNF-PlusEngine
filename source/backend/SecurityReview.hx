package backend;

import flixel.FlxSubState;

class SecurityReview
{
	public static function getPendingMods():Array<String>
	{
		#if MODS_ALLOWED
		return ModSecurity.getPendingMods();
		#else
		return [];
		#end
	}

	public static function createPrompt(pending:Array<String>):FlxSubState
	{
		#if MODS_ALLOWED
		return new substates.ModSecuritySubstate(pending);
		#else
		return null;
		#end
	}
}
