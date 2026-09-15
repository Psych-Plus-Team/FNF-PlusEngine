package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class PullToRefresh
{
	public static function compose(composer:Composer, refreshing:Bool, onRefresh:Void->Void, ?modifier:Modifier):Void
		Material3.PullToRefresh(composer, refreshing, onRefresh, modifier);
}
