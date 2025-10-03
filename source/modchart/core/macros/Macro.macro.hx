package modchart.core.macros;

import haxe.ds.StringMap;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassField;

class Macro {
	public static function includeFiles() {
		Compiler.include('modchart', true, ['modchart.standalone.adapters']);
		Compiler.include("modchart.standalone.adapters." + haxe.macro.Context.definedValue("FM_ENGINE").toLowerCase());
	}

	public static function addModchartStorage():Array<Field> {
		final fields = Context.getBuildFields();
		final pos = Context.currentPos();

		for (f in fields) {
			if (f.name == 'set_visible') {
				switch (f.kind) {
					case FFun(fun):
						fun.expr = macro {
							visible = value;
							_fmVisible = value;

							return value;
						};
					default:
						// do nothing
				}
			} else if (f.name == 'get_visible') {
				switch (f.kind) {
					case FFun(fun):
						fun.expr = macro {
							return _fmVisible;
						};
					default:
						// do nothing
				}
			}
		}

		// uses _z to prevent collisions with other classes
		final zField:Field = {
			name: "_z",
			access: [APublic],
			kind: FieldType.FVar(macro :Float, macro $v{0}),
			pos: pos
		};
		final visField:Field = {
			name: "_fmVisible",
			access: [APublic],
			kind: FieldType.FVar(macro :Null<Bool>, macro true),
			pos: pos
		};

		fields.push(zField);
		fields.push(visField);

		return fields;
	}

