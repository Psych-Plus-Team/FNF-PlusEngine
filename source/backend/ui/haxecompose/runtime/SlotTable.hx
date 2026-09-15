package backend.ui.haxecompose.runtime;

import backend.ui.haxecompose.ui.Node;

class SlotTable
{
	var nodes:Map<String, Node> = [];
	var groups:Map<String, CompositionGroup> = [];
	var remembered:Map<String, Dynamic> = [];
	var touchedNodes:Map<String, Bool> = [];
	var touchedSlots:Map<String, Bool> = [];

	public function new() {}

	public function begin():Void
	{
		touchedNodes = [];
		touchedSlots = [];
	}

	public function node(path:String, type:String):Node
	{
		var existing = nodes.get(path);
		if (existing == null || existing.type != type)
		{
			if (existing != null)
				existing.dispose();
			existing = new Node(type, path);
			nodes.set(path, existing);
			Recomposer.instance.metrics.nodesCreated++;
		}
		else
			Recomposer.instance.metrics.nodesReused++;
		touchedNodes.set(path, true);
		return existing;
	}

	public function group(path:String):CompositionGroup
	{
		var existing = groups.get(path);
		if (existing == null)
		{
			existing = new CompositionGroup(path);
			groups.set(path, existing);
		}
		return existing;
	}

	public function remember<T>(path:String, factory:Void->T):T
	{
		touchedSlots.set(path, true);
		if (!remembered.exists(path))
			remembered.set(path, factory());
		return cast remembered.get(path);
	}

	public function prune():Void
	{
		for (path in nodes.keys())
		{
			if (!touchedNodes.exists(path))
			{
				var node = nodes.get(path);
				if (node != null)
					node.dispose();
				nodes.remove(path);
				Recomposer.instance.metrics.nodesRemoved++;
			}
		}

		for (path in remembered.keys())
			if (!touchedSlots.exists(path))
				remembered.remove(path);

		for (path in groups.keys())
		{
			if (!nodes.exists(path))
			{
				var group = groups.get(path);
				StateDependencyRegistry.clearGroup(group);
				groups.remove(path);
			}
		}
	}
}
