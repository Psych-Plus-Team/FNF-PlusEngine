package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;

import haxe.Json;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<FlxText>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;

	var player:MusicPlayer;
	
	var inDifficultySelect:Bool = false;
	var difficultySelector:DifficultySelector;
	var songsOffsetX:Float = 0;
	
	var blackOverlay:FlxSprite;
	var layerFree:FlxSprite;
	var cardArray:Array<FlxSprite> = [];
	var modTextArray:Array<FlxText> = [];
	var freeplayText:FlxText;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		final accept:String = (controls.mobileC) ? "A" : "ACCEPT";
		final reject:String = (controls.mobileC) ? "B" : "BACK";

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress " + accept + " to go to the Week Editor Menu.\nPress " + reject + " to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		for (i in 0...WeekData.weeksList.length)
		{
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		
		blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackOverlay.alpha = 0.1;
		add(blackOverlay);
		
		layerFree = new FlxSprite().loadGraphic(Paths.image('ui/layerfree'));
		layerFree.antialiasing = ClientPrefs.data.antialiasing;
		layerFree.setGraphicSize(FlxG.width, FlxG.height);
		layerFree.updateHitbox();
		layerFree.alpha = 0.5;
		add(layerFree);

		grpSongs = new FlxTypedGroup<FlxText>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:FlxText = new FlxText(90, 320, 400, songs[i].songName, 32);
			songText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			songText.borderSize = 2;
			songText.ID = i;
			grpSongs.add(songText);

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.scale.set(0.8, 0.8);
			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = false;
			icon.visible = icon.active = false;

			var card:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/card'));
			card.antialiasing = ClientPrefs.data.antialiasing;
			card.setGraphicSize(470, 110);
			card.updateHitbox();
			card.visible = false;
			cardArray.push(card);
			add(card);
		
			var modName:String = songs[i].folder;
			if (modName == null || modName == '')
				modName = "Friday Night Funkin";

			var modText:FlxText = new FlxText(0, 0, 400, modName, 20);
			modText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
			modText.alpha = 0.7;
			modText.visible = false;
			modTextArray.push(modText);
			add(modText);

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.68, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		scoreText.visible = false;

		add(scoreText);

		freeplayText = new FlxText(0, 0, 0, "FREEPLAY", 40);
		freeplayText.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER);
		freeplayText.borderSize = 0;
		freeplayText.updateHitbox();
		freeplayText.x = FlxG.width * 0.41;
		freeplayText.y = 15;
		add(freeplayText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		final space:String = (controls.mobileC) ? "X" : "SPACE";
		final control:String = (controls.mobileC) ? "C" : "CTRL";
		final reset:String = (controls.mobileC) ? "Y" : "RESET";
		
		var leText:String = Language.getPhrase("freeplay_tip", "Press {1} to listen to the Song / Press {2} to open the Gameplay Changers Menu / Press {3} to Reset your Score and Accuracy.", [space, control, reset]);
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(0, FlxG.height - 24, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
		
		player = new MusicPlayer(this);
		add(player);
		
		difficultySelector = new DifficultySelector();
		add(difficultySelector.cards);
		add(difficultySelector.items);
		
		changeSelection();
		updateTexts();

		addTouchPad('LEFT_FULL', 'A_B_C_X_Y_Z');
		super.create();
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_C_X_Y_Z');
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;

	var stopMusicPlay:Bool = false;
	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
			return;

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) //No decimals, add an empty space
			ratingSplit.push('');
		
		while(ratingSplit[1].length < 2) //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if((FlxG.keys.pressed.SHIFT || touchPad.buttonZ.pressed) && !player.playingMusic) shiftMult = 3;

		if (!player.playingMusic)
		{
			scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST:\n{1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
			positionHighscore();
			
			if (!inDifficultySelect)
			{
				// Modo normal: navegación de canciones
				if(songs.length > 1)
				{
					if(FlxG.keys.justPressed.HOME)
					{
						curSelected = 0;
						changeSelection();
						holdTime = 0;	
					}
					else if(FlxG.keys.justPressed.END)
					{
						curSelected = songs.length - 1;
						changeSelection();
						holdTime = 0;	
					}
					if (controls.UI_UP_P)
					{
						changeSelection(-shiftMult);
						holdTime = 0;
					}
					if (controls.UI_DOWN_P)
					{
						changeSelection(shiftMult);
						holdTime = 0;
					}

					if(controls.UI_DOWN || controls.UI_UP)
					{
						var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
						holdTime += elapsed;
						var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

						if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
							changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}

					if(FlxG.mouse.wheel != 0)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
						changeSelection(-shiftMult * FlxG.mouse.wheel, false);
					}
				}
			}
			else
			{
				if (controls.UI_UP_P)
				{
					changeDifficultySelection(-1);
				}
				if (controls.UI_DOWN_P)
				{
					changeDifficultySelection(1);
				}
			}
		}

		if (controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else if (inDifficultySelect)
			{
				exitDifficultySelect();
			}
			else 
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if((FlxG.keys.justPressed.CONTROL || touchPad.buttonC.justPressed) && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
			removeTouchPad();
		}
		else if(FlxG.keys.justPressed.SPACE || touchPad.buttonX.justPressed)
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if(loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
							vocals.pause();
						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch(e:Dynamic)
					{
						vocals = FlxDestroyUtil.destroy(vocals);
					}
					
					opponentVocals = new FlxSound();
					try
					{
						//trace('please work...');
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
							opponentVocals.pause();
							//trace('yaaay!!');
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch(e:Dynamic)
					{
						//trace('FUUUCK');
						opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				FlxG.sound.music.pause();
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
				player.pauseOrResume(true);
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(!player.playing);
			}
		}
		else if (controls.ACCEPT && !player.playingMusic)
		{
			if (!inDifficultySelect)
			{
				enterDifficultySelect();
			}
			else
			{
				persistentUpdate = false;
				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, difficultySelector.curSelected);

				try
				{
					Song.loadFromJson(poop, songLowercase);
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = difficultySelector.curSelected;

					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
				}
				catch(e:haxe.Exception)
				{
					trace('ERROR! ${e.message}');

					var errorStr:String = e.message;
					if(errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1); //Missing chart
					else errorStr += '\n\n' + e.stack;

					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));

					updateTexts(elapsed);
					super.update(elapsed);
					return;
				}

				@:privateAccess
				if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
				{
					trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
					Paths.freeGraphicsFromMemory();
				}
				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(new PlayState());
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				stopMusicPlay = true;

				destroyFreeplayVocals();
				#if (MODS_ALLOWED && DISCORD_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			}
		}
		else if((controls.RESET || touchPad.buttonY.justPressed) && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			removeTouchPad();
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}
	
	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function enterDifficultySelect()
	{
		inDifficultySelect = true;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		
		scoreText.visible = true;

		difficultySelector.loadDifficulties();
		difficultySelector.curSelected = curDifficulty;
		difficultySelector.lerpSelected = curDifficulty;

		FlxTween.tween(this, {songsOffsetX: -1000}, 0.3, {ease: FlxEase.expoOut});
		FlxTween.tween(blackOverlay, {alpha: 0.6}, 1.0, {ease: FlxEase.sineInOut});
		FlxTween.tween(difficultySelector, {enterProgress: 1}, 0.4, {ease: FlxEase.expoOut, startDelay: 0.1});
	}

	function exitDifficultySelect()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));

		scoreText.visible = false;

		FlxTween.tween(difficultySelector, {enterProgress: 0}, 0.25, {
			ease: FlxEase.expoIn,
			onComplete: function(twn:FlxTween) {
				inDifficultySelect = false;
				difficultySelector.items.clear();
				difficultySelector.cards.clear();
			}
		});
		
		FlxTween.tween(this, {songsOffsetX: 0}, 0.3, {ease: FlxEase.expoOut});
		FlxTween.tween(blackOverlay, {alpha: 0.1}, 1.0, {ease: FlxEase.sineInOut});
	}

	function changeDifficultySelection(change:Int = 0)
	{
		difficultySelector.changeSelection(change);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, difficultySelector.curSelected);
		intendedRating = Highscore.getRating(songs[curSelected].songName, difficultySelector.curSelected);
		#end
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = iconArray[num];
			item.alpha = 0.6;
			icon.alpha = 0.6;
			if (item.ID == curSelected)
			{
			item.alpha = 1;
			icon.alpha = 1;
			}
		}

		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 40;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
			cardArray[i].visible = false;
			modTextArray[i].visible = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:FlxText = grpSongs.members[i];
			item.visible = item.active = true;

			var difference:Float = item.ID - lerpSelected;
			var baseY:Float = 320;
			item.y = baseY + (difference * 120);

			var curveOffset:Float = Math.abs(difference) * Math.abs(difference) * 60;
			var itemOffset:Float = songsOffsetX;
			if (inDifficultySelect && item.ID == curSelected)
			{
				itemOffset = 0;
			}

			var baseX:Float = 90 - curveOffset + itemOffset;
			var icon:HealthIcon = iconArray[i];

			icon.visible = icon.active = true;
			icon.updateHitbox();
			icon.y = item.y - 20;

			var card:FlxSprite = cardArray[i];
			card.visible = true;
			card.x = baseX + 80;
			card.y = item.y - 10;
			card.color = songs[i].color;

			icon.x = card.x + 340;
			item.x = card.x + 50;

			var modText:FlxText = modTextArray[i];
			modText.visible = true;
			modText.x = item.x;
			modText.y = item.y + 60;
			modText.alpha = (i == curSelected) ? 0.8 : 0.5;

			_lastVisibles.push(i);
		}

		layerFree.color = intendedColor;

		if (inDifficultySelect || difficultySelector.enterProgress > 0)
		{
			difficultySelector.update(elapsed);
		}
	}		
	
	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}

