package backend.ui.haxecompose.backend;

import backend.ui.haxecompose.ui.Constraints;
import backend.ui.haxecompose.ui.HitTest;
import backend.ui.haxecompose.ui.Node;
import backend.ui.haxecompose.ui.PointerEvent;
import backend.ui.haxecompose.ui.PointerEvent.PointerEventType;
import backend.ui.md3.MD3Theme;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

class FlixelRenderer implements Renderer
{
	public final host:FlxSpriteGroup;
	public var animationTime:Float = 0;
	public var hasActiveAnimations(default, null):Bool = false;

	var lastRoot:Node;
	var activeAnimations:Array<Node> = [];
	var collectingAnimations:Bool = false;

	public function new(host:FlxSpriteGroup)
	{
		this.host = host;
	}

	public function render(root:Node, width:Float, height:Float):Void
	{
		if (root == null)
			return;

		lastRoot = root;
		hasActiveAnimations = false;
		activeAnimations = [];
		collectingAnimations = true;
		root.measure(new Constraints(0, width, 0, height));
		root.place(0, 0);
		renderNode(root, 0, 0);
		collectingAnimations = false;
	}

	public function renderAnimations():Void
	{
		if (activeAnimations.length == 0)
		{
			hasActiveAnimations = false;
			return;
		}

		hasActiveAnimations = false;
		for (node in activeAnimations)
			renderAnimatedNode(node);
	}

	public function updateInput():Void
	{
		if (lastRoot == null)
			return;

		if (FlxG.mouse.justReleased)
			dispatchPointer(new PointerEvent(FlxG.mouse.screenX, FlxG.mouse.screenY, PointerEventType.Up));
	}

	public function dispatchPointer(event:PointerEvent):Void
	{
		if (lastRoot == null || event == null)
			return;

		var hits = HitTest.hitTest(lastRoot, event.x, event.y);
		hits.reverse();
		for (node in hits)
		{
			if (event.type == Up && node.modifier.onClick != null)
			{
				node.props.set("__pressStart", animationTime);
				queueAnimation(node);
				node.modifier.onClick();
				return;
			}
		}
	}

	function renderNode(node:Node, parentX:Float, parentY:Float):Void
	{
		var absX = parentX + node.x + node.modifier.offsetX;
		var absY = parentY + node.y + node.modifier.offsetY;
		node.renderX = absX;
		node.renderY = absY;

		switch (node.type)
		{
			case "Text":
				renderText(node, absX, absY);
			case "MD3Icon":
				renderIcon(node, absX, absY);
			case "Button", "Card", "Box", "Column", "Row", "ExpressiveButton", "MD3Button", "MD3Card", "MD3Chip", "MD3Badge", "MD3Surface", "MD3IconButton",
				"MD3FAB", "MD3Dialog", "MD3Toast", "MD3Banner", "MD3TextField", "MD3Menu", "MD3Tooltip", "MD3Box", "MD3SearchBar", "MD3BottomAppBar",
				"MD3NavigationRail", "MD3NavigationDrawer", "MD3BottomSheet", "MD3DockedSearchBar", "MD3MessageBox", "MD3DatePicker", "MD3TimePicker",
				"MD3Carousel", "MD3PullToRefresh", "MD3RichTooltip":
				renderContainer(node, absX, absY);
			case "WavyProgressIndicator":
				renderWavyProgress(node, absX, absY);
			case "WavyCircularProgressIndicator":
				renderWavyCircularProgress(node, absX, absY);
			case "MD3Checkbox":
				renderCheckbox(node, absX, absY);
			case "MD3RadioButton":
				renderRadioButton(node, absX, absY);
			case "MD3Switch":
				renderSwitch(node, absX, absY);
			case "MD3Slider":
				renderSlider(node, absX, absY);
			case "MD3Progress":
				renderProgress(node, absX, absY);
			case "MD3CircularProgressIndicator":
				renderCircularProgress(node, absX, absY);
			case "MD3Divider":
				renderDivider(node, absX, absY);
			case "Image":
				renderImage(node, absX, absY);
			default:
		}

		for (child in node.children)
			renderNode(child, absX, absY);

		node.needsDraw = false;
	}

