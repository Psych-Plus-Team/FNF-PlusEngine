package states;

import flixel.FlxObject;
import flixel.util.FlxSort;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
#if flash
import flash.display.GradientType;
import flash.geom.Matrix;
#end
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxTypedSpriteGroup;
import flixel.group.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxTimer;

#if ACHIEVEMENTS_ALLOWED
class AchievementsMenuState extends MusicBeatState
{
	public var curSelected:Int = 0;

	public var options:Array<Dynamic> = [];
	public var grpOptions:FlxSpriteGroup;
	public var nameText:FlxText;
	public var descText:FlxText;
	public var progressTxt:FlxText;
	public var progressBar:FlxSprite;
	
	public var totalText:FlxText;
	public var hintText:FlxText;

	public var canMove:Bool = true;
	public var particlesActive:Bool = true;
	public var barTween:FlxTween = null;

	var camFollow:FlxObject;
	var background:FlxSprite;
	var particles:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();
	var selectionGlow:FlxSprite;
	var lockedOverlay:FlxSprite;
	var unlockEffect:FlxSprite;

	var MAX_PER_ROW:Int = 4;
	var goingBack:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Achievements Menu", null);
		#end

		for (achievement => data in Achievements.achievements)
		{
			var unlocked:Bool = Achievements.isUnlocked(achievement);
			if(data.hidden != true || unlocked)
				options.push(makeAchievement(achievement, data, unlocked, data.mod));
		}

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		background = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		background.color = 0xFF1a1a2e;
		background.antialiasing = ClientPrefs.data.antialiasing;
		background.setGraphicSize(Std.int(FlxG.width * 1.2), Std.int(FlxG.height * 1.2));
		background.updateHitbox();
		background.screenCenter();
		background.scrollFactor.set();
		background.alpha = 0.8;
		add(background);

		particles = new FlxTypedSpriteGroup<FlxSprite>();
		add(particles);
		createParticles();

		selectionGlow = new FlxSprite();
		selectionGlow.makeGraphic(150, 150, 0x00000000);
		selectionGlow.loadGraphic(Paths.image('achievements/glowCircle'));
		selectionGlow.blend = ADD;
		selectionGlow.alpha = 0.7;
		selectionGlow.scrollFactor.set(0, 0);
		selectionGlow.visible = false;
		add(selectionGlow);

		grpOptions = new FlxSpriteGroup();
		grpOptions.scrollFactor.x = 0;

		options.sort(sortByID);
		for (option in options)
		{
			var hasAntialias:Bool = ClientPrefs.data.antialiasing;
			var graphic = null;
			var isPixel = false;
			
			if(option.unlocked)
			{
				#if MODS_ALLOWED Mods.currentModDirectory = option.mod; #end
				var image:String = 'achievements/' + option.name;
				if(Paths.fileExists('images/$image-pixel.png', IMAGE))
				{
					graphic = Paths.image('$image-pixel');
					hasAntialias = false;
					isPixel = true;
				}
				else graphic = Paths.image(image);

				if(graphic == null) graphic = Paths.image('unknownMod');
			}
			else graphic = Paths.image('achievements/lockedachievement');

			var spr:FlxSprite = new FlxSprite(0, Math.floor(grpOptions.members.length / MAX_PER_ROW) * 180).loadGraphic(graphic);
			spr.scrollFactor.x = 0;
			spr.screenCenter(X);
			spr.x += 180 * ((grpOptions.members.length % MAX_PER_ROW) - MAX_PER_ROW/2) + spr.width / 2 + 15;
			spr.ID = grpOptions.members.length;
			spr.antialiasing = hasAntialias;
			
			if(option.unlocked)
			{
				var frame:FlxSprite = new FlxSprite(spr.x - 5, spr.y - 5);
				frame.makeGraphic(Std.int(spr.width + 10), Std.int(spr.height + 10), 0x00000000);
				frame.drawFrame();
				var gfx:FlxGraphic = frame.graphic;
				var r = 2;
				for(i in 0...2)
				{
					var col = isPixel ? 0xFFCCCCCC : 0xFFF1C40F;
					gfx.bitmap.fillRect(new openfl.geom.Rectangle(i, i, spr.width + 10 - i*2, spr.height + 10 - i*2), col);
				}
				frame.antialiasing = hasAntialias;
				frame.scrollFactor.x = 0;
				frame.alpha = 0.8;
				grpOptions.add(frame);
			}
			
			grpOptions.add(spr);
		}
		#if MODS_ALLOWED Mods.loadTopMod(); #end

