package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class SegmentedButtonRow
{
	public static function compose(composer:Composer, segments:Array<String>, selectedIndex:Int, onSelect:Int->String->Void, ?modifier:Modifier):Void
		Material3.SegmentedButtonRow(composer, segments, selectedIndex, onSelect, modifier);
}
