package psychlua;

import modchart.Manager;
import psychlua.FunkinLua;
import flixel.tweens.FlxEase;

class LuaModchart
{
    public static function implement(funk:FunkinLua) {
        var lua:State = funk.lua;
        
        // Agregar modificador
        Lua_helper.add_callback(lua, "addModifier", function(name:String, ?field:Int = -1) {
            var playState = states.PlayState.instance;
            if (Manager.instance == null && playState != null) {
                #if LUA_ALLOWED
                playState.add(new Manager());
                #end
            }
            if (Manager.instance != null)
                Manager.instance.addModifier(name, field);
        });
        
        // Establecer porcentaje de modificador
        Lua_helper.add_callback(lua, "setPercent", function(name:String, value:Float, ?player:Int = -1, ?field:Int = -1) {
            var playState = states.PlayState.instance;
            if (Manager.instance == null && playState != null) {
                #if LUA_ALLOWED
                playState.add(new Manager());
                #end
            }
            if (Manager.instance != null)
                Manager.instance.setPercent(name, value, player, field);
        });
        
        // Obtener porcentaje de modificador
        Lua_helper.add_callback(lua, "getPercent", function(name:String, ?player:Int = 0, ?field:Int = 0):Float {
            if (Manager.instance != null)
                return Manager.instance.getPercent(name, player, field);
            return 0.0;
        });
        
        // Establecer valor en un beat específico
        Lua_helper.add_callback(lua, "set", function(name:String, beat:Float, value:Float, ?player:Int = -1, ?field:Int = -1) {
            var playState = states.PlayState.instance;
            if (Manager.instance == null && playState != null) {
                #if LUA_ALLOWED
                playState.add(new Manager());
                #end
            }
            if (Manager.instance != null)
                Manager.instance.set(name, beat, value, player, field);
        });
        
        // Aplicar easing a un modificador
        Lua_helper.add_callback(lua, "ease", function(name:String, beat:Float, length:Float, value:Float, easeName:String, ?player:Int = -1, ?field:Int = -1) {
            var playState = states.PlayState.instance;
            if (Manager.instance == null && playState != null) {
                #if LUA_ALLOWED
                playState.add(new Manager());
                #end
            }
            if (Manager.instance != null) {
                var easeFunc = getEaseFunction(easeName);
                Manager.instance.ease(name, beat, length, value, easeFunc, player, field);
            }
        });
        
        // Agregar valor con easing
        Lua_helper.add_callback(lua, "add", function(name:String, beat:Float, length:Float, value:Float, easeName:String, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null) {
                var easeFunc = getEaseFunction(easeName);
                Manager.instance.add(name, beat, length, value, easeFunc, player, field);
            }
        });
        
        // Establecer y agregar valor
        Lua_helper.add_callback(lua, "setAdd", function(name:String, beat:Float, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null)
                Manager.instance.setAdd(name, beat, value, player, field);
        });
        
        // Agregar nuevo playfield
        Lua_helper.add_callback(lua, "addPlayfield", function() {
            if (Manager.instance != null)
                Manager.instance.addPlayfield();
        });
        
        // Crear alias para modificador
        Lua_helper.add_callback(lua, "alias", function(name:String, aliasName:String, field:Int) {
            if (Manager.instance != null)
                Manager.instance.alias(name, aliasName, field);
        });
        
        // Constantes útiles
        Lua_helper.add_callback(lua, "getHoldSize", function():Float {
            return Manager.HOLD_SIZE;
        });
        
        Lua_helper.add_callback(lua, "getHoldSizeDiv2", function():Float {
            return Manager.HOLD_SIZEDIV2;
        });
        
        Lua_helper.add_callback(lua, "getArrowSize", function():Float {
            return Manager.ARROW_SIZE;
        });
        
        Lua_helper.add_callback(lua, "getArrowSizeDiv2", function():Float {
            return Manager.ARROW_SIZEDIV2;
        });
    }
    
    // Función auxiliar para convertir nombres de easing a funciones
    private static function getEaseFunction(easeName:String) {
        return LuaUtils.getTweenEaseByString(easeName);
    }
}