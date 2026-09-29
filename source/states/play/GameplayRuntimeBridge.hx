package states.play;

import debug.FPSCounter;

class GameplayRuntimeBridge
{
	public var counter(default, null):FPSCounter;

	public inline function new(counter:FPSCounter)
	{
		this.counter = counter;
	}

	public inline function sync(step:Int, beat:Int, section:Int, speed:Float, bpm:Float, health:Float, rating:String, combo:Int):Void
	{
	}
}