class DifficultySelector
{
	public var items:FlxTypedGroup<FlxText>;
	public var cards:FlxTypedGroup<FlxSprite>;
	public var curSelected:Int = 0;
	public var lerpSelected:Float = 0;
	public var enterProgress:Float = 0;
	
	private var baseXOffset:Float = 300;
	private var slideDistance:Float = 500;
	private var selectionTween:FlxTween;
	
	public function new()
	{
		items = new FlxTypedGroup<FlxText>();
		cards = new FlxTypedGroup<FlxSprite>();
	}
	
	public function loadDifficulties():Void
	{
		items.clear();
		cards.clear();
		Difficulty.loadFromWeek();
		
		for (i in 0...Difficulty.list.length)
		{
			var diffText:FlxText = new FlxText(0, 0, 500, Difficulty.getString(i), 48);
			diffText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			diffText.borderSize = 2;
			diffText.ID = i;
			diffText.alpha = 0;
			items.add(diffText);
			
			var card:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/card'));
			card.setGraphicSize(470, 110);
			card.updateHitbox();
			card.alpha = 0;
			card.color = getDifficultyColor(Difficulty.getString(i));
			cards.add(card);
		}
	}
	
	private function getDifficultyColor(diffName:String):Int
	{
		var lowerName = diffName.toLowerCase();
		
		if (lowerName == 'easy')
			return 0x40C057;
		else if (lowerName == 'normal')
			return 0xFFD43B;
		else if (lowerName == 'hard')
			return 0xFF6B6B;
		else
		{
			var pastelColors:Array<Int> = [
				0xA78BFA,
				0xFBB6CE,
				0x99E9F2,
				0xB8E994,
				0xFFD8A8,
				0xE0BBE4
			];
			var hash = 0;
			for (i in 0...diffName.length)
				hash = hash * 31 + diffName.charCodeAt(i);
			var index = (hash < 0 ? -hash : hash) % pastelColors.length;
			return pastelColors[index];
		}
	}
	