	function renderContainer(node:Node, x:Float, y:Float):Void
	{
		if (node.modifier.backgroundColor == null)
			return;

		var sprite:CachedPartSprite = cast getNative(node, function() return new CachedPartSprite());
		sprite.setPosition(x, y);
		sprite.alpha = node.modifier.alpha;
		FlixelDrawTools.prepareCanvas(sprite, Std.int(Math.max(1, Std.int(node.width))), Std.int(Math.max(1, Std.int(node.height))));
		FlixelDrawTools.roundRect(sprite, 0, 0, node.width, node.height, node.modifier.cornerRadius, node.modifier.backgroundColor);
		var outlineColor:Null<FlxColor> = node.props.get("outlineColor");
		if (outlineColor != null && outlineColor != FlxColor.TRANSPARENT)
			FlixelDrawTools.roundRectOutline(sprite, 1, 1, Math.max(1, node.width - 2), Math.max(1, node.height - 2), node.modifier.cornerRadius, 1, outlineColor);

		var pressStart:Null<Float> = node.props.get("__pressStart");
		if (pressStart != null)
		{
			var pressProgress = (animationTime - pressStart) / 0.22;
			if (pressProgress < 1)
			{
				hasActiveAnimations = true;
				queueAnimation(node);
				FlixelDrawTools.roundRect(sprite, 0, 0, node.width, node.height, node.modifier.cornerRadius,
					MD3Theme.withAlpha(MD3Theme.primary, 0.12 * (1 - pressProgress)));
			}
			else
				node.props.remove("__pressStart");
		}
		ensureAdded(sprite);
	}

	function renderText(node:Node, x:Float, y:Float):Void
	{
		var text:FlxText = cast getNative(node, function() return new FlxText());
		text.text = Std.string(node.props.get("text"));
		var size:Int = node.props.get("size");
		var label = Std.string(node.props.get("text"));
		var targetWidth = Math.max(1, node.width);
		var estimatedWidth = label.length * size * 0.58;
		if (estimatedWidth > targetWidth && label.length > 0)
			size = Std.int(Math.max(9, Math.min(size, targetWidth / (label.length * 0.58))));
		text.size = size;
		text.color = node.props.get("color");
		text.fieldWidth = node.width;
		text.wordWrap = false;
		text.autoSize = false;
		text.font = Paths.font("vcr.ttf");
		text.setPosition(x, y);
		text.alpha = node.modifier.alpha;
		ensureAdded(text);
	}

	function renderIcon(node:Node, x:Float, y:Float):Void
	{
		var text:FlxText = cast getNative(node, function() return new FlxText());
		text.text = Std.string(node.props.get("glyph"));
		text.size = node.props.get("size");
		text.color = node.props.get("color");
		text.fieldWidth = Math.max(node.width, text.size);
		text.wordWrap = false;
		text.autoSize = false;
		text.font = Paths.font("MaterialIcons-Regular.ttf");
		text.setPosition(x, y - 2);
		text.alpha = node.modifier.alpha;
		ensureAdded(text);
	}

	function renderImage(node:Node, x:Float, y:Float):Void
	{
		var sprite:FlxSprite = cast getNative(node, function() return new FlxSprite());
		var asset:String = node.props.get("asset");
		if (asset != null && asset.length > 0)
		{
			try
			{
				sprite.loadGraphic(Paths.image(asset));
			}
			catch (e:Dynamic)
			{
				FlixelDrawTools.prepareCanvas(sprite, Std.int(Math.max(1, Std.int(node.width))), Std.int(Math.max(1, Std.int(node.height))));
			}
		}
		sprite.setPosition(x, y);
		sprite.alpha = node.modifier.alpha;
		sprite.setGraphicSize(Std.int(node.width), Std.int(node.height));
		sprite.updateHitbox();
		ensureAdded(sprite);
	}

