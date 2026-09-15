package backend.ui.haxecompose.material3;

import openfl.utils.AssetType;
import openfl.utils.Assets;

class MaterialIconRegistry
{
	static var loaded:Bool = false;
	static var glyphs:Map<String, String> = [];

	public static function glyph(name:String):String
	{
		if (!loaded)
			load();

		if (name == null || name.length == 0)
			return "";

		var key = normalize(name);
		if (glyphs.exists(key))
			return glyphs.get(key);

		return fallbackGlyph(key);
	}

	static function load():Void
	{
		loaded = true;
		var path = "assets/fonts/material-icons-codepoints.txt";
		if (!Assets.exists(path, AssetType.TEXT))
			return;

		var raw = Assets.getText(path);
		if (raw == null)
			return;

		for (line in raw.split("\n"))
		{
			line = StringTools.trim(line);
			if (line.length == 0)
				continue;

			var parts = line.split(" ");
			if (parts.length < 2)
				continue;

			var code = Std.parseInt("0x" + parts[1]);
			if (code != null)
				glyphs.set(normalize(parts[0]), String.fromCharCode(code));
		}
	}

	static function fallbackGlyph(key:String):String
	{
		return switch (key)
		{
			case "add" | "plus":
				String.fromCharCode(0xE145);
			case "arrow_back" | "back" | "left":
				String.fromCharCode(0xE5C4);
			case "help" | "question":
				String.fromCharCode(0xE887);
			case "settings":
				String.fromCharCode(0xE8B8);
			case "close" | "cancel":
				String.fromCharCode(0xE5CD);
			case "check" | "ok":
				String.fromCharCode(0xE5CA);
			default:
				key.length == 1 ? key : String.fromCharCode(0xE887);
		}
	}

	static inline function normalize(name:String):String
		return name.toLowerCase().split("-").join("_");
}
