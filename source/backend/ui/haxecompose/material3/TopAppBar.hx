package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class TopAppBar
{
	public static function compose(composer:Composer, title:String, ?navigationLabel:String, ?actionLabel:String, ?onNavigationClick:Void->Void,
			?onActionClick:Void->Void, ?modifier:Modifier):Void
		Material3.TopAppBar(composer, title, navigationLabel, actionLabel, onNavigationClick, onActionClick, modifier);
}
