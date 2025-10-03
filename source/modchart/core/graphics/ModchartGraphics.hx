package modchart.core.graphics;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import haxe.ds.ObjectMap;
import haxe.ds.Vector as NativeVector;
import modchart.core.ModifierGroup.ModifierOutput;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.Visuals;
import modchart.core.util.ModchartUtil;
import openfl.Vector;
import openfl.display.GraphicsPathCommand;
import openfl.display.Shape;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Vector3D;

var rotationVector = new Vector3D();
var helperVector = new Vector3D();
var __matrix:Matrix = new Matrix();
var pathVector = new Vector3D();

typedef HoldSegmentOutput = {
	origin:Vector3D,
	left:Vector3D,
	right:Vector3D,
	visuals:Visuals,
	depth:Float
}

class ModchartRenderer<T:FlxBasic> extends FlxBasic {
	private var instance:Null<PlayField>;
	private var queue:NativeVector<FMDrawInstruction>;
	private var count:Int = 0;
	private var postCount:Int = 0;

	public function new(instance:PlayField) {
		super();

		this.instance = instance;
	}

	// Renderer-side
	public function prepare(item:T) {}

	public function shift():Void {}

	public function dispose() {}

	// Built-in functions
	public function preallocate(length:Int) {
		queue = new NativeVector<FMDrawInstruction>(length);
		count = postCount = 0;
	}

	public function sort() {
		if (queue == null || queue.length <= 0)
			return;
		queue.sort((a, b) -> {
			if (a == null || b == null)
				return 0;
			return FlxSort.byValues(FlxSort.DESCENDING, a.item._z, b.item._z);
		});
	}

	// public function render(times:Null<Int>):Void {}
}

class ModchartHoldRenderer extends ModchartRenderer<FlxSprite> {
	private var __lastHoldSubs:Int = -1;

	var _indices:Null<Vector<Int>> = new Vector<Int>();

	public function new(instance:PlayField) {
		super(instance);

		instance.setPercent('dizzyHolds', 1, -1);
	}

	inline private function __rotateTail(pos:Vector3D) {
		if (__parentOutput == null || (__rotateX == 0 && __rotateY == 0 && __rotateZ == 0))
			return pos;

		var tailFactor = pos.subtract(__parentOutput.pos);
		tailFactor = ModchartUtil.rotate3DVector(tailFactor, __rotateX, __rotateY, __rotateZ);
		var output = __parentOutput.pos.add(tailFactor);
		output.z *= 0.001 * Config.Z_SCALE;
		return ModchartUtil.project(output, __parentOutput.pos);
	}

	/**
	 * Returns the normal points along the hold path at specific hitTime using.
	 *
	 * Based on schmovin' hold system
	 * @param basePos The hold position per default
	 * @see https://en.wikipedia.org/wiki/Unit_circle
	 */
	@:noCompletion
	inline private function getHoldSegment(hold:FlxSprite, basePos:Vector3D, params:ArrowData):HoldSegmentOutput {
		@:privateAccess
		var holdTime = params.hitTime;
		var parentTime = Adapter.instance.getHoldParentTime(hold);

		var holdDistance = params.distance;
		var parentDistance = Math.max(0, parentTime - Adapter.instance.getSongPosition());

		params.hitTime = FlxMath.lerp(parentTime, holdTime, __long);
		params.distance = FlxMath.lerp(parentDistance, holdDistance, __long);
		if (params.hitten && params.distance < 0)
			params.distance = 0;

		final size = hold.frame.frame.width * hold.scale.x * .5;

		var origin:ModifierOutput = instance.modifiers.getPath(basePos.clone(), params);
		var curPoint = origin.pos;
		final depth = (origin.pos.z - 1) * 1000;
		final zScale:Float = curPoint.z != 0 ? (1 / curPoint.z) : 1;
		curPoint.z = 0;

		var unit:Vector3D;

		if (Config.OPTIMIZE_HOLDS) {
			unit = new Vector3D(0, 1, 0);
		} else {
			var next = instance.modifiers.getPath(basePos.clone(), params, 1, false, true);
			next.pos.z = 0;

			// normalized points difference (from 0-1)
			unit = next.pos.subtract(curPoint);
			unit.normalize();
		}

		var quad0 = new Vector3D(-unit.y * size, unit.x * size);
		var quad1 = new Vector3D(unit.y * size, -unit.x * size);

		final visuals = origin.visuals;
		@:privateAccess
		for (i in 0...2) {
			var quad = switch (i) {
				case 0: quad0;
				case 1: quad1;
				default: null;
			}
			var rotation = quad;
			var rotate = __dizzy != 0;

			if (rotate)
				rotation = ModchartUtil.rotate3DVector(quad, 0, visuals.angleY * __dizzy, 0);

			if (visuals.skewX != 0 || visuals.skewY != 0) {
				__matrix.identity();

				__matrix.b = ModchartUtil.tan(visuals.skewY * FlxAngle.TO_RAD);
				__matrix.c = ModchartUtil.tan(visuals.skewX * FlxAngle.TO_RAD);

				rotation.x = __matrix.__transformX(rotation.x, rotation.y);
				rotation.y = __matrix.__transformY(rotation.x, rotation.y);
			}
			rotation.x = rotation.x * zScale * visuals.scaleX;
			rotation.y = rotation.y * zScale * visuals.scaleY;

			var view = new Vector3D(rotation.x + curPoint.x, rotation.y + curPoint.y, rotation.z);
			view = __rotateTail(view);
			if (Config.CAMERA3D_ENABLED)
				view = instance.camera3D.applyViewTo(view);
			view.z *= 0.001;

			// The result of the perspective projection of rotation
			var projection = view;

			if (view.z != 0)
				projection = ModchartUtil.project(view);

			quad.x = projection.x;
			quad.y = projection.y;
			quad.z = projection.z;
		}
		return {
			origin: curPoint,
			left: quad0,
			right: quad1,
			visuals: origin.visuals,
			depth: depth
		};
	}