	public function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, Difficulty.list.length - 1);
		
		if (selectionTween != null) selectionTween.cancel();
		
		selectionTween = FlxTween.tween(this, {lerpSelected: curSelected}, 0.25, {
			ease: FlxEase.expoOut,
			onComplete: function(twn:FlxTween) {
				selectionTween = null;
			}
		});
	}
	
	public function update(elapsed:Float):Void
	{
		for (i in 0...items.members.length)
		{
			var item:FlxText = items.members[i];
			var card:FlxSprite = cards.members[i];
			var difference:Float = item.ID - lerpSelected;
			item.y = (difference * 120) + (FlxG.height * 0.5) - 60;

			var baseX:Float = (FlxG.width * 0.5) - (card.width * 0.5) + baseXOffset;
			var targetX:Float = FlxMath.lerp(baseX + slideDistance, baseX, enterProgress);
			card.x = targetX;
			card.y = item.y - 30;
			
			item.x = card.x + (card.width * 0.5) - (item.width * 0.5);
			card.y = item.y - 30;
			
			if (i == curSelected)
			{
				item.alpha = 1.0 * enterProgress;
				card.alpha = 1.0 * enterProgress;
			}
			else
			{
				item.alpha = 0.6 * enterProgress;
				card.alpha = 0.6 * enterProgress;
			}
		}
	}
}
