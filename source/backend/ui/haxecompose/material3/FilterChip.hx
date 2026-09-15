package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class FilterChip
{
	public static function compose(composer:Composer, label:String, selected:Bool, onClick:Void->Void, ?modifier:Modifier):Void
		Material3.Chip(composer, label, selected, onClick, modifier);
}
