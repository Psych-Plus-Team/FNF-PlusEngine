package psychlua;

class Mesh3DFunctions
{
	public static function implement(funk:FunkinLua):Void
	{
		var lua:State = funk.lua;

		Lua_helper.add_callback(lua, "is3DMeshAvailable", function()
		{
			return Mesh3DRenderer.available();
		});

		#if AWAY3D_ALLOWED
		var owner:String = funk.scriptName;

		Lua_helper.add_callback(lua, "init3DMeshView", function(?visible:Bool = true)
		{
			return Mesh3DRenderer.ensureView(visible);
		});

		Lua_helper.add_callback(lua, "set3DViewVisible", function(visible:Bool)
		{
			return Mesh3DRenderer.setViewVisible(visible);
		});

		Lua_helper.add_callback(lua, "set3DViewBackground", function(color:Int = 0x000000, alpha:Float = 0)
		{
			return Mesh3DRenderer.setViewBackground(color, alpha);
		});

		Lua_helper.add_callback(lua, "set3DCam", function(x:Float = 0, y:Float = 0, z:Float = -1000, lookX:Float = 0, lookY:Float = 0,
				lookZ:Float = 0)
		{
			return Mesh3DRenderer.setCamera(x, y, z, lookX, lookY, lookZ);
		});

		Lua_helper.add_callback(lua, "make3DFloor", function(tag:String, width:Float = 1800, depth:Float = 2200, y:Float = 280,
				z:Float = 300, color:Int = 0x202A3A, alpha:Float = 1)
		{
			return Mesh3DRenderer.makeFloor(tag, width, depth, y, z, color, alpha, owner);
		});

		Lua_helper.add_callback(lua, "make3DPlane", function(tag:String, width:Float = 100, height:Float = 100, color:Int = 0xFFFFFF,
				alpha:Float = 1, ?yUp:Bool = false)
		{
			return Mesh3DRenderer.makePlane(tag, width, height, color, alpha, owner, yUp);
		});

		Lua_helper.add_callback(lua, "make3DCube", function(tag:String, width:Float = 100, height:Float = 100, depth:Float = 100,
				color:Int = 0xFFFFFF, alpha:Float = 1)
		{
			return Mesh3DRenderer.makeCube(tag, width, height, depth, color, alpha, owner);
		});

		Lua_helper.add_callback(lua, "make3DSphere", function(tag:String, radius:Float = 50, color:Int = 0xFFFFFF, alpha:Float = 1,
				segmentsW:Int = 16, segmentsH:Int = 12)
		{
			return Mesh3DRenderer.makeSphere(tag, radius, color, alpha, segmentsW, segmentsH, owner);
		});

		Lua_helper.add_callback(lua, "make3DCylinder", function(tag:String, radius:Float = 50, height:Float = 100, color:Int = 0xFFFFFF,
				alpha:Float = 1, segments:Int = 16)
		{
			return Mesh3DRenderer.makeCylinder(tag, radius, height, color, alpha, segments, owner);
		});

		Lua_helper.add_callback(lua, "make3DCone", function(tag:String, radius:Float = 50, height:Float = 100, color:Int = 0xFFFFFF,
				alpha:Float = 1, segments:Int = 16)
		{
			return Mesh3DRenderer.makeCone(tag, radius, height, color, alpha, segments, owner);
		});

		Lua_helper.add_callback(lua, "make3DTorus", function(tag:String, radius:Float = 80, tubeRadius:Float = 18, color:Int = 0xFFFFFF,
				alpha:Float = 1, segmentsR:Int = 24, segmentsT:Int = 10)
		{
			return Mesh3DRenderer.makeTorus(tag, radius, tubeRadius, color, alpha, segmentsR, segmentsT, owner);
		});

		Lua_helper.add_callback(lua, "make3DSprite", function(tag:String, image:String, width:Float = 0, height:Float = 0, x:Float = 0,
				y:Float = 0, z:Float = 0, ?smooth:Bool = true, ?floorAligned:Bool = false)
		{
			return Mesh3DRenderer.makeSpritePlane(tag, image, width, height, x, y, z, owner, smooth, floorAligned);
		});

		Lua_helper.add_callback(lua, "remove3DMesh", function(tag:String)
		{
			return Mesh3DRenderer.remove(tag);
		});

		Lua_helper.add_callback(lua, "clear3DMeshes", function()
		{
			Mesh3DRenderer.clear();
		});

		Lua_helper.add_callback(lua, "set3DMeshTexture", function(tag:String, image:String, ?smooth:Bool = true)
		{
			return Mesh3DRenderer.setTexture(tag, image, smooth);
		});

		Lua_helper.add_callback(lua, "set3DTextureFromSprite", function(tag:String, spriteTag:String, ?smooth:Bool = true)
		{
			return Mesh3DRenderer.setTextureFromSprite(tag, spriteTag, smooth);
		});

		Lua_helper.add_callback(lua, "set3DMeshPosition", function(tag:String, x:Float = 0, y:Float = 0, z:Float = 0)
		{
			return Mesh3DRenderer.setPosition(tag, x, y, z);
		});

		Lua_helper.add_callback(lua, "set3DFloorPos", function(tag:String, x:Float = 0, z:Float = 0, y:Float = 280)
		{
			return Mesh3DRenderer.setFloorPosition(tag, x, z, y);
		});

		Lua_helper.add_callback(lua, "set3DMeshRotation", function(tag:String, x:Float = 0, y:Float = 0, z:Float = 0)
		{
			return Mesh3DRenderer.setRotation(tag, x, y, z);
		});

		Lua_helper.add_callback(lua, "set3DMeshScale", function(tag:String, x:Float = 1, y:Float = 1, z:Float = 1)
		{
			return Mesh3DRenderer.setScale(tag, x, y, z);
		});

		Lua_helper.add_callback(lua, "set3DMeshVisible", function(tag:String, visible:Bool)
		{
			return Mesh3DRenderer.setVisible(tag, visible);
		});

		Lua_helper.add_callback(lua, "set3DMeshAlpha", function(tag:String, alpha:Float)
		{
			return Mesh3DRenderer.setAlpha(tag, alpha);
		});

		Lua_helper.add_callback(lua, "set3DMeshColor", function(tag:String, color:Int)
		{
			return Mesh3DRenderer.setColor(tag, color);
		});

		Lua_helper.add_callback(lua, "set3DMeshProperty", function(tag:String, property:String, value:Dynamic)
		{
			return Mesh3DRenderer.setProperty(tag, property, value);
		});

		Lua_helper.add_callback(lua, "get3DMeshProperty", function(tag:String, property:String)
		{
			return Mesh3DRenderer.getProperty(tag, property);
		});

		Lua_helper.add_callback(lua, "get3DViewInfo", function()
		{
			return Mesh3DRenderer.getViewInfo();
		});

		Lua_helper.add_callback(lua, "set3DCameraPosition", function(x:Float = 0, y:Float = 0, z:Float = -1000)
		{
			return Mesh3DRenderer.setCameraPosition(x, y, z);
		});

		Lua_helper.add_callback(lua, "lookAt3D", function(x:Float = 0, y:Float = 0, z:Float = 0)
		{
			return Mesh3DRenderer.lookAt(x, y, z);
		});

		Lua_helper.add_callback(lua, "doTween3DMeshProperty", function(tag:String, meshTag:String, property:String, value:Float, duration:Float,
				?ease:String = 'linear')
		{
			var target:Dynamic = Mesh3DRenderer.getTweenTarget(meshTag, property);
			var tweenProperty:String = Mesh3DRenderer.normalizeTweenProperty(property);
			if (target == null || tweenProperty == null)
				return null;

			var values:Dynamic = {};
			Reflect.setField(values, tweenProperty, value);
			var originalTag:String = LuaUtils.formatVariable(tag);
			var tween:FlxTween = FlxTween.tween(target, values, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					LuaUtils.removeTween(originalTag);
					if (PlayState.instance != null)
						PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, meshTag]);
				}
			});
			return LuaUtils.storeTween(originalTag, tween);
		});

		Lua_helper.add_callback(lua, "tween3DFloorPos", function(tag:String, meshTag:String, x:Float = 0, z:Float = 0, duration:Float = 1,
				?ease:String = 'linear', y:Float = 280)
		{
			var target:Dynamic = Mesh3DRenderer.getTweenTarget(meshTag, 'x');
			if (target == null)
				return null;

			var values:Dynamic = {x: x, y: y, z: z};
			var originalTag:String = LuaUtils.formatVariable(tag);
			var tween:FlxTween = FlxTween.tween(target, values, duration, {
				ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					LuaUtils.removeTween(originalTag);
					if (PlayState.instance != null)
						PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, meshTag]);
				}
			});
			return LuaUtils.storeTween(originalTag, tween);
		});
		#else
		Lua_helper.add_callback(lua, "init3DMeshView", function(?visible:Bool = true) return false);
		#end
	}
}
