package scripting;

#if HSCRIPT_ALLOWED
import backend.AssetLoader;
import backend.Mods;
import backend.Paths;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import openfl.utils.AssetType;
import psychlua.backend.HScript;

#if sys
import sys.FileSystem;
#end

using StringTools;

class GlobalScriptManager
{
	public static var loadedMod(default, null):String = null;
	static var scripts:Array<HScript> = [];

	public static function loadForMod(mod:String):Void
	{
		#if MODS_ALLOWED
		if (mod == null || mod.trim().length < 1)
			return;

		if (loadedMod == mod && scripts.length > 0)
			return;

		dispose();
		loadedMod = mod;

		var files:Array<String> = collectFiles(mod);
		for (file in files)
			loadFile(file);
		#end
	}

	public static function dispose():Void
	{
		for (script in scripts)
		{
			try
			{
				if (script != null && script.exists('onDestroy'))
					script.call('onDestroy');
				if (script != null)
					script.destroy();
			}
			catch (_:Dynamic) {}
		}
		scripts = [];
		loadedMod = null;
	}

	public static function call(func:String, ?args:Array<Dynamic>):Void
	{
		for (script in scripts)
		{
			if (script == null || !script.exists(func))
				continue;
			try
				script.call(func, args)
			catch (e:Dynamic)
				trace('GlobalScriptManager: error calling $func in ${script.origin}: $e');
		}
	}

	static function collectFiles(mod:String):Array<String>
	{
		var files:Array<String> = [];

		#if sys
		var globalsFolder:String = Paths.mods(mod + '/scripts/globals');
		if (FileSystem.exists(globalsFolder) && FileSystem.isDirectory(globalsFolder))
		{
			var mainScript:String = globalsFolder + '/GlobalScript.hx';
			if (FileSystem.exists(mainScript) && !FileSystem.isDirectory(mainScript))
				files.push(mainScript);

			var names:Array<String> = FileSystem.readDirectory(globalsFolder);
			names.sort(Reflect.compare);
			for (name in names)
			{
				if (!name.toLowerCase().endsWith('.hx'))
					continue;
				if (name.toLowerCase() == 'globalscript.hx')
					continue;
				var path:String = globalsFolder + '/' + name;
				if (!FileSystem.isDirectory(path))
					files.push(path);
			}
		}
		#end

		return files;
	}

	static function loadFile(file:String):Void
	{
		try
		{
			var script:HScript = new HScript(null, file);
			if (script == null)
				return;

			scripts.push(script);
			if (script.exists('new'))
				script.call('new');
			if (script.exists('onCreate'))
				script.call('onCreate');
			if (script.exists('onInit'))
				script.call('onInit');

			trace('GlobalScriptManager: loaded $file');
		}
		catch (e:IrisError)
		{
			trace('GlobalScriptManager: ' + Printer.errorToString(e, false));
		}
		catch (e:Dynamic)
		{
			trace('GlobalScriptManager: failed loading $file: $e');
		}
	}
}
#end
