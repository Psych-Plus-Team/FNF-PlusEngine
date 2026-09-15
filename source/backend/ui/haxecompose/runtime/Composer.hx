package backend.ui.haxecompose.runtime;

import backend.ui.haxecompose.runtime.State.MutableState;
import backend.ui.haxecompose.ui.Modifier;
import backend.ui.haxecompose.ui.Node;

typedef Composable = Composer->Void;

class Composer
{
	public final recomposer:Recomposer;
	public final slots:SlotTable;
	public var root(default, null):Node;

	var nodeStack:Array<Node> = [];
	var pathStack:Array<String> = [];
	var childCounters:Array<Int> = [];
	var rememberCounters:Array<Int> = [];
	var groupStack:Array<CompositionGroup> = [];

	public function new(?recomposer:Recomposer)
	{
		this.recomposer = recomposer != null ? recomposer : Recomposer.instance;
		this.slots = new SlotTable();
	}

	public function compose(content:Composable):Bool
	{
		if (!recomposer.shouldCompose() && root != null)
			return false;

		slots.begin();
		nodeStack = [];
		pathStack = [];
		childCounters = [];
		rememberCounters = [];
		groupStack = [];

		root = startNode("Root", "root", Modifier.empty());
		if (content != null)
			content(this);
		endNode();

		slots.prune();
		recomposer.markComposed();
		return true;
	}

	public function emit(type:String, ?key:String, ?modifier:Modifier, ?configure:Node->Void, ?content:Composable):Node
	{
		var node = startNode(type, key, modifier);
		if (configure != null)
			configure(node);
		if (content != null)
			content(this);
		endNode();
		return node;
	}

	function startNode(type:String, ?key:String, ?modifier:Modifier):Node
	{
		var path:String;
		if (nodeStack.length == 0)
			path = key != null ? key : type;
		else
		{
			var parentIndex = childCounters.length - 1;
			var index = childCounters[parentIndex]++;
			var localKey = key != null ? key : Std.string(index);
			path = pathStack[pathStack.length - 1] + "/" + type + ":" + localKey;
		}

		var node = slots.node(path, type);
		var group = slots.group(path);
		node.beginCompose(modifier != null ? modifier : Modifier.empty());
		if (nodeStack.length > 0)
			nodeStack[nodeStack.length - 1].appendChild(node);

		nodeStack.push(node);
		pathStack.push(path);
		childCounters.push(0);
		rememberCounters.push(0);
		groupStack.push(group);
		StateObserver.currentGroup = group;
		return node;
	}

	function endNode():Void
	{
		var node = nodeStack.pop();
		if (node != null)
			node.endCompose();
		pathStack.pop();
		childCounters.pop();
		rememberCounters.pop();
		groupStack.pop();
		StateObserver.currentGroup = groupStack.length > 0 ? groupStack[groupStack.length - 1] : null;
	}

	public function remember<T>(factory:Void->T):T
	{
		if (pathStack.length == 0)
			return factory();

		var idx = rememberCounters.length - 1;
		var slot = rememberCounters[idx]++;
		return slots.remember(pathStack[pathStack.length - 1] + "/remember:" + slot, factory);
	}

	public function mutableStateOf<T>(initial:T):MutableState<T>
	{
		var state = remember(function() return new MutableState<T>(initial));
		return state;
	}
}
