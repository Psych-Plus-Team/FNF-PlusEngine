package modchart.standalone.adapters.fpsplus;

import flixel.FlxCamera;
import flixel.FlxSprite;
import modchart.standalone.IAdapter;
import note.Note;

class Fpsplus implements IAdapter {
	private var __fCrochet:Float = 0;

	public function new() {}

	public function onModchartingInitialization() {
		__fCrochet = Conductor.crochet;
	}

	public function isTapNote(sprite:FlxSprite) {
		return sprite is Note;
	}

	// Song related
	public function getSongPosition():Float {
		return Conductor.songPosition;
	}

	@:privateAccess public function getCurrentBeat():Float {
		return Conductor.songPosition / Conductor.crochet;
	}

	public function getStaticCrochet():Float {
		return __fCrochet;
	}

	public function getBeatFromStep(step:Float):Float {
		return step * 4;
	}

	public function arrowHit(arrow:FlxSprite) {
		if (arrow is Note) {
			final note:Note = cast arrow;
			return note.wasGoodHit;
		}
		return false;
	}

	public function isHoldEnd(arrow:FlxSprite) {
		if (arrow is Note) {
			final note:Note = cast arrow;
			return note.isSustainEnd;
		}
		return false;
	}

	public function getLaneFromArrow(arrow:FlxSprite) {
		if (arrow is Note) {
			final note:Note = cast arrow;
			return note.noteData;
		}

		return arrow.ID;
	}

    public function getPlayerFromArrow(arrow:FlxSprite) {
        if (arrow is Note) {
            final castedNote:Note = cast arrow;
            return castedNote.mustPress ? 1 : 0;
        }

        return PlayState.instance.playerStrums.members.contains(arrow) ? 1 : 0;
    }

	public function getHoldParentTime(arrow:FlxSprite) {
		final note:Note = cast arrow;
		return note.strumTime;
	}

	// im so fucking sorry for those conditionals
	public function getKeyCount(?player:Int = 0):Int {
		return 4;
	}

	public function getPlayerCount():Int {
		return 2;
	}

	public function getTimeFromArrow(arrow:FlxSprite) {
		if (arrow is Note) {
			final note:Note = cast arrow;
			return note.strumTime;
		}

		return 0;
	}

	public function getHoldSubdivisions():Int {
		return 3;
	}

	public function getDownscroll():Bool {
		return config.Config.downscroll;
	}

	public function getDefaultReceptorX(lane:Int, player:Int):Float {
        return __getStrumGroupFromPlayer(player).members[lane].x;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
        return __getStrumGroupFromPlayer(player).members[lane].y;
	}

	public function getArrowCamera():Array<FlxCamera>
		return [PlayState.instance.camHUD];

	public function getCurrentScrollSpeed():Float {
		return PlayState.SONG.speed * PlayState.instance.scrollSpeedMultiplier;
	}

	// 0 receptors
	// 1 tap arrows
	// 2 hold arrows
	// 3 lane attachments
	public function getArrowItems() {
		var pspr:Array<Array<Array<FlxSprite>>> = [[[], [], []], [[], [], []]];

		@:privateAccess
		final strums = [PlayState.instance.enemyStrums, PlayState.instance.playerStrums];
		for (i in 0...strums.length){
			strums[i].forEachAlive(strumNote -> {
				if (pspr[i] == null)
					pspr[i] = [];
	
				pspr[i][0].push(strumNote);
			});
		}
		PlayState.instance.notes.forEachAlive(strumNote -> {
			final player = Adapter.instance.getPlayerFromArrow(strumNote);
			if (pspr[player] == null)
				pspr[player] = [];

			pspr[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
		});

		return pspr;
	}

    private function __getStrumGroupFromPlayer(player:Int):flixel.group.FlxGroup.FlxTypedGroup<FlxSprite>
    {
        return player == 1 ? PlayState.instance.playerStrums : PlayState.instance.enemyStrums;
    }
}