package psychlua.actorframe;

#if LUA_ALLOWED
import backend.ClientPrefs;
import backend.CoolUtil;
import backend.MusicBeatState;
import backend.Paths;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import psychlua.FunkinLua;
import psychlua.LuaUtils;
import psychlua.ModchartSprite;

class ActorFrameBackend
{
	public static inline var PREFIX:String = "actorframe.";

	static var tweenCounter:Int = 0;

	public static function createActor(kind:String, tag:String, ?parentTag:String = null, ?texture:String = null, ?text:String = null,
			?camera:String = "hud", ?width:Float = 1, ?height:Float = 1, ?color:String = "FFFFFF"):Bool
	{
		tag = cleanTag(tag);
		parentTag = cleanNullableTag(parentTag);
		if (tag == null || tag.length == 0)
			return false;

		destroySingle(tag);

		var actorKind:String = kind == null ? "actorframe" : kind.toLowerCase().trim();
		var actor:FlxSprite = null;
		switch (actorKind)
		{
			case "actorframe" | "frame":
				actor = new FlxSpriteGroup();
			case "actorproxy" | "proxy":
				actor = new ActorFrameProxy();
			case "actorframetexture" | "aft":
				actor = new ActorFrameTextureSource(Std.int(Math.max(1, width)), Std.int(Math.max(1, height)));
				actor.visible = false;
			case "quad":
				var spr = new ModchartSprite();
				spr.makeGraphic(Std.int(Math.max(1, width)), Std.int(Math.max(1, height)), CoolUtil.colorFromString(color));
				actor = spr;
			case "text" | "bitmaptext":
				var label = new FlxText(0, 0, width > 1 ? width : 0, text == null ? "" : text, 16);
				label.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				label.borderSize = 1.25;
				actor = label;
			default:
				var spr = new ModchartSprite();
				if (texture != null && texture.length > 0)
					loadActorTexture(spr, texture);
				actor = spr;
		}

		if (actor == null)
			return false;

		actor.active = true;
		actor.antialiasing = ClientPrefs.data.antialiasing;
		applyCamera(actor, camera);
		MusicBeatState.getVariables().set(tag, actor);

		if (parentTag != null && parentTag.length > 0)
		{
			var parent:Dynamic = MusicBeatState.getVariables().get(parentTag);
			if (Std.isOfType(parent, FlxSpriteGroup))
			{
				var group:FlxSpriteGroup = cast parent;
				group.add(actor);
				return true;
			}
		}

		var target:Dynamic = LuaUtils.getTargetInstance();
		if (target != null && Reflect.hasField(target, "add"))
			Reflect.callMethod(target, Reflect.field(target, "add"), [actor]);
		return true;
	}

	public static function destroyActorTree(tag:String):Bool
	{
		tag = cleanTag(tag);
		if (tag == null || tag.length == 0)
			return false;

		var variables = MusicBeatState.getVariables();
		var keys:Array<String> = [];
		for (key in variables.keys())
			if (key == tag || key.startsWith(tag + "."))
				keys.push(key);

		keys.sort(function(a, b) return b.length - a.length);
		var destroyed:Bool = false;
		for (key in keys)
		{
			destroySingle(key);
			destroyed = true;
		}
		return destroyed;
	}

	static function destroySingle(tag:String):Void
	{
		var variables = MusicBeatState.getVariables();
		var obj:Dynamic = variables.get(tag);
		if (obj == null)
		{
			variables.remove(tag);
			return;
		}

		if (Std.isOfType(obj, FlxBasic))
		{
			var basic:FlxBasic = cast obj;
			var target:Dynamic = LuaUtils.getTargetInstance();
			if (target != null && Reflect.hasField(target, "remove"))
				try Reflect.callMethod(target, Reflect.field(target, "remove"), [basic, true]) catch (_:Dynamic) {}
			try basic.destroy() catch (_:Dynamic) {}
		}
		variables.remove(tag);
	}

