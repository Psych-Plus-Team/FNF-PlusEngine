package backend.ui.haxecompose.material;

import backend.ui.haxecompose.foundation.Column;
import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.runtime.Composer.Composable;
import backend.ui.haxecompose.ui.Modifier;

class Scaffold
{
	public static function compose(composer:Composer, ?modifier:Modifier, ?topBar:Composable, ?content:Composable):Void
	{
		Column.compose(composer, (modifier != null ? modifier : Modifier.empty()).fillMaxWidth(), function(c)
		{
			if (topBar != null)
				topBar(c);
			if (content != null)
				content(c);
		});
	}
}
