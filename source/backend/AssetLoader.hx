package backend;

import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flash.media.Sound;
import lime.utils.Assets;
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
import shaders.ShaderCompatibility;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Raw asset I/O for filesystem and bundled assets.
 * Inspired by the loader separation used in P-Slice.
 */
class AssetLoader
{
	public static function exists(path:String, type:AssetType):Bool
	{
		if (path == null || path.length == 0)
			return false;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return true;
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			return OpenFlAssets.exists(path, type);
		}
		catch (_:Dynamic)
		{
		}
		return false;
	}

	public static function loadText(path:String):String
	{
		if (path == null || path.length == 0)
			return null;

		var text:String = null;
		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				text = File.getContent(path);
		}
		catch (_:Dynamic)
		{
		}
		#end
		if (text != null)
			return maybeAdaptShaderText(path, text);

		try
		{
			if (OpenFlAssets.exists(path, TEXT))
				text = Assets.getText(path);
		}
		catch (_:Dynamic)
		{
		}
		return maybeAdaptShaderText(path, text);
	}

	static function maybeAdaptShaderText(path:String, text:String):String
	{
		if (text == null)
			return null;

		var normalized:String = path.replace("\\", "/");
		if (normalized.indexOf("/shaders/") == -1)
			return text;

		var stage:String = StringTools.endsWith(normalized.toLowerCase(), ".vert") ? "vertex" : "fragment";
		var shaderName:String = normalized;
		var slash:Int = shaderName.lastIndexOf("/");
		if (slash != -1)
			shaderName = shaderName.substr(slash + 1);
		var dot:Int = shaderName.lastIndexOf(".");
		if (dot != -1)
			shaderName = shaderName.substr(0, dot);

		return ShaderCompatibility.adaptRuntimeShaderCode(text, shaderName, stage);
	}

	public static function loadBitmap(path:String):BitmapData
	{
		if (path == null || path.length == 0)
			return null;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return BitmapData.fromFile(path);
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			if (OpenFlAssets.exists(path, IMAGE))
				return OpenFlAssets.getBitmapData(path);
		}
		catch (_:Dynamic)
		{
		}
		return null;
	}

	public static function loadSound(path:String):Sound
	{
		if (path == null || path.length == 0)
			return null;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return Sound.fromFile(path);
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			if (OpenFlAssets.exists(path, SOUND))
				return OpenFlAssets.getSound(path);
		}
		catch (_:Dynamic)
		{
		}
		return null;
	}

	/** Keeps long OGG tracks compressed and streamable for native tempo processing. */
	public static function loadStreamedSound(path:String):Sound
	{
		#if (lime_vorbis && sys)
		if (path != null && path.length > 0)
		{
			try
			{
				if (sys.FileSystem.exists(path))
				{
					// Some older mods store a Theora video and Vorbis audio in the same
					// .ogg container. Lime's streaming reader can open it, but may stall
					// once playback starts. The regular decoder handles these legacy files.
					if (hasTheoraStream(path))
						return loadSound(path);

					var vorbis = VorbisFile.fromFile(path);
					if (vorbis != null)
						return Sound.fromAudioBuffer(AudioBuffer.fromVorbisFile(vorbis));
				}
			}
			catch (_:Dynamic) {}
		}
		#end
		return loadSound(path);
	}

	#if sys
	static function hasTheoraStream(path:String):Bool
	{
		var input:sys.io.FileInput = null;
		try
		{
			var size:Int = Std.int(Math.min(sys.FileSystem.stat(path).size, 65536));
			input = sys.io.File.read(path, true);
			var header:haxe.io.Bytes = input.read(size);
			input.close();
			var signature:haxe.io.Bytes = haxe.io.Bytes.ofString('theora');
			for (offset in 0...(header.length - signature.length + 1))
			{
				var matches:Bool = true;
				for (index in 0...signature.length)
					if (header.get(offset + index) != signature.get(index))
					{
						matches = false;
						break;
					}
				if (matches)
					return true;
			}
			return false;
		}
		catch (_:Dynamic)
		{
			if (input != null)
				try input.close() catch (_:Dynamic) {}
			return false;
		}
	}
	#end
}