	private var __long:Float = 0.0;
	private var __straightAmount:Float = 0.0;
	private var __calculatingSegments:Bool = false;
	private var __rotateX:Float = 0;
	private var __rotateY:Float = 0;
	private var __rotateZ:Float = 0;
	private var __dizzy:Float = 0;
	private var __parentOutput:ModifierOutput;
	private var __centered2:Float = 0;
	private var basePos:Vector3D;

	/*
		private function getStraightHoldSegment(hold:FlxSprite, basePos:Vector3D, params:ArrowData):Array<Dynamic> {
			var perc = __straightAmount;

			var oldHitTime = params.hitTime;
			params.hitTime = Adapter.instance.getHoldParentTime(hold);

			var distance = params.hitTime - Adapter.instance.getSongPosition();
			params.distance = oldHitTime == 0 ? 0 : distance;

			var holdProgress = oldHitTime - params.hitTime;
			final origin = instance.modifiers.getPath(basePos.clone(), params);
			final next = instance.modifiers.getPath(basePos.clone(), params, 1);
			final originPos = origin.pos;
			final nextPos = next.pos;

			originPos.z = nextPos.z = 0;

			// actual unit
			var unit = nextPos.subtract(originPos);
			unit.normalize();

			// the center position of the hold
			var holdOrigin = unit.clone();
			holdOrigin.scaleBy(holdProgress * __long);
			holdOrigin.incrementBy(originPos);

			var zScale:Float = holdOrigin.z != 0 ? (1 / holdOrigin.z) : 1;
			holdOrigin.z = 0;

			var size = hold.frame.frame.width * hold.scale.x * .5;

			var quad0 = new Vector3D(-unit.y * size, unit.x * size);
			var quad1 = new Vector3D(unit.y * size, -unit.x * size);

			return [
				[
					holdOrigin.add(quad0),
					holdOrigin.add(quad1),
					holdOrigin.add(new Vector3D(0, 0, 1 + (1 - zScale) * 0.001))
				],
				origin.visuals
			];
	}*/
	@:noCompletion
	inline private function updateIndices() {
		final HOLD_SUBDIVISIONS = Adapter.instance.getHoldSubdivisions();

		_indices.length = (HOLD_SUBDIVISIONS * 6);
		for (sub in 0...HOLD_SUBDIVISIONS) {
			var vert = sub * 4;
			var count = sub * 6;

			_indices[count] = _indices[count + 3] = vert;
			_indices[count + 2] = _indices[count + 5] = vert + 3;
			_indices[count + 1] = vert + 1;
			_indices[count + 4] = vert + 2;
		}
	}

