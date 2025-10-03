package modchart.modifiers;

import flixel.FlxG;

class Zoom extends Modifier {
	var __curPercent:Null<Float> = -1;
	var __localPercent:Null<Float> = -1;

	override public function render(curPos:Vector3D, params:RenderParams) {
		updatePercent(params);
		
		// center zoom
		if (__curPercent != 1)
			curPos = __applyZoom(curPos, new Vector3D(FlxG.width * .5, FlxG.height * .5), __curPercent);
		if (__localPercent != 1)
			curPos = __applyZoom(curPos, new Vector3D(getReceptorX(Math.round(getKeyCount(params.player) * .5), params.player), FlxG.height * .5), __localPercent);
		return curPos;
	}
	inline function __applyZoom(pos:Vector3D, origin:Vector3D, amount:Float)
	{
		var diff = pos.subtract(origin);
		diff.scaleBy(amount);
		return diff.add(origin);
	}

	override public function visuals(data:Visuals, params:RenderParams):Visuals {
		if (__curPercent == null)
			updatePercent(params);

		data.scaleX = data.scaleX * (__curPercent * __localPercent);
		data.scaleY = data.scaleY * (__curPercent * __localPercent);

		__curPercent = __localPercent = null;

		return data;
	}

	inline function updatePercent(params:RenderParams) {
		__curPercent = 1 + ((-getPercent('zoom', params.player) + getPercent('mini', params.player)) * 0.5);
		__localPercent = 1 + ((-getPercent('localZoom', params.player) + getPercent('localMini', params.player)) * 0.5);
	}
	override public function shouldRun(params:RenderParams):Bool
		return true;
}
