package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class DockedSearchBar
{
	public static function compose(composer:Composer, query:String, suggestions:Array<String>, onSelect:Int->String->Void, ?modifier:Modifier):Void
		Material3.DockedSearchBar(composer, query, suggestions, onSelect, modifier);
}
