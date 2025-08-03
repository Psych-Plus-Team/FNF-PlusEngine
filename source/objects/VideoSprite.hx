package objects;

import flixel.addons.display.FlxPieDial;
import psychlua.LuaUtils;
import flixel.FlxCamera;
import psychlua.LuaUtils;

#if hxcodec
import hxcodec.flixel.FlxVideoSprite;
#end

class VideoSprite extends FlxSpriteGroup {
	#if VIDEOS_ALLOWED
	public var finishCallback:Void->Void = null;
	public var onSkip:Void->Void = null;

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;
	public var videoSprite:FlxVideoSprite;
	public var skipSprite:FlxPieDial;
	public var cover:FlxSprite;
	public var canSkip(default, set):Bool = false;

	private var videoName:String;
	private var _volume:Float = 1.0;

	public var waiting:Bool = false;

	public function new(videoName:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Dynamic = false, camera:String = "other") {
		super();

		this.videoName = videoName;
		scrollFactor.set();

		// Configuración optimizada de cámara
		var cam:FlxCamera = (camera == null || camera.trim() == "") ? 
			FlxG.cameras.list[FlxG.cameras.list.length - 1] : 
			LuaUtils.cameraFromString(camera);
		cameras = [cam];

		waiting = isWaiting;
		if(!waiting)
		{
			cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
			add(cover);
		}

		// initialize sprites
		videoSprite = new FlxVideoSprite();
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(videoSprite);
		if(canSkip) this.canSkip = true;

		// callbacks - configurar ANTES de reproducir el video
		if(!shouldLoop) videoSprite.bitmap.onEndReached.add(finishVideo);

		videoSprite.bitmap.onTextureSetup.add(function()
		{
			/*
			#if hxcodec
			var wd:Int = videoSprite.bitmap.width;
			var hg:Int = videoSprite.bitmap.height;
			trace('Video Resolution: ${wd}x${hg}');
			videoSprite.scale.set(FlxG.width / wd, FlxG.height / hg);
			#end
			*/
			videoSprite.setGraphicSize(FlxG.width);
			videoSprite.updateHitbox();
			videoSprite.screenCenter();
			
			// Configurar volumen del video
			updateVideoVolume();
		});

		// start video - mover al final para evitar conflictos
		videoSprite.play(videoName, shouldLoop);
		
		// Configurar volumen inicial después de un pequeño delay
		haxe.Timer.delay(updateVideoVolume, 200);
	}

	var alreadyDestroyed:Bool = false;
	override function destroy()
	{
		if(alreadyDestroyed)
			return;

		trace('Video destroyed');
		if(cover != null)
		{
			remove(cover);
			cover.destroy();
		}
		
		finishCallback = null;
		onSkip = null;

		if(FlxG.state != null)
		{
			if(FlxG.state.members.contains(this))
				FlxG.state.remove(this);

			if(FlxG.state.subState != null && FlxG.state.subState.members.contains(this))
				FlxG.state.subState.remove(this);
		}
		super.destroy();
		alreadyDestroyed = true;
	}
	function finishVideo()
	{
		if (!alreadyDestroyed)
		{
			if(finishCallback != null)
				finishCallback();
			
			destroy();
		}
	}

	override function update(elapsed:Float)
	{
		if(canSkip)
		{
			if(Controls.instance.pressed('accept'))
			{
				holdingTime = Math.max(0, Math.min(_timeToSkip, holdingTime + elapsed));
			}
			else if (holdingTime > 0)
			{
				holdingTime = Math.max(0, FlxMath.lerp(holdingTime, -0.1, FlxMath.bound(elapsed * 3, 0, 1)));
			}
			updateSkipAlpha();

			if(holdingTime >= _timeToSkip)
			{
				if(onSkip != null) onSkip();
				finishCallback = null;
				videoSprite.bitmap.onEndReached.dispatch();
				trace('Skipped video');
				return;
			}
		}
		
		// Actualizar volumen continuamente por si cambia el volumen global
		updateVideoVolume();
		
		super.update(elapsed);
	}

	function set_canSkip(newValue:Bool)
	{
		canSkip = newValue;
		if(canSkip)
		{
			if(skipSprite == null)
			{
				skipSprite = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 40, true, 24);
				skipSprite.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
				skipSprite.x = FlxG.width - (skipSprite.width + 80);
				skipSprite.y = FlxG.height - (skipSprite.height + 72);
				skipSprite.amount = 0;
				add(skipSprite);
			}
		}
		else if(skipSprite != null)
		{
			remove(skipSprite);
			skipSprite.destroy();
			skipSprite = null;
		}
		return canSkip;
	}

	function updateSkipAlpha()
	{
		if(skipSprite == null) return;

		skipSprite.amount = Math.min(1, Math.max(0, (holdingTime / _timeToSkip) * 1.025));
		skipSprite.alpha = FlxMath.remapToRange(skipSprite.amount, 0.025, 1, 0, 1);
	}

	public function play() videoSprite?.resume();
	public function resume() videoSprite?.resume();
	public function pause() videoSprite?.pause();
	
	// Método para precargar el video sin reproducirlo inmediatamente
	public function preload():Void {
		if (videoSprite != null && videoSprite.bitmap != null) {
			// El video ya está configurado, solo aplicar ajustes finales
			videoSprite.setGraphicSize(FlxG.width);
			videoSprite.updateHitbox();
			videoSprite.screenCenter();
		}
	}
	
	function onGamePaused()
    {
        pause();
    }

    function onGameResumed()
    {
        resume();
    }
	
	function updateVideoVolume()
	{
		if (videoSprite != null && videoSprite.bitmap != null)
		{
			// Mantener volumen siempre en 100 (máximo) para cutscenes
			videoSprite.bitmap.volume = 100;
		}
	}
	#end
}