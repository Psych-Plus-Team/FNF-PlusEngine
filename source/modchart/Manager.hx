package modchart;

import flixel.FlxBasic;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.util.FlxSort;
import haxe.ds.ArraySort;
import haxe.ds.Vector;
import modchart.core.ModifierGroup;
import modchart.core.PlayField;
import modchart.core.graphics.ModchartGraphics.ModchartArrowPath;
import modchart.core.graphics.ModchartGraphics.ModchartArrowRenderer;
import modchart.core.graphics.ModchartGraphics.ModchartHoldRenderer;
import modchart.core.graphics.ModchartGraphics.ModchartRenderer;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.core.util.Constants.Visuals;
import modchart.core.util.ModchartUtil;
import modchart.events.*;
import modchart.events.types.*;
import modchart.modifiers.*;

@:allow(modchart.core.ModifierGroup)
@:allow(modchart.core.graphics.ModchartGraphics)
@:access(modchart.core.PlayField)
final class Manager extends FlxBasic {
	/**
	 * Singleton instance of the Manager.
	 */
	public static var instance:Manager;

	/**
	 * Flag to enable or disable rendering of arrow paths.
	 */
	public var renderArrowPaths:Bool = false;

	/**
	 * List of playfields managed by the Manager.
	 */
	public var playfields:Vector<PlayField> = new Vector<PlayField>(16);

	private var playfieldCount:Int = 0;

	public function new() {
		super();

		instance = this;

		Adapter.init();
		Adapter.instance.onModchartingInitialization();

		addPlayfield();
	}

	/**
	 * Internal helper function to apply a function to each playfield.
	 * 
	 * @param func The function to apply to each playfield.
	 * @param player Optionally, the specific player to target (-1 for all).
	 */
	@:noCompletion
	private inline function __forEachPlayfield(func:PlayField->Void, player:Int = -1) {
		// If there's only one playfield or a specific player is provided, apply the function directly
		if (playfieldCount <= 1 || player != -1)
			return func(playfields[player != -1 ? player : 0]);

		// Otherwise, apply the function to all playfields
		for (i in 0...playfields.length)
			func(playfields[i]);
	}

	/**
	 * Registers a modifier for all playfields or a specific one.
	 * 
	 * @param name The name of the modifier.
	 * @param mod The class type of the modifier.
	 * @param player Optionally, the specific player to target.
	 */
	public inline function registerModifier(name:String, mod:Class<Modifier>, player:Int = -1)
		__forEachPlayfield((pf) -> pf.registerModifier(name, mod), player);

	/**
	 * Adds a modifier for all playfields or a specific one.
	 * 
	 * @param name The name of the modifier.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function addModifier(name:String, field:Int = -1)
		__forEachPlayfield((pf) -> pf.addModifier(name), field);

	/**
	 * Adds a scripted modifier for all playfields or a specific one.
	 * 
	 * @param name The name of the modifier.
	 * @param instance The instance of the modifier.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function addScriptedModifier(name:String, instance:Modifier, field:Int = -1)
		__forEachPlayfield((pf) -> pf.addScriptedModifier(name, instance), field);

	/**
	 * Sets the percent for a specific modifier for all playfields or a specific one.
	 * 
	 * @param name The name of the modifier.
	 * @param value The percent value to set.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function setPercent(name:String, value:Float, player:Int = -1, field:Int = -1)
		__forEachPlayfield((pf) -> pf.setPercent(name, value, player), field);

	/**
	 * Gets the percent for a specific modifier.
	 * 
	 * @param name The name of the modifier.
	 * @param player The player to target.
	 * @param field Optionally, the specific playfield to target.
	 * @return The percent value for the modifier.
	 */
	public inline function getPercent(name:String, player:Int = 0, field:Int = 0):Float {
		final possiblePlayfield = playfields[field];

		if (possiblePlayfield != null)
			return possiblePlayfield.getPercent(name, player);

		return 0.;
	}

