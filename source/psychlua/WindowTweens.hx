package psychlua;

import openfl.Lib;
import openfl.system.Capabilities;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.util.FlxColor;
import states.PlayState;

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

    public static function winResizeCenter(width:Int, height:Int, ?skip:Bool = false) {
        var window = Lib.application.window;
        var camHUD = PlayState.instance.camHUD;
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
                onComplete: function(_) camHUD.fade(FlxColor.BLACK, 0, true)
            });
        } else {
            FlxG.resizeWindow(width, height);
            window.y = Math.floor((Capabilities.screenResolutionY / 2) - (winY / 2));
            window.x = Std.int(Math.floor((Capabilities.screenResolutionX / 2) - (winX / 2)) + (Capabilities.screenResolutionX * Math.floor(window.x / (Capabilities.screenResolutionX))));
        }
        FlxG.scaleMode = new RatioScaleMode(true);
        window.resizable = width == 1280;
    }
}