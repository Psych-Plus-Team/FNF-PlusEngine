package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import backend.ClientPrefs;
import backend.MusicBeatSubstate;
import states.TitleState;
import states.MainMenuState;

class RestartConfirmSubState extends MusicBeatSubstate
{
    var bg:FlxSprite;
    var panel:FlxSprite;
    var warningIcon:FlxSprite;
    var titleText:FlxText;
    var messageText:FlxText;
    var yesButton:ConfirmButton;
    var noButton:ConfirmButton;
    var countdownText:FlxText;
    var selectedButton:Int = 0;
    var autoRestartTimer:FlxTimer;
    var countdown:Int = 10;
    
    public function new()
    {
        super();

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        add(bg);

        panel = new FlxSprite(0, 0);
        panel.makeGraphic(600, 400, FlxColor.TRANSPARENT);
        panel.screenCenter();
        FlxSpriteUtil.drawRoundRect(panel, 0, 0, 600, 400, 25, 25, 0xFF16213E);
        panel.alpha = 0;
        panel.y -= 50;
        add(panel);

        warningIcon = new FlxSprite();
        warningIcon.loadGraphic(Paths.image('menuDesat'));
        warningIcon.color = 0xFFFFA500;
        warningIcon.scale.set(0.3, 0.3);
        warningIcon.updateHitbox();
        warningIcon.screenCenter();
        warningIcon.y = panel.y + 70;
        warningIcon.alpha = 0;
        add(warningIcon);

        titleText = new FlxText(0, 0, 550, Language.getPhrase('restart_required_title', 'RESTART REQUIRED'), 36);
        titleText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        titleText.borderSize = 3;
        titleText.screenCenter(X);
        titleText.y = panel.y + 30;
        titleText.alpha = 0;
        add(titleText);

        messageText = new FlxText(0, 0, 550, 
            Language.getPhrase('restart_required_message', 
                'Mod changes require a restart to take effect.\n\nWould you like to restart now?\n\nGame will auto-restart in {0} seconds.', [countdown]), 
            24);
        messageText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFD3D3D3, CENTER);
        messageText.screenCenter(X);
        messageText.y = panel.y + 150;
        messageText.alpha = 0;
        add(messageText);

        countdownText = new FlxText(0, 0, 550, '', 48);
        countdownText.setFormat(Paths.font("vcr.ttf"), 48, 0xFFFFA500, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        countdownText.borderSize = 3;
        countdownText.screenCenter();
        countdownText.alpha = 0;
        add(countdownText);

        yesButton = new ConfirmButton(0, 0, 250, 60, 
            Language.getPhrase('restart_now', 'RESTART NOW'), 
            FlxColor.GREEN, function() {
                performRestart();
            });
        yesButton.x = panel.x + 50;
        yesButton.y = panel.y + panel.height - 90;
        yesButton.alpha = 0;
        add(yesButton);

        noButton = new ConfirmButton(0, 0, 250, 60, 
            Language.getPhrase('restart_later', 'RESTART LATER'), 
            FlxColor.RED, function() {
                cancelRestart();
            });
        noButton.x = panel.x + panel.width - 250 - 50;
        noButton.y = panel.y + panel.height - 90;
        noButton.alpha = 0;
        add(noButton);

        startAnimations();

        autoRestartTimer = new FlxTimer();
        autoRestartTimer.start(1, function(tmr:FlxTimer) {
            countdown--;
            updateCountdown();
            
            if (countdown <= 0) {
                performRestart();
            } else {
                tmr.reset(1);
            }
        }, countdown);

        updateSelection();
    }
    
