package substates;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.Http;

import states.MainMenuState;
import states.TitleState;

class OutdatedSubState extends MusicBeatSubstate
{
    public static var updateVersion:String = ""; // Agregar esta variable estática
    
    var leftState:Bool = false;
    var changelogLoaded:Bool = false;
    var changelog:String = "";

    var bg:FlxSprite;
    var titleText:FlxText;
    var versionText:FlxText;
    var changelogText:FlxText;
    var controlsText:FlxText;

    override function create()
    {
        super.create();

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.scrollFactor.set();
        bg.alpha = 0.0;
        add(bg);

        // Title text - "Update Available!"
        titleText = new FlxText(0, 50, FlxG.width, 
            Language.getPhrase('update_available_title', "Update Available!")
        );
        titleText.setFormat(Paths.defaultFont(), 48, FlxColor.YELLOW, CENTER);
        titleText.scrollFactor.set();
        titleText.alpha = 0.0;
        add(titleText);

        // Version comparison text
        versionText = new FlxText(0, 120, FlxG.width,
            Language.getPhrase('version_comparison', "Current Version: {1} => New Version: {2}", 
                [MainMenuState.plusEngineVersion, updateVersion])
        );
        versionText.setFormat(Paths.defaultFont(), 24, FlxColor.WHITE, CENTER);
        versionText.scrollFactor.set();
        versionText.alpha = 0.0;
        add(versionText);

        // Changelog text (will be loaded from GitHub)
        changelogText = new FlxText(50, 180, FlxG.width - 100,
            Language.getPhrase('loading_changelog', "Loading changelog...")
        );
        changelogText.setFormat(Paths.defaultFont(), 18, FlxColor.CYAN, LEFT);
        changelogText.scrollFactor.set();
        changelogText.alpha = 0.0;
        add(changelogText);

        // Controls text
        controlsText = new FlxText(0, FlxG.height - 120, FlxG.width,
            Language.getPhrase('update_controls',
                "Press ENTER to update to the latest version\nPress ESCAPE if you're on the correct engine version\nYou can disable this warning in Options Menu"
            )
        );
        controlsText.setFormat(Paths.defaultFont(), 20, FlxColor.WHITE, CENTER);
        controlsText.scrollFactor.set();
        controlsText.alpha = 0.0;
        add(controlsText);

        // Start animations
        FlxTween.tween(bg, { alpha: 0.8 }, 0.6, { ease: FlxEase.sineIn });
        FlxTween.tween(titleText, { alpha: 1.0 }, 0.6, { ease: FlxEase.sineIn });
        FlxTween.tween(versionText, { alpha: 1.0 }, 0.8, { ease: FlxEase.sineIn });
        FlxTween.tween(changelogText, { alpha: 1.0 }, 1.0, { ease: FlxEase.sineIn });
        FlxTween.tween(controlsText, { alpha: 1.0 }, 1.2, { ease: FlxEase.sineIn });

        // Load changelog from GitHub
        loadChangelog();
    }

    function loadChangelog():Void
    {
        var http = new Http("https://raw.githubusercontent.com/LeninAsto/FNF-PlusEngine/refs/heads/main/gitChangelog.txt");
        
        http.onData = function(data:String) {
            changelog = data;
            changelogLoaded = true;
            updateChangelogDisplay();
        };
        
        http.onError = function(error:String) {
            changelog = Language.getPhrase('changelog_error', "Error loading changelog: {1}", [error]);
            changelogLoaded = true;
            updateChangelogDisplay();
        };
        
        http.request();
    }

    function updateChangelogDisplay():Void
    {
        if (changelogLoaded && changelogText != null) {
            changelogText.text = Language.getPhrase('changelog_title', "What's New:\n{1}", [changelog]);
        }
    }

    override function update(elapsed:Float)
    {
        if(!leftState) {
            if (controls.ACCEPT) {
                leftState = true;
                CoolUtil.browserLoad("https://github.com/LeninAsto/FNF-PlusEngine/releases");
            }
            else if(controls.BACK) {
                leftState = true;
            }
            if(leftState)
            {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                FlxTween.tween(bg, { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
                FlxTween.tween(titleText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
                FlxTween.tween(versionText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
                FlxTween.tween(changelogText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
                FlxTween.tween(controlsText, {alpha: 0}, 1, {
                    ease: FlxEase.sineOut,
                    onComplete: function (twn:FlxTween) {
                        FlxG.state.persistentUpdate = true;
                        close();
                    }
                });
            }
        }
        super.update(elapsed);
    }
}
