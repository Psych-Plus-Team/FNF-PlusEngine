package substates;

import backend.Mods;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.ClientPrefs;
import states.TitleState;

#if sys
import sys.FileSystem;
#end

class StateModSubstate extends MusicBeatSubstate
{
    var modsList:Array<String> = [];
    var modsWithStates:Array<{mod:String, states:Array<String>}> = [];
    var itemsGroup:FlxTypedGroup<FlxText>;
    var curSelected:Int = -1; // -1 = ninguno seleccionado
    var previousSelected:Int = -1;
    
    var bg:FlxSprite;
    var titleTxt:FlxText;
    var instructionsTxt:FlxText;
    
    var selectedModName:String = null;
    var hasChanges:Bool = false;
    
    public function new()
    {
        super();
    }
    
    override function create()
    {
        super.create();
        
        // Fondo semi-transparente
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.7;
        bg.scrollFactor.set(0, 0);
        add(bg);
        
        // Título
        titleTxt = new FlxText(0, 50, FlxG.width, "SELECT MOD STATE", 32);
        titleTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        titleTxt.borderSize = 2;
        titleTxt.scrollFactor.set(0, 0);
        add(titleTxt);
        
        // Instrucciones
        instructionsTxt = new FlxText(0, FlxG.height - 80, FlxG.width, 
            "UP/DOWN: Navigate | ENTER: Select | ESC: Close", 16);
        instructionsTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        instructionsTxt.borderSize = 1.5;
        instructionsTxt.scrollFactor.set(0, 0);
        add(instructionsTxt);
        
        itemsGroup = new FlxTypedGroup<FlxText>();
        add(itemsGroup);
        
        scanModsForStates();
        generateList();
    }
    
    function scanModsForStates()
    {
        #if sys
        modsWithStates = [];
        var modsList = Mods.parseList();
        
        for(mod in modsList.enabled)
        {
            var statesPath:String = 'mods/$mod/states';
            if(FileSystem.exists(statesPath) && FileSystem.isDirectory(statesPath))
            {
                var files = FileSystem.readDirectory(statesPath);
                var stateFiles:Array<String> = [];
                
                for(file in files)
                {
                    if(file.endsWith('.hx'))
                    {
                        stateFiles.push(file.substring(0, file.length - 3)); // Quitar .hx
                    }
                }
                
                if(stateFiles.length > 0)
                {
                    modsWithStates.push({mod: mod, states: stateFiles});
                }
            }
        }
        #end
    }
    
    function generateList()
    {
        itemsGroup.clear();
        
        var startY:Float = 150;
        var index:Int = 0;
        
        // Opción "None"
        var noneItem = new FlxText(0, startY + (index * 40), FlxG.width, "[ NONE ]", 24);
        noneItem.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        noneItem.borderSize = 2;
        noneItem.scrollFactor.set(0, 0);
        noneItem.ID = -1;
        itemsGroup.add(noneItem);
        index++;
        
        // Lista de mods con states
        for(modData in modsWithStates)
        {
            var displayText = '${modData.mod} (${modData.states.length} state${modData.states.length != 1 ? "s" : ""})';
            var item = new FlxText(0, startY + (index * 40), FlxG.width, displayText, 24);
            item.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
            item.borderSize = 2;
            item.scrollFactor.set(0, 0);
            item.ID = index - 1; // ID corresponde al índice en modsWithStates
            itemsGroup.add(item);
            index++;
        }
        
        if(modsWithStates.length == 0)
        {
            var noModsText = new FlxText(0, startY + (index * 40), FlxG.width, 
                "No mods with states found", 20);
            noModsText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
            noModsText.borderSize = 1.5;
            noModsText.scrollFactor.set(0, 0);
            itemsGroup.add(noModsText);
        }
        
        curSelected = 0;
        updateSelection();
    }
    
