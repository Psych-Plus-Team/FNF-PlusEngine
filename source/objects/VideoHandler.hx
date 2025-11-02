package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.Lib;
import openfl.events.Event;
import openfl.display.BitmapData;
import sys.FileSystem;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

/**
 * Wrapper de compatibilidad para VideoHandler con hxvlc
 * Emula la API original de hxcodec usando FlxVideoSprite de hxvlc internamente
 * 
 * NOTA: Las funcionalidades de skip (saltar video con teclas) han sido deshabilitadas
 * para prevenir crashes de "null object reference" que ocurrían al presionar espacio
 * en el Chart Editor. Los videos ahora deben reproducirse completamente.
 */
class VideoHandler extends FlxSprite
{
	public var canSkip:Bool = false; // DISABLED - Evitar crashes de null object reference
	public var canUseSound:Bool = true;
	public var canUseAutoResize:Bool = true;

	public var openingCallback:Void->Void = null;
	public var finishCallback:Void->Void = null;

	private var pauseMusic:Bool = false;
	private var videoSprite:FlxVideoSprite;
	private var isCurrentlyPlaying:Bool = false;
	private var allowDestroy:Bool = false; // Prevenir destrucción prematura
	private var isDestroyed:Bool = false; // Bandera para evitar múltiples destrucciones
	private var endReachedCalled:Bool = false; // Prevenir múltiples llamadas a onVLCEndReached
	private static var instanceCounter:Int = 0;
	private var instanceId:Int;
	private var videoStartTime:Float = 0;

	// Propiedades emuladas de VLC
	public var isPlaying(get, never):Bool;
	public var isDisplaying(get, never):Bool;
	public var videoWidth(get, never):Int;
	public var videoHeight(get, never):Int;
	public var volume(get, set):Float;

	private var _volume:Float = 1.0;

	public function new(IndexModifier:Int = 0):Void
	{
		super();
		
		instanceId = ++instanceCounter;
		
		// Hacer invisible este sprite base, el video se renderiza en videoSprite
		makeGraphic(1, 1, 0x00FFFFFF);
		alpha = 0;
		visible = false;
		
		// Marcar como persistente para evitar destrucción automática
		this.active = true;
		this.exists = true;
	}

	/**
	 * Plays a video.
	 *
	 * @param Path Example: `your/video/here.mp4`
	 * @param Loop Loop the video.
	 * @param PauseMusic Pause music until the video ends.
	 */
	public function playVideo(Path:String, Loop:Dynamic = false, PauseMusic:Dynamic = false):Void
	{
		trace('VideoHandler[${instanceId}]: Starting playVideo with path: $Path');
		
		// Reinicializar estado para nuevo video
		isDestroyed = false;
		endReachedCalled = false;
		allowDestroy = false;
		
		var loopBool:Bool = false;
		var pauseBool:Bool = false;
		
		// Convertir los parámetros a booleanos (compatibilidad con Lua)
		if (Std.isOfType(Loop, Bool)) {
			loopBool = Loop;
		} else if (Std.isOfType(Loop, Int)) {
			loopBool = Loop != 0;
		} else if (Std.isOfType(Loop, String)) {
			loopBool = Loop == "true" || Loop == "1";
		}
		
		if (Std.isOfType(PauseMusic, Bool)) {
			pauseBool = PauseMusic;
		} else if (Std.isOfType(PauseMusic, Int)) {
			pauseBool = PauseMusic != 0;
		} else if (Std.isOfType(PauseMusic, String)) {
			pauseBool = PauseMusic == "true" || PauseMusic == "1";
		}

		pauseMusic = pauseBool;

		if (FlxG.sound.music != null && pauseBool)
			FlxG.sound.music.pause();

		// Determinar la ruta del video
		var videoPath = Path;
		if (FileSystem.exists(Sys.getCwd() + Path))
			videoPath = Sys.getCwd() + Path;
		
		
		// Crear el FlxVideoSprite directamente
		if (videoSprite != null) {
			cleanupVideoSprite();
		}
		
		#if hxvlc
		videoSprite = new FlxVideoSprite(0, 0);
		
		// hxvlc usa load() y luego play()
		if (videoSprite.load(videoPath)) {
			// Video cargado exitosamente
			
			// Registrar tiempo de inicio
			videoStartTime = haxe.Timer.stamp();
			
			// Configurar callback de fin
			videoSprite.bitmap.onEndReached.add(onVLCEndReached);
			
			// Centrar el video en pantalla
			videoSprite.screenCenter();
			
			// Para hxvlc, el loop se maneja diferente
			// Si queremos loop, recreamos el callback para reiniciar
			if (loopBool) {
				// Remover el callback anterior y añadir uno que reinicie
				videoSprite.bitmap.onEndReached.removeAll();
				videoSprite.bitmap.onEndReached.add(function() {
					if (isCurrentlyPlaying && !isDestroyed) {
						videoSprite.stop();
						haxe.Timer.delay(function() {
							if (videoSprite != null && isCurrentlyPlaying && !isDestroyed) {
								videoSprite.play();
							}
						}, 50);
					}
				});
			}
			
			// Iniciar reproducción
			if (videoSprite.play()) {
				// Simular el callback de opening
				if (openingCallback != null) {
					haxe.Timer.delay(openingCallback, 100);
				}
				
				isCurrentlyPlaying = true;
				
				// Permitir destrucción después de un tiempo mínimo
				haxe.Timer.delay(function() {
					allowDestroy = true;
				}, 2000);
				
				// Configurar volumen inicial
				haxe.Timer.delay(updateVolumeInternal, 200);
			} else {
				trace('VideoHandler[${instanceId}]: Error starting playback: $videoPath');
				cleanupVideoSprite();
			}
		} else {
			trace('VideoHandler[${instanceId}]: Error loading video: $videoPath');
			videoSprite = null;
		}
		#else
		trace('VideoHandler[${instanceId}]: hxvlc not available');
		#end
	}