		var box:FlxSprite = new FlxSprite(0, -30).makeGraphic(1, 1, 0xFF000000);
		box.scale.set(grpOptions.width + 100, grpOptions.height + 100);
		box.updateHitbox();
		box.alpha = 0.4;
		box.scrollFactor.x = 0;
		box.screenCenter(X);
		
		var gradient:FlxSprite = new FlxSprite(box.x, box.y);
		gradient.makeGraphic(Std.int(box.width), Std.int(box.height), 0x00000000);

		var matrix = new openfl.geom.Matrix();
		matrix.createGradientBox(box.width, box.height, Math.PI/2, 0, 0);

		#if flash
		var gfx:FlxGraphic = gradient.graphic;
		gfx.bitmap.lock();
		var shape = new flash.display.Shape();
		var g = shape.graphics;
		g.beginGradientFill(GradientType.LINEAR, [0x33000000, 0x66000000], [1, 1], [0, 255], matrix);
		g.drawRect(0, 0, box.width, box.height);
		g.endFill();
		gfx.bitmap.draw(shape);
		gfx.bitmap.unlock();
		#else
		var gfx:FlxGraphic = gradient.graphic;
		gfx.bitmap.fillRect(new openfl.geom.Rectangle(0, 0, box.width, box.height), 0x66000000);
		#end
		gradient.scrollFactor.x = 0;
		gradient.alpha = 0.6;
		
		add(box);
		add(gradient);
		add(grpOptions);

		var panelHeight:Int = 180;
		var box:FlxSprite = new FlxSprite(0, FlxG.height - panelHeight).makeGraphic(1, 1, 0xFF000000);
		box.scale.set(FlxG.width, panelHeight);
		box.updateHitbox();
		box.alpha = 0.7;
		box.scrollFactor.set();
		
		var panelGradient:FlxSprite = new FlxSprite(box.x, box.y);
		panelGradient.makeGraphic(FlxG.width, panelHeight, 0x00000000);

		var panelMatrix = new openfl.geom.Matrix();
		panelMatrix.createGradientBox(FlxG.width, panelHeight, 0, 0, 0);
		var panelGfx:FlxGraphic = panelGradient.graphic;
		#if flash
		panelGfx.bitmap.lock();
		var panelShape = new flash.display.Shape();
		var pg = panelShape.graphics;
		pg.beginGradientFill(GradientType.LINEAR, [0xAA1a1a2e, 0xDD1a1a2e], [1, 1], [0, 255], panelMatrix);
		pg.drawRect(0, 0, FlxG.width, panelHeight);
		pg.endFill();
		panelGfx.bitmap.draw(panelShape);
		panelGfx.bitmap.unlock();
		#else
		panelGfx.bitmap.fillRect(new openfl.geom.Rectangle(0, 0, FlxG.width, panelHeight), 0xDD1a1a2e);
		#end
		panelGradient.scrollFactor.set();
		
		add(box);
		add(panelGradient);
		
		var totalUnlocked:Int = 0;
		for (option in options) if (option.unlocked) totalUnlocked++;
		
		totalText = new FlxText(20, 20, 0, 
			Language.getPhrase('achievements_unlocked', 'Unlocked: $totalUnlocked/${options.length}'), 24);
		totalText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		totalText.scrollFactor.set();
		totalText.borderSize = 2;
		add(totalText);
		
