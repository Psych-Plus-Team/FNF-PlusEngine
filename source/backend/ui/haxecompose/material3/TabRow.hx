package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class TabRow
{
	public static function compose(composer:Composer, tabs:Array<String>, selectedTabIndex:Int, onTabSelected:Int->String->Void, ?modifier:Modifier):Void
		Material3.Tabs(composer, tabs, selectedTabIndex, onTabSelected, modifier);
}
