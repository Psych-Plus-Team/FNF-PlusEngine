package stages;

import states.PlayState;
import states.stages.StageWeek1;

class Stage extends StageWeek1
{
	var fixed_GF_X:Float = 480;
	var fixed_GF_Y:Float = 280;

	override function createPost()
	{
		super.createPost();

		if (PlayState.SONG != null && PlayState.SONG.song == 'Tutorial' && dad != null)
			dad.setPosition(fixed_GF_X, fixed_GF_Y);
	}
}