	public static function setActorProperty(tag:String, property:String, value:Dynamic):Bool
	{
		var actor:Dynamic = getActorVariable(tag);
		if (actor == null || property == null)
			return false;

		switch (property.toLowerCase().trim())
		{
			case "x":
				actor.x = toFloat(value, actor.x);
			case "y":
				actor.y = toFloat(value, actor.y);
			case "z":
				Reflect.setField(actor, "z", toFloat(value, 0));
			case "angle" | "rotationz":
				actor.angle = toFloat(value, actor.angle);
			case "rotationx" | "rotationy":
				Reflect.setProperty(actor, property.toLowerCase().trim(), toFloat(value, 0));
			case "alpha" | "diffusealpha":
				actor.alpha = toFloat(value, actor.alpha);
			case "visible":
				actor.visible = toBool(value, actor.visible);
			case "hidden":
				actor.visible = !toBool(value, !actor.visible);
			case "zoom" | "basezoom":
				var zoom = toFloat(value, 1);
				actor.scale.set(zoom, zoom);
			case "zoomx" | "scalex" | "basezoomx":
				actor.scale.x = toFloat(value, actor.scale.x);
			case "zoomy" | "scaley" | "basezoomy":
				actor.scale.y = toFloat(value, actor.scale.y);
			case "aux":
				Reflect.setField(actor, "__actorFrameAux", toFloat(value, 0));
			case "width":
				if (Std.isOfType(actor, ActorFrameTextureSource))
				{
					var aft:ActorFrameTextureSource = cast actor;
					aft.resizeTexture(Std.int(Math.max(1, toFloat(value, aft.renderWidth))), aft.renderHeight);
				}
				else
					actor.width = toFloat(value, actor.width);
			case "height":
				if (Std.isOfType(actor, ActorFrameTextureSource))
				{
					var aft:ActorFrameTextureSource = cast actor;
					aft.resizeTexture(aft.renderWidth, Std.int(Math.max(1, toFloat(value, aft.renderHeight))));
				}
				else
					actor.height = toFloat(value, actor.height);
			case "blend":
				actor.blend = LuaUtils.blendModeFromString(Std.string(value));
			case "camera":
				applyCamera(cast actor, Std.string(value));
			case "text":
				if (Std.isOfType(actor, FlxText))
				{
					var label:FlxText = cast actor;
					label.text = Std.string(value);
				}
			case "texture":
				if (Std.isOfType(actor, FlxSprite))
					return loadActorTexture(cast actor, Std.string(value));
			case "target":
				if (Std.isOfType(actor, ActorFrameTextureSource))
				{
					var aft:ActorFrameTextureSource = cast actor;
					aft.setTarget(Std.string(value));
				}
				else if (Std.isOfType(actor, ActorFrameProxy))
				{
					var proxy:ActorFrameProxy = cast actor;
					proxy.setTarget(resolveTarget(Std.string(value)), Std.string(value));
				}
			case "capturetarget" | "capturesource":
				if (Std.isOfType(actor, ActorFrameTextureSource))
				{
					var aft:ActorFrameTextureSource = cast actor;
					aft.setTarget(Std.string(value));
				}
			case "capturemode" | "capture":
				if (Std.isOfType(actor, ActorFrameTextureSource))
				{
					var aft:ActorFrameTextureSource = cast actor;
					aft.captureMode = Std.string(value).toLowerCase().trim();
				}
			case "captureeveryframe" | "updateeveryframe":
				if (Std.isOfType(actor, ActorFrameTextureSource))
				{
					var aft:ActorFrameTextureSource = cast actor;
					aft.captureEveryFrame = toBool(value, aft.captureEveryFrame);
				}
			case "captureinterval" | "updateinterval":
				if (Std.isOfType(actor, ActorFrameTextureSource))
				{
					var aft:ActorFrameTextureSource = cast actor;
					aft.captureInterval = Math.max(0, toFloat(value, aft.captureInterval));
				}
			case "followtarget" | "followtransform":
				if (Std.isOfType(actor, ActorFrameProxy))
				{
					var proxy:ActorFrameProxy = cast actor;
					proxy.followTransform = toBool(value, proxy.followTransform);
				}
			case "followvisuals":
				if (Std.isOfType(actor, ActorFrameProxy))
				{
					var proxy:ActorFrameProxy = cast actor;
					proxy.followVisuals = toBool(value, proxy.followVisuals);
				}
			case "color" | "diffuse":
				actor.color = CoolUtil.colorFromString(Std.string(value));
			default:
				Reflect.setProperty(actor, property, value);
		}
		return true;
	}

	public static function getActorProperty(tag:String, property:String):Dynamic
	{
		var actor:Dynamic = getActorVariable(tag);
		if (actor == null || property == null)
			return null;

		switch (property.toLowerCase().trim())
		{
			case "x":
				return actor.x;
			case "y":
				return actor.y;
			case "z":
				return Reflect.field(actor, "z");
			case "angle" | "rotationz":
				return actor.angle;
			case "rotationx" | "rotationy":
				return Reflect.field(actor, property.toLowerCase().trim());
			case "alpha" | "diffusealpha":
				return actor.alpha;
			case "visible":
				return actor.visible;
			case "hidden":
				return !actor.visible;
			case "zoom":
				return actor.scale.x;
			case "zoomx" | "scalex" | "basezoomx":
				return actor.scale.x;
			case "zoomy" | "scaley" | "basezoomy":
				return actor.scale.y;
			case "width":
				return actor.width;
			case "height":
				return actor.height;
			case "aux":
				var value:Dynamic = Reflect.field(actor, "__actorFrameAux");
				return value == null ? 0 : value;
			default:
				return Reflect.getProperty(actor, property);
		}
	}