	function renderCheckbox(node:Node, x:Float, y:Float):Void
	{
		var sprite:CachedPartSprite = cast getNative(node, function() return new CachedPartSprite());
		var checked:Bool = node.props.get("checked");
		var w = Std.int(Math.max(28, Std.int(node.width)));
		var h = Std.int(Math.max(28, Std.int(node.height)));
		var target = checked ? 1.0 : 0.0;
		var v = animateValue(node, sprite, target, 0.14);

		sprite.setPosition(x, y);
		sprite.alpha = node.modifier.alpha;
		var key = w * 31 + h * 37 + Std.int(v * 1000) * 41;
		if (sprite.cacheAnimKey != key || sprite.cacheColor != MD3Theme.primary)
		{
			sprite.cacheAnimKey = key;
			sprite.cacheColor = MD3Theme.primary;
			FlixelDrawTools.prepareCanvas(sprite, w, h);
			if (v > 0.02)
				FlixelDrawTools.roundRect(sprite, 2, 2, 22, 22, 4, MD3Theme.mix(MD3Theme.surface, MD3Theme.primary, v));
			if (v < 0.98)
				FlixelDrawTools.roundRect(sprite, 2, 2, 22, 22, 4, MD3Theme.outline);
			if (v > 0.45)
			{
				FlixelDrawTools.line(sprite, 7, 13, 11, 17, 3, MD3Theme.onPrimary);
				FlixelDrawTools.line(sprite, 11, 17, 19, 8, 3, MD3Theme.onPrimary);
			}
		}

		ensureAdded(sprite);
	}

	function renderSwitch(node:Node, x:Float, y:Float):Void
	{
		var sprite:CachedPartSprite = cast getNative(node, function() return new CachedPartSprite());
		var checked:Bool = node.props.get("checked");
		var w = Std.int(Math.max(52, Std.int(node.width)));
		var h = Std.int(Math.max(32, Std.int(node.height)));
		var target = checked ? 1.0 : 0.0;
		var v = animateValue(node, sprite, target, 0.16);
		var track = MD3Theme.mix(MD3Theme.surfaceVariant, MD3Theme.primary, v);
		var thumb = MD3Theme.mix(MD3Theme.outline, MD3Theme.onPrimary, v);
		var thumbX = 4 + 22 * v;
		var thumbRadius = 8 + 2 * v;

		sprite.setPosition(x, y);
		sprite.alpha = node.modifier.alpha;
		var key = w * 31 + h * 37 + Std.int(v * 1000) * 41;
		if (sprite.cacheAnimKey != key || sprite.cacheColor != MD3Theme.primary)
		{
			sprite.cacheAnimKey = key;
			sprite.cacheColor = MD3Theme.primary;
			FlixelDrawTools.prepareCanvas(sprite, w, h);
			FlixelDrawTools.roundRect(sprite, 0, 4, 48, 24, 12, track);
			FlixelDrawTools.circle(sprite, thumbX + 9, 16, thumbRadius, thumb);
		}

		ensureAdded(sprite);
	}

	function renderRadioButton(node:Node, x:Float, y:Float):Void
	{
		var sprite:CachedPartSprite = cast getNative(node, function() return new CachedPartSprite());
		var selected:Bool = node.props.get("selected");
		var w = Std.int(Math.max(28, Std.int(node.width)));
		var h = Std.int(Math.max(28, Std.int(node.height)));
		var cx = w * 0.5;
		var cy = h * 0.5;
		var target = selected ? 1.0 : 0.0;
		var v = animateValue(node, sprite, target, 0.14);

		sprite.setPosition(x, y);
		sprite.alpha = node.modifier.alpha;
		var key = w * 31 + h * 37 + Std.int(v * 1000) * 41;
		if (sprite.cacheAnimKey != key || sprite.cacheColor != MD3Theme.primary)
		{
			sprite.cacheAnimKey = key;
			sprite.cacheColor = MD3Theme.primary;
			FlixelDrawTools.prepareCanvas(sprite, w, h);
			FlixelDrawTools.circle(sprite, cx, cy, 10, MD3Theme.mix(MD3Theme.outline, MD3Theme.primary, v));
			FlixelDrawTools.circle(sprite, cx, cy, 6, MD3Theme.surface);
			if (v > 0.02)
				FlixelDrawTools.circle(sprite, cx, cy, 5 * v, MD3Theme.primary);
		}
		ensureAdded(sprite);
	}

