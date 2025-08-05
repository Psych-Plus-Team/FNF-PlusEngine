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
 * 
 * NOTA: La funcionalidad de skip ha sido deshabilitada para prevenir crashes de null object reference
 */
class MP4Handler extends FlxSprite
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;

	private var videoSprite:FlxVideoSprite;
	private var isCurrentlyPlaying:Bool = false;
	private var _volume:Float = 1.0;
	private var allowDestroy:Bool = false; // Prevenir destrucción prematura
	private var isDestroyed:Bool = false; // Bandera para evitar múltiples destrucciones
	private var endReachedCalled:Bool = false; // Prevenir múltiples llamadas
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
		trace('MP4Handler[${instanceId}]: Starting playVideo with path: $path');
		
		// Reinicializar estado para nuevo video
		isDestroyed = false;
		endReachedCalled = false;
		allowDestroy = false;
		
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
				
				// Permitir destrucción después de un tiempo mínimo
				haxe.Timer.delay(function() {
					allowDestroy = true;
				}, 2000);
				
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
		// Evitar llamadas múltiples con bandera específica
		if (endReachedCalled || isDestroyed) {
			trace('MP4Handler[${instanceId}]: onVideoFinished already called or destroyed, skipping');
			return;
		}
		
		// Marcar inmediatamente para evitar race conditions
		endReachedCalled = true;
		
		// Evitar llamadas múltiples con el flag de reproducción
		if (!isCurrentlyPlaying) {
			trace('MP4Handler[${instanceId}]: Not currently playing, skipping onVideoFinished');
			return;
		}
		
		// Verificar que se permita la destrucción
		if (!allowDestroy) {
			trace('MP4Handler[${instanceId}]: Destruction not allowed yet, ignoring');
			isCurrentlyPlaying = true; // Restaurar
			endReachedCalled = false; // Permitir otra llamada
			return;
		}
		
		trace('MP4Handler[${instanceId}]: Processing video end...');
		
		isCurrentlyPlaying = false;
		cleanupVideoSprite();

		if (finishCallback != null)
			finishCallback();
	}

	private function cleanupVideoSprite():Void
	{
		trace('MP4Handler[${instanceId}]: cleanupVideoSprite called from:');
		trace(haxe.CallStack.toString(haxe.CallStack.callStack()));
		
		// Evitar múltiples limpiezas
		if (isDestroyed) {
			trace('MP4Handler[${instanceId}]: Already destroyed, skipping cleanup');
			return;
		}
		
		// No permitir cleanup si no se ha autorizado
		if (!allowDestroy) {
			trace('MP4Handler[${instanceId}]: Destruction not allowed, skipping cleanup');
			return;
		}
		
		// Marcar como destruido inmediatamente para evitar re-entrada
		isDestroyed = true;
		
		if (videoSprite != null) {
			trace('MP4Handler[${instanceId}]: Cleaning up video sprite...');
			
			// Remover callbacks de forma segura
			#if hxvlc
			try {
				if (videoSprite.bitmap != null && videoSprite.bitmap.onEndReached != null) {
					videoSprite.bitmap.onEndReached.removeAll();
				}
			} catch (e:Dynamic) {
				trace('MP4Handler[${instanceId}]: Error removing callbacks: $e');
			}
			#end
			
			// Solo remover del state si está realmente añadido
			// (el MP4Handler no añade automáticamente, pero podría añadirse manualmente)
			try {
				if (FlxG.state != null && FlxG.state.members != null && FlxG.state.members.contains(videoSprite)) {
					FlxG.state.remove(videoSprite);
					trace('MP4Handler[${instanceId}]: Removed videoSprite from state');
				}
				
				videoSprite.destroy();
				videoSprite = null;
				trace('MP4Handler[${instanceId}]: Video sprite destroyed and set to null');
			} catch (e:Dynamic) {
				trace('MP4Handler[${instanceId}]: Error destroying video sprite: $e');
				videoSprite = null; // Asegurar que se establezca a null incluso si falla
			}
		} else {
			trace('MP4Handler[${instanceId}]: No video sprite to clean up');
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
					Std.int((FlxG.sound.muted ? 0 : 1) * (FlxG.sound.volume * _volume * 125))
				#else 
					Std.int(_volume * 125)
				#end;
				
				videoSprite.bitmap.volume = finalVolume;
			} catch (e:Dynamic) {
				trace('MP4Handler[${instanceId}]: Error updating volume: $e');
			}
		}
		#end
	}

	public function finishVideo():Void 
	{
		#if hxvlc
		if (videoSprite != null && !isDestroyed) {
			trace('MP4Handler[${instanceId}]: Finishing video...');
			videoSprite.stop();
			if (!endReachedCalled) {
				haxe.Timer.delay(onVideoFinished, 1);
			}
		}
		#end
	}

	public function pause():Void 
	{
		#if hxvlc
		if (videoSprite != null && !isDestroyed) {
			trace('MP4Handler[${instanceId}]: Pausing video...');
			videoSprite.pause();
		} else {
			trace('MP4Handler[${instanceId}]: Cannot pause - videoSprite is null or destroyed');
		}
		#else
		trace('MP4Handler[${instanceId}]: Cannot pause - hxvlc not available');
		#end
	}

	public function resume():Void 
	{
		#if hxvlc
		if (videoSprite != null && !isDestroyed) {
			trace('MP4Handler[${instanceId}]: Resuming video...');
			videoSprite.resume();
		} else {
			trace('MP4Handler[${instanceId}]: Cannot resume - videoSprite is null or destroyed');
		}
		#else
		trace('MP4Handler[${instanceId}]: Cannot resume - hxvlc not available');
		#end
	}

	// Getters para propiedades emuladas
	private function get_isPlaying():Bool 
	{
		#if hxvlc
		return isCurrentlyPlaying && videoSprite != null && !isDestroyed;
		#else
		return false;
		#end
	}

	private function get_videoWidth():Int 
	{
		#if hxvlc
		if (videoSprite != null && videoSprite.bitmap != null && !isDestroyed) {
			try {
				return Std.int(videoSprite.bitmap.bitmapData.width);
			} catch (e:Dynamic) {
				trace('MP4Handler[${instanceId}]: Error getting video width: $e');
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
				trace('MP4Handler[${instanceId}]: Error getting video height: $e');
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
		_volume = value + 0.4; // Emular el comportamiento original
		updateVolumeInternal();
		return _volume;
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
				trace('MP4Handler[${instanceId}]: Error getting bitmap data: $e');
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
		trace('MP4Handler[${instanceId}]: destroy() called, allowDestroy=$allowDestroy, isDestroyed=$isDestroyed');
		
		// Bloquear destrucción si no está permitida o ya fue destruido
		if (!allowDestroy || isDestroyed) {
			trace('MP4Handler[${instanceId}]: Destroy blocked');
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
		trace('MP4Handler[${instanceId}]: Destroy completed');
	}
	
	// Método de emergencia para forzar limpieza
	public function forceCleanup():Void 
	{
		trace('MP4Handler[${instanceId}]: Force cleanup requested');
		allowDestroy = true;
		isDestroyed = false; // Permitir una limpieza final
		cleanupVideoSprite();
	}
	
	// Método para permitir destrucción manual
	public function allowDestruction():Void 
	{
		allowDestroy = true;
	}
}
