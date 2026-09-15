package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class LoadingIndicator
{
	public static function compose(composer:Composer, progress:Null<Float> = null, ?modifier:Modifier):Void
		Material3.Progress(composer, progress, true, modifier);
}
