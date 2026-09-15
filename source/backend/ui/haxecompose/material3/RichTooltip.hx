package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class RichTooltip
{
	public static function compose(composer:Composer, title:String, text:String, ?actionLabel:String, ?onAction:Void->Void, ?modifier:Modifier):Void
		Material3.RichTooltip(composer, title, text, actionLabel, onAction, modifier);
}