	override public function prepare(item:FlxSprite):Void {
		if (item.alpha <= 0)
			return;
		final arrow:FlxSprite = item;
		final newInstruction:FMDrawInstruction = {};
		final HOLD_SUBDIVISIONS = Adapter.instance.getHoldSubdivisions();

		if (__lastHoldSubs != HOLD_SUBDIVISIONS)
			updateIndices();

		if (__lastHoldSubs == -1)
			__lastHoldSubs = Adapter.instance.getHoldSubdivisions();

		Manager.HOLD_SIZE = arrow.width;
		Manager.HOLD_SIZEDIV2 = arrow.width * .5;

		final player = Adapter.instance.getPlayerFromArrow(item);
		final lane = Adapter.instance.getLaneFromArrow(item);

		basePos = ModchartUtil.getHalfPos();
		basePos.x += Adapter.instance.getDefaultReceptorX(lane, player);
		basePos.y += Adapter.instance.getDefaultReceptorY(lane, player);

		var vertices:openfl.Vector<Float> = new openfl.Vector<Float>(8 * HOLD_SUBDIVISIONS, true);
		var transfTotal:Array<ColorTransform> = [];
		transfTotal.resize(HOLD_SUBDIVISIONS);
		var tID = 0;

		var lastData:ArrowData = null;
		var lastSegment:Null<HoldSegmentOutput> = null;

		var depthApplied = false;
		var alphaTotal:Float = 0.;

		// refresh global mods percents
		__long = instance.getPercent('longHolds', player) - instance.getPercent('shortHolds', player) + 1;
		__centered2 = instance.getPercent('centered2', player);
		__dizzy = instance.getPercent('dizzyHolds', player);

		__rotateX = instance.getPercent('holdRotateX', player);
		__rotateY = instance.getPercent('holdRotateY', player);
		__rotateZ = instance.getPercent('holdRotateZ', player);

		var parentTime = Adapter.instance.getHoldParentTime(item);
		var parentData:ArrowData = {
			hitTime: parentTime,
			// this fixed the clipping gaps
			distance: Math.max(0, parentTime - Adapter.instance.getSongPosition()),
			lane: lane,
			player: player,
			hitten: Adapter.instance.arrowHit(item),
			isTapArrow: true
		};
		if (__rotateX != 0 || __rotateY != 0 || __rotateZ != 0) {
			__parentOutput = instance.modifiers.getPath(basePos.clone(), parentData);
			__parentOutput.pos.z = (__parentOutput.pos.z - 1) * 1000;
		}

		var getSegmentFunc = getHoldSegment;

		var vertPointer = 0;

		var subCr = ((Adapter.instance.getStaticCrochet() * .25) * ((Adapter.instance.isHoldEnd(item)) ? 0.6 * Config.HOLD_END_SCALE : 1)) / HOLD_SUBDIVISIONS;
		for (sub in 0...HOLD_SUBDIVISIONS) {
			var subOff = subCr * sub;

			var out1 = lastSegment;

			if (out1 == null)
				out1 = getSegmentFunc(item, basePos, lastData != null ? lastData : getArrowParams(arrow, subOff));

			var out2 = getSegmentFunc(item, basePos, (lastData = getArrowParams(arrow, subOff + subCr)));

			lastSegment = out2;

			if (!depthApplied) {
				arrow._z = out1.depth;
				depthApplied = true;
			}

			alphaTotal = alphaTotal + out1.visuals.alpha;

			var vertPos = (vertPointer++) * 8;
			vertices[vertPos] = out1.left.x;
			vertices[vertPos + 1] = out1.left.y;
			vertices[vertPos + 2] = out1.right.x;
			vertices[vertPos + 3] = out1.right.y;
			vertices[vertPos + 4] = out2.left.x;
			vertices[vertPos + 5] = out2.left.y;
			vertices[vertPos + 6] = out2.right.x;
			vertices[vertPos + 7] = out2.right.y;

			final negGlow = 1 - out1.visuals.glow;
			final absGlow = out1.visuals.glow * 255;
			transfTotal[tID++] = new ColorTransform(negGlow, negGlow, negGlow, out1.visuals.alpha * arrow.alpha, Math.round(out1.visuals.glowR * absGlow),
				Math.round(out1.visuals.glowG * absGlow), Math.round(out1.visuals.glowB * absGlow));
		}

		newInstruction.item = item;
		newInstruction.vertices = vertices;
		newInstruction.indices = _indices.copy();
		newInstruction.uvt = ModchartUtil.getHoldUVT(arrow, HOLD_SUBDIVISIONS);
		newInstruction.colorData = transfTotal;
		newInstruction.extra = [alphaTotal];

		queue[count] = newInstruction;
		count++;

		__lastHoldSubs = Adapter.instance.getHoldSubdivisions();
	}