	private function onVLCEndReached():Void
	{
		// Evitar llamadas múltiples con bandera específica
		if (endReachedCalled || isDestroyed) {
			trace('VideoHandler[${instanceId}]: onVLCEndReached already called or destroyed, skipping');
			return;
		}
		
		// Marcar inmediatamente para evitar race conditions
		endReachedCalled = true;
		
		// Evitar llamadas múltiples con el flag de reproducción
		if (!isCurrentlyPlaying) {
			trace('VideoHandler[${instanceId}]: Not currently playing, skipping onVLCEndReached');
			return;
		}
		
		// Verificar que haya pasado suficiente tiempo desde que comenzó el video
		var currentTime = haxe.Timer.stamp();
		if (currentTime - videoStartTime < 1.0) { // Al menos 1 segundo
			trace('VideoHandler[${instanceId}]: Video ended too quickly, ignoring');
			isCurrentlyPlaying = true; // Restaurar si fue muy rápido
			endReachedCalled = false; // Permitir otra llamada
			return;
		}
		
		// Verificar que se permita la destrucción
		if (!allowDestroy) {
			trace('VideoHandler[${instanceId}]: Destruction not allowed yet, ignoring');
			isCurrentlyPlaying = true; // Restaurar si no se permite
			endReachedCalled = false; // Permitir otra llamada
			return;
		}
		
		trace('VideoHandler[${instanceId}]: Processing video end...');
		
		// Marcar como no reproduciendo ANTES de limpiar
		isCurrentlyPlaying = false;
		
		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.resume();

		cleanupVideoSprite();

		if (finishCallback != null)
			finishCallback();
	}

	private function cleanupVideoSprite():Void
	{
		trace('VideoHandler[${instanceId}]: cleanupVideoSprite called');
		
		// Evitar múltiples limpiezas
		if (isDestroyed) {
			trace('VideoHandler[${instanceId}]: Already destroyed, skipping cleanup');
			return;
		}
		
		// No permitir cleanup si no se ha autorizado
		if (!allowDestroy) {
			trace('VideoHandler[${instanceId}]: Destruction not allowed, skipping cleanup');
			return;
		}
		
		// Marcar como destruido inmediatamente para evitar re-entrada
		isDestroyed = true;
		
		if (videoSprite != null) {
			trace('VideoHandler[${instanceId}]: Cleaning up video sprite...');
			
			// IMPORTANTE: Detener el video primero
			try {
				videoSprite.stop();
				trace('VideoHandler[${instanceId}]: Video stopped');
			} catch (e:Dynamic) {
				trace('VideoHandler[${instanceId}]: Error stopping video: $e');
			}
			
			// Remover callbacks de forma segura
			#if hxvlc
			try {
				if (videoSprite.bitmap != null && videoSprite.bitmap.onEndReached != null) {
					videoSprite.bitmap.onEndReached.removeAll();
					trace('VideoHandler[${instanceId}]: Callbacks removed');
				}
			} catch (e:Dynamic) {
				trace('VideoHandler[${instanceId}]: Error removing callbacks: $e');
			}
			#end
			
			// Destruir el sprite de video
			try {
				videoSprite.destroy();
				videoSprite = null;
				trace('VideoHandler[${instanceId}]: Video sprite destroyed and set to null');
			} catch (e:Dynamic) {
				trace('VideoHandler[${instanceId}]: Error destroying video sprite: $e');
				videoSprite = null; // Asegurar que se establezca a null incluso si falla
			}
		} else {
			trace('VideoHandler[${instanceId}]: No video sprite to clean up');
		}
	}

