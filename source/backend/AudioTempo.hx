package backend;

import flixel.sound.FlxSound;

/** Bridges FlxSound to Lime's native pitch-independent tempo control. */
class AudioTempo
{
	public static function apply(sound:FlxSound, rate:Float, preservePitch:Bool):Void
	{
		if (sound == null) return;

		#if FLX_PITCH
		sound.pitch = preservePitch ? 1 : rate;
		#end

		#if (lime && !html5 && !flash)
		@:privateAccess
		if (sound._channel != null && sound._channel.__audioSource != null)
			sound._channel.__audioSource.tempo = preservePitch ? rate : 1;
		#end
	}
}