    function updateSelection()
    {
        var i:Int = 0;
        for(item in itemsGroup.members)
        {
            if(item == null) continue;
            
            if(i == curSelected)
            {
                item.color = FlxColor.YELLOW;
                item.scale.set(1.1, 1.1);
            }
            else
            {
                item.color = FlxColor.WHITE;
                item.scale.set(1, 1);
            }
            i++;
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var accept = controls.ACCEPT;
        var back = controls.BACK;
        var up = controls.UI_UP_P;
        var down = controls.UI_DOWN_P;
        
        if(up)
        {
            changeSelection(-1);
        }
        
        if(down)
        {
            changeSelection(1);
        }
        
        if(accept)
        {
            selectOption();
        }
        
        if(back)
        {
            closeSubstate();
        }
    }
    
    function changeSelection(change:Int)
    {
        curSelected += change;
        
        var maxItems = itemsGroup.length;
        if(modsWithStates.length == 0) maxItems = 1; // Solo "NONE"
        
        if(curSelected < 0) curSelected = maxItems - 1;
        if(curSelected >= maxItems) curSelected = 0;
        
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        updateSelection();
    }
    
    function selectOption()
    {
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
        
        // Verificar si seleccionó algo diferente
        if(previousSelected != curSelected)
        {
            hasChanges = true;
        }
        
        if(curSelected == 0) // NONE
        {
            selectedModName = null;
            if(hasChanges)
            {
                // Reiniciar al TitleState del juego base con intro completa
                FlxG.sound.music.stop();
                
                // Resetear el estado de inicialización para forzar la intro
                TitleState.initialized = false;
                TitleState.fromSubstate = true; // Marcar que viene del substate
                
                FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function()
                {
                    MusicBeatState.switchState(new TitleState());
                });
            }
            else
            {
                closeSubstate();
            }
        }
        else if(curSelected > 0 && modsWithStates.length > 0)
        {
            var selectedIndex = curSelected - 1;
            if(selectedIndex >= 0 && selectedIndex < modsWithStates.length)
            {
                var modData = modsWithStates[selectedIndex];
                selectedModName = modData.mod;
                
                if(hasChanges)
                {
                    // Mover el mod al top
                    moveModToTop(selectedModName);
                    
                    // Reiniciar al FlashingState o TitleState del mod
                    FlxG.sound.music.stop();
                    FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function()
                    {
                        restartToModState(selectedModName);
                    });
                }
                else
                {
                    closeSubstate();
                }
            }
        }
    }
    
    function moveModToTop(modName:String)
    {
        #if sys
        var modsList = Mods.parseList();
        
        // Verificar si el mod existe en la lista
        if(modsList.all.contains(modName))
        {
            // Remover el mod de su posición actual
            modsList.all.remove(modName);
            
            // Insertarlo al inicio
            modsList.all.insert(0, modName);
            
            // Guardar la lista actualizada
            saveModsList(modsList);
            
            trace('Moved mod $modName to top position');
        }
        #end
    }
    
    function saveModsList(modsList:ModsList)
    {
        #if sys
        var fileStr:String = '';
        for (mod in modsList.all)
        {
            if(mod.trim().length < 1) continue;

            if(fileStr.length > 0) fileStr += '\n';

            var on = '1';
            if(modsList.disabled.contains(mod)) on = '0';
            fileStr += '$mod|$on';
        }

        var path:String = #if android StorageUtil.getExternalStorageDirectory() + #else Sys.getCwd() + #end 'modsList.txt';
        sys.io.File.saveContent(path, fileStr);
        Mods.parseList();
        Mods.loadTopMod();
        #end
    }
    
    function restartToModState(modName:String)
    {
        #if sys
        // Primero verificar si tiene FlashingState
        var flashingPath = 'mods/$modName/states/FlashingState.hx';
        if(FileSystem.exists(flashingPath))
        {
            // Intentar cargar FlashingState del mod
            var flashingState = new states.ModState('FlashingState');
            MusicBeatState.switchState(flashingState);
        }
        else
        {
            // Si no tiene FlashingState, buscar TitleState
            var titlePath = 'mods/$modName/states/TitleState.hx';
            if(FileSystem.exists(titlePath))
            {
                var titleState = new states.ModState('TitleState');
                MusicBeatState.switchState(titleState);
            }
            else
            {
                // Si no tiene ninguno, ir al TitleState base del juego
                TitleState.fromSubstate = true; // Marcar que viene del substate
                MusicBeatState.switchState(new TitleState());
            }
        }
        #end
    }
    
    function closeSubstate()
    {
        FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
        close();
    }
    
    override function close()
    {
        // Reanudar el estado cuando se cierra el substate
        if(FlxG.state != null && Std.isOfType(FlxG.state, backend.MusicBeatState))
        {
            var state:backend.MusicBeatState = cast FlxG.state;
            state.persistentUpdate = true;
            trace('StateModSubstate closed - state resumed');
        }
        super.close();
    }
}

