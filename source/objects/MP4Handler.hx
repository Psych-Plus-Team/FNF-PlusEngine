package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.events.Event;
import openfl.display.BitmapData;
import sys.FileSystem;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

/**
 * Wrapper de compatibilidad para MP4Handler con hxvlc
 * Emula la API original de hxcodec 2.5.1 usando FlxVideoSprite de hxvlc internamente
 */
class MP4Handler extends FlxSprite
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;

	private var videoSprite:FlxVideoSprite;
	private var isCurrentlyPlaying:Bool = false;
	private var _volume:Float = 1.0;
	private static var instanceCounter:Int = 0;
	private var instanceId:Int;

	// Propiedades emuladas
	public var isPlaying(get, never):Bool;
	public var videoWidth(get, never):Int;
	public var videoHeight(get, never):Int;
	public var volume(get, set):Float;

	public function new(width:Int = 320, height:Int = 240, autoScale:Bool = true):Void
	{
		super();
		
		instanceId = ++instanceCounter;
		
		// Hacer invisible este sprite base
		makeGraphic(1, 1, 0x00FFFFFF);
		alpha = 0;
		visible = false;
		
		// NO añadir este sprite base al state
		
	}

	public function playVideo(path:String, repeat:Bool = false, pauseMusic:Bool = false):Void
	{
		
		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.pause();

		// Determinar la ruta del video
		var videoPath = path;
		if (FileSystem.exists(Sys.getCwd() + path))
			videoPath = Sys.getCwd() + path;
		
		// Crear el FlxVideoSprite directamente
		if (videoSprite != null) {
			cleanupVideoSprite();
		}
		
		#if hxvlc
		videoSprite = new FlxVideoSprite(0, 0);
		
		// hxvlc usa load() y luego play()
		if (videoSprite.load(videoPath)) {
			// Video cargado exitosamente
			videoSprite.bitmap.onEndReached.add(onVideoFinished);
			
			// Para hxvlc, el loop se maneja diferente
			// Si queremos loop, recreamos el callback para reiniciar
			if (repeat) {
				// Remover el callback anterior y añadir uno que reinicie
				videoSprite.bitmap.onEndReached.removeAll();
				videoSprite.bitmap.onEndReached.add(function() {
					if (isCurrentlyPlaying) {
						videoSprite.stop();
						haxe.Timer.delay(function() {
							if (videoSprite != null && isCurrentlyPlaying) {
								videoSprite.play();
							}
						}, 50);
					}
				});
			}
			
			// NO añadir automáticamente al state - el script maneja la visualización
			// Los scripts copian el bitmapData a su propio sprite
			
			// Centrar el video en pantalla (por si se añade manualmente)
			videoSprite.screenCenter();
			
			// Iniciar reproducción
			if (videoSprite.play()) {
				// Simular readyCallback
				if (readyCallback != null) {
					haxe.Timer.delay(readyCallback, 100);
				}
				
				isCurrentlyPlaying = true;
				
				// Configurar volumen inicial
				haxe.Timer.delay(updateVolumeInternal, 200);
			} else {
				trace('MP4Handler: Error starting playback: $videoPath');
				cleanupVideoSprite();
			}
		} else {
			trace('MP4Handler: Error loading video: $videoPath');
			videoSprite = null;
		}
		#else
		trace('MP4Handler: hxvlc not available');
		#end
	}

	private function onVideoFinished():Void
	{
		isCurrentlyPlaying = false;
		cleanupVideoSprite();

		if (finishCallback != null)
			finishCallback();
	}

	private function cleanupVideoSprite():Void
	{
		if (videoSprite != null) {
			// Remover callbacks
			#if hxvlc
			if (videoSprite.bitmap != null && videoSprite.bitmap.onEndReached != null) {
				videoSprite.bitmap.onEndReached.removeAll();
			}
			#end
			
			// Solo remover del state si está realmente añadido
			// (el MP4Handler no añade automáticamente, pero podría añadirse manualmente)
			if (FlxG.state.members.contains(videoSprite)) {
				FlxG.state.remove(videoSprite);
				trace('MP4Handler[${instanceId}]: Removed videoSprite from state');
			}
			
			videoSprite.destroy();
			videoSprite = null;
			trace('MP4Handler[${instanceId}]: VideoSprite cleaned up');
		}
	}

	private function updateVolumeInternal():Void
	{
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null) {
			var finalVolume = #if FLX_SOUND_SYSTEM 
				Std.int((FlxG.sound.muted ? 0 : 1) * (FlxG.sound.volume * _volume * 125))
			#else 
				Std.int(_volume * 125)
			#end;
			
			videoSprite.bitmap.volume = finalVolume;
		}
		#end
	}

	public function finishVideo():Void 
	{
		#if hxvlc
		if (videoSprite != null) {
			videoSprite.stop();
			onVideoFinished();
		}
		#end
	}

	public function pause():Void 
	{
		#if hxvlc
		if (videoSprite != null) {
			videoSprite.pause();
		}
		#end
	}

	public function resume():Void 
	{
		#if hxvlc
		if (videoSprite != null) {
			videoSprite.resume();
		}
		#end
	}

	// Getters para propiedades emuladas
	private function get_isPlaying():Bool 
	{
		#if hxvlc
		return isCurrentlyPlaying && videoSprite != null;
		#else
		return false;
		#end
	}

	private function get_videoWidth():Int 
	{
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null)
			return Std.int(videoSprite.bitmap.bitmapData.width);
		#end
		return 0;
	}

	private function get_videoHeight():Int 
	{
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null)
			return Std.int(videoSprite.bitmap.bitmapData.height);
		#end
		return 0;
	}

	private function get_volume():Float 
	{
		return _volume;
	}

	private function set_volume(value:Float):Float 
	{
		_volume = value + 0.4; // Emular el comportamiento original
		updateVolumeInternal();
		return _volume;
	}

	// Propiedad bitmapData para compatibilidad con scripts
	public var bitmapData(get, never):openfl.display.BitmapData;
	private function get_bitmapData():openfl.display.BitmapData 
	{
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null)
			return videoSprite.bitmap.bitmapData;
		#end
		
		// Retornar un bitmap vacío en lugar de null para evitar errores
		if (_fallbackBitmap == null) {
			_fallbackBitmap = new openfl.display.BitmapData(1, 1, true, 0x00000000);
		}
		return _fallbackBitmap;
	}
	
	private var _fallbackBitmap:openfl.display.BitmapData;

	override function destroy():Void 
	{
		cleanupVideoSprite();
		
		if (_fallbackBitmap != null) {
			_fallbackBitmap.dispose();
			_fallbackBitmap = null;
		}
		
		super.destroy();
	}
}
