package psychlua;

#if LUA_ALLOWED
import flixel.FlxBasic;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class ActorFrameFunctions
{
	static inline var PREFIX:String = "actorframe.";

	public static function implement(funk:FunkinLua):Void
	{
		var lua = funk.lua;

		Lua_helper.add_callback(lua, "_actorFrameCreate",
			function(kind:String, tag:String, ?parentTag:String = null, ?texture:String = null, ?text:String = null, ?camera:String = "hud",
					?width:Float = 1, ?height:Float = 1, ?color:String = "FFFFFF")
			{
				return createActor(kind, tag, parentTag, texture, text, camera, width, height, color);
			});

		Lua_helper.add_callback(lua, "_actorFrameDestroy", function(tag:String)
		{
			return destroyActorTree(tag);
		});

		Lua_helper.add_callback(lua, "_actorFrameSet", function(tag:String, property:String, value:Dynamic)
		{
			return setActorProperty(tag, property, value);
		});

		Lua_helper.add_callback(lua, "_actorFrameSetColor", function(tag:String, r:Dynamic, ?g:Dynamic = null, ?b:Dynamic = null, ?a:Dynamic = null)
		{
			return setActorColor(tag, r, g, b, a);
		});

		Lua_helper.add_callback(lua, "_actorFrameTween",
			function(tag:String, property:String, value:Dynamic, ?duration:Float = 0, ?ease:String = "linear", ?delay:Float = 0)
			{
				return tweenActorProperty(tag, property, value, duration, ease, delay);
			});

		Lua_helper.add_callback(lua, "_actorFrameSetShader", function(tag:String, shader:String)
		{
			return setActorShader(funk, tag, shader);
		});

		Lua_helper.add_callback(lua, "_actorFrameSetTarget", function(tag:String, targetTag:String)
		{
			return setActorProxyTarget(tag, targetTag);
		});

		Lua_helper.add_callback(lua, "_actorFrameCapture", function(tag:String)
		{
			return captureActorFrameTexture(tag);
		});

		Lua_helper.add_callback(lua, "_actorFrameExists", function(tag:String)
		{
			return MusicBeatState.getVariables().exists(tag);
		});

		runLuaChunk(funk, prelude(), "ActorFrame prelude");
	}

	public static function installHooks(funk:FunkinLua):Void
	{
		runLuaChunk(funk, hookInstaller(), "ActorFrame hooks");
	}

	static function createActor(kind:String, tag:String, ?parentTag:String = null, ?texture:String = null, ?text:String = null, ?camera:String = "hud",
			?width:Float = 1, ?height:Float = 1, ?color:String = "FFFFFF"):Bool
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
				label.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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

	static function destroyActorTree(tag:String):Bool
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

	static function setActorProperty(tag:String, property:String, value:Dynamic):Bool
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
			case "alpha" | "diffusealpha":
				actor.alpha = toFloat(value, actor.alpha);
			case "visible":
				actor.visible = toBool(value, actor.visible);
			case "zoom":
				var zoom = toFloat(value, 1);
				actor.scale.set(zoom, zoom);
			case "zoomx" | "scalex":
				actor.scale.x = toFloat(value, actor.scale.x);
			case "zoomy" | "scaley":
				actor.scale.y = toFloat(value, actor.scale.y);
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

	static function loadActorTexture(sprite:FlxSprite, texture:String):Bool
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

	static function setActorColor(tag:String, r:Dynamic, ?g:Dynamic = null, ?b:Dynamic = null, ?a:Dynamic = null):Bool
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

	static function setActorProxyTarget(tag:String, targetTag:String):Bool
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

	static function captureActorFrameTexture(tag:String):Bool
	{
		var actor:Dynamic = getActorVariable(tag);
		if (!Std.isOfType(actor, ActorFrameTextureSource))
			return false;

		var texture:ActorFrameTextureSource = cast actor;
		return texture.captureNow();
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

	static var tweenCounter:Int = 0;

	static function tweenActorProperty(tag:String, property:String, value:Dynamic, ?duration:Float = 0, ?ease:String = "linear", ?delay:Float = 0):Bool
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
			case "zoom":
				target = actor.scale;
				Reflect.setField(values, "x", toFloat(value, actor.scale.x));
				Reflect.setField(values, "y", toFloat(value, actor.scale.y));
			case "zoomx" | "scalex":
				target = actor.scale;
				Reflect.setField(values, "x", toFloat(value, actor.scale.x));
			case "zoomy" | "scaley":
				target = actor.scale;
				Reflect.setField(values, "y", toFloat(value, actor.scale.y));
			case "rotationz":
				Reflect.setField(values, "angle", value);
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

	static function setActorShader(funk:FunkinLua, tag:String, shader:String):Bool
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

	static function cleanTag(tag:String):String
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

	static function runLuaChunk(funk:FunkinLua, code:String, label:String):Bool
	{
		if (funk == null || funk.lua == null)
			return false;
		var result:Int = LuaL.dostring(funk.lua, code);
		if (result != 0)
		{
			var msg:String = Lua.tostring(funk.lua, -1);
			FunkinLua.luaTrace('$label failed: $msg', false, false, FlxColor.RED);
			Lua.pop(funk.lua, 1);
			return false;
		}
		return true;
	}

	static function prelude():String
	{
		return [
			"Def = Def or {}",
			"ActorFrame = ActorFrame or { Roots = {}, Actors = {}, _counter = 0, _tweenCounter = 0 }",
			"local AF = ActorFrame",
			"local function sanitize(name)",
			"  name = tostring(name or '')",
			"  name = name:gsub('^%s+', ''):gsub('%s+$', '')",
			"  if name == '' then name = 'actor' .. tostring(AF._counter + 1) end",
			"  return (name:gsub('[^%w_%-]', '_'))",
			"end",
			"local function def(kind)",
			"  return function(t)",
			"    t = t or {}",
			"    t.__ActorFrameKind = kind",
			"    return t",
			"  end",
			"end",
			"Def.ActorFrame = Def.ActorFrame or def('ActorFrame')",
			"Def.Sprite = Def.Sprite or def('Sprite')",
			"Def.Quad = Def.Quad or def('Quad')",
			"Def.Text = Def.Text or def('Text')",
			"Def.ActorProxy = Def.ActorProxy or def('ActorProxy')",
			"Def.ActorFrameTexture = Def.ActorFrameTexture or def('ActorFrameTexture')",
			"Def.ProxyWall = Def.ProxyWall or function(t)",
			"  t = t or {}",
			"  local count = tonumber(t.Count or t.count or 24) or 24",
			"  local spacing = tonumber(t.Spacing or t.spacing or 256) or 256",
			"  local startX = tonumber(t.StartX or t.startX or 500) or 500",
			"  local texture = t.Texture or t.texture or t.File or t.file",
			"  local root = { Name = t.Name or 'proxwall', Camera = t.Camera or t.camera or 'hud', __ActorFrameKind = 'ActorFrame', __ActorFrameProxyWall = true }",
			"  for i = 1, count do",
			"    root[#root + 1] = Def.Sprite { Name = 'proxy' .. tostring(i), Texture = texture, X = startX - spacing * i, Y = t.Y or t.y or 0, Alpha = t.Alpha or t.alpha or 1, Visible = t.Visible ~= false, Blend = t.Blend or t.blend }",
			"  end",
			"  return root",
			"end",
			"local methods = {}",
			"local function setImmediate(self, prop, value)",
			"  _actorFrameSet(self.Tag, prop, value)",
			"end",
			"local function tween(self, values)",
			"  if self._duration and (self._duration > 0 or self._delay > 0) then",
			"    for k, v in pairs(values) do _actorFrameTween(self.Tag, k, v, self._duration or 0, self._ease or 'linear', self._delay or 0) end",
			"    self._delay = (self._delay or 0) + (self._duration or 0)",
			"  else",
			"    for k, v in pairs(values) do setImmediate(self, k, v) end",
			"  end",
			"  return self",
			"end",
			"function methods:sleep(t) self._delay = (self._delay or 0) + (tonumber(t) or 0); return self end",
			"function methods:linear(t) self._duration = tonumber(t) or 0; self._ease = 'linear'; return self end",
			"function methods:decelerate(t) self._duration = tonumber(t) or 0; self._ease = 'decelerate'; return self end",
			"function methods:accelerate(t) self._duration = tonumber(t) or 0; self._ease = 'accelerate'; return self end",
			"function methods:x(v) return tween(self, {x = v}) end",
			"function methods:y(v) return tween(self, {y = v}) end",
			"function methods:xy(x, y) return tween(self, {x = x, y = y}) end",
			"function methods:zoom(v) return tween(self, {zoom = v}) end",
			"function methods:zoomx(v) return tween(self, {zoomx = v}) end",
			"function methods:zoomy(v) return tween(self, {zoomy = v}) end",
			"function methods:rotationz(v) return tween(self, {angle = v}) end",
			"function methods:diffusealpha(v) return tween(self, {alpha = v}) end",
			"function methods:visible(v) setImmediate(self, 'visible', v); return self end",
			"function methods:hidden(v) setImmediate(self, 'visible', not (v == true or v == 1)); return self end",
			"function methods:diffuse(r, g, b, a) _actorFrameSetColor(self.Tag, r, g, b, a); return self end",
			"function methods:blend(v) setBlendMode(self.Tag, v); return self end",
			"function methods:additiveblend(v) if v == nil or v then setBlendMode(self.Tag, 'add') else setBlendMode(self.Tag, 'normal') end; return self end",
			"function methods:queuecommand(name) AF.playCommand(name, self); return self end",
			"function methods:playcommand(name) AF.playCommand(name, self); return self end",
			"function methods:setshader(shader) _actorFrameSetShader(self.Tag, shader); return self end",
			"function methods:SetTarget(target) _actorFrameSetTarget(self.Tag, type(target) == 'table' and target.Tag or target); return self end",
			"function methods:target(target) return self:SetTarget(target) end",
			"function methods:SetWidth(v) setImmediate(self, 'width', v); return self end",
			"function methods:SetHeight(v) setImmediate(self, 'height', v); return self end",
			"function methods:Create() _actorFrameCapture(self.Tag); return self end",
			"function methods:GetTexture() return self.Tag end",
			"function methods:SetTexture(texture) setImmediate(self, 'texture', texture); return self end",
			"function methods:SetCaptureMode(mode) setImmediate(self, 'capturemode', mode); return self end",
			"function methods:SetCaptureInterval(seconds) setImmediate(self, 'captureinterval', seconds); return self end",
			"function methods:SetCaptureEveryFrame(enabled) setImmediate(self, 'captureeveryframe', enabled); return self end",
			"function methods:capture() _actorFrameCapture(self.Tag); return self end",
			"function methods:hibernate(t) return self:sleep(t) end",
			"local function command(spec, name)",
			"  return spec[name .. 'Command'] or spec[name]",
			"end",
			"local function run(actor, name, a, b)",
			"  if not actor then return end",
			"  local fn = command(actor.Spec or {}, name)",
			"  if type(fn) == 'function' then fn(actor, a, b) end",
			"end",
			"local function runTree(actor, name, a, b)",
			"  run(actor, name, a, b)",
			"  if actor and actor.Children then",
			"    for _, child in ipairs(actor.Children) do runTree(child, name, a, b) end",
			"  end",
			"end",
			"local function create(spec, tag, parentTag, inheritedCamera)",
			"  AF._counter = AF._counter + 1",
			"  local kind = spec.__ActorFrameKind or 'ActorFrame'",
			"  local camera = spec.Camera or spec.camera or inheritedCamera or 'hud'",
			"  local actor = { Tag = tag, Name = spec.Name or tag, Kind = kind, Spec = spec, Children = {}, _delay = 0, _duration = 0, _ease = 'linear' }",
			"  setmetatable(actor, { __index = methods })",
			"  AF.Actors[tag] = actor",
			"  if spec.Name then AF.Actors[tostring(spec.Name)] = actor; rawset(_G, tostring(spec.Name), actor) end",
			"  _actorFrameCreate(kind, tag, parentTag, spec.Texture or spec.texture or spec.File or spec.file, spec.Text or spec.text, camera, spec.Width or spec.width or 1, spec.Height or spec.height or 1, spec.Color or spec.color or 'FFFFFF')",
			"  local props = { X = 'x', Y = 'y', Z = 'z', Alpha = 'alpha', DiffuseAlpha = 'alpha', RotationZ = 'angle', Angle = 'angle', Zoom = 'zoom', ZoomX = 'zoomx', ZoomY = 'zoomy', Visible = 'visible', Blend = 'blend', FollowTarget = 'followtarget', FollowTransform = 'followtransform', FollowVisuals = 'followvisuals', Capture = 'capturemode', CaptureMode = 'capturemode', CaptureInterval = 'captureinterval', CaptureEveryFrame = 'captureeveryframe' }",
			"  for from, to in pairs(props) do if spec[from] ~= nil then _actorFrameSet(tag, to, spec[from]) end end",
			"  if spec.Target or spec.target then _actorFrameSetTarget(tag, spec.Target or spec.target) end",
			"  if kind == 'ActorFrameTexture' then _actorFrameCapture(tag) end",
			"  if spec.Diffuse then _actorFrameSetColor(tag, spec.Diffuse) end",
			"  for _, childSpec in ipairs(spec) do",
			"    local childName = sanitize(childSpec.Name or ('actor' .. tostring(#actor.Children + 1)))",
			"    local child = create(childSpec, tag .. '.' .. childName, tag, camera)",
			"    table.insert(actor.Children, child)",
			"  end",
			"  if spec.__ActorFrameProxyWall and spec.Name then rawset(_G, tostring(spec.Name), actor.Children) end",
			"  return actor",
			"end",
			"local function forgetTree(actor)",
			"  if not actor then return end",
			"  AF.Actors[actor.Tag] = nil",
			"  if actor.Name then AF.Actors[tostring(actor.Name)] = nil end",
			"  if actor.Children then for _, child in ipairs(actor.Children) do forgetTree(child) end end",
			"end",
			"function AF.get(name)",
			"  local actor = AF.Actors[name]",
			"  if actor then return actor end",
			"  local tag = tostring(name or '')",
			"  if not tag:match('^actorframe%.') then tag = 'actorframe.' .. sanitize(tag) end",
			"  return AF.Actors[tag]",
			"end",
			"function AF.load(spec, name)",
			"  if type(spec) ~= 'table' then return nil end",
			"  local rootName = sanitize(name or spec.Name or 'default')",
			"  local rootTag = 'actorframe.' .. rootName",
			"  AF.destroy(rootTag, false)",
			"  local actor = create(spec, rootTag, nil, spec.Camera or spec.camera or 'hud')",
			"  AF.Roots[rootTag] = actor",
			"  runTree(actor, 'Init')",
			"  runTree(actor, 'On')",
			"  return actor",
			"end",
			"function AF.destroy(name, runOff)",
			"  local tag = tostring(name or 'actorframe.default')",
			"  if not tag:match('^actorframe%.') then tag = 'actorframe.' .. sanitize(tag) end",
			"  local actor = AF.Roots[tag]",
			"  if runOff ~= false then runTree(actor, 'Off') end",
			"  AF.Roots[tag] = nil",
			"  forgetTree(actor)",
			"  return _actorFrameDestroy(tag)",
			"end",
			"function AF.destroyAll(runOff)",
			"  for tag, actor in pairs(AF.Roots) do if runOff ~= false then runTree(actor, 'Off') end; _actorFrameDestroy(tag); AF.Roots[tag] = nil; forgetTree(actor) end",
			"end",
			"function AF.playCommand(name, root)",
			"  name = tostring(name or ''):gsub('Command$', '')",
			"  if type(root) == 'table' and root.Tag then runTree(root, name); return true end",
			"  if root then",
			"    local tag = tostring(root)",
			"    if not tag:match('^actorframe%.') then tag = 'actorframe.' .. sanitize(tag) end",
			"    runTree(AF.Roots[tag], name)",
			"    return AF.Roots[tag] ~= nil",
			"  end",
			"  for _, actor in pairs(AF.Roots) do runTree(actor, name) end",
			"  return true",
			"end",
			"function AF.loadXML(path) debugPrint('ActorFrame.loadXML is reserved for a future XML importer: ' .. tostring(path)); return false end",
			"function AF.__update(elapsed) for _, actor in pairs(AF.Roots) do runTree(actor, 'Update', elapsed) end end",
			"function AF.__beat(beat) for _, actor in pairs(AF.Roots) do runTree(actor, 'Beat', beat) end end",
			"function AF.__step(step) for _, actor in pairs(AF.Roots) do runTree(actor, 'Step', step) end end",
			"function AF.__destroyAll() AF.destroyAll(true) end"
		].join("\n");
	}

	static function hookInstaller():String
	{
		return [
			"if ActorFrame and not ActorFrame.__hooksInstalled then",
			"  ActorFrame.__hooksInstalled = true",
			"  local oldUpdate = _G.onUpdate",
			"  _G.onUpdate = function(elapsed)",
			"    local ret = nil",
			"    if oldUpdate then ret = oldUpdate(elapsed) end",
			"    if ActorFrame.__update then ActorFrame.__update(elapsed) end",
			"    return ret or Function_Continue",
			"  end",
			"  local oldBeat = _G.onBeatHit",
			"  _G.onBeatHit = function()",
			"    local ret = nil",
			"    if oldBeat then ret = oldBeat() end",
			"    if ActorFrame.__beat then ActorFrame.__beat(curBeat) end",
			"    return ret or Function_Continue",
			"  end",
			"  local oldStep = _G.onStepHit",
			"  _G.onStepHit = function()",
			"    local ret = nil",
			"    if oldStep then ret = oldStep() end",
			"    if ActorFrame.__step then ActorFrame.__step(curStep) end",
			"    return ret or Function_Continue",
			"  end",
			"  local oldDestroy = _G.onDestroy",
			"  _G.onDestroy = function()",
			"    local ret = nil",
			"    if oldDestroy then ret = oldDestroy() end",
			"    if ActorFrame.__destroyAll then ActorFrame.__destroyAll() end",
			"    return ret or Function_Continue",
			"  end",
			"end"
		].join("\n");
	}
}

class ActorFrameProxy extends FlxSprite
{
	public var targetTag:String;
	public var target:FlxSprite;
	public var followTransform:Bool = false;
	public var followVisuals:Bool = true;

	public function new()
	{
		super();
		active = true;
	}

	public function setTarget(value:Dynamic, ?tag:String):Bool
	{
		targetTag = tag;
		target = Std.isOfType(value, FlxSprite) ? cast value : null;
		if (target == null)
			return false;

		copyTargetVisuals();
		if (followTransform)
			copyTargetTransform();
		return true;
	}

	override public function update(elapsed:Float):Void
	{
		if (targetTag != null)
		{
			var resolved:Dynamic = ActorFrameFunctions.getActorVariable(targetTag);
			if (resolved == null)
				resolved = LuaUtils.getObjectDirectly(targetTag);
			if (Std.isOfType(resolved, FlxSprite) && resolved != target)
				target = cast resolved;
		}

		if (target != null)
		{
			if (followVisuals)
				copyTargetVisuals();
			if (followTransform)
				copyTargetTransform();
		}
		super.update(elapsed);
	}

	function copyTargetVisuals():Void
	{
		if (target == null)
			return;

		if (target.frames != null && frames != target.frames)
			frames = target.frames;
		else if (target.graphic != null && graphic != target.graphic)
			loadGraphic(target.graphic);

		if (target.animation != null && target.animation.curAnim != null && animation != null)
		{
			var animName = target.animation.curAnim.name;
			if (animation.getByName(animName) != null)
				animation.play(animName, true, false, target.animation.curAnim.curFrame);
		}

		frame = target.frame;
		origin.copyFrom(target.origin);
		offset.copyFrom(target.offset);
		antialiasing = target.antialiasing;
	}

	function copyTargetTransform():Void
	{
		if (target == null)
			return;

		x = target.x;
		y = target.y;
		angle = target.angle;
		alpha = target.alpha;
		visible = target.visible;
		scale.copyFrom(target.scale);
		scrollFactor.copyFrom(target.scrollFactor);
		color = target.color;
		flipX = target.flipX;
		flipY = target.flipY;
		blend = target.blend;
		shader = target.shader;
	}
}

class ActorFrameTextureSource extends FlxSprite
{
	static var textureCounter:Int = 0;

	public var renderWidth:Int = 1;
	public var renderHeight:Int = 1;
	public var preserveTexture:Bool = true;
	public var targetTag:String = "hud";
	public var captureMode:String = "camera";
	public var captureEveryFrame:Bool = false;
	public var captureInterval:Float = 0;

	var captureTimer:Float = 0;
	var consumers:Array<FlxSprite> = [];
	var drawMatrix:Matrix = new Matrix();
	var drawRect:Rectangle = new Rectangle();
	var drawPoint:Point = new Point();

	public function new(width:Int, height:Int)
	{
		super();
		resizeTexture(width, height);
		active = true;
		visible = false;
	}

	public function resizeTexture(width:Int, height:Int):Void
	{
		renderWidth = Std.int(Math.max(1, width));
		renderHeight = Std.int(Math.max(1, height));
		textureCounter++;
		makeGraphic(renderWidth, renderHeight, FlxColor.TRANSPARENT, true, 'actorframe_texture_$textureCounter');
		useFramePixels = false;
		dirty = true;
		markConsumersDirty();
	}

	public function setTarget(value:String):Void
	{
		if (value == null || value.length == 0)
			return;
		targetTag = value;
	}

	public function addConsumer(sprite:FlxSprite):Void
	{
		if (sprite == null || consumers.indexOf(sprite) >= 0)
			return;
		consumers.push(sprite);
		sprite.useFramePixels = false;
		sprite.dirty = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!captureEveryFrame)
			return;

		captureTimer += elapsed;
		if (captureInterval > 0 && captureTimer < captureInterval)
			return;

		captureTimer = 0;
		captureNow();
	}

	public function captureNow():Bool
	{
		if (pixels == null)
			resizeTexture(renderWidth, renderHeight);

		var bmp:BitmapData = pixels;
		if (bmp == null)
			return false;

		drawRect.setTo(0, 0, renderWidth, renderHeight);
		bmp.fillRect(drawRect, FlxColor.TRANSPARENT);

		var ok:Bool = false;
		switch (captureMode == null ? "camera" : captureMode.toLowerCase().trim())
		{
			case "sprite" | "actor" | "object":
				ok = captureSprite(ActorFrameFunctions.resolveTarget(targetTag), bmp);
			case "auto":
				var target:Dynamic = ActorFrameFunctions.getActorVariable(targetTag);
				if (target != null && Std.isOfType(target, FlxSprite))
					ok = captureSprite(target, bmp);
				else
					ok = captureCamera(resolveCameraTarget(), bmp);
			default:
				ok = captureCamera(resolveCameraTarget(), bmp);
		}

		if (ok)
		{
			pixels = bmp;
			dirty = true;
			markConsumersDirty();
		}
		return ok;
	}

	function captureCamera(camera:FlxCamera, target:BitmapData):Bool
	{
		if (camera == null)
			return false;

		if (FlxG.renderBlit && camera.buffer != null)
		{
			drawRect.setTo(0, 0, Math.min(renderWidth, camera.buffer.width), Math.min(renderHeight, camera.buffer.height));
			target.copyPixels(camera.buffer, drawRect, drawPoint, null, null, true);
			return true;
		}

		if (camera.flashSprite == null)
			return false;

		var sourceWidth = Math.max(1, camera.width * camera.initialZoom * FlxG.scaleMode.scale.x);
		var sourceHeight = Math.max(1, camera.height * camera.initialZoom * FlxG.scaleMode.scale.y);
		drawMatrix.setTo(renderWidth / sourceWidth, 0, 0, renderHeight / sourceHeight, renderWidth * 0.5, renderHeight * 0.5);

		try
		{
			target.draw(camera.flashSprite, drawMatrix, null, null, drawRect, true);
			return true;
		}
		catch (_:Dynamic)
		{
			return false;
		}
	}

	function captureSprite(value:Dynamic, target:BitmapData):Bool
	{
		if (!Std.isOfType(value, FlxSprite))
			return false;

		var sprite:FlxSprite = cast value;
		if (sprite.frame != null)
		{
			sprite.frame.paint(target, drawPoint, true, false);
			return true;
		}

		if (sprite.pixels != null)
		{
			drawRect.setTo(0, 0, Math.min(renderWidth, sprite.pixels.width), Math.min(renderHeight, sprite.pixels.height));
			target.copyPixels(sprite.pixels, drawRect, drawPoint, null, null, true);
			return true;
		}
		return false;
	}

	function resolveCameraTarget():FlxCamera
	{
		var target:Dynamic = ActorFrameFunctions.getActorVariable(targetTag);
		if (target != null && Std.isOfType(target, FlxCamera))
			return cast target;
		return LuaUtils.cameraFromString(targetTag);
	}

	function markConsumersDirty():Void
	{
		var alive:Array<FlxSprite> = [];
		for (sprite in consumers)
		{
			if (sprite != null && sprite.exists)
			{
				sprite.dirty = true;
				alive.push(sprite);
			}
		}
		consumers = alive;
	}

	override public function destroy():Void
	{
		consumers = [];
		super.destroy();
	}
}
#end