		nameText = new FlxText(50, FlxG.height - panelHeight + 20, FlxG.width - 100, "", 36);
		nameText.setFormat(Paths.font("vcr.ttf"), 36, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		nameText.scrollFactor.set();
		nameText.borderSize = 3;

		descText = new FlxText(50, nameText.y + 48, FlxG.width - 100, "", 22);
		descText.setFormat(Paths.font("vcr.ttf"), 22, 0xFFCCCCCC, CENTER);
		descText.scrollFactor.set();

		progressBar = new FlxSprite(0, descText.y + 38);
		progressBar.makeGraphic(400, 20, 0xFF2C3E50);
		progressBar.screenCenter(X);
		progressBar.scrollFactor.set();
		var progressBarFill = new FlxSprite(progressBar.x, progressBar.y);
		progressBarFill.makeGraphic(1, 20, 0xFF1ABC9C);
		progressBarFill.scrollFactor.set();
		add(progressBar);
		add(progressBarFill);
		
		progressTxt = new FlxText(50, progressBar.y - 8, FlxG.width - 100, "", 28);
		progressTxt.setFormat(Paths.font("vcr.ttf"), 28, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		progressTxt.scrollFactor.set();
		progressTxt.borderSize = 2;

		var controlY = FlxG.height - 30;
		hintText = new FlxText(20, controlY, FlxG.width - 40, 
			Language.getPhrase('achievements_controls', 
				'[ARROWS]: Navigate  [C]: Reset Selected  [B]: Back'), 18);
		hintText.setFormat(Paths.font("vcr.ttf"), 18, 0xFF888888, CENTER);
		hintText.scrollFactor.set();
		add(hintText);

		add(progressTxt);
		add(descText);
		add(nameText);
		
		grpOptions.forEach(function(spr:FlxSprite) {
			spr.alpha = 0;
			spr.y += 20;
			FlxTween.tween(spr, {alpha: 0.6, y: spr.y - 20}, 0.5, {ease: FlxEase.cubeOut});
		});
		
		FlxTween.tween(background, {alpha: 1}, 1, {ease: FlxEase.quartInOut});
		
		changeSelection();

		addTouchPad('LEFT_FULL', 'B_C');

		super.create();
		
		FlxG.camera.follow(camFollow, null, 0.15);
		FlxG.camera.scroll.y = -FlxG.height;
		
		if (FlxG.sound.music != null && !FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		FlxG.sound.music.fadeIn(1, 0, 0.7);
	}

	override function closeSubState() {
		super.closeSubState();
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'B_C');
		particlesActive = true;
	}

	function createParticles()
	{
		for (i in 0...30)
		{
			var particle:FlxSprite = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			particle.makeGraphic(4, 4, 0xFFFFFFFF);
			particle.alpha = FlxG.random.float(0.1, 0.3);
			particle.velocity.set(FlxG.random.float(-5, 5), FlxG.random.float(-5, 5));
			particle.blend = ADD;
			particle.scrollFactor.set();
			particles.add(particle);
		}
	}

	function makeAchievement(achievement:String, data:Achievement, unlocked:Bool, mod:String = null)
	{
		return {
			name: achievement,
			displayName: unlocked ? Language.getPhrase('achievement_$achievement', data.name) : Language.getPhrase('achievement_locked', '???'),
			description: unlocked ? Language.getPhrase('description_$achievement', data.description) : 
				Language.getPhrase('achievement_hidden_desc', 'Unlock to reveal description'),
			curProgress: data.maxScore > 0 ? Achievements.getScore(achievement) : 0,
			maxProgress: data.maxScore > 0 ? data.maxScore : 0,
			decProgress: data.maxScore > 0 ? data.maxDecimals : 0,
			unlocked: unlocked,
			ID: data.ID,
			mod: mod
		};
	}

	public static function sortByID(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.ID, Obj2.ID);
	
	override function update(elapsed:Float) {
		super.update(elapsed);
		
		if (particlesActive)
		{
			particles.forEach(function(p:FlxSprite) {
				if (p.x < -10 || p.x > FlxG.width + 10) p.velocity.x *= -1;
				if (p.y < -10 || p.y > FlxG.height + 10) p.velocity.y *= -1;
				p.alpha = 0.1 + Math.sin(FlxG.game.ticks / 100 + p.ID) * 0.2;
			});
		}
		
		if(!goingBack && options.length > 1 && canMove)
		{
			var add:Int = 0;
			if (controls.UI_LEFT_P || (touchPad != null && touchPad.buttonLeft.justPressed)) add = -1;
			else if (controls.UI_RIGHT_P || (touchPad != null && touchPad.buttonRight.justPressed)) add = 1;

			if(add != 0)
			{
				var oldRow:Int = Math.floor(curSelected / MAX_PER_ROW);
				var rowSize:Int = Std.int(Math.min(MAX_PER_ROW, options.length - oldRow * MAX_PER_ROW));
				
				curSelected += add;
				var curRow:Int = Math.floor(curSelected / MAX_PER_ROW);
				if(curSelected >= options.length) curRow++;

				if(curRow != oldRow)
				{
					if(curRow < oldRow) curSelected += rowSize;
					else curSelected = curSelected -= rowSize;
				}
				changeSelection();
			}

			if(options.length > MAX_PER_ROW)
			{
				var add:Int = 0;
				if (controls.UI_UP_P || (touchPad != null && touchPad.buttonUp.justPressed)) add = -1;
				else if (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed)) add = 1;

				if(add != 0)
				{
					var diff:Int = curSelected - (Math.floor(curSelected / MAX_PER_ROW) * MAX_PER_ROW);
					curSelected += add * MAX_PER_ROW;
					if(curSelected < 0)
					{
						curSelected += Math.ceil(options.length / MAX_PER_ROW) * MAX_PER_ROW;
						if(curSelected >= options.length) curSelected -= MAX_PER_ROW;
					}
					if(curSelected >= options.length)
					{
						curSelected = diff;
					}

					changeSelection();
				}
			}
			
			if(MusicBeatState.getState().touchPad.buttonC.justPressed || controls.RESET && (options[curSelected].unlocked || options[curSelected].curProgress > 0))
			{
				canMove = false;
				particlesActive = false;
				removeTouchPad();
				openSubState(new ResetAchievementSubstate());
			}
		}

		if (controls.BACK || (touchPad != null && touchPad.buttonB.justPressed)) {
			goingBack = true;
			canMove = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.sound.music.fadeOut(0.5, 0);
			
			FlxTween.tween(grpOptions, {alpha: 0, y: grpOptions.y + 20}, 0.5, {ease: FlxEase.cubeIn});
			FlxTween.tween(nameText, {alpha: 0}, 0.5, {ease: FlxEase.cubeIn});
			FlxTween.tween(descText, {alpha: 0}, 0.5, {ease: FlxEase.cubeIn});
			FlxTween.tween(progressBar, {alpha: 0}, 0.5, {ease: FlxEase.cubeIn});
			FlxTween.tween(progressTxt, {alpha: 0}, 0.5, {ease: FlxEase.cubeIn});
			FlxTween.tween(hintText, {alpha: 0}, 0.5, {ease: FlxEase.cubeIn});
			FlxTween.tween(totalText, {alpha: 0}, 0.5, {ease: FlxEase.cubeIn});
			
			new FlxTimer().start(0.5, function(tmr:FlxTimer) {
				MusicBeatState.switchState(new MainMenuState());
			});
		}
	}