	function renderSlider(node:Node, x:Float, y:Float):Void
	{
		var sprite:CachedPartSprite = cast getNative(node, function() return new CachedPartSprite());
		var normalized:Float = node.props.get("normalized");
		var w = Std.int(Math.max(1, Std.int(node.width)));
		var h = Std.int(Math.max(28, Std.int(node.height)));
		var trackY = h * 0.5 - 2;
		var fillW = Std.int(Math.max(0, Math.min(w, Std.int(w * normalized))));

		sprite.setPosition(x, y);
		sprite.alpha = node.modifier.alpha;
		var key = w * 31 + h * 37 + fillW * 41;
		if (sprite.cacheAnimKey != key || sprite.cacheColor != MD3Theme.primary)
		{
			sprite.cacheAnimKey = key;
			sprite.cacheColor = MD3Theme.primary;
			FlixelDrawTools.prepareCanvas(sprite, w, h);
			FlixelDrawTools.roundRect(sprite, 0, trackY, w, 4, 2, MD3Theme.surfaceVariant);
			FlixelDrawTools.roundRect(sprite, 0, trackY, fillW, 4, 2, MD3Theme.primary);
			FlixelDrawTools.circle(sprite, fillW, h * 0.5, 8, MD3Theme.primary);
		}
		ensureAdded(sprite);
	}

	function renderProgress(node:Node, x:Float, y:Float):Void
	{
		var native:ProgressNative = cast getNative(node, function() return new ProgressNative());
		var progress:Null<Float> = node.props.get("progress");
		var w = Std.int(Math.max(1, Std.int(node.width)));
		var h = Std.int(Math.max(1, Std.int(node.height)));
		var fillW = progress == null ? Std.int(w * 0.34) : Std.int(Math.max(1, Std.int(w * progress)));
		var startX = 0.0;
		var endX = fillW * 1.0;
		if (progress == null)
		{
			hasActiveAnimations = true;
			trackAnimation(node);
			var cycle = animationCycle(1.35, 30);
			fillW = Std.int(w * (0.28 + Math.sin(cycle * Math.PI) * 0.26));
			startX = cycle * (w + fillW) - fillW;
			endX = startX + fillW;
		}

		native.setPosition(x, y);
		native.alpha = node.modifier.alpha;
		prepareProgressPart(native.track, w, h, MD3Theme.surfaceVariant, h * 0.5);
		prepareProgressPart(native.fill, w, h, MD3Theme.primary, h * 0.5);
		positionProgressIndicator(native.fill, x, y, w, startX, endX);
		native.track.scale.set(1, 1);
		native.track.setPosition(x, y);
		ensureAdded(native);
	}

	function renderCircularProgress(node:Node, x:Float, y:Float):Void
	{
		var native:CircularNative = cast getNative(node, function() return new CircularNative());
		var progress:Null<Float> = node.props.get("progress");
		var size = Std.int(Math.max(12, Std.int(Math.min(node.width, node.height))));
		var radius = size * 0.5 - 3;
		var cx = size * 0.5;
		var cy = size * 0.5;
		var start = -90.0;
		var t = animationFrameTime(30);
		var sweep = progress == null ? 120 + Math.sin(t * 4) * 42 : 360 * progress;
		if (progress == null)
		{
			hasActiveAnimations = true;
			trackAnimation(node);
			start = -90 + (t * 260) % 360;
		}

		native.setPosition(x, y);
		native.alpha = node.modifier.alpha;
		prepareArcPart(native.track, size, radius, 3, MD3Theme.surfaceVariant);
		drawArcIndicator(native.fill, size, radius, 4, MD3Theme.primary, start, sweep);
		native.track.setPosition(x, y);
		native.fill.setPosition(x, y);
		ensureAdded(native);
	}

	function renderDivider(node:Node, x:Float, y:Float):Void
	{
		var sprite:CachedPartSprite = cast getNative(node, function() return new CachedPartSprite());
		sprite.setPosition(x, y);
		sprite.alpha = node.modifier.alpha;
		var w = Std.int(Math.max(1, Std.int(node.width)));
		var h = Std.int(Math.max(1, Std.int(node.height)));
		var color = MD3Theme.dividerColor();
		var key = w * 31 + h * 37;
		if (sprite.cacheAnimKey != key || sprite.cacheColor != color)
		{
			sprite.cacheAnimKey = key;
			sprite.cacheColor = color;
			FlixelDrawTools.prepareCanvas(sprite, w, h);
			FlixelDrawTools.fill(sprite, color);
		}
		ensureAdded(sprite);
	}