	private function updateVolumeInternal():Void
	{
		// Verificar si ya fue destruido
		if (isDestroyed) {
			return;
		}
		
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null) {
			try {
				var finalVolume = #if FLX_SOUND_SYSTEM 
					Std.int(((FlxG.sound.muted || !canUseSound) ? 0 : 1) * (FlxG.sound.volume * _volume * 125))
				#else 
					Std.int(_volume * 125)
				#end;
				
				videoSprite.bitmap.volume = finalVolume;
			} catch (e:Dynamic) {
				trace('VideoHandler[${instanceId}]: Error updating volume: $e');
			}
		}
		#end
	}

	// Métodos de control de reproducción
	public function pause():Void 
	{
		#if hxvlc
		if (videoSprite != null && !isDestroyed) {
			videoSprite.pause();
		}
		#end
	}

	public function resume():Void 
	{
		#if hxvlc
		if (videoSprite != null && !isDestroyed) {
			videoSprite.resume();
		}
		#end
	}

	public function stop():Void 
	{
		#if hxvlc
		if (videoSprite != null && !isDestroyed) {
			videoSprite.stop();
			if (!endReachedCalled) {
				haxe.Timer.delay(onVLCEndReached, 1);
			}
		}
		#end
	}

	// Getters para propiedades emuladas
	private function get_isPlaying():Bool 
	{
		var playing = false;
		#if hxvlc
		playing = isCurrentlyPlaying && videoSprite != null && !isDestroyed;
		#else
		playing = false;
		#end
		return playing;
	}

	private function get_isDisplaying():Bool 
	{
		var displaying = isPlaying && !isDestroyed;
		return displaying;
	}

	private function get_videoWidth():Int 
	{
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null && !isDestroyed) {
			try {
				return Std.int(videoSprite.bitmap.bitmapData.width);
			} catch (e:Dynamic) {
				trace('VideoHandler[${instanceId}]: Error getting video width: $e');
			}
		}
		#end
		return 0;
	}

	private function get_videoHeight():Int 
	{
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null && !isDestroyed) {
			try {
				return Std.int(videoSprite.bitmap.bitmapData.height);
			} catch (e:Dynamic) {
				trace('VideoHandler[${instanceId}]: Error getting video height: $e');
			}
		}
		#end
		return 0;
	}

	private function get_volume():Float 
	{
		return _volume;
	}

	private function set_volume(value:Float):Float 
	{
		_volume = value;
		updateVolumeInternal();
		return _volume;
	}

	// Métodos para emular VLC
	public function dispose():Void 
	{
		#if hxvlc
		if (videoSprite != null && !isDestroyed) {
			videoSprite.stop();
			if (!endReachedCalled) {
				haxe.Timer.delay(onVLCEndReached, 1);
			}
		}
		#end
	}

	public function finishVideo():Void 
	{
		#if hxvlc
		if (videoSprite != null && !isDestroyed) {
			videoSprite.stop();
			if (!endReachedCalled) {
				haxe.Timer.delay(onVLCEndReached, 1);
			}
		}
		#end
	}
	
	// Método para verificar si el VideoHandler es válido
	public function isValid():Bool 
	{
		var valid = videoSprite != null && !allowDestroy && !isDestroyed;
		return valid;
	}

	// Propiedad bitmapData para compatibilidad con scripts
	public var bitmapData(get, never):openfl.display.BitmapData;
	private function get_bitmapData():openfl.display.BitmapData 
	{
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null && !isDestroyed) {
			try {
				return videoSprite.bitmap.bitmapData;
			} catch (e:Dynamic) {
				trace('VideoHandler[${instanceId}]: Error getting bitmap data: $e');
			}
		}
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
		trace('VideoHandler[${instanceId}]: destroy() called, allowDestroy=$allowDestroy, isDestroyed=$isDestroyed');
		
		// Bloquear destrucción si no está permitida o ya fue destruido
		if (!allowDestroy || isDestroyed) {
			trace('VideoHandler[${instanceId}]: Destroy blocked');
			return;
		}
		
		// Marcar como destruido inmediatamente para evitar re-entrada
		isDestroyed = true;

		cleanupVideoSprite();
		
		if (_fallbackBitmap != null) {
			_fallbackBitmap.dispose();
			_fallbackBitmap = null;
		}
		
		super.destroy();
		trace('VideoHandler[${instanceId}]: Destroy completed');
	}
	
	// Método de emergencia para forzar limpieza
	public function forceCleanup():Void 
	{
		trace('VideoHandler[${instanceId}]: Force cleanup requested');
		allowDestroy = true;
		isDestroyed = false; // Permitir una limpieza final
		cleanupVideoSprite();
	}
	
	// Método para permitir destrucción manual
	public function allowDestruction():Void 
	{
		allowDestroy = true;
	}
	
	// Sobrescribir update para auto-resize si está habilitado
	override public function update(elapsed:Float):Void 
	{
		// Verificar si ya fue destruido antes de actualizar
		if (isDestroyed) {
			return;
		}
		
		super.update(elapsed);
		
		// Auto-resize del video si está habilitado
		if (canUseAutoResize && isCurrentlyPlaying && videoSprite != null && videoSprite.bitmap != null)
		{
			try {
				var newWidth = Std.int(FlxG.width);
				var newHeight = Std.int(FlxG.height);
				
				if (newWidth > 0 && newHeight > 0) {
					videoSprite.setGraphicSize(newWidth, newHeight);
					videoSprite.updateHitbox();
					videoSprite.screenCenter();
				}
			} catch (e:Dynamic) {
				trace('VideoHandler[${instanceId}]: Error resizing video: $e');
			}
		}
		
		// Actualizar volumen
		updateVolumeInternal();
	}
}