	public function changeSelection()
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		var hasProgress = options[curSelected].maxProgress > 0;
		nameText.text = options[curSelected].displayName;
		descText.text = options[curSelected].description;
		progressTxt.visible = hasProgress;

		if(options[curSelected].unlocked)
			nameText.color = 0xFFFFFFFF;
		else
			nameText.color = 0xFF888888;

		if(barTween != null) barTween.cancel();

		if(hasProgress)
		{
			var val1:Float = options[curSelected].curProgress;
			var val2:Float = options[curSelected].maxProgress;
			progressTxt.text = CoolUtil.floorDecimal(val1, options[curSelected].decProgress) + ' / ' + CoolUtil.floorDecimal(val2, options[curSelected].decProgress);

			var progressBarFill = members[members.indexOf(progressBar) + 1];
			if(progressBarFill != null && Std.isOfType(progressBarFill, FlxSprite))
			{
				var targetWidth = (val1 / val2) * 400;
				barTween = FlxTween.tween(progressBarFill, {"scale.x": targetWidth / 20}, 0.5, {
					ease: FlxEase.quartOut
				});
			}
			
			progressTxt.scale.set(1.1, 1.1);
			FlxTween.tween(progressTxt.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});
		}
		else
		{
			var progressBarFill = members[members.indexOf(progressBar) + 1];
			if(progressBarFill != null && Std.isOfType(progressBarFill, FlxSprite))
				progressBarFill.scale.x = 0;
		}

		var maxRows = Math.floor(grpOptions.members.length / MAX_PER_ROW);
		if(maxRows > 0)
		{
			var camY:Float = FlxG.height / 2 + (Math.floor(curSelected / MAX_PER_ROW) / maxRows) * Math.max(0, grpOptions.height - FlxG.height / 2 - 50) - 100;
			camFollow.setPosition(0, camY);
		}
		else camFollow.setPosition(0, grpOptions.members[curSelected].getGraphicMidpoint().y - 100);

		var selectedSpr = grpOptions.members[curSelected * 2];
		selectionGlow.visible = true;
		selectionGlow.setPosition(selectedSpr.x + selectedSpr.width/2 - selectionGlow.width/2, 
								 selectedSpr.y + selectedSpr.height/2 - selectionGlow.height/2);
		
		selectionGlow.scale.set(1, 1);
		FlxTween.cancelTweensOf(selectionGlow.scale);
		FlxTween.tween(selectionGlow.scale, {x: 1.1, y: 1.1}, 0.8, {ease: FlxEase.sineInOut, type: FlxTweenType.PINGPONG});

		grpOptions.forEach(function(spr:FlxSprite) {
			var isSelected = (spr.ID == curSelected * 2) || (spr.ID == curSelected * 2 + 1);
			
			if(isSelected) {
				spr.alpha = 1;
				spr.scale.set(1.05, 1.05);
				FlxTween.cancelTweensOf(spr);
				FlxTween.tween(spr.scale, {x: 1.1, y: 1.1}, 0.5, {ease: FlxEase.quartOut});
			} else {
				spr.alpha = 0.4;
				spr.scale.set(1, 1);
			}
		});
		
		nameText.scale.set(1.1, 1.1);
            FlxTween.tween(nameText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});
	}
}