	public static function loadActorTexture(sprite:FlxSprite, texture:String):Bool
	{
		if (sprite == null || texture == null || texture.length == 0)
			return false;

		var source:Dynamic = getActorVariable(texture);
		if (Std.isOfType(source, ActorFrameTextureSource))
		{
			var sourceTexture:ActorFrameTextureSource = cast source;
			if (sourceTexture.graphic != null)
			{
				sprite.loadGraphic(sourceTexture.graphic);
				sprite.setGraphicSize(sourceTexture.renderWidth, sourceTexture.renderHeight);
				sprite.updateHitbox();
				sourceTexture.addConsumer(sprite);
				return true;
			}
		}

		if (Std.isOfType(source, FlxSprite))
		{
			var sourceSprite:FlxSprite = cast source;
			if (sourceSprite.graphic != null)
			{
				sprite.loadGraphic(sourceSprite.graphic);
				sprite.setGraphicSize(Std.int(Math.max(1, sourceSprite.width)), Std.int(Math.max(1, sourceSprite.height)));
				sprite.updateHitbox();
				return true;
			}
		}

		try
		{
			sprite.loadGraphic(Paths.image(texture));
			return true;
		}
		catch (_:Dynamic)
		{
			return false;
		}
	}

	public static function setActorColor(tag:String, r:Dynamic, ?g:Dynamic = null, ?b:Dynamic = null, ?a:Dynamic = null):Bool
	{
		var actor:Dynamic = getActorVariable(tag);
		if (actor == null)
			return false;

		if (g == null && b == null)
		{
			actor.color = CoolUtil.colorFromString(Std.string(r));
		}
		else
		{
			var red:Int = colorChannel(r);
			var green:Int = colorChannel(g);
			var blue:Int = colorChannel(b);
			actor.color = FlxColor.fromRGB(red, green, blue);
			if (a != null)
				actor.alpha = toFloat(a, actor.alpha);
		}
		return true;
	}

	public static function setActorProxyTarget(tag:String, targetTag:String):Bool
	{
		var actor:Dynamic = getActorVariable(tag);
		if (Std.isOfType(actor, ActorFrameTextureSource))
		{
			var texture:ActorFrameTextureSource = cast actor;
			texture.setTarget(targetTag);
			return true;
		}

		if (Std.isOfType(actor, ActorFrameProxy))
		{
			var proxy:ActorFrameProxy = cast actor;
			return proxy.setTarget(resolveTarget(targetTag), targetTag);
		}
		return false;
	}

	public static function captureActorFrameTexture(tag:String):Bool
	{
		var actor:Dynamic = getActorVariable(tag);
		if (!Std.isOfType(actor, ActorFrameTextureSource))
			return false;

		var texture:ActorFrameTextureSource = cast actor;
		return texture.captureNow();
	}

	public static function tweenActorProperty(tag:String, property:String, value:Dynamic, ?duration:Float = 0, ?ease:String = "linear",
			?delay:Float = 0):Bool
	{
		var actor:Dynamic = getActorVariable(tag);
		if (actor == null || property == null)
			return false;

		if (duration <= 0 && delay <= 0)
			return setActorProperty(tag, property, value);

		var prop = property.toLowerCase().trim();
		var target:Dynamic = actor;
		var values:Dynamic = {};

		switch (prop)
		{
			case "zoom" | "basezoom":
				target = actor.scale;
				Reflect.setField(values, "x", toFloat(value, actor.scale.x));
				Reflect.setField(values, "y", toFloat(value, actor.scale.y));
			case "zoomx" | "scalex" | "basezoomx":
				target = actor.scale;
				Reflect.setField(values, "x", toFloat(value, actor.scale.x));
			case "zoomy" | "scaley" | "basezoomy":
				target = actor.scale;
				Reflect.setField(values, "y", toFloat(value, actor.scale.y));
			case "rotationz":
				Reflect.setField(values, "angle", value);
			case "rotationx" | "rotationy" | "aux":
				return setActorProperty(tag, property, value);
			case "diffusealpha":
				Reflect.setField(values, "alpha", value);
			case "x" | "y" | "angle" | "alpha":
				Reflect.setField(values, prop, value);
			default:
				return setActorProperty(tag, property, value);
		}

		tweenCounter++;
		var tweenTag = 'actorframe_${cleanTag(tag).replace(".", "_")}_$tweenCounter';
		var tween = FlxTween.tween(target, values, duration, {
			ease: LuaUtils.getTweenEaseByString(ease),
			startDelay: Math.max(0, delay),
			onComplete: function(_)
			{
				LuaUtils.removeTween(tweenTag);
			}
		});
		LuaUtils.storeTween(tweenTag, tween);
		return true;
	}