	public static function buildFlxCamera():Array<Field> {
		var fields = Context.getBuildFields();

		// idk why when i dont change the general draw items pooling system, theres so much graphic issues (with colors and uvs)
		/*
			var newField:Field = {
				name: '__fmStartTrianglesBatch',
				pos: Context.currentPos(),
				access: [APrivate],
				kind: FFun({
					args: [
						{
							name: "graphic",
							type: macro :flixel.graphics.FlxGraphic
						},
						{
							name: "blend",
							type: macro :openfl.display.BlendMode
						},
						{
							name: "shader",
							type: macro :flixel.system.FlxAssets.FlxShader
						},
						{
							name: "antialiasing",
							type: macro :Bool,
							value: macro $v{false}
						}
					],
					expr: macro {
						return getNewDrawTrianglesItem(graphic, antialiasing, true, blend, true, shader);
					},
					ret: macro :flixel.graphics.tile.FlxDrawTrianglesItem
				})
			};
			fields.push(newField);
		 */

		for (f in fields) {
			if (f.name == 'startTrianglesBatch') {
				switch (f.kind) {
					case FFun(fun):
						// we're just removing a if statement cuz causes some color issues
						fun.expr = macro {
							return getNewDrawTrianglesItem(graphic, smoothing, isColored, blend #if (flixel >= "5.2.0"), hasColorOffsets, shader #end);
						};
					default:
						// do nothing
				}
			}
		}

		return fields;
	}

	public static function buildFlxDrawTrianglesItem():Array<Field> {
		var fields = Context.getBuildFields();
		var newField:Field = {
			name: 'addGradientTriangles',
			pos: Context.currentPos(),
			access: [APublic],
			kind: FieldType.FFun({
				args: [
					{
						name: 'vertices',
						type: macro :DrawData<Float>
					},
					{
						name: 'indices',
						type: macro :DrawData<Int>
					},
					{
						name: 'uvtData',
						type: macro :DrawData<Float>
					},
					{
						name: 'colors',
						type: macro :DrawData<Int>,
						opt: true
					},
					{
						name: 'position',
						type: macro :FlxPoint,
						opt: true
					},
					{
						name: 'cameraBounds',
						type: macro :FlxRect,
						opt: true
					},
					{
						name: 'transforms',
						type: macro :Array<ColorTransform>,
						opt: true
					}
				],
				expr: macro {
					if (position == null)
						position = point.set();

					if (cameraBounds == null)
						cameraBounds = rect.set(0, 0, FlxG.width, FlxG.height);

					var verticesLength:Int = vertices.length;
					var prevVerticesLength:Int = this.vertices.length;
					var numberOfVertices:Int = Std.int(verticesLength / 2);
					var prevIndicesLength:Int = this.indices.length;
					var prevUVTDataLength:Int = this.uvtData.length;
					var prevColorsLength:Int = this.colors.length;
					var prevNumberOfVertices:Int = this.numVertices;

					var tempX:Float, tempY:Float;
					var i:Int = 0;
					var currentVertexPosition:Int = prevVerticesLength;

					while (i < verticesLength) {
						tempX = position.x + vertices[i];
						tempY = position.y + vertices[i + 1];

						this.vertices[currentVertexPosition++] = tempX;
						this.vertices[currentVertexPosition++] = tempY;

						if (i == 0) {
							bounds.set(tempX, tempY, 0, 0);
						} else {
							inflateBounds(bounds, tempX, tempY);
						}

						i = i + 2;
					}

					var indicesLength:Int = indices.length;
					if (!cameraBounds.overlaps(bounds)) {
						this.vertices.splice(this.vertices.length - verticesLength, verticesLength);
					} else {
						var uvtDataLength:Int = uvtData.length;
						for (i in 0...uvtDataLength) {
							this.uvtData[prevUVTDataLength + i] = uvtData[i];
						}

						for (i in 0...indicesLength) {
							this.indices[prevIndicesLength + i] = indices[i] + prevNumberOfVertices;
						}

						if (colored) {
							for (i in 0...numberOfVertices) {
								this.colors[prevColorsLength + i] = colors[i];
							}

							colorsPosition = colorsPosition + numberOfVertices;
						}

						verticesPosition = verticesPosition + verticesLength;
						indicesPosition = indicesPosition + indicesLength;
					}

					position.putWeak();
					cameraBounds.putWeak();

					#if (flixel >= "5.2.0")
					final indDiv = (1 / indicesLength);

					var curAlphas = [];
					curAlphas.resize(indicesLength);
					var j = 0;

					for (_ in 0...indicesLength) {
						final possibleTransform = transforms[Std.int(_ * indDiv * transforms.length)];

						var alphaMultiplier = 1.;

						if (possibleTransform != null)
							alphaMultiplier = possibleTransform.alphaMultiplier;

						curAlphas[j++] = alphaMultiplier;
					}

					alphas = alphas.concat(curAlphas);

					if (colored || hasColorOffsets) {
						if (colorMultipliers == null)
							colorMultipliers = [];

						if (colorOffsets == null)
							colorOffsets = [];

						var curMultipliers = [];
						var curOffsets = [];

						var multCount = 0;
						var offCount = 0;

						curMultipliers.resize(indicesLength * (3 + 1));
						curOffsets.resize(indicesLength * 4);

						for (_ in 0...indicesLength) {
							final transform = transforms[Std.int(_ * indDiv * transforms.length)];
							if (transform != null) {
								curMultipliers[multCount + 0] = transform.redMultiplier;
								curMultipliers[multCount + 1] = transform.greenMultiplier;
								curMultipliers[multCount + 2] = transform.blueMultiplier;

								curOffsets[offCount + 0] = transform.redOffset;
								curOffsets[offCount + 1] = transform.greenOffset;
								curOffsets[offCount + 2] = transform.blueOffset;
								curOffsets[offCount + 3] = transform.alphaOffset;
							} else {
								curMultipliers[multCount + 0] = 1;
								curMultipliers[multCount + 1] = 1;
								curMultipliers[multCount + 2] = 1;

								curOffsets[offCount + 0] = 0;
								curOffsets[offCount + 1] = 0;
								curOffsets[offCount + 2] = 0;
								curOffsets[offCount + 3] = 0;
							}

							curMultipliers[multCount + 3] = 1;

							multCount = multCount + (3 + 1);
							offCount = offCount + 4;
						}

						colorMultipliers = colorMultipliers.concat(curMultipliers);
						colorOffsets = colorOffsets.concat(curOffsets);
					}
					#end
				}
			}),
		};

		fields.push(newField);

		return fields;
	}
	/*
		public static function generateModList()
		{
			Context.onAfterInitMacros(() -> {
				final modifierList:Array<Class<Modifier>> = Type.resolveClass('CompileTime').getClassList('modchart.modifiers', true, modchart.Modifier);
				final mappedModifiers:Map<String, Class<Modifier>> = [];

				for (i in 0...modifierList.length)
				{
					final modifierClass = modifierList[i];

					final meta = Meta.getType(modifierClass);
					if (meta != null)
					{
						Context.info('$meta', Context.currentPos());
					}

					var modifierName = Type.getClassName(modifierClass);
					modifierName = modifierName.substring(modifierName.lastIndexOf('.') + 1);
					mappedModifiers[modifierName.toLowerCase()] = modifierClass;
				}

				Constants.MODIFIER_LIST = mappedModifiers;

				Context.info('---- Modifiers Founded ----\n$mappedModifiers');
			});
	}*/
}