    function startAnimations()
    {
        FlxTween.tween(bg, {alpha: 0.7}, 0.3, {ease: FlxEase.quadOut});

        FlxTween.tween(panel, {alpha: 1, y: panel.y + 50}, 0.5, {
            ease: FlxEase.backOut,
            onComplete: function(twn:FlxTween) {
                FlxTween.tween(warningIcon, {alpha: 0.8}, 0.3, {ease: FlxEase.quadOut});
                FlxTween.tween(titleText, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
                FlxTween.tween(messageText, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
                FlxTween.tween(yesButton, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
                FlxTween.tween(noButton, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
                FlxTween.tween(countdownText, {alpha: 0.7}, 0.3, {ease: FlxEase.quadOut});
            }
        });

        new FlxTimer().start(0.01, function(tmr:FlxTimer) {
            if (warningIcon != null && warningIcon.exists) {
                warningIcon.scale.x = 0.3 + 0.05 * Math.sin(FlxG.game.ticks * 0.01);
                warningIcon.scale.y = 0.3 + 0.05 * Math.sin(FlxG.game.ticks * 0.01);
                warningIcon.updateHitbox();
                warningIcon.screenCenter(X);
                warningIcon.y = panel.y + 70;
            }
        }, 0);
    }
    
    function updateCountdown()
    {
        messageText.text = Language.getPhrase('restart_required_message', 
            'Mod changes require a restart to take effect.\n\nWould you like to restart now?\n\nGame will auto-restart in {0} seconds.', [countdown]);

        if (countdown <= 5) {
            countdownText.text = Std.string(countdown);
            countdownText.screenCenter();

            countdownText.scale.set(1.2, 1.2);
            FlxTween.tween(countdownText.scale, {x: 1.0, y: 1.0}, 0.5, {ease: FlxEase.quadOut});

            if (countdown <= 3) {
                countdownText.color = FlxColor.RED;
            } else if (countdown <= 5) {
                countdownText.color = 0xFFFFA500;
            }
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.UI_LEFT_P) {
            changeSelection(-1);
        } else if (controls.UI_RIGHT_P) {
            changeSelection(1);
        }

        if (controls.ACCEPT) {
            selectButton();
        }

        if (controls.BACK || FlxG.mouse.justPressedRight) {
            cancelRestart();
        }

        if (FlxG.mouse.justMoved) {
            var mouseOverYes = FlxG.mouse.overlaps(yesButton);
            var mouseOverNo = FlxG.mouse.overlaps(noButton);
            
            if (mouseOverYes && selectedButton != 0) {
                selectedButton = 0;
                updateSelection();
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
            } else if (mouseOverNo && selectedButton != 1) {
                selectedButton = 1;
                updateSelection();
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
            }
        }

        if (FlxG.mouse.justPressed) {
            if (FlxG.mouse.overlaps(yesButton)) {
                yesButton.onClick();
            } else if (FlxG.mouse.overlaps(noButton)) {
                noButton.onClick();
            }
        }
    }
    
    function changeSelection(change:Int)
    {
        selectedButton += change;
        
        if (selectedButton < 0) selectedButton = 1;
        if (selectedButton > 1) selectedButton = 0;
        
        updateSelection();
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
    }
    
    function updateSelection()
    {
        yesButton.setSelected(selectedButton == 0);
        noButton.setSelected(selectedButton == 1);
    }
    
    function selectButton()
    {
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
        
        if (selectedButton == 0) {
            performRestart();
        } else {
            cancelRestart();
        }
    }
    
    function performRestart()
    {
        if (autoRestartTimer != null) {
            autoRestartTimer.cancel();
        }

        yesButton.enabled = false;
        noButton.enabled = false;

        FlxTween.tween(panel, {alpha: 0, y: panel.y - 50}, 0.5, {ease: FlxEase.quadIn});
        FlxTween.tween(bg, {alpha: 0}, 0.5, {ease: FlxEase.quadIn});

        var restartingText = new FlxText(0, 0, FlxG.width, Language.getPhrase('restarting', 'Restarting...'), 32);
        restartingText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        restartingText.borderSize = 3;
        restartingText.screenCenter();
        restartingText.alpha = 0;
        add(restartingText);
        
        FlxTween.tween(restartingText, {alpha: 1}, 0.5, {
            ease: FlxEase.quadOut,
            onComplete: function(twn:FlxTween) {
                new FlxTimer().start(1, function(tmr:FlxTimer) {
                    #if desktop
                    saveModsState();

                    TitleState.initialized = false;
                    TitleState.closedState = false;

                    FlxG.sound.music.fadeOut(0.5, 0, function(twn:FlxTween) {
                        FlxG.resetGame();
                    });
                    #else
                    close();
                    MusicBeatState.switchState(new MainMenuState());
                    #end
                });
            }
        });
    }
    
    function cancelRestart()
    {
        if (autoRestartTimer != null) {
            autoRestartTimer.cancel();
        }
        
        FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);

        FlxTween.tween(bg, {alpha: 0}, 0.3, {ease: FlxEase.quadOut});
        FlxTween.tween(panel, {alpha: 0, y: panel.y - 50}, 0.3, {
            ease: FlxEase.quadOut,
            onComplete: function(twn:FlxTween) {
                close();
            }
        });
    }
    
    function saveModsState()
    {
        var fileStr = '';
        var modsList = Mods.parseList();
        
        for (mod in modsList.all) {
            if (mod.trim().length < 1) continue;
            
            var status = modsList.disabled.contains(mod) ? '0' : '1';
            fileStr += '$mod|$status\n';
        }
        
        var path = #if android StorageUtil.getExternalStorageDirectory() + #else Sys.getCwd() + #end 'modsList.txt';
        File.saveContent(path, fileStr);
    }
    
    override function destroy()
    {
        if (autoRestartTimer != null) {
            autoRestartTimer.cancel();
        }
        
        super.destroy();
    }
}

class ConfirmButton extends FlxSpriteGroup
{
    public var bg:FlxSprite;
    public var text:FlxText;
    public var onClick:Void->Void;
    public var enabled(default, set):Bool = true;
    
    public function new(x:Float, y:Float, width:Int, height:Int, label:String, color:FlxColor, ?onClick:Void->Void)
    {
        super(x, y);
        
        this.onClick = onClick;

        bg = new FlxSprite(0, 0);
        bg.makeGraphic(width, height, color);
        FlxSpriteUtil.drawRoundRect(bg, 0, 0, width, height, 15, 15, FlxColor.BLACK);
        bg.alpha = 0.8;
        add(bg);

        text = new FlxText(0, 0, width, label, 24);
        text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        text.borderSize = 2;
        text.y = height / 2 - text.height / 2;
        add(text);
    }
    
    public function setSelected(selected:Bool)
    {
        if (selected) {
            bg.alpha = 1;
            text.scale.set(1.1, 1.1);
            text.color = FlxColor.YELLOW;

            FlxTween.cancelTweensOf(bg);
            FlxTween.tween(bg.scale, {x: 1.05, y: 1.05}, 0.5, {
                type: FlxTweenType.PINGPONG,
                ease: FlxEase.sineInOut
            });
        } else {
            bg.alpha = enabled ? 0.8 : 0.4;
            text.scale.set(1, 1);
            text.color = FlxColor.WHITE;
            
            FlxTween.cancelTweensOf(bg);
            bg.scale.set(1, 1);
        }
    }
    
    function set_enabled(value:Bool):Bool
    {
        enabled = value;
        setSelected(false);
        return enabled;
    }
    
    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (enabled && FlxG.mouse.justPressed && FlxG.mouse.overlaps(this)) {
            if (onClick != null) onClick();
        }

        if (Controls.instance.mobileC && enabled) {
            for (touch in FlxG.touches.list) {
                if (touch.justPressed && touch.overlaps(this)) {
                    if (onClick != null) onClick();
                    break;
                }
            }
        }
    }
}