	function renderWavyProgress(node:Node, x:Float, y:Float):Void
	{
		var native:ProgressNative = cast getNative(node, function() return new ProgressNative());
		var width = Std.int(Math.max(1, Std.int(node.width)));
		var height = Std.int(Math.max(1, Std.int(node.height)));
		var trackColor:FlxColor = node.props.get("trackColor");
		var color:FlxColor = node.props.get("color");
		var progress:Null<Float> = node.props.get("progress");
		var fillWidth = progress == null ? width : Std.int(Math.max(1, Std.int(width * progress)));
		var startX = 0.0;
		var endX = fillWidth * 1.0;
		if (progress == null)
		{
			hasActiveAnimations = true;
			trackAnimation(node);
			var cycle = animationCycle(1.55, 30);
			var activeWidth = Math.max(28, width * (0.34 + Math.sin(cycle * Math.PI) * 0.22));
			startX = cycle * (width + activeWidth) - activeWidth;
			endX = startX + activeWidth;
		}

		native.setPosition(x, y);
		native.alpha = node.modifier.alpha;
		prepareProgressPart(native.track, width, height, trackColor, height * 0.5);
		native.track.scale.set(1, 1);
		native.fill.scale.set(1, 1);
		native.track.setPosition(x, y);
		native.fill.setPosition(x, y);
		drawWavyIndicator(native.fill, width, height, color, width, startX, endX, progress == null ? animationCycle(1.1, 30) * Math.PI * 2 : 0);
		ensureAdded(native);
	}

	function renderWavyCircularProgress(node:Node, x:Float, y:Float):Void
	{
		var native:CircularNative = cast getNative(node, function() return new CircularNative());
		var progress:Null<Float> = node.props.get("progress");
		var color:FlxColor = node.props.get("color");
		var trackColor:FlxColor = node.props.get("trackColor");
		var size = Std.int(Math.max(24, Std.int(Math.min(node.width, node.height))));
		var radius = size * 0.5 - 4;
		var cx = size * 0.5;
		var cy = size * 0.5;
		var start = -90.0;
		var sweep = progress == null ? 255.0 : 360 * progress;

		if (progress == null)
		{
			hasActiveAnimations = true;
			trackAnimation(node);
			var t = animationFrameTime(30);
			start = -90 + (t * 210) % 360;
			sweep = 220 + Math.sin(t * 3.2) * 38;
		}

		native.setPosition(x, y);
		native.alpha = node.modifier.alpha;
		prepareArcPart(native.track, size, radius, 3, trackColor);
		drawWavyArcIndicator(native.fill, size, radius, 4, color, start, sweep, animationFrameTime(30) * 6);
		native.track.setPosition(x, y);
		native.fill.setPosition(x, y);
		ensureAdded(native);
	}

	function getNative(node:Node, factory:Void->Dynamic):Dynamic
	{
		if (node.native == null)
			node.native = factory();
		return node.native;
	}

	function prepareProgressPart(sprite:CachedPartSprite, width:Int, height:Int, color:FlxColor, radius:Float):Void
	{
		if (sprite == null)
			return;

		if (sprite.cacheWidth == width && sprite.cacheHeight == height && sprite.cacheColor == color)
			return;

		sprite.cacheWidth = width;
		sprite.cacheHeight = height;
		sprite.cacheColor = color;
		FlixelDrawTools.prepareCanvas(sprite, width, height);
		FlixelDrawTools.roundRect(sprite, 0, 0, width, height, radius, color);
	}

