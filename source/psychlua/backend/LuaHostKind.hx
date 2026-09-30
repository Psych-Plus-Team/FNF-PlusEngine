#if LUA_ALLOWED
package psychlua.backend;

enum abstract LuaHostKind(String) from String to String
{
	var PLAYSTATE = "playstate";
	var NONE = "none";
}
#end
