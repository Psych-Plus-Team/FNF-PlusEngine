package debug;

import flixel.FlxG;
import openfl.Lib;
import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.display.Graphics;
import openfl.display.Shape;
import haxe.Http;
import haxe.Json;
import states.MainMenuState;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	/**
		Peak memory usage tracking
	**/
	public var memoryPeak(default, null):Float = 0;

	/**
		Debug level for FPS counter (0: normal, 1: with background + debug info, 2: extended debug info)
	**/
	public var debugLevel:Int = 0;

	/**
		Mod author text that can be set from Lua scripts
	**/
	public var modAuthor:String = "";

	/**
		Charting info from PlayState (Step, Beat, Section)
	**/
	public var currentStep:Int = 0;
	public var currentBeat:Int = 0;
	public var currentSection:Int = 0;

	/**
		Debug info from PlayState (Speed, BPM, Health)
	**/
	public var songSpeed:Float = 1.0;
	public var currentBPM:Int = 0;
	public var playerHealth:Float = 1.0;
	
	/**
		Rating and Combo from PlayState
	**/
	public var lastRating:String = "None";
	public var comboCount:Int = 0;

	/**
		Background shape for debug mode
	**/
	private var bgShape:Shape;

	/**
		Last GitHub commit info
	**/
	private var lastCommit:String = "Loading...";
	private var commitTime:String = ""; // Hora del commit
	private var commitDate:String = ""; // Fecha del commit
	
	/**
		Script statistics from PlayState
	**/
	public var luaScriptsLoaded:Int = 0;
	public var luaScriptsFailed:Int = 0;
	public var hscriptsLoaded:Int = 0;
	public var hscriptsFailed:Int = 0;
	public var sscriptsErrors:Int = 0;

	/**
		Instancia singleton para acceso global
	**/
	public static var instance:FPSCounter;

	/**
		CPU and GPU usage tracking - ELIMINADO para optimización
	**/
	// Variables eliminadas para mejor rendimiento

	/**
		Note and sprite counters - ELIMINADO para optimización  
	**/
	// Variables eliminadas para mejor rendimiento

	/**
		Runtime tracking
	**/
	private var startTime:Float = 0.0;

	/**
		Cached values for minimal operations
	**/
	private var cachedCurrentState:String = "Unknown";
	private var lastCacheUpdateTime:Float = 0.0;
	
	/**
		Control de actualización de texto para reducir lag en modo debug
	**/
	private var lastTextUpdateTime:Float = 0.0;
	private var textUpdateInterval:Float = 0.5; // Actualizar texto estático cada 500ms
	private var cachedStaticText:String = ""; // Cache del texto estático (OS, commit, etc.)
	
	/**
		Frame timing para medición de delay
	**/
	private var lastFrameTime:Float = 0.0;
	private var frameTimeMs:Float = 0.0;
	private var frameTimesArray:Array<Float> = [];
	private var avgFrameTimeMs:Float = 0.0;

	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var lastFramerateUpdateTime:Float;
	@:noCompletion private var updateTime:Int;
	@:noCompletion private var framesCount:Int;
	@:noCompletion private var prevTime:Int;

	public var os:String = '';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		// Asignar singleton
		instance = this;

		#if officialBuild
		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';
		#end

		positionFPS(x, y);

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(Paths.font("aller.ttf"), 14, color);
		width = 350; // Ancho fijo para evitar reorganización
		height = 550; // Altura aumentada para acomodar toda la información
		multiline = true;
		text = "FPS: ";
		wordWrap = false; // Evitar que las palabras se corten
		autoSize = openfl.text.TextFieldAutoSize.NONE; // Desactivar auto-size para evitar saltos

		// Habilitar formato HTML para diferentes tamaños de texto
		#if !flash
		embedFonts = true; // Habilitar fuentes embebidas para usar aller.ttf
		#end

		times = [];
		lastFramerateUpdateTime = Timer.stamp();
		prevTime = Lib.getTimer();
		updateTime = prevTime + 500;
		
		// Inicializar medición de frame time
		lastFrameTime = Timer.stamp();
		frameTimesArray = [];

		// Crear el fondo para el modo debug
		bgShape = new Shape();
		
		// Agregar el fondo al stage después de que este TextField esté agregado
		// Lo haremos en updateBackground para asegurar que esté visible

		// Agregar listener para F2
		if (FlxG.stage != null) {
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		// Obtener información del último commit
		getLastCommit();

		// Obtener información de rendimiento
		startTime = haxe.Timer.stamp();
		lastCacheUpdateTime = startTime;
		
		// Inicializar cache mínimo
		cachedCurrentState = "Unknown";
	}

	// Función para interpolar entre dos colores ARGB
	function lerpColor(color1:Int, color2:Int, t:Float):Int {
		var a1 = (color1 >> 24) & 0xFF;
		var r1 = (color1 >> 16) & 0xFF;
		var g1 = (color1 >> 8) & 0xFF;
		var b1 = color1 & 0xFF;

		var a2 = (color2 >> 24) & 0xFF;
		var r2 = (color2 >> 16) & 0xFF;
		var g2 = (color2 >> 8) & 0xFF;
		var b2 = color2 & 0xFF;

		var a = Std.int(a1 + (a2 - a1) * t);
		var r = Std.int(r1 + (r2 - r1) * t);
		var g = Std.int(g1 + (g2 - g1) * t);
		var b = Std.int(b1 + (b2 - b1) * t);

		return (a << 24) | (r << 16) | (g << 8) | b;
	}

	public dynamic function updateText():Void // so people can override it in hscript
	{
		// Actualizar memoria pico
		var currentMemory = memoryMegas;
		if (currentMemory > memoryPeak) {
			memoryPeak = currentMemory;
		}
		
		// Formatear memoria actual y pico
		var currentMemoryStr = flixel.util.FlxStringUtil.formatBytes(currentMemory);
		var peakMemoryStr = flixel.util.FlxStringUtil.formatBytes(memoryPeak);

		// Interpolación de color según FPS
		var targetFPS = #if (ClientPrefs && ClientPrefs.data && ClientPrefs.data.framerate) ClientPrefs.data.framerate #else FlxG.stage.window.frameRate #end;
		var halfFPS = targetFPS * 0.5;
		var colorHex:String;

		if (currentFPS >= targetFPS) {
			colorHex = "#00FF00"; // Verde
		} else if (currentFPS <= halfFPS) {
			colorHex = "#FF0000"; // Rojo
		} else {
			// Interpola de verde a amarillo a rojo
			var t = (targetFPS - currentFPS) / (targetFPS - halfFPS);
			var interpolatedColor = lerpColor(0xFF00FF00, 0xFFFFFF00, Math.min(t, 1.0));
			if (currentFPS < halfFPS * 1.5) {
				t = (halfFPS * 1.5 - currentFPS) / (halfFPS * 0.5);
				interpolatedColor = lerpColor(0xFFFFFF00, 0xFFFF0000, Math.min(t, 1.0));
			}
			colorHex = "#" + StringTools.hex(interpolatedColor & 0xFFFFFF, 6);
		}

		// Actualizar contadores para modo debug extendido (siempre, sin intervalo)
		if (debugLevel == 2) {
			updateCountersOptimized();
		}

		var displayText:String = "";

		switch (debugLevel) {
			case 0:
				// Modo normal - FPS + Delay + Memory
				displayText = '<font face="' + Paths.font("aller.ttf") + '" size="24" color="' + colorHex + '">' + currentFPS + '</font>' +
						   '<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '"> FPS</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">' + formatFloat(frameTimeMs, 1) + ' / ' + formatFloat(avgFrameTimeMs, 1) + ' ms</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">' + currentMemoryStr + ' / ' + peakMemoryStr + '</font>';
				
				// Agregar texto del autor del mod si está disponible
				if (modAuthor != null && modAuthor.length > 0) {
					displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="16" color="' + colorHex + '">' + modAuthor + '</font>';
				}
			
			case 1:
				// Modo debug básico - con fondo y datos básicos (fuentes más grandes)
				displayText = '<font face="' + Paths.font("aller.ttf") + '" size="24" color="' + colorHex + '">' + currentFPS + '</font>' +
						   	'<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '"> FPS</font>' +
						   	'\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Delay: ' + formatFloat(frameTimeMs, 1) + ' ms</font>' +
						   	'\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Avg: ' + formatFloat(avgFrameTimeMs, 1) + ' ms</font>' +
						   	'\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Memory: ' + currentMemoryStr + '</font>' +
						   	'\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Peak: ' + peakMemoryStr + '</font>' +
						   	'\n\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">' + os.substring(1) + '</font>' +
						   	'\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Commit: ' + lastCommit + '</font>';
			
			case 2:
				// Modo debug extendido - optimizado para mejor rendimiento
				var currentTime = Timer.stamp();
			
				// Actualizar texto estático solo cada textUpdateInterval segundos
				if (cachedStaticText == "" || (currentTime - lastTextUpdateTime) >= textUpdateInterval) {
					lastTextUpdateTime = currentTime;
					
					// Construir texto estático (que no cambia frecuentemente)
					cachedStaticText = '<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">' + os.substring(1) + '</font>' +
									 '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Last Commit: ' + lastCommit + '</font>';
					
					// Mostrar la fecha y hora del commit si están disponibles
					if (commitDate != null && commitDate.length > 0) {
						cachedStaticText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Date: ' + commitDate + '</font>';
					}
					if (commitTime != null && commitTime.length > 0) {
						cachedStaticText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Time: ' + commitTime + ' UTC</font>';
					}
					
					cachedStaticText += '\n\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Objects: ' + FlxG.state.members.length + '</font>';
					cachedStaticText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Uptime: ' + getUptime() + '</font>';
					cachedStaticText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">State: ' + cachedCurrentState + '</font>';
					
					// Información de scripts (se actualiza poco)
					var totalScripts = luaScriptsLoaded + hscriptsLoaded;
					var totalFailed = luaScriptsFailed + hscriptsFailed;
					cachedStaticText += '\n\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="#00FF00">Scripts: ' + totalScripts + '</font>';
					if (totalFailed > 0) {
						cachedStaticText += ' <font face="' + Paths.font("aller.ttf") + '" size="14" color="#FF8800">(Failed: ' + totalFailed + ')</font>';
					}
					if (sscriptsErrors > 0) {
						cachedStaticText += ' <font face="' + Paths.font("aller.ttf") + '" size="14" color="#FF4444">(SScript Errors: ' + sscriptsErrors + ')</font>';
					}
					if (totalScripts > 0) {
						cachedStaticText += '\n<font face="' + Paths.font("aller.ttf") + '" size="12" color="#888888">  Lua: ' + luaScriptsLoaded + ' | HScript: ' + hscriptsLoaded + '</font>';
					}
					
					cachedStaticText += '\n\n\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Plus Engine v'+ MainMenuState.plusEngineVersion +'</font>';
					cachedStaticText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Psych v'+ MainMenuState.psychEngineVersion +'</font>';
				}
				
				// Construir texto dinámico (actualizado en cada frame para modders)
				displayText = '<font face="' + Paths.font("aller.ttf") + '" size="24" color="' + colorHex + '">' + currentFPS + '</font>' +
						   '<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '"> FPS</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Delay: ' + formatFloat(frameTimeMs, 1) + ' ms</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Avg: ' + formatFloat(avgFrameTimeMs, 1) + ' ms</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Memory: ' + currentMemoryStr + '</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Peak: ' + peakMemoryStr + '</font>';
				
				displayText += '\n\n' + cachedStaticText;
				
				// Información crítica para modders - SIEMPRE actualizada en tiempo real
				// Step, Beat y Section (CYAN)
				displayText += '\n\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="#00FFFF">Step: ' + currentStep + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="#00FFFF">Beat: ' + currentBeat + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="#00FFFF">Section: ' + currentSection + '</font>';
				
				// PlayState debug info (YELLOW)
				var healthPercent = Math.floor((playerHealth / 2) * 100);
				displayText += '\n\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="#FFFF00">Speed: ' + formatFloat(songSpeed, 2) + 'x</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="#FFFF00">BPM: ' + currentBPM + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="#FFFF00">Health: ' + healthPercent + '%</font>';
				
				// Rating y Combo (MAGENTA)
				displayText += '\n\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="#FF00FF">Rating: ' + lastRating + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="#FF00FF">Combo: x' + comboCount + '</font>';
		}

		// Usar htmlText para diferentes tamaños de fuente
		htmlText = displayText;

		// Actualizar el fondo
		updateBackground();

		// Fallback para plataformas que no soportan htmlText
		#if flash
		var fallbackText = switch (debugLevel) {
			case 0:
				var baseText = 'FPS: $currentFPS\nMemory: ${currentMemoryStr} / ${peakMemoryStr}';
				if (modAuthor != null && modAuthor.length > 0) {
					baseText += '\n$modAuthor';
				}
				baseText;
			case 1:
				'FPS: $currentFPS\nMemory: ${currentMemoryStr}\nPeak: ${peakMemoryStr}${os}\nCommit: ${lastCommit}';
			case 2:
				var healthPercent = Math.floor((playerHealth / 2) * 100);
				'FPS: $currentFPS\nMemory: ${currentMemoryStr}\nPeak: ${peakMemoryStr}${os}\nCommit: ${lastCommit}\nObjects: ${FlxG.state.members.length}\nUptime: ${getUptime()}\nState: ${cachedCurrentState}\n\nStep: ${currentStep}\nBeat: ${currentBeat}\nSection: ${currentSection}\n\nSpeed: ${formatFloat(songSpeed, 2)}x\nBPM: ${currentBPM}\nHealth: ${healthPercent}%';
		}
		text = fallbackText;
		
		// Aplicar el color interpolado también al fallback
		if (currentFPS >= targetFPS) {
			textColor = 0xFF00FF00; // Verde
		} else if (currentFPS <= halfFPS) {
			textColor = 0xFFFF0000; // Rojo
		} else {
			var t = (targetFPS - currentFPS) / (targetFPS - halfFPS);
			var interpolatedColor = lerpColor(0xFF00FF00, 0xFFFFFF00, Math.min(t, 1.0));
			if (currentFPS < halfFPS * 1.5) {
				t = (halfFPS * 1.5 - currentFPS) / (halfFPS * 0.5);
				interpolatedColor = lerpColor(0xFFFFFF00, 0xFFFF0000, Math.min(t, 1.0));
			}
			textColor = interpolatedColor;
		}
		#end
	}

	var deltaTimeout:Float = 0.0;
	private override function __enterFrame(deltaTime:Float):Void
	{
		// Calcular frame time (delay)
		var currentFrameTime = Timer.stamp();
		frameTimeMs = (currentFrameTime - lastFrameTime) * 1000.0; // Convertir a milisegundos
		lastFrameTime = currentFrameTime;
		
		// Mantener un promedio móvil de los últimos 10 frames
		frameTimesArray.push(frameTimeMs);
		if (frameTimesArray.length > 10) {
			frameTimesArray.shift();
		}
		
		// Calcular promedio
		var sum:Float = 0.0;
		for (time in frameTimesArray) {
			sum += time;
		}
		avgFrameTimeMs = sum / frameTimesArray.length;
		
		if (ClientPrefs.data.fpsRework)
		{
			// Flixel keeps reseting this to 60 on focus gained
			if (FlxG.stage.window.frameRate != ClientPrefs.data.framerate && FlxG.stage.window.frameRate != FlxG.game.focusLostFramerate)
				FlxG.stage.window.frameRate = ClientPrefs.data.framerate;

			var currentTime = openfl.Lib.getTimer();
			framesCount++;

			if (currentTime >= updateTime)
			{
				var elapsed = currentTime - prevTime;
				currentFPS = Math.ceil((framesCount * 1000) / elapsed);
				framesCount = 0;
				prevTime = currentTime;
				updateTime = currentTime + 500;
			}

			// Set Update and Draw framerate to the current FPS every 1.5 second to prevent "slowness" issue
			if ((FlxG.updateFramerate >= currentFPS + 5 || FlxG.updateFramerate <= currentFPS - 5)
				&& haxe.Timer.stamp() - lastFramerateUpdateTime >= 1.5
				&& currentFPS >= 30)
			{
				FlxG.updateFramerate = FlxG.drawFramerate = currentFPS;
				lastFramerateUpdateTime = haxe.Timer.stamp();
			}
		}
		else
		{
			final now:Float = haxe.Timer.stamp() * 1000;
			times.push(now);
			while (times[0] < now - 1000)
				times.shift();
			// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
			if (deltaTimeout < 50)
			{
				deltaTimeout += deltaTime;
				return;
			}

			currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
			deltaTimeout = 0.0;
		}

		updateText();
	}

	// Función para manejar el evento de F2
	private function onKeyDown(event:KeyboardEvent):Void {
		if (event.keyCode == Keyboard.F2) {
			debugLevel = (debugLevel + 1) % 3;
			
			// Forzar actualización inmediata del texto y fondo
			updateText();
		}
	}

	// Función para actualizar el fondo
	private function updateBackground():Void {
		if (bgShape == null) return;

		var g:Graphics = bgShape.graphics;
		g.clear();

		if (debugLevel > 0) {
			// Asegurar que el fondo esté agregado al stage
			if (bgShape.parent == null && this.parent != null) {
				this.parent.addChildAt(bgShape, this.parent.getChildIndex(this));
			}

		// Calcular el tamaño del fondo basado en el texto
		var lines = switch (debugLevel) {
			case 1: 7; // FPS, Delay, Memory, Peak, espacio, OS, Commit
			case 2: 32; // FPS, Delay, Avg, Memory, Peak + resto de info
			default: 0;
			}
			
			var bgWidth = 325; // Ancho suficiente
			var bgHeight = lines * 18 + 20; // Altura calculada + padding

			// Dibujar fondo semi-transparente negro
			g.beginFill(0x000000, 0.7);
			g.drawRect(x - 10, y, bgWidth, bgHeight);
			g.endFill();

			// Borde para mejor visibilidad
			g.lineStyle(1, 0x666666, 0.8);
			g.drawRect(x - 10, y, bgWidth, bgHeight);
		} else {
			// Remover el fondo si no se necesita
			if (bgShape.parent != null) {
				bgShape.parent.removeChild(bgShape);
			}
		}
	}

	// Función para obtener información del último commit
	private function getLastCommit():Void {
		#if sys
		// Intentar obtener información desde la API de GitHub
		var http = new Http('https://api.github.com/repos/LeninAsto/FNF-PlusEngine/commits?per_page=1');
		http.addHeader('User-Agent', 'FNF-PlusEngine');
		
		http.onData = function(data:String) {
			try {
				var commits:Array<Dynamic> = Json.parse(data);
				if (commits != null && commits.length > 0) {
					var latestCommit = commits[0];
					var sha:String = latestCommit.sha.substr(0, 7);
					var message:String = latestCommit.commit.message;
					
					// Obtener la fecha y hora del commit
					var commitDateRaw:String = latestCommit.commit.author.date; // Formato ISO 8601
					
					// Tomar solo la primera línea del mensaje
					if (message.indexOf('\n') != -1) {
						message = message.substr(0, message.indexOf('\n'));
					}
					
					// Limitar longitud del mensaje
					if (message.length > 30) {
						message = message.substring(0, 30) + "...";
					}
					
					// Formatear la fecha y hora del commit
					if (commitDateRaw != null && commitDateRaw.length > 0) {
						// Formato: 2024-11-02T15:30:45Z
						var parts = commitDateRaw.split('T');
						if (parts.length >= 2) {
							// Extraer fecha (2024-11-02)
							commitDate = parts[0];
							
							// Extraer hora (15:30:45Z -> 15:30)
							var timePart = parts[1];
							if (timePart != null) {
								commitTime = timePart.substr(0, 5); // "15:30"
							}
						}
					}
					
					lastCommit = sha + " " + message;
				} else {
					lastCommit = "Build version";
					commitTime = "";
					commitDate = "";
				}
			} catch (e:Dynamic) {
				lastCommit = "Build version";
				commitTime = "";
				commitDate = "";
			}
		};
		
		http.onError = function(error:String) {
			lastCommit = "Build version";
		};
		
		http.request(false);
		
		#else
		lastCommit = "Build version";
		#end
	}

	// Función para obtener tiempo de ejecución
	private function getUptime():String {
		var uptime = haxe.Timer.stamp() - startTime;
		var hours = Math.floor(uptime / 3600);
		var minutes = Math.floor((uptime % 3600) / 60);
		var seconds = Math.floor(uptime % 60);
		
		if (hours > 0) {
			return '${hours}h ${minutes}m ${seconds}s';
		} else if (minutes > 0) {
			return '${minutes}m ${seconds}s';
		} else {
			return '${seconds}s';
		}
	}

	// Función para formatear números flotantes
	private function formatFloat(value:Float, decimals:Int):String {
		var multiplier = Math.pow(10, decimals);
		var rounded = Math.round(value * multiplier) / multiplier;
		var str = Std.string(rounded);
		
		// Asegurar que tenga el número correcto de decimales
		if (str.indexOf('.') == -1) {
			str += '.';
		}
		
		var parts = str.split('.');
		if (parts.length > 1) {
			while (parts[1].length < decimals) {
				parts[1] += '0';
			}
			return parts[0] + '.' + parts[1];
		}
		
		return str + StringTools.lpad('', '0', decimals);
	}

	// Función para obtener draw calls aproximados
	private function getDrawCalls():Int {
		// Estimación basada en objetos visibles
		return FlxG.state.members.length * 2; // Aproximación
	}

	// Función para obtener estadísticas del recolector de basura
	private function getGCStats():String {
		#if cpp
		try {
			// Obtener información de memoria del GC
			var totalMem = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED);
			var usedMem = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
			var freeMem = totalMem - usedMem;
			
			var freePercentage = Math.round((freeMem / totalMem) * 100);
			return '${freePercentage}% free';
		} catch (e:Dynamic) {
			return 'N/A';
		}
		#else
		return 'N/A';
		#end
	}

	// Función para obtener el estado actual
	private function getCurrentState():String {
		if (FlxG.state == null) return "null";
		
		var stateName = Type.getClassName(Type.getClass(FlxG.state));
		
		// Simplificar el nombre (quitar packages)
		if (stateName.indexOf('.') > -1) {
			var parts = stateName.split('.');
			stateName = parts[parts.length - 1];
		}
		
		// Verificar si hay un substate activo
		if (FlxG.state.subState != null) {
			var subStateName = Type.getClassName(Type.getClass(FlxG.state.subState));
			if (subStateName.indexOf('.') > -1) {
				var parts = subStateName.split('.');
				subStateName = parts[parts.length - 1];
			}
			return '${stateName} -> ${subStateName}';
		}
		
		return stateName;
	}

	// Función para obtener el idioma actual
	private function getCurrentLanguage():String {
		#if TRANSLATIONS_ALLOWED
		try {
			// Obtener el código del idioma desde ClientPrefs
			var langCode = ClientPrefs.data.language;
			
			// Obtener el nombre del idioma desde Language.hx
			var langName = Language.getPhrase('language_name');
			if (langName != null && langName.length > 0) {
				return '${langName} (${langCode})';
			} else {
				return langCode;
			}
		} catch (e:Dynamic) {
			return 'Unknown';
		}
		#else
		return 'English (US)'; // Default cuando las traducciones están deshabilitadas
		#end
	}

	// Función para actualizar contadores de rendimiento (ultra-optimizada)
	private function updateCountersOptimized():Void {
		var currentTime = haxe.Timer.stamp();
		
		// Actualizar cache de datos mínimos cada 0.5 segundos para mejor respuesta
		if (currentTime - lastCacheUpdateTime >= 0.5) {
			lastCacheUpdateTime = currentTime;
			cachedCurrentState = getCurrentState();
		}
	}

	// Función optimizada para contar notas sin reflection costosa
	// ELIMINADA - Ya no se usa para mejor rendimiento

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		// Mantener siempre el mismo tamaño, ignorar el parámetro scale
		scaleX = scaleY = 1.0;
		
		// Solo reposicionamiento, sin escalado
		x = X;
		y = Y;

		// Actualizar posición del fondo también para que siga al texto
		updateBackground();
	}

	// Función para limpiar recursos
	public function destroy():Void {
		if (FlxG.stage != null) {
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		if (bgShape != null && bgShape.parent != null) {
			bgShape.parent.removeChild(bgShape);
		}
	}

	// Funciones para obtener uso real de CPU y GPU
	// ELIMINADAS - Ya no se usan para mejor rendimiento

	// Funciones de estimación como fallback  
	// ELIMINADAS - Ya no se usan para mejor rendimiento

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}
