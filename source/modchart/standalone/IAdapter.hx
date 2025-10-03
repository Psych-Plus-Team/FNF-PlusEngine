package modchart.standalone;

import flixel.FlxCamera;
import flixel.FlxSprite;
import haxe.ds.Vector;

interface IAdapter {
	public function onModchartingInitialization():Void;

	// Song-related stuff
	public function getSongPosition():Float; // Current song position
	// public function getCrochet():Float           // Current beat crochet
	public function getStaticCrochet():Float; // Beat crochet without bpm changes
	public function getCurrentBeat():Float; // Current beat
	public function getCurrentScrollSpeed():Float; // Current arrow scroll speed
	public function getBeatFromStep(step:Float):Float;

	// Arrow-related stuff
	public function getDefaultReceptorX(lane:Int, player:Int):Float; // Get default strum x position
	public function getDefaultReceptorY(lane:Int, player:Int):Float; // Get default strum y position
	public function getTimeFromArrow(arrow:FlxSprite):Float; // Get strum time for arrow
	public function isTapNote(sprite:FlxSprite):Bool; // If the sprite is an arrow, return true, if it is an lane/strum, return false
	public function isHoldEnd(sprite:FlxSprite):Bool; // If its the hold end
	public function arrowHit(sprite:FlxSprite):Bool; // If the arrow was hitted
	public function getHoldParentTime(sprite:FlxSprite):Float;

	public function getLaneFromArrow(sprite:FlxSprite):Int; // Get lane/note data from arrow
	public function getPlayerFromArrow(sprite:FlxSprite):Int; // Get player from arrow

	public function getKeyCount(?player:Int):Int; // Get total key count from specific player (4 for almost every engine)
	public function getPlayerCount():Int; // Get total player count (2 for almost every engine)

	// Get cameras to render the arrows (camHUD for almost every engine)
	public function getArrowCamera():Array<FlxCamera>;

	// Options section
	public function getHoldSubdivisions():Int; // Hold resolution
	public function getDownscroll():Bool; // Get if it is downscroll

	/**
	 * Get the every arrow/lane indexed by player.
	 * Example:
	 * [
	 *      [ // Player 0
	 *          [strum1, strum2...],
	 *          [arrow1, arrow2...],
	 *          [hold1, hold2....],
	 * 			[splash1, splash2....]
	 *      ],
	 *      [ // Player 2
	 *          [strum1, strum2...],
	 *          [arrow1, arrow2...],
	 *          [hold1, hold2....],
	 * 			[splash1, splash2....]
	 *      ]
	 * ]
	 * @return Array<Array<Array<FlxSprite>>>
	 */
	public function getArrowItems():Array<Array<Array<FlxSprite>>>;
}
