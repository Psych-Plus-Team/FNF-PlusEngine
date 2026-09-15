package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class SearchBar
{
	public static function compose(composer:Composer, query:String, placeholder:String, ?onClick:Void->Void, ?modifier:Modifier):Void
		Material3.SearchBar(composer, query, placeholder, onClick, modifier);
}
