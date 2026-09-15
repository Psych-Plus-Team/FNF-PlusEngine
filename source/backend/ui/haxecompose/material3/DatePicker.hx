package backend.ui.haxecompose.material3;

import backend.ui.haxecompose.runtime.Composer;
import backend.ui.haxecompose.ui.Modifier;

class DatePicker
{
	public static function compose(composer:Composer, label:String, value:String, onPrevious:Void->Void, onNext:Void->Void, ?modifier:Modifier):Void
		Material3.DatePicker(composer, label, value, onPrevious, onNext, modifier);
}