	inline static final drawMargin = 50;

	inline function shouldDraw(info:HoldSegmentOutput) {
		return info.origin.x < -drawMargin
			&& info.origin.x > FlxG.width + drawMargin
			&& info.origin.y < -drawMargin
			&& info.origin.y > FlxG.height + drawMargin;
	}

	override public function shift() {
		__drawInstruction(queue[postCount++]);
	}

	private function __drawInstruction(instruction:FMDrawInstruction) {
		if (instruction == null)
			return;
		final item:FlxSprite = instruction.item;

		var cameras = item._cameras != null ? item._cameras : Adapter.instance.getArrowCamera();

		@:privateAccess for (camera in cameras) {
			var cTransforms = instruction.colorData.copy();

			for (t in cTransforms)
				t.alphaMultiplier *= camera.alpha;

			var item = camera.startTrianglesBatch(item.graphic, item.antialiasing, true, item.blend, true, item.shader);
			item.addGradientTriangles(instruction.vertices, instruction.indices, instruction.uvt, new openfl.Vector<Int>(), null, camera._bounds, cTransforms);
		}
	}

	inline private function computeCentered2Height() {
		var center = FlxG.height * .5;
		var cury = basePos.y;
	}

	inline private function getArrowParams(arrow:FlxSprite, posOff:Float = 0):ArrowData {
		final player = Adapter.instance.getPlayerFromArrow(arrow);
		final lane = Adapter.instance.getLaneFromArrow(arrow);

		final timeC2 = flixel.FlxG.height * 0.25 * __centered2;
		final hitTime = Adapter.instance.getTimeFromArrow(arrow);

		var pos = (hitTime - Adapter.instance.getSongPosition()) + posOff;

		pos += timeC2;

		return {
			__holdSubdivisionOffset: posOff,
			hitTime: hitTime + posOff + timeC2,
			distance: pos,
			lane: lane,
			player: player,
			hitten: Adapter.instance.arrowHit(arrow),
			isTapArrow: true
		};
	}
}

class ModchartArrowRenderer extends ModchartRenderer<FlxSprite> {
	inline private function getGraphicVertices(planeWidth:Float, planeHeight:Float, flipX:Bool, flipY:Bool) {
		var x1 = flipX ? planeWidth : -planeWidth;
		var x2 = flipX ? -planeWidth : planeWidth;
		var y1 = flipY ? planeHeight : -planeHeight;
		var y2 = flipY ? -planeHeight : planeHeight;

		return [
			// top left
			x1,
			y1,
			// top right
			x2,
			y1,
			// bottom left
			x1,
			y2,
			// bottom right
			x2,
			y2
		];
	}