class ResetAchievementSubstate extends MusicBeatSubstate
{
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;
	var bgBlur:FlxSprite;

	public function new()
	{
		controls.isInSubstate = true;

		super();

		bgBlur = new FlxSprite(-FlxG.width, -FlxG.height);
		bgBlur.makeGraphic(FlxG.width * 3, FlxG.height * 3, 0xFF000000);
		bgBlur.alpha = 0;
		bgBlur.scrollFactor.set();
		add(bgBlur);
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		
		FlxTween.tween(bg, {alpha: 0.7}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(bgBlur, {alpha: 0.3}, 0.4, {ease: FlxEase.quartInOut});

		var dialogBox:FlxSprite = new FlxSprite(0, 150).makeGraphic(FlxG.width - 200, 300, 0xFF000000);
		dialogBox.alpha = 0.9;
		dialogBox.screenCenter(X);
		dialogBox.scrollFactor.set();
		
		var shine:FlxSprite = new FlxSprite(dialogBox.x, dialogBox.y);
		shine.makeGraphic(Std.int(dialogBox.width), Std.int(dialogBox.height), 0x00000000);

		var shineMatrix = new openfl.geom.Matrix();
		shineMatrix.createGradientBox(dialogBox.width, dialogBox.height, Math.PI/4, 0, 0);
		var shineGfx:FlxGraphic = shine.graphic;
		#if flash
		shineGfx.bitmap.lock();
		var shineShape = new flash.display.Shape();
		var sg = shineShape.graphics;
		sg.beginGradientFill(GradientType.LINEAR, [0x00FFFFFF, 0x22FFFFFF, 0x00FFFFFF], [0, 0.5, 1], [0, 128, 255], shineMatrix);
		sg.drawRect(0, 0, dialogBox.width, dialogBox.height);
		sg.endFill();
		shineGfx.bitmap.draw(shineShape);
		shineGfx.bitmap.unlock();
		#else
		shineGfx.bitmap.fillRect(new openfl.geom.Rectangle(0, 0, dialogBox.width, dialogBox.height), 0x22FFFFFF);
		#end
		shine.scrollFactor.set();
		
		add(dialogBox);
		add(shine);

		var text:Alphabet = new Alphabet(0, 180, Language.getPhrase('reset_achievement_confirm', 'Reset Achievement?'), true);
		text.screenCenter(X);
		text.scrollFactor.set();
		add(text);
		
		var state:AchievementsMenuState = cast FlxG.state;
		var achievementName:String = state.options[state.curSelected].displayName;
		
		var text:FlxText = new FlxText(50, text.y + 90, FlxG.width - 100, 
			'"' + achievementName + '"', 32);
		text.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFF00, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		text.scrollFactor.set();
		text.borderSize = 2;
		add(text);
		
		var warningText:FlxText = new FlxText(50, text.y + 45, FlxG.width - 100, 
			Language.getPhrase('reset_achievement_warning', 'This will reset all progress for this achievement'), 20);
		warningText.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFF0000, CENTER);
		warningText.scrollFactor.set();
		warningText.alpha = 0.8;
		add(warningText);
		
		yesText = new Alphabet(0, text.y + 110, Language.getPhrase('yes_reset', 'Yes, Reset'), false);
		yesText.screenCenter(X);
		yesText.x -= 200;
		yesText.scrollFactor.set();
		for(letter in yesText.letters) letter.color = 0xFFFF0000;
		yesText.alpha = 0.7;
		add(yesText);
		
		noText = new Alphabet(0, text.y + 110, Language.getPhrase('no_cancel', 'No, Cancel'), false);
		noText.screenCenter(X);
		noText.x += 200;
		noText.scrollFactor.set();
		for(letter in noText.letters) letter.color = 0xFF00FF00;
		noText.alpha = 0.7;
		add(noText);
		
		updateOptions();

		var hint:FlxText = new FlxText(0, text.y + 170, FlxG.width, 
			Language.getPhrase('reset_controls', '[<->]: Select  [A]: Confirm  [B]: Cancel'), 18);
		hint.setFormat(Paths.font("vcr.ttf"), 18, 0xFF888888, CENTER);
		hint.scrollFactor.set();
		add(hint);

		addTouchPad('LEFT_RIGHT', 'A');
		
		dialogBox.y += 50;
		dialogBox.alpha = 0;
		FlxTween.tween(dialogBox, {y: dialogBox.y - 50, alpha: 0.9}, 0.5, {ease: FlxEase.backOut});
	}

