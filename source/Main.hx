package;

import debug.FPSCounter;
import debug.TraceDisplay;
import debug.TraceButton;
import debug.DebugButton;
import backend.Highscore;
import flixel.FlxGame;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;
#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
import psychlua.SScript.SScriptCompat;
#end
import mobile.backend.MobileScaleMode;
import openfl.events.KeyboardEvent;
import lime.system.System as LimeSystem;

#if (linux || mac)
import lime.graphics.Image;
#end
#if COPYSTATE_ALLOWED
import states.CopyState;
#end
import backend.Highscore;

// NATIVE API STUFF, YOU CAN IGNORE THIS AND SCROLL //
#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

// // // // // // // // //
class Main extends Sprite
{
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSCounter;
	public static var traceDisplay:TraceDisplay;
	public static var traceButton:TraceButton;
	public static var debugButton:DebugButton;

	public static final platform:String = #if mobile "Phones" #else "PCs" #end;
	public static var watermarkSprite:Sprite = null;
	public static var watermark:Bitmap = null;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
	}

	public function new()
	{
		super();
		#if mobile
		#if android
		StorageUtil.requestPermissions();
		#end
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end
		backend.CrashHandler.init();

		#if (cpp && windows)
		backend.Native.fixScaling();
		#end

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		Highscore.load();

		#if HSCRIPT_ALLOWED
		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		}
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		}
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		}
		#end

		#if SSCRIPT_ALLOWED
		// Handlers para SScript (Psych 0.7.3)
		SScriptCompat.sscriptWarnHandler = function(message:String, origin:String) {
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('SSCRIPT WARNING ($origin): $message', FlxColor.YELLOW);
			debug.TraceDisplay.addWarning('SSCRIPT WARNING ($origin): $message');
		};
		
		SScriptCompat.sscriptErrorHandler = function(message:String, origin:String) {
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('SSCRIPT ERROR ($origin): $message', FlxColor.RED);
			debug.TraceDisplay.addSScriptError(message, origin);
		};
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		#if mobile
		FlxG.signals.postGameStart.addOnce(() -> {
			FlxG.scaleMode = new MobileScaleMode();
		});
		#end
		addChild(new FlxGame(game.width, game.height, #if COPYSTATE_ALLOWED !CopyState.checkExistingFiles() ? CopyState : #end game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		
		traceDisplay = new TraceDisplay(10, 100, 0xFFFFFF);
		addChild(traceDisplay);
		traceDisplay.setupBackground();
		
		// Agregar los botones de TraceDisplay y Debug para móvil
		#if mobile
		traceButton = new TraceButton();
		addChild(traceButton);
		
		debugButton = new DebugButton();
		addChild(debugButton);
		#end
		
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
			// Posicionamiento inicial con márgenes constantes
			var marginX = 10;
			var marginY = 3;
			fpsVar.positionFPS(marginX, marginY, 1.0);
		}

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = #if mobile 30 #else 60 #end;
		#if web
		FlxG.keys.preventDefaultKeys.push(TAB);
		#else
		FlxG.keys.preventDefaultKeys = [TAB];
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end
		
		#if desktop 
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, toggleFullScreen);
		#end

		#if mobile
		#if android FlxG.android.preventDefaultKeys = [BACK]; #end
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end

		Application.current.window.vsync = ClientPrefs.data.vsync;

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
			// Solo reposicionamiento del FPS, sin escalado
			if(fpsVar != null) {
				var marginX = 10;
				var marginY = 3;
				// Sin escalado, solo reposicionamiento
				fpsVar.positionFPS(marginX, marginY, 1.0);
			}
			
			// Reposicionar el botón de TraceDisplay
			#if mobile
			if(traceButton != null) {
				traceButton.updatePosition();
			}
			if(debugButton != null) {
				debugButton.updatePosition();
			}
			#end
			
			// Solo reposicionamiento de la marca de agua, sin escalado
			positionWatermark();
			
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
		});

		setupGame();
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	function toggleFullScreen(event:KeyboardEvent) {
		if (Controls.instance.justReleased('fullscreen'))
			FlxG.fullscreen = !FlxG.fullscreen;
	}

	function positionWatermark():Void {
		if (watermarkSprite != null && watermark != null) {
			var marginX = 10;
			var marginY = 10;
			var stageW = openfl.Lib.current.stage.stageWidth;
			watermarkSprite.x = stageW - watermark.width * Math.abs(watermark.scaleX) - marginX;
			watermarkSprite.y = marginY;
		}
		if (watermark != null && watermark.parent == this) {
			var stageW = Lib.current.stage.stageWidth;
			var stageH = Lib.current.stage.stageHeight;
			watermark.x = stageW - watermark.width * Math.abs(watermark.scaleX) + 110;
			watermark.y = stageH - watermark.height * Math.abs(watermark.scaleY) - 30;
		}
	}

	private function setupGame():Void
	{
		shaders.ShaderCompatibility.init();
		
		trace('\n\n' + backend.Native.buildSystemInfo());
		
		#if hxvlc
		try {
			hxvlc.util.Handle.init();
			trace('hxvlc initialized successfully');
		} catch(e:Dynamic) {
			trace('hxvlc initialization failed: $e');
		}
		#end
		
		var flxGraphic = backend.Paths.image("marca");
		if (flxGraphic != null) {
			var bmpData:openfl.display.BitmapData = flxGraphic.bitmap;
			if (watermarkSprite != null && watermarkSprite.parent != null) {
				watermarkSprite.parent.removeChild(watermarkSprite);
			}
			watermark = new openfl.display.Bitmap(bmpData);
			watermark.smoothing = true;
			watermarkSprite = new openfl.display.Sprite();
			watermarkSprite.addChild(watermark);
			var scale:Float = 0.85;
			watermark.scaleX = scale;
			watermark.scaleY = scale;
			positionWatermark();
			watermarkSprite.alpha = 0.5;
			watermarkSprite.visible = ClientPrefs.data.showWatermark;
			openfl.Lib.current.stage.addChild(watermarkSprite);
		} else {
			trace('No se pudo cargar la marca de agua con backend.Paths.image("marca").');
		}

		var imagePath = backend.Paths.getPath('images/marca.png', IMAGE);
		if (sys.FileSystem.exists(imagePath)) {
		    if (watermark != null && watermark.parent != null)
		        removeChild(watermark);
			var bmpData = openfl.display.BitmapData.fromFile(imagePath);
			watermark = new openfl.display.Bitmap(bmpData);
			var scale = 0.85;
			watermark.scaleX = -scale;
			watermark.scaleY = scale;
			watermark.alpha = 0.5;
			addChild(watermark);
			positionWatermark();
			Lib.current.stage.addEventListener(openfl.events.Event.RESIZE, function(_) positionWatermark());
		}
		if (watermark != null) {
		    watermark.visible = ClientPrefs.data.showWatermark;
		}
	}
}
