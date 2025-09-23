package debug;

import flixel.FlxG;
import openfl.Lib;
import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;

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
		width = FlxG.width;
		multiline = true;
		text = "FPS: ";

		// Habilitar formato HTML para diferentes tamaños de texto
		#if !flash
		embedFonts = true; // Habilitar fuentes embebidas para usar aller.ttf
		#end

		times = [];
		lastFramerateUpdateTime = Timer.stamp();
		prevTime = Lib.getTimer();
		updateTime = prevTime + 500;
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

		// Usar htmlText para diferentes tamaños de fuente
		htmlText = '<font face="' + Paths.font("aller.ttf") + '" size="24" color="' + colorHex + '">' + currentFPS + '</font>' +
				   '<font face="' + Paths.font("aller.ttf") + '" size="14" color="' + colorHex + '"> FPS</font>' +
				   '\n<font face="' + Paths.font("aller.ttf") + '" size="12" color="' + colorHex + '">' + currentMemoryStr + ' / ' + peakMemoryStr + '</font>' +
				   '\n<font face="' + Paths.font("aller.ttf") + '" size="10" color="' + colorHex + '">' + os + '</font>';

		// Fallback para plataformas que no soportan htmlText
		#if flash
		text = 'FPS: $currentFPS' + 
			   '\nMemory: ${currentMemoryStr} / ${peakMemoryStr}' +
			   os;
		
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

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		// Mantener siempre el mismo tamaño, ignorar el parámetro scale
		scaleX = scaleY = 1.0;
		
		// Solo reposicionamiento, sin escalado
		x = X;
		y = Y;
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
