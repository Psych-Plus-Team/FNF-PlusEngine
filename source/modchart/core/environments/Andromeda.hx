package modchart.core.environments;

import haxe.ds.StringMap;
import modchart.events.Event;

using StringTools;

// Adapter to use Andromeda's ModMngr functions on FunkinModchart (based on LuaModMngr)
// andromeda engine doesnt support PlayFields so u cant use playfields on this environment :/
class Andromeda implements IEnvironment {
	public var parent:Manager;

	private final parseKeys:StringMap<String> = ['localrotate' => 'fieldrotate', 'boost' => 'accelerate'];

	public function setup(parent:Manager) {
		this.parent = parent;

		define('oppponentSwap');
		define('zigzag');
		define('sawtooth');
		define('bounce');
		define('square');
		define('mini');
		define('invert');
		define('tornado');
		define('drunk');
		define('beat');
		define('rotate');
		define('centerrotate');
		define('localrotate');
		define('accelerate');
		define('transform');
		define('infinite');
		define('receptorscroll');
	}

	public function dispose() {}

	public function define(modName:String) {
		parent.addModifier(modName);
	}

	public function set(modName:String, percent:Float, player:Null<Int>) {
		parent.setPercent(parseMod(modName), percent * 0.001, parsePlayer(player));
	}

	public function get(modName:String, player:Null<Int>):Float {
		return parent.getPercent(parseMod(modName), parsePlayer(player));
	}

	public function queueSet(step:Float, modName:String, percent:Float, player:Null<Int>) {
		parent.set(parseMod(modName), bfs(step), percent * 0.001, parsePlayer(player));
	}

	public function queueEase(step:Float, endStep:Float, modName:String, percent:Float, easingStyle:String, player:Null<Int>) {
		parent.ease(parseMod(modName), bfs(step), bfs(endStep - step), percent * 0.01, cast Reflect.field(flixel.tweens.FlxEase, easingStyle),
			parsePlayer(player));
	}

	public function queueEaseL(step:Float, length:Float, modName:String, percent:Float, easingStyle:String, player:Null<Int>) {
		parent.ease(parseMod(modName), bfs(step), bfs(length), percent * 0.01, cast Reflect.field(flixel.tweens.FlxEase, easingStyle), parsePlayer(player));
	}

	private function parsePlayer(player:Null<Int>):Int {
		if (player == null)
			return -1;

		return 1 - player;
	}

	private function parseMod(name:String) {
		var vname = name.toLowerCase();
		for (k => v in parseKeys) {
			vname.replace(k, v);
		}
		return vname;
	}

	private final bfs:Float->Float = (s) -> Adapter.instance.getBeatFromStep(s);
}
