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
		Background shape for debug mode
	**/
	private var bgShape:Shape;

	/**
		Last GitHub commit info
	**/
	private var lastCommit:String = "Loading...";

	/**
		CPU and GPU usage tracking
	**/
	private var cpuUsage:Float = 0.0;
	private var gpuUsage:Float = 0.0;

	/**
		Note and sprite counters
	**/
	private var noteCount:Int = 0;
	private var spriteCount:Int = 0;

	/**
		Runtime tracking
	**/
	private var startTime:Float = 0.0;

	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var lastFramerateUpdateTime:Float;
	@:noCompletion private var updateTime:Int;
	@:noCompletion private var framesCount:Int;
	@:noCompletion private var prevTime:Int;

	public var os:String = '';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		#if !officialBuild
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
		width = 600; // Aumentar más el ancho para evitar saltos de línea
		height = 300; // Asegurar altura suficiente
		multiline = true;
		text = "FPS: ";
		wordWrap = false; // Evitar que las palabras se corten
		autoSize = openfl.text.TextFieldAutoSize.LEFT; // Auto-ajustar al contenido

		// Habilitar formato HTML para diferentes tamaños de texto
		#if !flash
		embedFonts = true; // Habilitar fuentes embebidas para usar aller.ttf
		#end

		times = [];
		lastFramerateUpdateTime = Timer.stamp();
		prevTime = Lib.getTimer();
		updateTime = prevTime + 500;

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

		// Actualizar contadores para modo debug extendido
		if (debugLevel == 2) {
			updateCounters();
		}

		var displayText:String = "";

		switch (debugLevel) {
			case 0:
				// Modo normal - solo FPS
				displayText = '<font face="' + Paths.font("aller.ttf") + '" size="24" color="' + colorHex + '">' + currentFPS + '</font>' +
						   '<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '"> FPS</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">' + currentMemoryStr + ' / ' + peakMemoryStr + '</font>';
			
			case 1:
				// Modo debug básico - con fondo y datos básicos (fuentes más grandes)
				displayText = '<font face="' + Paths.font("aller.ttf") + '" size="24" color="' + colorHex + '">' + currentFPS + '</font>' +
						   '<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '"> FPS</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Memory: ' + currentMemoryStr + '</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Peak: ' + peakMemoryStr + '</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">' + os.substring(1) + '</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Commit: ' + lastCommit + '</font>';
			
			case 2:
				// Modo debug extendido - todos los datos (fuentes más grandes)
				displayText = '<font face="' + Paths.font("aller.ttf") + '" size="24" color="' + colorHex + '">' + currentFPS + '</font>' +
						   '<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '"> FPS</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Memory: ' + currentMemoryStr + '</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Peak: ' + peakMemoryStr + '</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">' + os.substring(1) + '</font>' +
						   '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Commit: ' + lastCommit + '</font>';
				
				// Agregar líneas extra por separado para evitar problemas de parsing
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">CPU Usage: ' + cpuUsage + '%</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">GPU Usage: ' + gpuUsage + '%</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Note count: ' + noteCount + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Sprites: ' + spriteCount + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Objects: ' + FlxG.state.members.length + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Uptime: ' + getUptime() + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Target FPS: ' + targetFPS + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Draw Calls: ' + getDrawCalls() + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">GC Memory: ' + getGCStats() + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">State: ' + getCurrentState() + '</font>';
				displayText += '\n<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '">Language: ' + getCurrentLanguage() + '</font>';
		}

		// Usar htmlText para diferentes tamaños de fuente
		htmlText = displayText;

		// Actualizar el fondo
		updateBackground();

		// Fallback para plataformas que no soportan htmlText
		#if flash
		var fallbackText = switch (debugLevel) {
			case 0:
				'FPS: $currentFPS\nMemory: ${currentMemoryStr} / ${peakMemoryStr}';
			case 1:
				'FPS: $currentFPS\nMemory: ${currentMemoryStr}\nPeak: ${peakMemoryStr}${os}\nCommit: ${lastCommit}';
			case 2:
				'FPS: $currentFPS\nMemory: ${currentMemoryStr}\nPeak: ${peakMemoryStr}${os}\nCommit: ${lastCommit}\nCPU Usage: ${cpuUsage}%\nGPU Usage: ${gpuUsage}%\nNotes: ${noteCount}\nSprites: ${spriteCount}\nObjects: ${FlxG.state.members.length}\nUptime: ${getUptime()}\nTarget FPS: ${targetFPS}\nDraw Calls: ${getDrawCalls()}\nGC Memory: ${getGCStats()}\nState: ${getCurrentState()}\nLanguage: ${getCurrentLanguage()}';
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
				case 1: 5; // FPS, Memory, Peak, OS, Commit
				case 2: 16; // Todo lo anterior + más datos de debug (agregamos 3 líneas más)
				default: 0;
			}
			
			var bgWidth = 400; // Ancho suficiente
			var bgHeight = lines * 18 + 20; // Altura calculada + padding

			// Dibujar fondo semi-transparente negro
			g.beginFill(0x000000, 0.7);
			g.drawRect(x - 5, y - 5, bgWidth, bgHeight);
			g.endFill();

			// Borde para mejor visibilidad
			g.lineStyle(1, 0x666666, 0.8);
			g.drawRect(x - 5, y - 5, bgWidth, bgHeight);
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
		try {
			var process = new sys.io.Process('git', ['log', '--oneline', '-n', '1']);
			var output = process.stdout.readAll().toString().trim();
			process.close();
			
			if (output.length > 0) {
				var parts = output.split(' ');
				if (parts.length > 0) {
					var shortHash:String = parts[0].substring(0, Std.int(Math.min(7, parts[0].length)));
					var message = parts.slice(1).join(' ');
					if (message.length > 30) {
						message = message.substring(0, 30) + "...";
					}
					lastCommit = shortHash + " " + message;
				} else {
					lastCommit = "Invalid commit format";
				}
			} else {
				lastCommit = "No commits found";
			}
		} catch (e:Dynamic) {
			lastCommit = "Git not available";
		}
		#else
		lastCommit = "Not available";
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

	// Función para actualizar contadores de rendimiento
	private function updateCounters():Void {
		// Actualizar uso de CPU (simulado por ahora, requiere implementación específica por plataforma)
		#if cpp
		#if windows
		// Esto es una aproximación, en un caso real necesitarías usar WMI o performance counters
		cpuUsage = Math.round(Math.random() * 15 + 5); // Simulado entre 5-20%
		gpuUsage = Math.round(Math.random() * 20 + 10); // Simulado entre 10-30%
		#else
		cpuUsage = 0;
		gpuUsage = 0;
		#end
		#end

		// Contar objetos en el juego
		spriteCount = 0;
		noteCount = 0;

		// Contar sprites y notas si estamos en PlayState
		if (FlxG.state != null) {
			try {
				var state = Type.getClass(FlxG.state);
				var stateName = Type.getClassName(state);
				
				if (stateName == "states.PlayState") {
					// Intentar acceder a los arrays de notas y sprites del PlayState
					var playState = FlxG.state;
					var fields = Reflect.fields(playState);
					
					for (field in fields) {
						var value = Reflect.field(playState, field);
						if (Std.isOfType(value, Array)) {
							var array:Array<Dynamic> = cast value;
							if (field.toLowerCase().indexOf('note') != -1) {
								noteCount += array.length;
							}
						}
					}
				}
			} catch (e:Dynamic) {
				// Fallar silenciosamente si no podemos acceder al estado
			}
			
			spriteCount = FlxG.state.members.length;
		}
	}

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