	function drawProgressIndicator(sprite:CachedPartSprite, width:Int, height:Int, color:FlxColor, startX:Float, endX:Float):Void
	{
		if (sprite == null)
			return;

		var key = width * 31 + height * 37 + Std.int(startX) * 41 + Std.int(endX) * 43;
		if (sprite.cacheAnimKey == key && sprite.cacheColor == color)
			return;
		sprite.cacheAnimKey = key;
		sprite.cacheWidth = width;
		sprite.cacheHeight = height;
		sprite.cacheColor = color;
		var clippedStart = Math.max(0, startX);
		var clippedEnd = Math.min(width, endX);
		FlixelDrawTools.prepareCanvas(sprite, width, height);
		if (clippedEnd <= clippedStart)
			return;
		sprite.drawRect.x = clippedStart;
		sprite.drawRect.y = 0;
		sprite.drawRect.width = clippedEnd - clippedStart;
		sprite.drawRect.height = height;
		sprite.pixels.fillRect(sprite.drawRect, color);
		sprite.dirty = true;
	}

	function positionProgressIndicator(sprite:CachedPartSprite, x:Float, y:Float, width:Int, startX:Float, endX:Float):Void
	{
		if (sprite == null)
			return;

		var clippedStart = Math.max(0, startX);
		var clippedEnd = Math.min(width, endX);
		var visibleWidth = clippedEnd - clippedStart;
		if (visibleWidth <= 0)
		{
			sprite.visible = false;
			return;
		}

		sprite.visible = true;
		sprite.setPosition(x + clippedStart, y);
		sprite.scale.set(visibleWidth / Math.max(1, width), 1);
	}

	function drawWavyIndicator(sprite:CachedPartSprite, width:Int, height:Int, color:FlxColor, sourceWidth:Float, startX:Float, endX:Float, phase:Float):Void
	{
		if (sprite == null)
			return;

		var key = width * 31 + height * 37 + Std.int(startX) * 41 + Std.int(endX) * 43 + Std.int(phase * 16) * 47;
		if (sprite.cacheAnimKey == key && sprite.cacheColor == color && sprite.cacheExtra == sourceWidth)
			return;
		sprite.cacheAnimKey = key;
		sprite.cacheWidth = width;
		sprite.cacheHeight = height;
		sprite.cacheColor = color;
		sprite.cacheExtra = sourceWidth;
		FlixelDrawTools.prepareCanvas(sprite, width, height);
		FlixelDrawTools.wavyLine(sprite, Math.max(0, startX), Math.min(width, endX), height * 0.5, Math.min(3, height * 0.24), Math.max(18, sourceWidth / 5), phase,
			Math.max(2, height * 0.58), color);
	}

	function prepareArcPart(sprite:CachedPartSprite, size:Int, radius:Float, thickness:Float, color:FlxColor):Void
	{
		if (sprite == null)
			return;

		var extra = radius + thickness;
		if (sprite.cacheWidth == size && sprite.cacheHeight == size && sprite.cacheColor == color && sprite.cacheExtra == extra)
			return;

		sprite.cacheWidth = size;
		sprite.cacheHeight = size;
		sprite.cacheColor = color;
		sprite.cacheExtra = extra;
		FlixelDrawTools.prepareCanvas(sprite, size, size);
		FlixelDrawTools.arc(sprite, size * 0.5, size * 0.5, radius, 0, 360, thickness, color);
	}

	function drawArcIndicator(sprite:CachedPartSprite, size:Int, radius:Float, thickness:Float, color:FlxColor, start:Float, sweep:Float):Void
	{
		if (sprite == null)
			return;

		var key = size * 31 + Std.int(start * 2) * 37 + Std.int(sweep * 2) * 41 + Std.int(radius * 4) * 43;
		if (sprite.cacheAnimKey == key && sprite.cacheColor == color)
			return;
		sprite.cacheAnimKey = key;
		sprite.cacheColor = color;
		FlixelDrawTools.prepareCanvas(sprite, size, size);
		FlixelDrawTools.arc(sprite, size * 0.5, size * 0.5, radius, start, sweep, thickness, color);
	}

