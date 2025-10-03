package modchart.modifiers;

import modchart.core.PlayField;
import modchart.core.util.Constants.ArrowData;
import modchart.core.util.Constants.RenderParams;
import modchart.modifiers.PathModifier.PathNode;
import openfl.geom.Vector3D;

class ArrowShape extends PathModifier {
	public function new(pf:PlayField) {
		var path:Array<PathNode> = [];

		for (line in ModchartUtil.coolTextFile('assets/modchart/arrowShape.csv')) {
			var coords = line.split(';');
			path.push({
				x: Std.parseFloat(coords[0]) * 200,
				y: Std.parseFloat(coords[1]) * 200,
				z: Std.parseFloat(coords[2]) * 200
			});
		}

		super(pf, path);

		pathOffset.setTo(WIDTH * 0.5, HEIGHT * 0.5 + 280, 0);
	}

	override function render(pos:Vector3D, params:RenderParams) {
		var perc = getPercent('arrowshape', params.player);

		if (perc == 0)
			return pos;

		pathOffset.z = pos.z;
		return computePath(pos, params, perc);
	}
}
