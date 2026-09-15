package backend.ui.haxecompose.runtime;

class ComposeMetrics
{
	public var recompositions:Int = 0;
	public var nodesCreated:Int = 0;
	public var nodesReused:Int = 0;
	public var nodesRemoved:Int = 0;
	public var measurePasses:Int = 0;
	public var drawPasses:Int = 0;
	public var stateInvalidations:Int = 0;

	public function new() {}

	public function resetFrame():Void
	{
		recompositions = 0;
		nodesCreated = 0;
		nodesReused = 0;
		nodesRemoved = 0;
		measurePasses = 0;
		drawPasses = 0;
		stateInvalidations = 0;
	}

	public function dump():String
	{
		return [
			"Recompositions: " + recompositions,
			"Nodes created: " + nodesCreated,
			"Nodes reused: " + nodesReused,
			"Nodes removed: " + nodesRemoved,
			"Measure passes: " + measurePasses,
			"Draw passes: " + drawPasses,
			"State invalidations: " + stateInvalidations
		].join("\n");
	}
}