	function drawWavyArcIndicator(sprite:CachedPartSprite, size:Int, radius:Float, thickness:Float, color:FlxColor, start:Float, sweep:Float,
			phase:Float):Void
	{
		if (sprite == null)
			return;

		var key = size * 31 + Std.int(start * 2) * 37 + Std.int(sweep * 2) * 41 + Std.int(phase * 8) * 43;
		if (sprite.cacheAnimKey == key && sprite.cacheColor == color)
			return;
		sprite.cacheAnimKey = key;
		sprite.cacheColor = color;
		FlixelDrawTools.prepareCanvas(sprite, size, size);
		FlixelDrawTools.wavyArc(sprite, size * 0.5, size * 0.5, radius, start, sweep, thickness, color, phase);
	}

	function renderAnimatedNode(node:Node):Void
	{
		switch (node.type)
		{
			case "MD3Progress":
				renderProgress(node, node.renderX, node.renderY);
			case "MD3CircularProgressIndicator":
				renderCircularProgress(node, node.renderX, node.renderY);
			case "WavyProgressIndicator":
				renderWavyProgress(node, node.renderX, node.renderY);
			case "WavyCircularProgressIndicator":
				renderWavyCircularProgress(node, node.renderX, node.renderY);
			case "MD3Switch":
				renderSwitch(node, node.renderX, node.renderY);
			case "MD3Checkbox":
				renderCheckbox(node, node.renderX, node.renderY);
			case "MD3RadioButton":
				renderRadioButton(node, node.renderX, node.renderY);
			case "Button", "Card", "Box", "Column", "Row", "ExpressiveButton", "MD3Button", "MD3Card", "MD3Chip", "MD3Badge", "MD3Surface", "MD3IconButton",
				"MD3FAB", "MD3Dialog", "MD3Toast", "MD3Banner", "MD3TextField", "MD3Menu", "MD3Tooltip", "MD3Box", "MD3SearchBar", "MD3BottomAppBar",
				"MD3NavigationRail", "MD3NavigationDrawer", "MD3BottomSheet", "MD3DockedSearchBar", "MD3MessageBox", "MD3DatePicker", "MD3TimePicker",
				"MD3Carousel", "MD3PullToRefresh", "MD3RichTooltip":
				renderContainer(node, node.renderX, node.renderY);
			default:
		}
	}

	function trackAnimation(node:Node):Void
	{
		if (!collectingAnimations)
			return;
		queueAnimation(node);
	}

	function queueAnimation(node:Node):Void
	{
		if (node != null && !activeAnimations.contains(node))
			activeAnimations.push(node);
	}

	function animateValue(node:Node, sprite:CachedPartSprite, target:Float, duration:Float):Float
	{
		if (sprite.animValue < 0)
			sprite.animValue = target;

		var diff = target - sprite.animValue;
		if (Math.abs(diff) > 0.001)
		{
			var amount = duration <= 0 ? 1 : Math.min(1, FlxG.elapsed / duration);
			sprite.animValue += diff * amount;
			hasActiveAnimations = true;
			queueAnimation(node);
		}
		else
			sprite.animValue = target;

		return sprite.animValue;
	}

	inline function animationCycle(duration:Float, fps:Float = 0):Float
	{
		if (duration <= 0)
			return 0;
		var t = fps > 0 ? animationFrameTime(fps) : animationTime;
		return (t % duration) / duration;
	}

	inline function animationFrameTime(fps:Float):Float
	{
		return fps <= 0 ? animationTime : Math.floor(animationTime * fps) / fps;
	}

	function ensureAdded(sprite:FlxSprite):Void
	{
		if (sprite != null && !host.members.contains(sprite))
			host.add(sprite);
	}
}

private class CachedPartSprite extends FlxSprite
{
	public var cacheWidth:Int = -1;
	public var cacheHeight:Int = -1;
	public var cacheColor:FlxColor = 0;
	public var cacheExtra:Float = -1;
	public var cacheAnimKey:Int = -2147483648;
	public var animValue:Float = -1;
	public final drawRect:Rectangle = new Rectangle();

	public function new()
	{
		super();
	}
}

private class ProgressNative extends FlxSpriteGroup
{
	public final track:CachedPartSprite;
	public final fill:CachedPartSprite;

	public function new()
	{
		super();
		track = new CachedPartSprite();
		fill = new CachedPartSprite();
		add(track);
		add(fill);
	}
}

private class CircularNative extends ProgressNative
{
	public function new()
	{
		super();
	}
}
