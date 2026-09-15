package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class ListItem
{
	public static function compose(composer:Composer, headline:String, ?supportingText:String, ?leadingLabel:String, ?trailingLabel:String,
			?onClick:Void->Void, ?modifier:Modifier):Void
		Material3.ListItem(composer, headline, supportingText, leadingLabel, trailingLabel, onClick, modifier);
}
