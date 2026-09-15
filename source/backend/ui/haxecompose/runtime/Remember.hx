package backend.ui.haxecompose.runtime;

import backend.ui.haxecompose.runtime.State.MutableState;

class Remember
{
	public static inline function remember<T>(composer:Composer, factory:Void->T):T
		return composer.remember(factory);

	public static inline function mutableStateOf<T>(composer:Composer, initial:T):MutableState<T>
		return composer.mutableStateOf(initial);
}
