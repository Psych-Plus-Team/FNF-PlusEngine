package shaders;

class ShaderCompatibility
{
	public static function adaptRuntimeShaderCode(source:String, shaderName:String = null, stage:String = "fragment"):String
	{
		if (source == null)
			return null;

		var code:String = source.replace("\r\n", "\n").replace("\r", "\n");
		var dialect:String = getShaderDialect(code, shaderName);

		if (dialect == null)
			return code;

		code = stripDialectPragmas(code);
		code = stripUniformInitializers(code);

		if (stage == "fragment")
		{
			switch (dialect)
			{
				case "notitg":
					code = adaptNotITGFragment(code);
				case "shadertoy":
					code = adaptShadertoyFragment(code);
				default:
			}
		}

		return normalizeStrictConstructors(code);
	}

	static function getShaderDialect(source:String, shaderName:String):String
	{
		var lower:String = source.toLowerCase();
		if (hasDialectFlag(lower, "notitg"))
			return "notitg";
		if (hasDialectFlag(lower, "shadertoy"))
			return "shadertoy";

		if (shaderName != null)
		{
			var name:String = shaderName.toLowerCase();
			if (StringTools.startsWith(name, "notitg:") || StringTools.startsWith(name, "notitg/"))
				return "notitg";
			if (StringTools.startsWith(name, "shadertoy:") || StringTools.startsWith(name, "shadertoy/"))
				return "shadertoy";
		}

		return null;
	}

	static function hasDialectFlag(source:String, dialect:String):Bool
	{
		return source.indexOf("#pragma " + dialect) != -1
			|| source.indexOf("#pragma shader_dialect " + dialect) != -1
			|| source.indexOf("#pragma shader-dialect " + dialect) != -1
			|| source.indexOf("@shader_dialect " + dialect) != -1
			|| source.indexOf("@shader-dialect " + dialect) != -1;
	}

	static function stripDialectPragmas(source:String):String
	{
		var lines:Array<String> = source.split("\n");
		for (i in 0...lines.length)
		{
			var line:String = lines[i];
			var lower:String = StringTools.trim(line).toLowerCase();
			if (StringTools.startsWith(lower, "#pragma notitg")
				|| StringTools.startsWith(lower, "#pragma shadertoy")
				|| StringTools.startsWith(lower, "#pragma shader_dialect")
				|| StringTools.startsWith(lower, "#pragma shader-dialect")
				|| lower.indexOf("@shader_dialect ") != -1
				|| lower.indexOf("@shader-dialect ") != -1)
			{
				lines[i] = "";
			}
		}
		return lines.join("\n");
	}

	static function stripVersionPragmas(source:String):String
	{
		var version:EReg = ~/^\s*#version\s+[0-9]+\s*.*$/gm;
		return version.replace(source, "");
	}

