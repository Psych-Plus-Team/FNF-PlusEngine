package psychlua;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#end

class LuaVideo {
    #if LUA_ALLOWED
    // Mapa para rastrear videos activos
    private static var activeVideos:Map<String, FlxVideoSprite> = new Map();
    
    public static function implement(funk:FunkinLua) {
        var lua = funk.lua;
        
        #if VIDEOS_ALLOWED
        // Precargar video sin reproducir
        Lua_helper.add_callback(lua, "precacheLuaVideo", function(tag:String, path:String) {
            if(tag == null || tag.trim() == '') {
                FunkinLua.luaTrace('precacheLuaVideo: tag cannot be empty!', false, false, FlxColor.RED);
                return false;
            }
            
            if(path == null || path.trim() == '') {
                FunkinLua.luaTrace('precacheLuaVideo: path cannot be empty!', false, false, FlxColor.RED);
                return false;
            }
            
            var variables = MusicBeatState.getVariables();
            
            // Verificar si ya existe
            if(variables.get(tag) != null) {
                FunkinLua.luaTrace('precacheLuaVideo: Video with tag "$tag" already exists!', false, false, FlxColor.YELLOW);
                return false;
            }
            
            // Crear el video sprite
            var videoSprite:FlxVideoSprite = new FlxVideoSprite();
            videoSprite.antialiasing = ClientPrefs.data.antialiasing;
            videoSprite.visible = false; // Oculto hasta que se reproduzca
            
            // Obtener ruta usando backend.Paths
            var videoPath = backend.Paths.video(path);
            
            // Cargar video pero no reproducir
            try {
                videoSprite.load(videoPath);
                videoSprite.pause(); // Pausar inmediatamente
                
                // Agregar al estado (pero invisible)
                PlayState.instance.add(videoSprite);
                
                // Guardar en variables
                variables.set(tag, videoSprite);
                activeVideos.set(tag, videoSprite);
                
                trace('Preloaded video "$tag"');
                return true;
            } catch(e:Dynamic) {
                FunkinLua.luaTrace('precacheLuaVideo: Error loading video: $e', false, false, FlxColor.RED);
                return false;
            }
        });
        
        // PlayLuaVideoSprite(tag, path, x, y, camera, volume, front)
        // front: true = encima de todo, false = debajo de todo (default)
        Lua_helper.add_callback(lua, "playLuaVideoSprite", function(tag:String, path:String, ?x:Float = 0, ?y:Float = 0, ?camera:String = 'game', ?volume:Float = 1.0, ?front:Bool = false) {
            if(tag == null || tag.trim() == '') {
                FunkinLua.luaTrace('playLuaVideoSprite: tag cannot be empty!', false, false, FlxColor.RED);
                return;
            }
            
            if(path == null || path.trim() == '') {
                FunkinLua.luaTrace('playLuaVideoSprite: path cannot be empty!', false, false, FlxColor.RED);
                return;
            }
            
            // Verificar si ya existe un video precargado con este tag
            var variables = MusicBeatState.getVariables();
            var existingVideo = variables.get(tag);
            
            // Si existe y es un video, usar el precargado
            if(existingVideo != null && Std.isOfType(existingVideo, FlxVideoSprite)) {
                var videoSprite:FlxVideoSprite = cast existingVideo;
                
                // Actualizar propiedades
                videoSprite.x = x;
                videoSprite.y = y;
                videoSprite.visible = true;
                videoSprite.bitmap.volume = Std.int(volume * 100);
                
                // Cambiar cámara si es necesaria
                var targetCamera = LuaUtils.cameraFromString(camera);
                if(targetCamera != null) {
                    videoSprite.cameras = [targetCamera];
                }
                
                // Reproducir
                videoSprite.play();
                
                trace('Play video "$tag"');
                return;
            }
            
            // Si existe pero no es video, removerlo
            if(existingVideo != null) {
                FunkinLua.luaTrace('playLuaVideoSprite: Tag "$tag" exists but is not a video! Removing...', false, false, FlxColor.YELLOW);
                removeLuaVideo(tag);
            }
            
            // Crear nuevo video sprite
            var videoSprite:FlxVideoSprite = new FlxVideoSprite();
            videoSprite.antialiasing = ClientPrefs.data.antialiasing;
            
            // Posición
            videoSprite.x = x;
            videoSprite.y = y;
            
            // Configurar cámara
            var targetCamera = LuaUtils.cameraFromString(camera);
            if(targetCamera != null) {
                videoSprite.cameras = [targetCamera];
            }
            
            // Callback cuando el video termina
            videoSprite.bitmap.onEndReached.add(function() {
                // Llamar callback de Lua si existe
                funk.call('onVideoFinished', [tag]);
                
                // Destruir automáticamente (el trace sale de removeLuaVideo)
                removeLuaVideo(tag);
            });
            
            // Callback para ajustar tamaño cuando se carga
            videoSprite.bitmap.onFormatSetup.add(function() {
                videoSprite.updateHitbox();
            });
            
            // Obtener ruta usando backend.Paths
            var videoPath = backend.Paths.video(path);
            
            // Cargar y reproducir video
            try {
                videoSprite.load(videoPath);
                videoSprite.bitmap.volume = Std.int(volume * 100);
                videoSprite.play();
                
                // Guardar en el mapa de variables
                variables.set(tag, videoSprite);
                activeVideos.set(tag, videoSprite);
                
                // Agregar al estado (encima o debajo según el parámetro front)
                if(front) {
                    PlayState.instance.add(videoSprite); // Encima de todo
                } else {
                    var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
                    if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
                        position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
                    if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
                        position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
                    
                    PlayState.instance.insert(position, videoSprite); // Debajo de personajes
                }
                
                trace('Play video "$tag"');
            } catch(e:Dynamic) {
                FunkinLua.luaTrace('playLuaVideoSprite: Error loading video: $e', false, false, FlxColor.RED);
            }
        });
        
        // Pausar video
        Lua_helper.add_callback(lua, "pauseLuaVideo", function(tag:String) {
            var video = getLuaVideo(tag);
            if(video != null) {
                video.pause();
                FunkinLua.luaTrace('Video "$tag" paused', false, false);
            }
        });
        
        // Reanudar video
        Lua_helper.add_callback(lua, "resumeLuaVideo", function(tag:String) {
            var video = getLuaVideo(tag);
            if(video != null) {
                video.resume();
                FunkinLua.luaTrace('Video "$tag" resumed', false, false);
            }
        });
        
        // Detener y destruir video
        Lua_helper.add_callback(lua, "removeLuaVideo", function(tag:String) {
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
        Lua_helper.add_callback(lua, "playLuaVideoSprite", function(tag:String, path:String, ?x:Float = 0, ?y:Float = 0, ?camera:String = 'game', ?volume:Float = 1.0, ?front:Bool = false) {
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
        var video = getLuaVideo(tag);
        if(video != null) {
            // Detener el video
            video.pause();
            
            // Remover del estado
            if(PlayState.instance.members.contains(video)) {
                PlayState.instance.remove(video);
            }
            
            // Limpiar callbacks
            video.bitmap.onEndReached.removeAll();
            video.bitmap.onFormatSetup.removeAll();
            
            // Destruir
            video.destroy();
            
            // Remover del mapa de variables
            var variables = MusicBeatState.getVariables();
            variables.remove(tag);
            
            // Remover del mapa de videos activos
            activeVideos.remove(tag);
            
            trace('Destroy video "$tag"');
        }
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
        for(tag in activeVideos.keys()) {
            removeLuaVideo(tag);
        }
        activeVideos.clear();
        #end
    }
    #end
    #end
}