	override public function prepare(arrow:FlxSprite) {
		if (arrow.alpha <= 0)
			return;

		final arrowPosition = helperVector;

		final player = Adapter.instance.getPlayerFromArrow(arrow);

		// setup the position
		var arrowTime = Adapter.instance.getTimeFromArrow(arrow);
		var songPos = Adapter.instance.getSongPosition();
		var arrowDiff = arrowTime - songPos;

		// apply centered 2 (aka centered path)
		if (Adapter.instance.isTapNote(arrow)) {
			arrowDiff += FlxG.height * 0.25 * instance.getPercent('centered2', player);
		} else {
			arrowTime = songPos + (FlxG.height * 0.25 * instance.getPercent('centered2', player));
			arrowDiff = arrowTime - songPos;
		}
		var arrowData:ArrowData = {
			hitTime: arrowTime,
			distance: arrowDiff,
			lane: Adapter.instance.getLaneFromArrow(arrow),
			player: player,
			isTapArrow: Adapter.instance.isTapNote(arrow)
		};

		arrowPosition.setTo(Adapter.instance.getDefaultReceptorX(arrowData.lane, arrowData.player) + Manager.ARROW_SIZEDIV2,
			Adapter.instance.getDefaultReceptorY(arrowData.lane, arrowData.player) + Manager.ARROW_SIZEDIV2, 0);

		final output = instance.modifiers.getPath(arrowPosition, arrowData);
		arrowPosition.copyFrom(output.pos.clone());

		// internal mods
		final orient = instance.getPercent('orient', arrowData.player);
		if (orient != 0) {
			final nextOutput = instance.modifiers.getPath(new Vector3D(Adapter.instance.getDefaultReceptorX(arrowData.lane, arrowData.player)
				+ Manager.ARROW_SIZEDIV2,
				Adapter.instance.getDefaultReceptorY(arrowData.lane, arrowData.player)
				+ Manager.ARROW_SIZEDIV2),
				arrowData, 1, false, true);
			final thisPos = output.pos;
			final nextPos = nextOutput.pos;

			output.visuals.angleZ += FlxAngle.wrapAngle((-90 + (Math.atan2(nextPos.y - thisPos.y, nextPos.x - thisPos.x) * FlxAngle.TO_DEG)) * orient);
		}

		// prepare the instruction for drawing
		final projectionDepth = arrowPosition.z;
		final depth = projectionDepth;

		var depthScale = 1 / depth;
		var planeWidth = arrow.frame.frame.width * arrow.scale.x * .5;
		var planeHeight = arrow.frame.frame.height * arrow.scale.y * .5;

		arrow._z = (depth - 1) * 1000;

		var planeVertices = getGraphicVertices(planeWidth, planeHeight, arrow.flipX, arrow.flipY);
		var projectionZ:haxe.ds.Vector<Float> = new haxe.ds.Vector(Math.ceil(planeVertices.length / 2));

		var vertPointer = 0;
		@:privateAccess do {
			rotationVector.setTo(planeVertices[vertPointer], planeVertices[vertPointer + 1], 0);

			// The result of the vert rotation
			var rotation = ModchartUtil.rotate3DVector(rotationVector, output.visuals.angleX, output.visuals.angleY,
				ModchartUtil.getFrameAngle(arrow) + output.visuals.angleZ);

			// apply skewness
			if (output.visuals.skewX != 0 || output.visuals.skewY != 0) {
				__matrix.identity();

				__matrix.b = ModchartUtil.tan(output.visuals.skewY * FlxAngle.TO_RAD);
				__matrix.c = ModchartUtil.tan(output.visuals.skewX * FlxAngle.TO_RAD);

				rotation.x = __matrix.__transformX(rotation.x, rotation.y);
				rotation.y = __matrix.__transformY(rotation.x, rotation.y);
			}
			rotation.x = rotation.x * depthScale * output.visuals.scaleX;
			rotation.y = rotation.y * depthScale * output.visuals.scaleY;

			var view = new Vector3D(rotation.x + arrowPosition.x, rotation.y + arrowPosition.y, rotation.z);
			if (Config.CAMERA3D_ENABLED)
				view = instance.camera3D.applyViewTo(view);
			view.z *= 0.001;

			// The result of the perspective projection of rotation
			final projection = ModchartUtil.project(view);

			planeVertices[vertPointer] = projection.x;
			planeVertices[vertPointer + 1] = projection.y;

			// stores depth from this vert to use it for perspective correction on uv's
			projectionZ[Math.floor(vertPointer / 2)] = Math.max(0.0001, projection.z);

			vertPointer = vertPointer + 2;
		} while (vertPointer < planeVertices.length);

        // @formatter:off
		// this is confusing af
		var vertices = new DrawData<Float>(12, true, [
			// triangle 1
			planeVertices[0], planeVertices[1], // top left
			planeVertices[2], planeVertices[3], // top right
			planeVertices[6], planeVertices[7], // bottom left
			// triangle 2
			planeVertices[0], planeVertices[1], // top right
			planeVertices[4], planeVertices[5], // top left
			planeVertices[6], planeVertices[7] // bottom right
		]);
		final uvRectangle = arrow.frame.uv;
		var uvData = new DrawData<Float>(18, true, [
			// uv for triangle 1
			uvRectangle.x,      uvRectangle.y,      1 / projectionZ[0], // top left
			uvRectangle.width,  uvRectangle.y,      1 / projectionZ[1], // top right
			uvRectangle.width,  uvRectangle.height, 1 / projectionZ[3], // bottom left
			// uv for triangle 2
			uvRectangle.x,      uvRectangle.y,      1 / projectionZ[0], // top right
			uvRectangle.x,      uvRectangle.height, 1 / projectionZ[2], // top left
			uvRectangle.width,  uvRectangle.height, 1 / projectionZ[3]  // bottom right
		]);
        // @formatter:on
		final absGlow = output.visuals.glow * 255;
		final negGlow = 1 - output.visuals.glow;
		var color = new ColorTransform(negGlow, negGlow, negGlow, arrow.alpha * output.visuals.alpha, Math.round(output.visuals.glowR * absGlow),
			Math.round(output.visuals.glowG * absGlow), Math.round(output.visuals.glowB * absGlow));

		// make the instruction
		var newInstruction:FMDrawInstruction = {};
		newInstruction.item = arrow;
		newInstruction.vertices = vertices;
		newInstruction.uvt = uvData;
		newInstruction.indices = new Vector<Int>(vertices.length, true, [for (i in 0...vertices.length) i]);
		newInstruction.colorData = [color];
		queue[count] = newInstruction;

		count++;
	}