	static function stripUniformInitializers(source:String):String
	{
		var uniformInit:EReg = ~/^(\s*uniform\s+(?:(?:lowp|mediump|highp)\s+)?[A-Za-z_][A-Za-z0-9_]*\s+[A-Za-z_][A-Za-z0-9_]*(?:\s*\[[^\]]+\])?)\s*=\s*[^;]+;\s*$/;
		var lines:Array<String> = source.split("\n");
		for (i in 0...lines.length)
		{
			var line:String = lines[i];
			if (uniformInit.match(line))
				lines[i] = uniformInit.matched(1) + ";";
		}
		return lines.join("\n");
	}

	static function adaptNotITGFragment(source:String):String
	{
		var code:String = source;
		var needsHeader:Bool = code.indexOf("#pragma header") == -1;
		var usedLegacyColor:Bool = code.indexOf("color") != -1;

		code = stripVersionPragmas(code);
		code = removeBuiltinDeclarations(code);
		code = replaceWord(code, "sampler0", "bitmap");
		code = replaceWord(code, "imageCoord", "openfl_TextureCoordv");
		code = replaceWord(code, "textureCoord", "openfl_TextureCoordv");
		code = replaceWord(code, "imageSize", "openfl_TextureSize");
		code = replaceWord(code, "textureSize", "openfl_TextureSize");
		code = replaceWord(code, "resolution", "openfl_TextureSize");
		code = replaceTexture2DBiasCalls(code);

		if (usedLegacyColor)
			code = "#define color vec4(1.0)\n" + code;
		if (needsHeader)
			code = "#pragma header\n\n" + code;

		return code;
	}

	static function adaptShadertoyFragment(source:String):String
	{
		var code:String = stripVersionPragmas(source);
		var needsHeader:Bool = code.indexOf("#pragma header") == -1;
		var usesITime:Bool = code.indexOf("iTime") != -1;
		var hasITimeUniform:Bool = code.indexOf("uniform float iTime") != -1;

		code = removeBuiltinDeclarations(code, [
			"iResolution" => true,
			"iChannel0" => true
		]);
		code = replaceWord(code, "iResolution", "vec3(openfl_TextureSize, 1.0)");
		code = replaceWord(code, "iChannel0", "bitmap");
		code = replaceWord(code, "texture", "texture2D");

		if (usesITime && !hasITimeUniform)
			code = "uniform float iTime;\n" + code;

		if (code.indexOf("void mainImage") != -1 && code.indexOf("void main()") == -1)
		{
			code += "\n\nvoid main()\n{\n\tvec4 fragColor = vec4(0.0);\n\tmainImage(fragColor, openfl_TextureCoordv * openfl_TextureSize);\n\tgl_FragColor = fragColor;\n}\n";
		}

		if (needsHeader)
			code = "#pragma header\n\n" + code;

		return code;
	}

	static function removeBuiltinDeclarations(source:String, ?builtins:Map<String, Bool>):String
	{
		var lines:Array<String> = source.split("\n");
		if (builtins == null)
		{
			builtins = [
				"color" => true,
				"textureCoord" => true,
				"imageCoord" => true,
				"textureSize" => true,
				"imageSize" => true,
				"resolution" => true,
				"sampler0" => true
			];
		}

		for (i in 0...lines.length)
		{
			var trimmed:String = StringTools.trim(lines[i]);
			if (isBuiltinDeclaration(trimmed, builtins))
				lines[i] = "";
		}
		return lines.join("\n");
	}

	static function isBuiltinDeclaration(line:String, builtins:Map<String, Bool>):Bool
	{
		if (!(StringTools.startsWith(line, "uniform ") || StringTools.startsWith(line, "varying ")))
			return false;
		if (!StringTools.endsWith(line, ";"))
			return false;

		var declaration:String = line.substr(0, line.length - 1);
		var parts:Array<String> = declaration.split(" ");
		if (parts.length < 3)
			return false;

		var name:String = parts[parts.length - 1];
		var bracket:Int = name.indexOf("[");
		if (bracket != -1)
			name = name.substr(0, bracket);
		return builtins.exists(name);
	}

	static function replaceTexture2DBiasCalls(source:String):String
	{
		var code:String = source;
		var search:String = "texture2D(";
		var index:Int = code.indexOf(search);
		while (index != -1)
		{
			var startArgs:Int = index + search.length;
			var end:Int = findMatchingParen(code, startArgs - 1);
			if (end == -1)
				break;

			var args:String = code.substr(startArgs, end - startArgs);
			var split:Array<String> = splitTopLevelArgs(args);
			if (split.length >= 2)
			{
				var sampler:String = StringTools.trim(split[0]);
				var coord:String = StringTools.trim(split[1]);
				var functionName:String = sampler == "bitmap" ? "flixel_texture2D" : "texture2D";
				var replacement:String = functionName + "(" + sampler + ", " + coord + ")";
				code = code.substr(0, index) + replacement + code.substr(end + 1);
				index = code.indexOf(search, index + replacement.length);
			}
			else
				index = code.indexOf(search, end + 1);
		}
		return code;
	}

	static function splitTopLevelArgs(args:String):Array<String>
	{
		var result:Array<String> = [];
		var depth:Int = 0;
		var start:Int = 0;
		for (i in 0...args.length)
		{
			var char:String = args.charAt(i);
			switch (char)
			{
				case "(":
					depth++;
				case ")":
					if (depth > 0)
						depth--;
				case ",":
					if (depth == 0)
					{
						result.push(args.substr(start, i - start));
						start = i + 1;
					}
				default:
			}
		}
		result.push(args.substr(start));
		return result;
	}

	static function findMatchingParen(source:String, openIndex:Int):Int
	{
		var depth:Int = 0;
		for (i in openIndex...source.length)
		{
			var char:String = source.charAt(i);
			if (char == "(")
				depth++;
			else if (char == ")")
			{
				depth--;
				if (depth == 0)
					return i;
			}
		}
		return -1;
	}

	static function normalizeStrictConstructors(source:String):String
	{
		var code:String = source;
		for (typeName in ["mat2", "mat3", "mat4", "vec2", "vec3", "vec4"])
		{
			code = code.replace(typeName + "(0)", typeName + "(0.0)");
			code = code.replace(typeName + "(1)", typeName + "(1.0)");
		}
		return code;
	}

	static function hasAny(source:String, needles:Array<String>):Bool
	{
		for (needle in needles)
			if (source.indexOf(needle) != -1)
				return true;
		return false;
	}

	static function replaceWord(source:String, word:String, replacement:String):String
	{
		var reg:EReg = new EReg("\\b" + word + "\\b", "g");
		return reg.replace(source, replacement);
	}
}

