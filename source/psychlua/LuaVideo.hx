package psychlua;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#end

class LuaVideo {
    #if LUA_ALLOWED
    // Mapa para rastrear videos activos
    private static var activeVideos:Map<String, FlxVideoSprite> = new Map();
    
    // Flags de protección
    private static var isDestroyed:Map<String, Bool> = new Map();
    private static var allowDestroy:Map<String, Bool> = new Map();
    
    public static function implement(funk:FunkinLua) {
        var lua = funk.lua;
        
        #if VIDEOS_ALLOWED
        // PlayLuaVideoSprite(tag, path, x, y, volume, front)
        // front: true = encima de todo, false = debajo de todo (default)
        Lua_helper.add_callback(lua, "playLuaVideoSprite", function(tag:String, path:String, ?x:Float = 0, ?y:Float = 0, ?front:Bool = false) {
            if(tag == null || tag.trim() == '') {
                FunkinLua.luaTrace('playLuaVideoSprite: tag cannot be empty!', false, false, FlxColor.RED);
                return;
            }
            
            if(path == null || path.trim() == '') {
                FunkinLua.luaTrace('playLuaVideoSprite: path cannot be empty!', false, false, FlxColor.RED);
                return;
            }
            
            // Verificar si ya existe
            var variables = MusicBeatState.getVariables();
            var existingVideo = variables.get(tag);
            
            // Si existe, removerlo primero
            if(existingVideo != null) {
                removeLuaVideo(tag);
            }
            
            // Inicializar flags de protección
            isDestroyed.set(tag, false);
            allowDestroy.set(tag, false);
            
            // Crear FlxVideoSprite directamente (sin usar VideoSprite para tener control total)
            var videoSprite:FlxVideoSprite = new FlxVideoSprite();
            videoSprite.antialiasing = ClientPrefs.data.antialiasing;
            
            // Configurar cámara por defecto en camHUD
            videoSprite.cameras = [PlayState.instance.camHUD];
            
            // Callback cuando el video esté listo - SIN escalado automático
            videoSprite.bitmap.onFormatSetup.add(function() {
                // Solo actualizar hitbox, NO escalar ni centrar
                videoSprite.updateHitbox();
                
                // Configurar posición manual (x, y)
                videoSprite.x = x;
                videoSprite.y = y;
                
                trace('Video "$tag" playing successfully');
            });
            
            // Callback cuando el video termina naturalmente
            videoSprite.bitmap.onEndReached.add(function() {
                funk.call('onVideoFinished', [tag]);
                removeLuaVideo(tag);
            });
            
            // Cargar y reproducir el video
            videoSprite.load(backend.Paths.video(path), null);
            videoSprite.play();
            
            // Permitir destrucción después de 2 segundos
            new flixel.util.FlxTimer().start(2.0, function(tmr:flixel.util.FlxTimer) {
                allowDestroy.set(tag, true);
            });
            
            // Guardar en mapas
            variables.set(tag, videoSprite);
            activeVideos.set(tag, videoSprite);
            
            // Agregar al estado (encima o debajo según el parámetro front)
            if(front) {
                PlayState.instance.add(videoSprite);
            } else {
                var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
                if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
                    position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
                if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
                    position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
                
                PlayState.instance.insert(position, videoSprite);
            }
            
        });
        
        // Pausar video
        Lua_helper.add_callback(lua, "pauseLuaVideo", function(tag:String) {
            var video = getLuaVideo(tag);
            if(video != null) {
                video.pause();
            }
        });
        
        // Reanudar video
        Lua_helper.add_callback(lua, "resumeLuaVideo", function(tag:String) {
            var video = getLuaVideo(tag);
            if(video != null) {
                video.resume();
            }
        });
        
        // Detener y destruir video
        Lua_helper.add_callback(lua, "removeLuaVideo", function(tag:String) {
            removeLuaVideo(tag);
        });
        
        // Forzar destrucción
        Lua_helper.add_callback(lua, "forceRemoveLuaVideo", function(tag:String) {
            if(allowDestroy.exists(tag)) {
                allowDestroy.set(tag, true); // Permitir destrucción inmediata
            }
            removeLuaVideo(tag);
        });
        
        // Verificar si el video existe
        Lua_helper.add_callback(lua, "luaVideoExists", function(tag:String):Bool {
            return getLuaVideo(tag) != null;
        });
        
        // Verificar si el video está reproduciendo
        Lua_helper.add_callback(lua, "isLuaVideoPlaying", function(tag:String):Bool {
            var video = getLuaVideo(tag);
            if(video != null) {
                return video.bitmap.isPlaying;
            }
            return false;
        });
        
        // Cambiar volumen del video
        Lua_helper.add_callback(lua, "setLuaVideoVolume", function(tag:String, volume:Float) {
            var video = getLuaVideo(tag);
            if(video != null) {
                video.bitmap.volume = Std.int(volume * 100);
            }
        });
        
        // Obtener duración del video en segundos
        Lua_helper.add_callback(lua, "getLuaVideoDuration", function(tag:String):Float {
            var video = getLuaVideo(tag);
            if(video != null) {
                return haxe.Int64.toInt(video.bitmap.duration) / 1000.0;
            }
            return 0;
        });
        
        // Obtener tiempo actual del video en segundos
        Lua_helper.add_callback(lua, "getLuaVideoTime", function(tag:String):Float {
            var video = getLuaVideo(tag);
            if(video != null) {
                return haxe.Int64.toInt(video.bitmap.time) / 1000.0;
            }
            return 0;
        });
        
        #else
        // Si no hay soporte de videos, crear funciones dummy
        Lua_helper.add_callback(lua, "playLuaVideoSprite", function(tag:String, path:String, ?x:Float = 0, ?y:Float = 0, ?volume:Float = 1.0, ?front:Bool = false) {
            FunkinLua.luaTrace('playLuaVideoSprite: Video support is not enabled!', false, false, FlxColor.RED);
        });
        #end
    }
    