	override public function shift() {
		__drawInstruction(queue[postCount++]);
	}

	private function __drawInstruction(instruction:FMDrawInstruction) {
		if (instruction == null)
			return;

		final item = instruction.item;
		final cameras = item._cameras != null ? item._cameras : Adapter.instance.getArrowCamera();

		@:privateAccess
		for (camera in cameras) {
			final cTransform = instruction.colorData[0];
			cTransform.alphaMultiplier *= camera.alpha;

			camera.drawTriangles(item.graphic, instruction.vertices, instruction.indices, instruction.uvt, new Vector<Int>(), null, item.blend, false,
				item.antialiasing, cTransform, item.shader);
		}
	}
}

class ModchartArrowPath extends ModchartRenderer<FlxSprite> {
	var __shape:Shape = new Shape();
	var __display:FlxSprite = new FlxSprite();
	var __queuedPoints:Array<Array<Float>> = [];
	var __pathPoints:Vector<Float> = new Vector<Float>();
	var __pathCommands:Vector<Int> = new Vector<Int>();

	public function new(instance:PlayField) {
		super(instance);

		__display.makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
	}

	// the entry sprite should be A RECEPTOR / STRUM !!
	override public function prepare(item:FlxSprite) {
		final lane = Adapter.instance.getLaneFromArrow(item);
		final fn = Adapter.instance.getPlayerFromArrow(item);

		final alpha = instance.getPercent('arrowPathAlpha', fn);
		final thickness = 1 + Std.int(instance.getPercent('arrowPathThickness', fn));

		if (alpha <= 0 || thickness <= 0)
			return;

		final divisions = Std.int(40 / Math.max(1, instance.getPercent('arrowPathDivisions', fn)));
		final limit = 1500 * (1 + instance.getPercent('arrowPathLength', fn));
		final interval = limit / divisions;

		var moved = false;

		pathVector.setTo(Adapter.instance.getDefaultReceptorX(lane, fn), Adapter.instance.getDefaultReceptorY(lane, fn), 0);
		pathVector.incrementBy(ModchartUtil.getHalfPos());

		var pointData:Array<Array<Dynamic>> = [];
		pointData.resize(divisions);

		var pID = 0;

		var songPos = Adapter.instance.getSongPosition();

		for (sub in 0...divisions) {
			var hitTime = -500 + interval * sub;

			var output = instance.modifiers.getPath(pathVector.clone(), {
				hitTime: songPos + hitTime,
				distance: hitTime,
				lane: lane,
				player: fn,
				isTapArrow: true
			}, 0, true);
			final position = output.pos;

			/*
			 * So it seems that if the lines are too far from the screen
			 * causes HORRIBLE memory leaks (from 60mb to 3gb-5gb in 2 seconds WHAT THE FUCK)
			 */
			if ((position.x <= 0 - thickness - ARROW_PATH_BOUNDARY_OFFSET)
				|| (position.x >= __display.pixels.rect.width + ARROW_PATH_BOUNDARY_OFFSET)
				|| (position.y <= 0 - thickness - ARROW_PATH_BOUNDARY_OFFSET)
				|| (position.y >= __display.pixels.rect.height + ARROW_PATH_BOUNDARY_OFFSET))
				continue;

			final vis:PathVisuals = {
				alpha: alpha * output.visuals.alpha,
				scale: thickness * output.visuals.scaleX,
				color: 0xFFFFFF
			};
			pointData[pID++] = [!moved, position.x, position.y, position.z, vis];

			moved = true;
		}

		var newInstruction:FMDrawInstruction = {};
		// newInstruction.mappedExtra = ['s' => [thickness, 0xFFFFFFFF, alpha], 'pd' => pointData, 'l' => lane, 'p' => fn];
		newInstruction.extra = [pointData];
		queue[count] = newInstruction;
		count++;
	}