	override function update(elapsed:Float)
	{
		if(controls.BACK)
		{
			close();
			controls.isInSubstate = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			var state:AchievementsMenuState = cast FlxG.state;
			state.canMove = true;
			state.particlesActive = true;
			return;
		}

		super.update(elapsed);

		if(controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			onYes = !onYes;
			updateOptions();
		}

		if(controls.ACCEPT)
		{
			if(onYes)
			{
				var state:AchievementsMenuState = cast FlxG.state;
				var option:Dynamic = state.options[state.curSelected];

				Achievements.variables.remove(option.name);
				Achievements.achievementsUnlocked.remove(option.name);
				option.unlocked = false;
				option.curProgress = 0;
				option.displayName = Language.getPhrase('achievement_locked', '???');
				option.description = Language.getPhrase('achievement_hidden_desc', 'Unlock to reveal description');
				
				if(option.maxProgress > 0) state.progressTxt.text = '0 / ' + option.maxProgress;
				
				var iconIndex = state.curSelected * 2 + 1;
				state.grpOptions.members[iconIndex].loadGraphic(Paths.image('achievements/lockedachievement'));
				state.grpOptions.members[iconIndex].antialiasing = ClientPrefs.data.antialiasing;
				
				if(state.grpOptions.members[state.curSelected * 2] != null)
					state.grpOptions.members[state.curSelected * 2].destroy();

				var progressBarFill = state.members[state.members.indexOf(state.progressBar) + 1];
				if(progressBarFill != null && Std.isOfType(progressBarFill, FlxSprite))
				{
					if(state.barTween != null) state.barTween.cancel();
					state.barTween = FlxTween.tween(progressBarFill, {"scale.x": 0}, 0.5, {ease: FlxEase.quadOut});
				}
				
				var totalUnlocked:Int = 0;
				for (opt in state.options) if (opt.unlocked) totalUnlocked++;
				state.totalText.text = Language.getPhrase('achievements_unlocked', 'Unlocked: $totalUnlocked/${state.options.length}');
				
				Achievements.save();
				FlxG.save.flush();

				FlxG.sound.play(Paths.sound('noise'), 0.7);
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			
			controls.isInSubstate = false;
			var state:AchievementsMenuState = cast FlxG.state;
			state.canMove = true;
			state.particlesActive = true;
			state.changeSelection();
			close();
			return;
		}
	}

	function updateOptions() {
		var scales:Array<Float> = [0.85, 1.15];
		var alphas:Array<Float> = [0.6, 1];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
}
#end