	public static function cancelActorTweens(tag:String, ?finish:Bool = false):Bool
	{
		var actor:Dynamic = getActorVariable(tag);
		if (actor == null)
			return false;

		if (finish)
		{
			try FlxTween.completeTweensOf(actor) catch (_:Dynamic) {}
			try FlxTween.completeTweensOf(actor.scale) catch (_:Dynamic) {}
		}
		else
		{
			try FlxTween.cancelTweensOf(actor) catch (_:Dynamic) {}
			try FlxTween.cancelTweensOf(actor.scale) catch (_:Dynamic) {}
		}
		return true;
	}

	public static function setActorShader(funk:FunkinLua, tag:String, shader:String):Bool
	{
		if (!ClientPrefs.data.shaders)
			return false;

		#if (!flash && sys)
		var actor:Dynamic = getActorVariable(tag);
		if (actor == null || shader == null || shader.length == 0)
			return false;

		var shaderValue:Dynamic = MusicBeatState.getVariables().get(shader);
		if (!Std.isOfType(shaderValue, flixel.addons.display.FlxRuntimeShader))
		{
			if (shaders.ErrorHandledShader.isBroken(shader))
				return false;
			if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
				return false;

			var data:Array<String> = funk.runtimeShaders.get(shader);
			var runtime = new shaders.ErrorHandledShader.ErrorHandledRuntimeShader(shader, data[0], data[1]);
			if (runtime.failed || shaders.ErrorHandledShader.isBroken(shader))
				return false;
			shaderValue = runtime;
		}

		actor.shader = shaderValue;
		return true;
		#else
		return false;
		#end
	}

	public static function resolveTarget(targetTag:String):Dynamic
	{
		if (targetTag == null || targetTag.length == 0)
			return null;

		var cleaned = cleanTag(targetTag);
		var value:Dynamic = getActorVariable(cleaned);
		if (value != null)
			return value;

		return LuaUtils.getObjectDirectly(targetTag);
	}

	public static function getActorVariable(tag:String):Dynamic
	{
		var cleaned = cleanTag(tag);
		if (cleaned == null || cleaned.length == 0)
			return null;

		var variables = MusicBeatState.getVariables();
		if (variables.exists(cleaned))
			return variables.get(cleaned);

		if (cleaned.startsWith(PREFIX))
			return null;

		var suffix = "." + cleaned;
		for (key in variables.keys())
			if (key.startsWith(PREFIX) && key.endsWith(suffix))
				return variables.get(key);

		return null;
	}

	public static function cleanTag(tag:String):String
	{
		if (tag == null)
			return null;
		tag = tag.trim();
		if (!tag.startsWith(PREFIX))
			return tag.replace(" ", "_");

		var out = new StringBuf();
		for (i in 0...tag.length)
		{
			var code = tag.charCodeAt(i);
			var valid = (code >= "A".code && code <= "Z".code)
				|| (code >= "a".code && code <= "z".code)
				|| (code >= "0".code && code <= "9".code)
				|| tag.charAt(i) == "_"
				|| tag.charAt(i) == "-"
				|| tag.charAt(i) == ".";
			out.add(valid ? tag.charAt(i) : "_");
		}
		return out.toString();
	}

	static function applyCamera(actor:FlxSprite, ?camera:String = "hud"):Void
	{
		if (actor == null)
			return;
		var camName = camera == null || camera.length == 0 ? "hud" : camera;
		actor.cameras = [LuaUtils.cameraFromString(camName)];
		switch (camName.toLowerCase())
		{
			case "hud" | "camhud" | "other" | "camother":
				actor.scrollFactor.set();
			default:
		}
	}

	static function cleanNullableTag(tag:String):String
	{
		if (tag == null || tag.length == 0 || tag == "nil")
			return null;
		return cleanTag(tag);
	}

	static function toFloat(value:Dynamic, fallback:Float):Float
	{
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
			return value;
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	static function toBool(value:Dynamic, fallback:Bool):Bool
	{
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Bool))
			return value;
		var text = Std.string(value).toLowerCase().trim();
		return text == "true" || text == "1" || text == "yes" || text == "on";
	}

	static function colorChannel(value:Dynamic):Int
	{
		var channel = Std.int(toFloat(value, 1));
		if (channel <= 1)
			channel = Std.int(channel * 255);
		return Std.int(FlxMath.bound(channel, 0, 255));
	}
}
#end
