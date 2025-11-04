package psychlua;

import openfl.Lib;
import openfl.system.Capabilities;
import openfl.display.StageDisplayState;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import states.PlayState;
import haxe.Timer;

#if windows
import winapi.WindowsAPI;
#end

class WindowTweens {
    public static function winTweenX(tag:String, targetX:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        var window = Lib.current.stage.window;
        var startX = window.x;
        var variables = MusicBeatState.getVariables();
        if(tag != null) {
            var originalTag:String = tag;
            tag = LuaUtils.formatVariable('wintween_$tag');
            variables.set(tag, FlxTween.num(startX, targetX, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onUpdate: function(tween:FlxTween) {
                    window.x = Std.int(FlxMath.lerp(startX, targetX, tween.percent));
                },
                onComplete: function(_) {
                    variables.remove(tag);
                    if (onComplete != null) onComplete();
                    if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, 'window.x']);
                }
            }));
            return tag;
        } else {
            FlxTween.num(startX, targetX, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onUpdate: function(tween:FlxTween) {
                    window.x = Std.int(FlxMath.lerp(startX, targetX, tween.percent));
                },
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
        }
        #end
        return null;
    }

    public static function winTweenY(tag:String, targetY:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        var window = Lib.current.stage.window;
        var startY = window.y;
        var variables = MusicBeatState.getVariables();
        if(tag != null) {
            var originalTag:String = tag;
            tag = LuaUtils.formatVariable('wintween_$tag');
            variables.set(tag, FlxTween.num(startY, targetY, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onUpdate: function(tween:FlxTween) {
                    window.y = Std.int(FlxMath.lerp(startY, targetY, tween.percent));
                },
                onComplete: function(_) {
                    variables.remove(tag);
                    if (onComplete != null) onComplete();
                    if(PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, 'window.y']);
                }
            }));
            return tag;
        } else {
            FlxTween.num(startY, targetY, duration, {
                ease: LuaUtils.getTweenEaseByString(ease),
                onUpdate: function(tween:FlxTween) {
                    window.y = Std.int(FlxMath.lerp(startY, targetY, tween.percent));
                },
                onComplete: function(_) {
                    if (onComplete != null) onComplete();
                }
            });
        }
        #end
        return null;
    }
    
    public static function setWindowBorderless(enable:Bool) {
    #if windows
    var window = Lib.current.stage.window;
    window.borderless = enable;
    #end
    }

    public static function setWindowX(x:Int) {
        #if windows
        var window = Lib.current.stage.window;
        window.x = x;
        #end
    }

    public static function setWindowY(y:Int) {
        #if windows
        var window = Lib.current.stage.window;
        window.y = y;
        #end
    }

    public static function setWindowSize(width:Int, height:Int) {
        #if windows
        var window = Lib.current.stage.window;
        window.resize(width, height);
        FlxG.resizeGame(width, height);
        #end
    }

    public static function getWindowX():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.x;
        #else
        return 0;
        #end
    }

    public static function getWindowY():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.y;
        #else
        return 0;
        #end
    }

    public static function getWindowWidth():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.width;
        #else
        return FlxG.width;
        #end
    }

    public static function getWindowHeight():Int {
        #if windows
        var window = Lib.current.stage.window;
        return window.height;
        #else
        return FlxG.height;
        #end
    }

    public static function centerWindow() {
        #if windows
        var window = Lib.current.stage.window;
        var screenWidth = Capabilities.screenResolutionX;
        var screenHeight = Capabilities.screenResolutionY;
        window.x = Std.int((screenWidth - window.width) / 2);
        window.y = Std.int((screenHeight - window.height) / 2);
        #end
    }

    public static function setWindowTitle(title:String) {
        #if windows
        var window = Lib.current.stage.window;
        window.title = title;
        #end
    }

    public static function getWindowTitle():String {
        #if windows
        var window = Lib.current.stage.window;
        return window.title;
        #else
        return "";
        #end
    }

    public static function setWindowIcon(iconPath:String) {
        #if windows
        try {
            var window = Lib.current.stage.window;
            var iconBitmap = openfl.display.BitmapData.fromFile(iconPath);
            if (iconBitmap != null) {
                window.setIcon(lime.graphics.Image.fromBitmapData(iconBitmap));
            }
        } catch (e:Dynamic) {
            trace('Error setting window icon: $e');
        }
        #end
    }

    public static function setWindowResizable(enable:Bool) {
        #if windows
        var window = Lib.current.stage.window;
        window.resizable = enable;
        #end
    }

    public static function shakeWindow(intensity:Float = 5.0, duration:Float = 0.5) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var shakeTimer = new haxe.Timer(16); // ~60 FPS
        shakeTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = originalX;
                window.y = originalY;
                shakeTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var currentIntensity = intensity * (1.0 - progress); // Decrease over time
            
            var shakeX = Std.int(originalX + (Math.random() - 0.5) * currentIntensity * 2);
            var shakeY = Std.int(originalY + (Math.random() - 0.5) * currentIntensity * 2);
            
            window.x = shakeX;
            window.y = shakeY;
        };
        #end
    }

    public static function bounceWindow(bounces:Int = 3, height:Float = 50.0, duration:Float = 1.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalY = window.y;
        var bounceHeight = Std.int(height);
        
        // Create a bounce animation
        var bounceCount = 0;
        var isGoingUp = true;
        var targetY = originalY - bounceHeight;
        
        function doBounce() {
            if (bounceCount >= bounces) {
                // Return to original position
                winTweenY(null, originalY, 0.2, "quadOut");
                return;
            }
            
            var bounceIntensity = 1.0 - (bounceCount / bounces); // Decrease each bounce
            var currentHeight = Std.int(bounceHeight * bounceIntensity);
            
            if (isGoingUp) {
                targetY = originalY - currentHeight;
            } else {
                targetY = originalY;
                bounceCount++;
            }
            
            winTweenY(null, targetY, duration / (bounces * 2), "quadInOut", function() {
                isGoingUp = !isGoingUp;
                doBounce();
            });
        }
        
        doBounce();
        #end
    }

    public static function orbitWindow(centerX:Int, centerY:Int, radius:Float = 100.0, speed:Float = 1.0, duration:Float = 5.0) {
        #if windows
        var window = Lib.current.stage.window;
        var startTime = haxe.Timer.stamp();
        var angle:Float = 0.0;
        
        var orbitTimer = new haxe.Timer(16); // ~60 FPS
        orbitTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                orbitTimer.stop();
                return;
            }
            
            angle += speed * 0.1; // Adjust speed multiplier as needed
            var x = centerX + Math.cos(angle) * radius;
            var y = centerY + Math.sin(angle) * radius;
            
            window.x = Std.int(x);
            window.y = Std.int(y);
        };
        #end
    }

    public static function pulseWindow(minScale:Float = 0.8, maxScale:Float = 1.2, pulseSpeed:Float = 2.0, duration:Float = 3.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalWidth = window.width;
        var originalHeight = window.height;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var pulseTimer = new haxe.Timer(16); // ~60 FPS
        pulseTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                // Restore original size and position
                window.resize(originalWidth, originalHeight);
                window.x = originalX;
                window.y = originalY;
                FlxG.resizeGame(originalWidth, originalHeight);
                pulseTimer.stop();
                return;
            }
            
            var pulse = Math.sin(elapsed * pulseSpeed * Math.PI) * 0.5 + 0.5; // 0 to 1
            var scale = minScale + (maxScale - minScale) * pulse;
            
            var newWidth = Std.int(originalWidth * scale);
            var newHeight = Std.int(originalHeight * scale);
            
            // Center the window while scaling
            var newX = originalX + Std.int((originalWidth - newWidth) / 2);
            var newY = originalY + Std.int((originalHeight - newHeight) / 2);
            
            window.resize(newWidth, newHeight);
            window.x = newX;
            window.y = newY;
            FlxG.resizeGame(newWidth, newHeight);
        };
        #end
    }

    public static function spinWindow(rotations:Int = 1, duration:Float = 2.0) {
        #if windows
        var window = Lib.current.stage.window;
        var centerX = window.x + Std.int(window.width / 2);
        var centerY = window.y + Std.int(window.height / 2);
        var startTime = haxe.Timer.stamp();
        var totalRotation = rotations * 360.0;
        
        var spinTimer = new haxe.Timer(16); // ~60 FPS
        spinTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                // Return to original position
                window.x = centerX - Std.int(window.width / 2);
                window.y = centerY - Std.int(window.height / 2);
                spinTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var currentRotation = totalRotation * progress;
            var radians = currentRotation * Math.PI / 180.0;
            
            // Calculate position as if rotating around center point
            var radius = Math.sqrt(Math.pow(window.width / 2, 2) + Math.pow(window.height / 2, 2));
            var x = centerX + Math.cos(radians) * (window.width / 2) - Std.int(window.width / 2);
            var y = centerY + Math.sin(radians) * (window.height / 2) - Std.int(window.height / 2);
            
            window.x = Std.int(x);
            window.y = Std.int(y);
        };
        #end
    }

    public static function randomizeWindowPosition(minX:Int = 0, maxX:Int = -1, minY:Int = 0, maxY:Int = -1) {
        #if windows
        var window = Lib.current.stage.window;
        var screenWidth = Capabilities.screenResolutionX;
        var screenHeight = Capabilities.screenResolutionY;
        
        // Use screen bounds if not specified
    if (maxX == -1) maxX = Std.int(screenWidth - window.width);
    if (maxY == -1) maxY = Std.int(screenHeight - window.height);
        
        // Ensure mins don't exceed maxs
        minX = Std.int(Math.min(minX, maxX));
        minY = Std.int(Math.min(minY, maxY));
        
        var randomX = Std.int(minX + Math.random() * (maxX - minX));
        var randomY = Std.int(minY + Math.random() * (maxY - minY));
        
        window.x = randomX;
        window.y = randomY;
        #end
    }

    public static function getScreenResolution():{width:Int, height:Int} {
        return {
            width: Std.int(Capabilities.screenResolutionX),
            height: Std.int(Capabilities.screenResolutionY)
        };
    }

    public static function setWindowFullscreen(enable:Bool) {
        #if windows
        var window = Lib.current.stage.window;
        window.fullscreen = enable;
        #end
    }

    public static function isWindowFullscreen():Bool {
        #if windows
        var window = Lib.current.stage.window;
        return window.fullscreen;
        #else
        return false;
        #end
    }

    public static function saveWindowState():String {
        #if windows
        var window = Lib.current.stage.window;
        var state = {
            x: window.x,
            y: window.y,
            width: window.width,
            height: window.height,
            borderless: window.borderless,
            resizable: window.resizable,
            title: window.title
        };
        return haxe.Json.stringify(state);
        #else
        return "{}";
        #end
    }

    public static function loadWindowState(stateJson:String) {
        #if windows
        try {
            var state = haxe.Json.parse(stateJson);
            var window = Lib.current.stage.window;
            
            if (state.x != null) window.x = state.x;
            if (state.y != null) window.y = state.y;
            if (state.width != null && state.height != null) {
                window.resize(state.width, state.height);
                FlxG.resizeGame(state.width, state.height);
            }
            if (state.borderless != null) window.borderless = state.borderless;
            if (state.resizable != null) window.resizable = state.resizable;
            if (state.title != null) window.title = state.title;
        } catch (e:Dynamic) {
            trace('Error loading window state: $e');
        }
        #end
    }

    public static function winTweenSize(targetW:Int, targetH:Int, duration:Float = 1, ease:String = "linear", ?onComplete:Void->Void) {
        #if windows
        var window = Lib.current.stage.window;
        var startW = window.width;
        var startH = window.height;

        // Cambia el modo de escala para que el juego se estire con la ventana
        FlxG.scaleMode = new flixel.system.scaleModes.RatioScaleMode();

        FlxTween.num(0, 1, duration, {
            ease: LuaUtils.getTweenEaseByString(ease),
            onUpdate: function(tween:FlxTween) {
                window.resize(
                    Std.int(FlxMath.lerp(startW, targetW, tween.percent)),
                    Std.int(FlxMath.lerp(startH, targetH, tween.percent))
                );
                FlxG.resizeGame(window.width, window.height);
            },
            onComplete: function(_) {
                if (onComplete != null) onComplete();
            }
        });
        #end
    }

    public static function winResizeCenter(width:Int, height:Int, ?skip:Bool = false, ?markAsResized:Bool = true) {
        #if windows
        if (markAsResized && PlayState.instance != null) {
            PlayState.instance.windowResizedByScript = true;
        }
        var window = Lib.application.window;
        var winYRatio = 1;
        var winY = height * winYRatio;
        var winX = width * winYRatio;

        FlxTween.cancelTweensOf(window);
        if (!skip) {
            FlxTween.tween(window, {
                width: winX,
                height: winY,
                y: Math.floor((Capabilities.screenResolutionY / 2) - (winY / 2)),
                x: Math.floor((Capabilities.screenResolutionX / 2) - (winX / 2)) + (Capabilities.screenResolutionX * Math.floor(window.x / (Capabilities.screenResolutionX)))
            }, 0.4, {
                ease: FlxEase.quadInOut,
                onComplete: function(_) {
                    if (PlayState.instance != null && PlayState.instance.camHUD != null) {
                        PlayState.instance.camHUD.fade(FlxColor.BLACK, 0, true);
                    }
                }
            });
        } else {
            FlxG.resizeWindow(width, height);
            window.y = Math.floor((Capabilities.screenResolutionY / 2) - (winY / 2));
            window.x = Std.int(Math.floor((Capabilities.screenResolutionX / 2) - (winX / 2)) + (Capabilities.screenResolutionX * Math.floor(window.x / (Capabilities.screenResolutionX))));
        }
        FlxG.scaleMode = new RatioScaleMode(true);
        window.resizable = width == 1280;
        #end
    }

    // === NUEVAS FUNCIONES CON WINDOWS API ===

    public static function getWindowState():String {
        #if windows
        try {
            // Función simplificada sin acceso directo a Windows API
            var window = Lib.current.stage.window;
            if (window.fullscreen) return "fullscreen";
            return "normal";
        } catch (e:Dynamic) {
            trace('Error getting window state: $e');
            return "error";
        }
        #else
        return "normal";
        #end
    }

    public static function slideInWindow(direction:String, duration:Int = 500) {
        #if windows
        // Usar animación básica en lugar de Windows API
        var window = Lib.current.stage.window;
        var targetX = window.x;
        var targetY = window.y;
        
        switch(direction.toLowerCase()) {
            case "left": window.x = window.x - 200; winTweenX(null, targetX, duration / 1000);
            case "right": window.x = window.x + 200; winTweenX(null, targetX, duration / 1000);
            case "up": window.y = window.y - 200; winTweenY(null, targetY, duration / 1000);
            case "down": window.y = window.y + 200; winTweenY(null, targetY, duration / 1000);
        }
        #end
    }

    public static function fadeInWindow(duration:Int = 500) {
        #if windows
        // Usar función de transparencia disponible
        try {
            WindowsAPI.setWindowOppacity(0.0);
            var steps = 20;
            var stepDuration = duration / steps;
            var currentStep = 0;
            
            var fadeTimer = new haxe.Timer(stepDuration);
            fadeTimer.run = function() {
                currentStep++;
                var opacity = currentStep / steps;
                WindowsAPI.setWindowOppacity(opacity);
                
                if (currentStep >= steps) {
                    fadeTimer.stop();
                }
            };
        } catch (e:Dynamic) {
            trace('Error fading in window: $e');
        }
        #end
    }

    public static function expandWindow(duration:Int = 500) {
        #if windows
        // Usar escalado básico
        var window = Lib.current.stage.window;
        var originalWidth = window.width;
        var originalHeight = window.height;
        
        window.resize(Std.int(originalWidth * 0.1), Std.int(originalHeight * 0.1));
        winTweenSize(originalWidth, originalHeight, duration / 1000);
        #end
    }

    public static function setSystemVolume(volume:Float) {
        #if windows
        try {
            // Clamp volume between 0.0 and 1.0
            var clampedVolume = Math.max(0.0, Math.min(1.0, volume));
            var volumeLevel = Std.int(clampedVolume * 65535); // 0-65535 range
            
            // This would require more complex Windows API calls to audio system
            trace('Setting system volume to: $clampedVolume');
        } catch (e:Dynamic) {
            trace('Error setting system volume: $e');
        }
        #end
    }

    public static function muteSystem(mute:Bool) {
        #if windows
        try {
            // This would require Windows audio API calls
            trace('System mute: $mute');
        } catch (e:Dynamic) {
            trace('Error muting system: $e');
        }
        #end
    }

    private static function getVirtualKeyCode(key:String):Int {
        // Función no utilizada con la librería actual
        return 0;
    }

    public static function createDesktopShortcut(name:String, targetPath:String, iconPath:String = "") {
        #if windows
        try {
            // This would require COM interface calls to create shortcuts
            trace('Creating desktop shortcut: $name -> $targetPath');
        } catch (e:Dynamic) {
            trace('Error creating desktop shortcut: $e');
        }
        #end
    }

    // === FUNCIONES DISPONIBLES CON SL-WINDOWS-API ===

    public static function setDesktopWallpaper(path:String) {
        #if windows
        try {
            WindowsAPI.setWallpaper(path);
            trace('Wallpaper set to: $path');
        } catch (e:Dynamic) {
            trace('Error setting wallpaper: $e');
        }
        #end
    }

    public static function hideDesktopIcons(hide:Bool) {
        #if windows
        try {
            WindowsAPI.hideDesktopIcons(hide);
            trace('Desktop icons hidden: $hide');
        } catch (e:Dynamic) {
            trace('Error hiding desktop icons: $e');
        }
        #end
    }

    public static function hideTaskBar(hide:Bool) {
        #if windows
        try {
            WindowsAPI.hideTaskbar(hide);
            trace('Taskbar hidden: $hide');
        } catch (e:Dynamic) {
            trace('Error hiding taskbar: $e');
        }
        #end
    }

    public static function moveDesktopElements(x:Int, y:Int) {
        #if windows
        try {
            WindowsAPI.moveDesktopWindowsInXY(x, y);
            trace('Desktop elements moved to: $x, $y');
        } catch (e:Dynamic) {
            trace('Error moving desktop elements: $e');
        }
        #end
    }

    public static function setDesktopTransparency(alpha:Float) {
        #if windows
        try {
            var clampedAlpha = Math.max(0.0, Math.min(1.0, alpha));
            WindowsAPI.setDesktopWindowsAlpha(clampedAlpha);
            trace('Desktop transparency set to: $clampedAlpha');
        } catch (e:Dynamic) {
            trace('Error setting desktop transparency: $e');
        }
        #end
    }

    public static function setTaskBarTransparency(alpha:Float) {
        #if windows
        try {
            var clampedAlpha = Math.max(0.0, Math.min(1.0, alpha));
            WindowsAPI.setTaskBarAlpha(clampedAlpha);
            trace('Taskbar transparency set to: $clampedAlpha');
        } catch (e:Dynamic) {
            trace('Error setting taskbar transparency: $e');
        }
        #end
    }

    public static function getCursorPosition():{x:Int, y:Int} {
        #if windows
        try {
            return {
                x: WindowsAPI.getCursorPositionX(),
                y: WindowsAPI.getCursorPositionY()
            };
        } catch (e:Dynamic) {
            trace('Error getting cursor position: $e');
            return {x: 0, y: 0};
        }
        #else
        return {x: 0, y: 0};
        #end
    }

    public static function getSystemRAM():Int {
        #if windows
        try {
            return WindowsAPI.obtainRAM();
        } catch (e:Dynamic) {
            trace('Error getting system RAM: $e');
            return 0;
        }
        #else
        return 0;
        #end
    }

    public static function showNotification(title:String, message:String) {
        #if windows
        try {
            WindowsAPI.sendWindowsNotification(title, message);
            trace('Notification sent: $title - $message');
        } catch (e:Dynamic) {
            trace('Error showing notification: $e');
        }
        #end
    }

    public static function resetSystemChanges() {
        #if windows
        try {
            WindowsAPI.resetWindowsFuncs();
            trace('System changes reset');
        } catch (e:Dynamic) {
            trace('Error resetting system changes: $e');
        }
        #end
    }

    // === ANIMACIONES AVANZADAS Y ESPECTACULARES ===

    public static function elasticWindow(intensity:Float = 1.5, cycles:Int = 3, duration:Float = 2.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalWidth = window.width;
        var originalHeight = window.height;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var elasticTimer = new haxe.Timer(16);
        elasticTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.resize(originalWidth, originalHeight);
                window.x = originalX;
                window.y = originalY;
                FlxG.resizeGame(originalWidth, originalHeight);
                elasticTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var damping = Math.exp(-4 * progress);
            var oscillation = Math.sin(cycles * 2 * Math.PI * progress);
            var elastic = 1.0 + intensity * damping * oscillation;
            
            var newWidth = Std.int(originalWidth * elastic);
            var newHeight = Std.int(originalHeight * elastic);
            var newX = originalX + Std.int((originalWidth - newWidth) / 2);
            var newY = originalY + Std.int((originalHeight - newHeight) / 2);
            
            window.resize(newWidth, newHeight);
            window.x = newX;
            window.y = newY;
            FlxG.resizeGame(newWidth, newHeight);
        };
        #end
    }

    public static function waveWindow(amplitude:Float = 50.0, frequency:Float = 2.0, duration:Float = 3.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var waveTimer = new haxe.Timer(16);
        waveTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = originalX;
                window.y = originalY;
                waveTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var wave = Math.sin(frequency * 2 * Math.PI * progress);
            var fadeOut = 1.0 - progress;
            
            var offsetX = Std.int(amplitude * wave * fadeOut);
            var offsetY = Std.int(amplitude * Math.cos(frequency * 2 * Math.PI * progress) * fadeOut * 0.5);
            
            window.x = originalX + offsetX;
            window.y = originalY + offsetY;
        };
        #end
    }

    public static function spiralWindow(spirals:Float = 2.0, radius:Float = 100.0, duration:Float = 3.0) {
        #if windows
        var window = Lib.current.stage.window;
        var centerX = window.x + Std.int(window.width / 2);
        var centerY = window.y + Std.int(window.height / 2);
        var startTime = haxe.Timer.stamp();
        
        var spiralTimer = new haxe.Timer(16);
        spiralTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = centerX - Std.int(window.width / 2);
                window.y = centerY - Std.int(window.height / 2);
                spiralTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var angle = spirals * 2 * Math.PI * progress;
            var currentRadius = radius * (1.0 - progress);
            
            var x = centerX + Math.cos(angle) * currentRadius - Std.int(window.width / 2);
            var y = centerY + Math.sin(angle) * currentRadius - Std.int(window.height / 2);
            
            window.x = Std.int(x);
            window.y = Std.int(y);
        };
        #end
    }

    public static function zigzagWindow(zigzags:Int = 5, amplitude:Float = 100.0, duration:Float = 2.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var zigzagTimer = new haxe.Timer(16);
        zigzagTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = originalX;
                window.y = originalY;
                zigzagTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var zigzagProgress = (progress * zigzags) % 1.0;
            var direction = Math.floor(progress * zigzags) % 2 == 0 ? 1 : -1;
            var zigzag = Math.abs(zigzagProgress * 2 - 1) * direction;
            
            var offsetX = Std.int(amplitude * zigzag);
            var offsetY = Std.int(amplitude * progress * 0.3);
            
            window.x = originalX + offsetX;
            window.y = originalY + offsetY;
        };
        #end
    }

    public static function earthquakeWindow(intensity:Float = 10.0, frequency:Float = 15.0, duration:Float = 1.5) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var earthquakeTimer = new haxe.Timer(16);
        earthquakeTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = originalX;
                window.y = originalY;
                earthquakeTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var fadeOut = 1.0 - progress;
            
            var randomX = (Math.random() - 0.5) * 2 * intensity * fadeOut;
            var randomY = (Math.random() - 0.5) * 2 * intensity * fadeOut;
            var vibration = Math.sin(frequency * elapsed * 2 * Math.PI) * intensity * fadeOut;
            
            window.x = originalX + Std.int(randomX + vibration);
            window.y = originalY + Std.int(randomY + vibration * 0.7);
        };
        #end
    }

    public static function morphWindow(targetWidth:Int, targetHeight:Int, morphStyle:String = "smooth", duration:Float = 2.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalWidth = window.width;
        var originalHeight = window.height;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var morphTimer = new haxe.Timer(16);
        morphTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.resize(targetWidth, targetHeight);
                window.x = originalX + Std.int((originalWidth - targetWidth) / 2);
                window.y = originalY + Std.int((originalHeight - targetHeight) / 2);
                FlxG.resizeGame(targetWidth, targetHeight);
                morphTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var easedProgress = switch(morphStyle.toLowerCase()) {
                case "elastic": {
                    var c4 = (2 * Math.PI) / 3;
                    progress == 0 ? 0 : progress == 1 ? 1 : 
                    Math.pow(2, -10 * progress) * Math.sin((progress * 10 - 0.75) * c4) + 1;
                }
                case "bounce": {
                    var n1 = 7.5625;
                    var d1 = 2.75;
                    if (progress < 1 / d1) {
                        n1 * progress * progress;
                    } else if (progress < 2 / d1) {
                        n1 * (progress -= 1.5 / d1) * progress + 0.75;
                    } else if (progress < 2.5 / d1) {
                        n1 * (progress -= 2.25 / d1) * progress + 0.9375;
                    } else {
                        n1 * (progress -= 2.625 / d1) * progress + 0.984375;
                    }
                }
                default: progress; // smooth
            }
            
            var currentWidth = Std.int(originalWidth + (targetWidth - originalWidth) * easedProgress);
            var currentHeight = Std.int(originalHeight + (targetHeight - originalHeight) * easedProgress);
            var currentX = originalX + Std.int((originalWidth - currentWidth) / 2);
            var currentY = originalY + Std.int((originalHeight - currentHeight) / 2);
            
            window.resize(currentWidth, currentHeight);
            window.x = currentX;
            window.y = currentY;
            FlxG.resizeGame(currentWidth, currentHeight);
        };
        #end
    }

    public static function liquidWindow(viscosity:Float = 0.8, amplitude:Float = 20.0, duration:Float = 3.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalWidth = window.width;
        var originalHeight = window.height;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var liquidTimer = new haxe.Timer(16);
        liquidTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.resize(originalWidth, originalHeight);
                window.x = originalX;
                window.y = originalY;
                FlxG.resizeGame(originalWidth, originalHeight);
                liquidTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var wave1 = Math.sin(progress * 6 * Math.PI) * amplitude;
            var wave2 = Math.cos(progress * 4 * Math.PI) * amplitude * 0.7;
            var wave3 = Math.sin(progress * 8 * Math.PI) * amplitude * 0.5;
            
            var distortionX = Std.int((wave1 + wave2) * viscosity);
            var distortionY = Std.int((wave2 + wave3) * viscosity);
            
            var newWidth = originalWidth + distortionX;
            var newHeight = originalHeight + distortionY;
            var newX = originalX - Std.int(distortionX / 2);
            var newY = originalY - Std.int(distortionY / 2);
            
            window.resize(newWidth, newHeight);
            window.x = newX;
            window.y = newY;
            FlxG.resizeGame(newWidth, newHeight);
        };
        #end
    }

    public static function teleportWindow(targetX:Int, targetY:Int, glitchIntensity:Float = 20.0, teleportDuration:Float = 0.5) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        var glitchPhase = true;
        
        var teleportTimer = new haxe.Timer(16);
        teleportTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            
            if (elapsed >= teleportDuration) {
                window.x = targetX;
                window.y = targetY;
                teleportTimer.stop();
                return;
            }
            
            var progress = elapsed / teleportDuration;
            
            if (progress < 0.3) {
                // Glitch phase
                var glitchX = originalX + Std.int((Math.random() - 0.5) * glitchIntensity * progress * 10);
                var glitchY = originalY + Std.int((Math.random() - 0.5) * glitchIntensity * progress * 10);
                window.x = glitchX;
                window.y = glitchY;
            } else if (progress < 0.7) {
                // Fade/disappear phase (simulate with rapid position changes)
                if (Math.random() > 0.7) {
                    window.x = -window.width - 100; // Move offscreen
                }
            } else {
                // Reappear phase
                var appearProgress = (progress - 0.7) / 0.3;
                var currentX = Std.int(targetX + (Math.random() - 0.5) * glitchIntensity * (1 - appearProgress));
                var currentY = Std.int(targetY + (Math.random() - 0.5) * glitchIntensity * (1 - appearProgress));
                window.x = currentX;
                window.y = currentY;
            }
        };
        #end
    }

    public static function magnetWindow(magnetX:Int, magnetY:Int, strength:Float = 1.0, duration:Float = 2.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var magnetTimer = new haxe.Timer(16);
        magnetTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                magnetTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var windowCenterX = window.x + Std.int(window.width / 2);
            var windowCenterY = window.y + Std.int(window.height / 2);
            
            var deltaX = magnetX - windowCenterX;
            var deltaY = magnetY - windowCenterY;
            var distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
            
            if (distance > 0) {
                var force = strength * (1000 / (distance + 100));
                var magnetForceX = (deltaX / distance) * force;
                var magnetForceY = (deltaY / distance) * force;
                
                window.x += Std.int(magnetForceX);
                window.y += Std.int(magnetForceY);
            }
        };
        #end
    }

    public static function windWindow(windDirection:Float = 0, windStrength:Float = 5.0, turbulence:Float = 2.0, duration:Float = 3.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        var velocityX:Float = 0;
        var velocityY:Float = 0;
        
        var windTimer = new haxe.Timer(16);
        windTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = originalX;
                window.y = originalY;
                windTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var windX = Math.cos(windDirection) * windStrength;
            var windY = Math.sin(windDirection) * windStrength;
            
            // Add turbulence
            var turbulenceX = (Math.random() - 0.5) * turbulence;
            var turbulenceY = (Math.random() - 0.5) * turbulence;
            
            velocityX += windX + turbulenceX;
            velocityY += windY + turbulenceY;
            
            // Apply friction
            velocityX *= 0.95;
            velocityY *= 0.95;
            
            window.x += Std.int(velocityX);
            window.y += Std.int(velocityY);
        };
        #end
    }

    public static function breathingWindow(breathRate:Float = 1.0, intensity:Float = 0.1, duration:Float = 5.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalWidth = window.width;
        var originalHeight = window.height;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var breathingTimer = new haxe.Timer(16);
        breathingTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.resize(originalWidth, originalHeight);
                window.x = originalX;
                window.y = originalY;
                FlxG.resizeGame(originalWidth, originalHeight);
                breathingTimer.stop();
                return;
            }
            
            var breath = Math.sin(elapsed * breathRate * 2 * Math.PI) * intensity;
            var scale = 1.0 + breath;
            
            var newWidth = Std.int(originalWidth * scale);
            var newHeight = Std.int(originalHeight * scale);
            var newX = originalX + Std.int((originalWidth - newWidth) / 2);
            var newY = originalY + Std.int((originalHeight - newHeight) / 2);
            
            window.resize(newWidth, newHeight);
            window.x = newX;
            window.y = newY;
            FlxG.resizeGame(newWidth, newHeight);
        };
        #end
    }

    // === ANIMACIONES COMBINADAS Y SECUENCIALES ===

    public static function comboAnimation(animations:Array<String>, duration:Float = 1.0) {
        #if windows
        if (animations.length == 0) return;
        
        var currentIndex = 0;
        var animationDuration = duration / animations.length;
        
        function playNextAnimation() {
            if (currentIndex >= animations.length) return;
            
            var anim = animations[currentIndex];
            switch(anim.toLowerCase()) {
                case "shake": shakeWindow(10, animationDuration);
                case "bounce": bounceWindow(2, 30, animationDuration);
                case "pulse": pulseWindow(0.9, 1.1, 3, animationDuration);
                case "elastic": elasticWindow(1.2, 2, animationDuration);
                case "wave": waveWindow(30, 3, animationDuration);
                case "spiral": spiralWindow(1, 50, animationDuration);
                case "zigzag": zigzagWindow(3, 50, animationDuration);
                case "earthquake": earthquakeWindow(8, 12, animationDuration);
                case "breathing": breathingWindow(2, 0.05, animationDuration);
            }
            
            currentIndex++;
            if (currentIndex < animations.length) {
                var timer = new haxe.Timer(Std.int(animationDuration * 1000));
                timer.run = function() {
                    timer.stop();
                    playNextAnimation();
                };
            }
        }
        
        playNextAnimation();
        #end
    }

    public static function rhythmWindow(bpm:Float = 120.0, pattern:String = "pulse", intensity:Float = 1.0, duration:Float = 8.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalWidth = window.width;
        var originalHeight = window.height;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        var beatDuration = 60.0 / bpm; // seconds per beat
        
        var rhythmTimer = new haxe.Timer(16);
        rhythmTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.resize(originalWidth, originalHeight);
                window.x = originalX;
                window.y = originalY;
                FlxG.resizeGame(originalWidth, originalHeight);
                rhythmTimer.stop();
                return;
            }
            
            var beatProgress = (elapsed % beatDuration) / beatDuration;
            var effect:Float = 0;
            
            switch(pattern.toLowerCase()) {
                case "pulse": {
                    effect = Math.abs(Math.sin(beatProgress * Math.PI)) * intensity;
                    var scale = 1.0 + effect * 0.1;
                    var newWidth = Std.int(originalWidth * scale);
                    var newHeight = Std.int(originalHeight * scale);
                    var newX = originalX + Std.int((originalWidth - newWidth) / 2);
                    var newY = originalY + Std.int((originalHeight - newHeight) / 2);
                    window.resize(newWidth, newHeight);
                    window.x = newX;
                    window.y = newY;
                    FlxG.resizeGame(newWidth, newHeight);
                }
                case "shake": {
                    if (beatProgress < 0.1) {
                        var shakeIntensity = intensity * 5;
                        window.x = originalX + Std.int((Math.random() - 0.5) * shakeIntensity);
                        window.y = originalY + Std.int((Math.random() - 0.5) * shakeIntensity);
                    } else {
                        window.x = originalX;
                        window.y = originalY;
                    }
                }
                case "bounce": {
                    if (beatProgress < 0.2) {
                        var bounceHeight = intensity * 20;
                        var bounceProgress = beatProgress / 0.2;
                        var bounce = Math.abs(Math.sin(bounceProgress * Math.PI));
                        window.y = originalY - Std.int(bounceHeight * bounce);
                    } else {
                        window.y = originalY;
                    }
                }
            }
        };
        #end
    }

    public static function danceWindow(danceType:String = "sway", tempo:Float = 1.0, amplitude:Float = 30.0, duration:Float = 5.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        var danceTimer = new haxe.Timer(16);
        danceTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = originalX;
                window.y = originalY;
                danceTimer.stop();
                return;
            }
            
            var time = elapsed * tempo;
            
            switch(danceType.toLowerCase()) {
                case "sway": {
                    var swayX = Math.sin(time) * amplitude;
                    var swayY = Math.cos(time * 0.7) * amplitude * 0.3;
                    window.x = originalX + Std.int(swayX);
                    window.y = originalY + Std.int(swayY);
                }
                case "figure8": {
                    var figureX = Math.sin(time) * amplitude;
                    var figureY = Math.sin(time * 2) * amplitude * 0.5;
                    window.x = originalX + Std.int(figureX);
                    window.y = originalY + Std.int(figureY);
                }
                case "circle": {
                    var circleX = Math.cos(time) * amplitude;
                    var circleY = Math.sin(time) * amplitude;
                    window.x = originalX + Std.int(circleX);
                    window.y = originalY + Std.int(circleY);
                }
                case "pendulum": {
                    var pendulumX = Math.sin(time * 2) * amplitude;
                    window.x = originalX + Std.int(pendulumX);
                    window.y = originalY;
                }
            }
        };
        #end
    }

    public static function glitchWindow(glitchIntensity:Float = 50.0, glitchFrequency:Float = 0.1, duration:Float = 2.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var originalWidth = window.width;
        var originalHeight = window.height;
        var startTime = haxe.Timer.stamp();
        
        var glitchTimer = new haxe.Timer(16);
        glitchTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = originalX;
                window.y = originalY;
                window.resize(originalWidth, originalHeight);
                FlxG.resizeGame(originalWidth, originalHeight);
                glitchTimer.stop();
                return;
            }
            
            if (Math.random() < glitchFrequency) {
                // Position glitch
                var glitchX = originalX + Std.int((Math.random() - 0.5) * glitchIntensity);
                var glitchY = originalY + Std.int((Math.random() - 0.5) * glitchIntensity);
                window.x = glitchX;
                window.y = glitchY;
                
                // Size glitch
                var sizeVariation = 1.0 + (Math.random() - 0.5) * 0.2;
                var glitchWidth = Std.int(originalWidth * sizeVariation);
                var glitchHeight = Std.int(originalHeight * sizeVariation);
                window.resize(glitchWidth, glitchHeight);
                FlxG.resizeGame(glitchWidth, glitchHeight);
            } else {
                // Return to normal position occasionally
                window.x = originalX;
                window.y = originalY;
                window.resize(originalWidth, originalHeight);
                FlxG.resizeGame(originalWidth, originalHeight);
            }
        };
        #end
    }

    public static function matrixWindow(fallSpeed:Float = 2.0, duration:Float = 3.0) {
        #if windows
        var window = Lib.current.stage.window;
        var startY = -window.height - 100;
        var endY = Std.int(Capabilities.screenResolutionY) + 100;
        var originalX = window.x;
        var originalY = window.y;
        var startTime = haxe.Timer.stamp();
        
        // Start from top
        window.y = startY;
        
        var matrixTimer = new haxe.Timer(16);
        matrixTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = originalX;
                window.y = originalY;
                matrixTimer.stop();
                return;
            }
            
            var progress = elapsed / duration;
            var currentY = Std.int(startY + (endY - startY) * progress * fallSpeed);
            
            // Add some horizontal wobble
            var wobble = Math.sin(elapsed * 10) * 10;
            window.x = originalX + Std.int(wobble);
            window.y = currentY;
            
            // If fallen past screen, reset to top
            if (window.y > endY) {
                window.y = startY;
            }
        };
        #end
    }

    public static function gravityWindow(gravityStrength:Float = 0.5, bounce:Float = 0.7, duration:Float = 4.0) {
        #if windows
        var window = Lib.current.stage.window;
        var originalX = window.x;
        var originalY = window.y;
        var velocityY:Float = 0;
        var startTime = haxe.Timer.stamp();
        var screenHeight = Std.int(Capabilities.screenResolutionY);
        var groundY = screenHeight - window.height - 50;
        
        var gravityTimer = new haxe.Timer(16);
        gravityTimer.run = function() {
            var elapsed = haxe.Timer.stamp() - startTime;
            if (elapsed >= duration) {
                window.x = originalX;
                window.y = originalY;
                gravityTimer.stop();
                return;
            }
            
            // Apply gravity
            velocityY += gravityStrength;
            window.y += Std.int(velocityY);
            
            // Check for ground collision
            if (window.y >= groundY) {
                window.y = groundY;
                velocityY = -velocityY * bounce; // Bounce with energy loss
                
                // Stop bouncing if velocity is too small
                if (Math.abs(velocityY) < 1) {
                    velocityY = 0;
                }
            }
            
            // Prevent going above original position too much
            if (window.y < originalY - 100) {
                window.y = originalY - 100;
                velocityY = 0;
            }
        };
        #end
    }
}