	override public function shift() {
		if (queue.length <= 0)
			return;

		__pathPoints.splice(0, __pathPoints.length);
		__pathCommands.splice(0, __pathCommands.length);
		__shape.graphics.clear();
		__display.cameras = Adapter.instance.getArrowCamera();

		var lastLane = -1;

		for (i in 0...queue.length) {
			final instruction = queue[i];
			final data:Array<Array<Dynamic>> = cast instruction.extra[0];
			final steps = data.iterator();

			var stepsHasNext = steps.hasNext;
			var stepsNext = steps.next;

			while (stepsHasNext()) {
				final thisStep = stepsNext();

				// in case the instruction is null (if the point is not visible in screen, we skip it)
				if (thisStep == null)
					continue;

				final needsToMove:Bool = cast thisStep[0];
				final posX:Float = cast thisStep[1];
				final posY:Float = cast thisStep[2];
				final visuals:PathVisuals = cast thisStep[4];

				__shape.graphics.lineStyle(visuals.scale, visuals.color, visuals.alpha, false, NORMAL);
				__pathCommands.push(needsToMove ? GraphicsPathCommand.MOVE_TO : GraphicsPathCommand.LINE_TO);
				__pathPoints.push(posX);
				__pathPoints.push(posY);
			}
		}

		__shape.graphics.drawPath(__pathCommands, __pathPoints);

		// then drawing the path pixels into the sprite pixels
		__display.pixels.fillRect(__display.pixels.rect, 0x00FFFFFF);
		__display.pixels.draw(__shape);
		// draw the sprite to the cam
		__display.draw();
	}

	override function dispose() {
		__display.destroy();
		__shape.graphics.clear();
		__pathPoints.splice(0, __pathPoints.length);
		__pathCommands.splice(0, __pathCommands.length);
	}

	inline static final ARROW_PATH_BOUNDARY_OFFSET:Float = 300;
}

// TODO: fix this, i have this class in private cuz it sucks and doesnt even draw anything
// also should i call this actor frame ?
class ModchartProxyRenderer extends ModchartRenderer<FlxCamera> {
	override public function prepare(cam:FlxCamera):Void {}
}

/*
	private class ModchartRenderCache {
	static var positionCache:ObjectMap<MCachedInfo, modchart.core.ModifierGroup.ModifierOutput>;

	static function get(time:Float, lane:Int, player:Int):MCachedInfo
		return positionCache.get(buildInfo(time, lane, player));

	static function set(output:modchart.core.ModifierGroup.ModifierOutput, time:Float, lane:Int, player:Int):MCachedInfo
		positionCache.set(buildInfo(time, lane, player));

	static function buildInfo(time:Float, lane:Int, player:Int):MCachedInfo {
		return {
			time: time,
			lane: lane,
			player: player
		};
	}

	static function dispose() {
		for (out in positionCache) {
			out.visuals = null;
			out.pos = null;
		}
		positionCache.clear();
		positionCache = null;
	}
	}

	typedef MCachedInfo = {
	time:Float,
	lane:Int,
	player:Int
};*/
@:publicFields
@:structInit
class FMDrawInstruction {
	var item:FlxSprite;
	var vertices:openfl.Vector<Float>;
	var uvt:openfl.Vector<Float>;
	var indices:openfl.Vector<Int>;
	var colorData:Array<ColorTransform>;

	var extra:Array<Dynamic>;
	var mappedExtra:Map<String, Dynamic>;

	public function new() {}
}

@:publicFields
@:structInit
class PathVisuals {
	var alpha:Float = 1;
	var scale:Float = 1;
	var color:Int = 0xFFFFFFF;
}
