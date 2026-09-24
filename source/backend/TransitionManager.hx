package backend;

import flixel.FlxSubState;

class TransitionManager
{
	public static var finishCallback:Void->Void;
	static var lastWasScripted:Bool = false;

	public static function create(duration:Float, isTransIn:Bool):FlxSubState
	{
		#if HSCRIPT_ALLOWED
		var scripted:FlxSubState = ScriptableSubstate.tryCreate('TransitionSubstate', null, [duration, isTransIn]);
		if (scripted != null) {
			lastWasScripted = true;
			return scripted;
		}
		#end

		lastWasScripted = false;
		return new CustomFadeTransition(duration, isTransIn);
	}

	public static function setFinishCallback(callback:Void->Void):Void
	{
		finishCallback = callback;
		if (!lastWasScripted)
			CustomFadeTransition.finishCallback = callback;
	}

	public static function finish():Void
		if (finishCallback != null)
			finishCallback();

	public static function cancelCurrentTransition():Void
	{
		CustomFadeTransition.cancelCurrentTransition();
	}
}