    #if VIDEOS_ALLOWED
    private static function getLuaVideo(tag:String):FlxVideoSprite {
        var variables = MusicBeatState.getVariables();
        var sprite = variables.get(tag);
        if(sprite != null && Std.isOfType(sprite, FlxVideoSprite)) {
            return cast sprite;
        }
        
        if(sprite == null) {
            FunkinLua.luaTrace('getLuaVideo: Video "$tag" does not exist!', false, false, FlxColor.RED);
        } else {
            FunkinLua.luaTrace('getLuaVideo: "$tag" is not a video!', false, false, FlxColor.RED);
        }
        
        return null;
    }
    
    private static function removeLuaVideo(tag:String):Void {
        // Verificar flags de protección
        if(isDestroyed.exists(tag) && isDestroyed.get(tag)) {
            return; // Ya fue destruido
        }
        
        if(allowDestroy.exists(tag) && !allowDestroy.get(tag)) {
            trace('LuaVideo: Cannot destroy "$tag" yet (not ready)');
            return; // Aún no está listo para destruir
        }
        
        var variables = MusicBeatState.getVariables();
        var video = variables.get(tag);
        
        if(video == null || !Std.isOfType(video, FlxVideoSprite)) {
            return;
        }
        
        // Marcar como destruido INMEDIATAMENTE
        isDestroyed.set(tag, true);
        
        var videoSprite:FlxVideoSprite = cast video;
        
        // Remover de los mapas
        variables.remove(tag);
        activeVideos.remove(tag);
        
        // Limpiar callbacks
        if(videoSprite.bitmap != null) {
            videoSprite.bitmap.onEndReached.removeAll();
            videoSprite.bitmap.onFormatSetup.removeAll();
        }
        
        // Remover del estado
        if(PlayState.instance != null && PlayState.instance.members != null) {
            if(PlayState.instance.members.contains(videoSprite)) {
                PlayState.instance.remove(videoSprite);
            }
        }
        
        // Destruir
        videoSprite.destroy();
        
        // Limpiar flags
        isDestroyed.remove(tag);
        allowDestroy.remove(tag);
        
        trace('Video "$tag" destroyed');
    }
    
    // Pausar todos los videos activos (llamado cuando se pausa el juego)
    public static function pauseAll():Void {
        #if VIDEOS_ALLOWED
        for(tag => video in activeVideos) {
            if(video != null && video.bitmap.isPlaying) {
                video.pause();
            }
        }
        #end
    }
    
    // Reanudar todos los videos activos (llamado cuando se reanuda el juego)
    public static function resumeAll():Void {
        #if VIDEOS_ALLOWED
        for(tag => video in activeVideos) {
            if(video != null && !video.bitmap.isPlaying) {
                video.resume();
            }
        }
        #end
    }
    
    // Limpiar todos los videos (llamado al destruir el state)
    public static function clearAll():Void {
        #if VIDEOS_ALLOWED
        var tags:Array<String> = [];
        for(tag in activeVideos.keys()) {
            tags.push(tag);
        }
        
        for(tag in tags) {
            removeLuaVideo(tag);
        }
        
        activeVideos.clear();
        #end
    }
    #end
    #end
}
