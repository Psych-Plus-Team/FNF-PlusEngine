package states;

import flixel.FlxState;
import flixel.text.FlxText;

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
#end

import psychlua.LuaUtils;

#if sys
import sys.FileSystem;
#end

class ModState extends MusicBeatState
{
    #if HSCRIPT_ALLOWED
    public var hscriptArray:Array<HScript> = [];
    #end
    
    // Variables para cambiar de estado
    public static var nextState:FlxState = null;
    public var stateName:String = '';
    
    // Sistema de variables compartidas entre ModStates
    public static var sharedVars:Map<String, Dynamic> = new Map<String, Dynamic>();
    
    // Limpia sharedVars (útil al cambiar de mod o resetear)
    public static function clearAllSharedVars():Void
    {
        sharedVars.clear();
        trace('ModState: All shared vars cleared globally');
    }
    
    // Limpia solo variables de un mod específico (prefix-based)
    public static function clearModSharedVars(modName:String):Void
    {
        var keysToRemove:Array<String> = [];
        for(key in sharedVars.keys())
        {
            if(key.startsWith('${modName}_'))
                keysToRemove.push(key);
        }
        
        for(key in keysToRemove)
        {
            sharedVars.remove(key);
            trace('ModState: Removed shared var: $key');
        }
    }
    
    public function new(?stateName:String = '')
    {
        super();
        this.stateName = stateName;
    }

    override function create()
    {
        // Permitir que los scripts individuales controlen persistentUpdate
        // Solo establecer persistentDraw en true por defecto
        persistentDraw = true;
        
        // Cargar scripts automáticamente si se proporciona un stateName
        if(stateName != null && stateName.length > 0)
            loadStateScripts(stateName);
            
        callOnScripts('onCreate');
        super.create();
        callOnScripts('onCreatePost');
        var plusVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Plus Engine v" + MainMenuState.plusEngineVersion, 12);
        plusVer.scrollFactor.set();
        plusVer.alpha = 0.8;
        plusVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(plusVer);
    }

    override function update(elapsed:Float)
    {
        callOnScripts('onUpdate', [elapsed]);
        super.update(elapsed);
        callOnScripts('onUpdatePost', [elapsed]);
        
        // Cambiar de estado si se estableció uno nuevo
        if(nextState != null)
        {
            MusicBeatState.switchState(nextState);
            nextState = null;
        }
    }

    override function destroy()
    {
        callOnScripts('onDestroy');
        
        #if HSCRIPT_ALLOWED
        // Limpiar scripts
        for(script in hscriptArray)
        {
            if(script != null)
                script.destroy();
        }
        hscriptArray = [];
        #end
        
        super.destroy();
        callOnScripts('onDestroyPost');
    }
    
    // Carga scripts desde mods/nombredelmod/states/
    public function loadStateScripts(stateName:String)
    {
        #if (HSCRIPT_ALLOWED && sys)
        // Obtener el mod activo actual
        #if MODS_ALLOWED
        Mods.loadTopMod(); // Carga el mod activo
        var currentMod:String = Mods.currentModDirectory;
        #else
        var currentMod:String = '';
        #end
        
        // Limpiar sharedVars si cambió el mod
        var savedModDir:String = sharedVars.exists('currentModDirectory') ? sharedVars.get('currentModDirectory') : null;
        if(savedModDir != null && savedModDir != currentMod)
        {
            trace('ModState: Mod changed from "$savedModDir" to "$currentMod" - Clearing shared vars');
            sharedVars.clear(); // ✅ Limpia datos del mod anterior
        }
        
        var scriptPath:String = Paths.hx(stateName);
        
        if(FileSystem.exists(scriptPath))
        {
            initHScript(scriptPath);
            
            // Guardar el mod directory actual en sharedVars para futuros usos
            #if MODS_ALLOWED
            if(currentMod != null && currentMod.length > 0)
            {
                sharedVars.set('currentModDirectory', currentMod);
            }
            #end
        }
        else
        {
            trace('No script found for state: $stateName at $scriptPath');
            #if MODS_ALLOWED
            trace('Current mod directory: ${currentMod}');
            #end
        }
        #end
    }

    // Script management functions
    #if HSCRIPT_ALLOWED
    public function initHScript(file:String)
    {
        var newScript:HScript = null;
        try
        {
            newScript = new HScript(null, file);
            
            // Exponer funciones para manejar variables compartidas entre ModStates
            newScript.set('setSharedVar', function(name:String, value:Dynamic) {
                sharedVars.set(name, value);
                trace('ModState: Shared var set - $name = $value');
                return value;
            });
            
            newScript.set('getSharedVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
                if (sharedVars.exists(name)) {
                    var value = sharedVars.get(name);
                    trace('ModState: Shared var get - $name = $value');
                    return value;
                }
                trace('ModState: Shared var $name not found');
                return defaultValue;
            });
            
            newScript.set('hasSharedVar', function(name:String):Bool {
                return sharedVars.exists(name);
            });
            
            newScript.set('removeSharedVar', function(name:String):Bool {
                if (sharedVars.exists(name)) {
                    sharedVars.remove(name);
                    return true;
                }
                return false;
            });
            
            newScript.set('clearSharedVars', function() {
                sharedVars.clear();
                trace('ModState: All shared vars cleared');
            });
            
            if (newScript.exists('onCreate')) newScript.call('onCreate');
            trace('initialized hscript interp successfully: $file');
            hscriptArray.push(newScript);
        }
        catch(e:IrisError)
        {
            var pos:HScriptInfos = cast {fileName: file, showLine: false};
            Iris.error(Printer.errorToString(e, false), pos);
            var newScript:HScript = cast (Iris.instances.get(file), HScript);
            if(newScript != null)
                newScript.destroy();
        }
    }

    public function addHScript(scriptFile:String):Bool
    {
        #if sys
        var scriptToLoad:String = Paths.modFolders(scriptFile);
        if(!FileSystem.exists(scriptToLoad))
            scriptToLoad = Paths.getSharedPath(scriptFile);

        if(FileSystem.exists(scriptToLoad))
        {
            if (Iris.instances.exists(scriptToLoad)) return false;

            initHScript(scriptToLoad);
            return true;
        }
        #end
        return false;
    }
    #end

    // Call functions on all scripts
    public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
    {
        return callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
    }

    public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
    {
        var returnVal:Dynamic = LuaUtils.Function_Continue;

        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = new Array();
        if(excludeValues == null) excludeValues = new Array();
        excludeValues.push(LuaUtils.Function_Continue);

        var len:Int = hscriptArray.length;
        if (len < 1)
            return returnVal;

        for(script in hscriptArray)
        {
            @:privateAccess
            if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
                continue;

            var callValue = script.call(funcToCall, args);
            if(callValue != null)
            {
                var myValue:Dynamic = callValue.returnValue;

                if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
                {
                    returnVal = myValue;
                    break;
                }

                if(myValue != null && !excludeValues.contains(myValue))
                    returnVal = myValue;
            }
        }
        #end

        return returnVal;
    }

    public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
    {
        setOnHScript(variable, arg, exclusions);
    }

    public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
    {
        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = [];
        for (script in hscriptArray)
        {
            @:privateAccess
            if (exclusions.contains(script.origin))
                continue;

            script.set(variable, arg);
        }
        #end
    }
}