	/**
	 * Adds an event to all playfields or a specific one.
	 * 
	 * @param event The event to add.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function addEvent(event:Event, field:Int = -1)
		__forEachPlayfield((pf) -> pf.addEvent(event), field);

	/**
	 * Sets a specific value at a certain beat for all playfields or a specific one.
	 * 
	 * @param name The name of the value.
	 * @param beat The beat at which the value should be set.
	 * @param value The value to set.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function set(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1)
		__forEachPlayfield((pf) -> pf.set(name, beat, value, player), field);

	/**
	 * Applies easing to a modifier.
	 * 
	 * @param name The name of the modifier.
	 * @param beat The beat at which to start easing.
	 * @param length The length of the easing.
	 * @param value The final value after easing.
	 * @param easeFunc The easing function to use.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function ease(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1)
		__forEachPlayfield((pf) -> pf.ease(name, beat, length, value, easeFunc, player), field);

	/**
	 * Adds easing to a modifier.
	 * 
	 * @param name The name of the modifier.
	 * @param beat The beat at which to start easing.
	 * @param length The length of the easing.
	 * @param value The value to apply after easing.
	 * @param easeFunc The easing function to use.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function add(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1)
		__forEachPlayfield((pf) -> pf.add(name, beat, length, value, easeFunc, player), field);

	/**
	 * Sets and adds a value to a modifier.
	 * 
	 * @param name The name of the modifier.
	 * @param beat The beat at which the value should be set.
	 * @param value The value to set.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function setAdd(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1)
		__forEachPlayfield((pf) -> pf.setAdd(name, beat, value, player), field);

	/**
	 * Adds a repeater event for all playfields or a specific one.
	 * 
	 * @param beat The beat at which the repeater starts.
	 * @param length The length of the repeat action.
	 * @param callback The callback function to execute.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function repeater(beat:Float, length:Float, callback:Event->Void, field:Int = -1)
		__forEachPlayfield((pf) -> pf.repeater(beat, length, callback), field);

	/**
	 * Adds a callback event for all playfields or a specific one.
	 * 
	 * @param beat The beat at which the callback will be triggered.
	 * @param callback The callback function to execute.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function callback(beat:Float, callback:Event->Void, field:Int = -1)
		__forEachPlayfield((pf) -> pf.callback(beat, callback), field);

	/**
	 * Creates a node linking inputs and outputs to a function.
	 * 
	 * @param input The list of input names.
	 * @param output The list of output names.
	 * @param func The function to execute for the node.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function node(input:Array<String>, output:Array<String>, func:NodeFunction, field:Int = -1)
		__forEachPlayfield((pf) -> pf.node(input, output, func), field);

	/**
	 * Creates an alias for a given modifier.
	 * 
	 * @param name The original modifier name.
	 * @param alias The alias name.
	 * @param field The specific playfield to apply the alias to.
	 */
	public inline function alias(name:String, alias:String, field:Int)
		__forEachPlayfield((pf) -> pf.alias(name, alias), field);

	/**
	 * Adds a new playfield to the Manager.
	 */
	public inline function addPlayfield()
		playfields[playfieldCount++] = new PlayField();

	/**
	 * Updates all playfields in the game loop.
	 * 
	 * @param elapsed The time elapsed since the last update.
	 */
	override function update(elapsed:Float):Void {
		super.update(elapsed);

		__forEachPlayfield(pf -> pf.update(elapsed));
	}

	/**
	 * Draws all playfields, sorting them by z-order before drawing.
	 */
	override function draw():Void {
		var total = 0;
		__forEachPlayfield(pf -> {
			pf.draw();
			total += pf.drawCB.length;
		});

		var drawQueue:haxe.ds.Vector<Funny> = new haxe.ds.Vector<Funny>(total);

		var j = 0;
		__forEachPlayfield(pf -> {
			for (x in pf.drawCB)
				drawQueue[j++] = x;
		});

		drawQueue.sort((a, b) -> {
			return FlxSort.byValues(FlxSort.DESCENDING, a.z, b.z);
		});

		for (item in drawQueue) {
			item.callback();
		}
	}

	/**
	 * Destroys all playfields and cleans up.
	 */
	override function destroy():Void {
		super.destroy();

		__forEachPlayfield(pf -> {
			pf.destroy();
		});
	}

	// Constants for hold and arrow sizes
	public static var HOLD_SIZE:Float = 50 * 0.7;
	public static var HOLD_SIZEDIV2:Float = (50 * 0.7) * 0.5;
	public static var ARROW_SIZE:Float = 160 * 0.7;
	public static var ARROW_SIZEDIV2:Float = (160 * 0.7) * 0.5;
}

typedef Funny = {callback:Void->Void, z:Float};
