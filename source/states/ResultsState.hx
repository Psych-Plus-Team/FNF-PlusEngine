package states;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import states.FreeplayState;
import backend.MusicBeatState;
import backend.Paths; 
import sys.io.File;
import sys.FileSystem;

#if mobile
import mobile.backend.TouchUtil;
#end

class ResultsState extends MusicBeatState
{
    var menuBG:FlxSprite;
    var backdropImage:FlxSprite;
    var flxGroupImage:FlxSprite;
    
    var songInstrumental:String = "";
    var canRetry:Bool = true;

    var params:Dynamic;

    var animatedScore:Int = 0;
    var animatedEpics:Int = 0;
    var animatedSicks:Int = 0;
    var animatedGoods:Int = 0;
    var animatedBads:Int = 0;
    var animatedShits:Int = 0;
    var animatedMisses:Int = 0;
    var animatedCombo:Int = 0;
    var animatedAccuracy:Float = 0;

    var scoreText:FlxText;
    var epics:FlxText;
    var sicks:FlxText;
    var goods:FlxText;
    var bads:FlxText;
    var shits:FlxText;
    var misses:FlxText;
    var comboText:FlxText;
    var accText:FlxText;

    static var use24HourFormat:Bool = true;
    static var dateFormat:String = "MM/DD/YYYY";
    static var timeFormat:String = "HH:mm";

    public function new(params:Dynamic)
    {
        super();
        this.params = params;

        loadDeviceDateTimeSettings();
    }

    override public function create()
    {
        super.create();

        #if MODS_ALLOWED
        if (params.isMod && params.modFolder != null && params.modFolder != "") {
            backend.Mods.currentModDirectory = params.modFolder;
        }
        #end

        menuBG = new FlxSprite();
        menuBG.loadGraphic(Paths.image('menuBG'));
        menuBG.setGraphicSize(FlxG.width, FlxG.height);
        menuBG.updateHitbox();
        menuBG.alpha = 1.0;
        add(menuBG);

        backdropImage = new FlxSprite();
        backdropImage.loadGraphic(Paths.image('ui/backdrop'));
        backdropImage.setGraphicSize(FlxG.width, FlxG.height + 1);
        backdropImage.updateHitbox();
        backdropImage.alpha = 0.8;
        add(backdropImage);

        flxGroupImage = new FlxSprite();
        flxGroupImage.loadGraphic(Paths.image('ui/flxgroup'));
        flxGroupImage.setGraphicSize(FlxG.width, FlxG.height + 1);
        flxGroupImage.updateHitbox();
        flxGroupImage.alpha = 0.4;
        add(flxGroupImage);

        if (!FlxG.sound.music.playing || FlxG.sound.music.length <= 0) {
            FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7, true);
        }

        var infoWidth = 700;
        var songAndDiff = '${params.songName} [${params.difficulty}]';
        var modOrGame = params.isMod && params.modFolder != null && params.modFolder != "" ? params.modFolder : "Friday Night Funkin'";
        var now = Date.now();

        var dateStr = formatDateTimeAccordingToDevice(now);
        
        var resulText = new FlxText(500, 12, infoWidth, Language.getPhrase('results_title', 'Results'), 60);
        resulText.setFormat(Paths.font("aller.ttf"), 60, FlxColor.WHITE, "right");
        add(resulText);

        var topText = new FlxText(10, 5, infoWidth, songAndDiff, 28);
        topText.setFormat(Paths.font("aller.ttf"), 28, FlxColor.WHITE, "left");
        add(topText);

        var modText = new FlxText(10, 39, infoWidth, modOrGame, 22);
        modText.setFormat(Paths.font("aller.ttf"), 22, FlxColor.WHITE, "left");
        add(modText);

        var playedText = new FlxText(10, 65, infoWidth, Language.getPhrase('results_played_on', 'Played on') + ' $dateStr', 18);
        playedText.setFormat(Paths.font("aller.ttf"), 18, FlxColor.WHITE, "left");
        add(playedText);

        var scoreY = 130;
        var scoreStr = StringTools.lpad("0", "0", 8);
        var scoreLabel = new FlxText(60, scoreY, 400, Language.getPhrase('results_score', 'Score') + ':', 34);
        scoreLabel.setFormat(Paths.font("aller.ttf"), 34, FlxColor.WHITE, "left");
        add(scoreLabel);

        scoreText = new FlxText(240, scoreY - 10, 400, scoreStr, 44);
        scoreText.setFormat(Paths.font("aller.ttf"), 44, FlxColor.WHITE, "left");
        add(scoreText);

        var leftX = 30;
        var rightX = 300;
        var judgY = 235;
        var judgSpacing = 90; // Más espacio

        epics = new FlxText(leftX, judgY, 340, Language.getPhrase('judgement_epics', 'Epics') + ': 0', 32);
        epics.setFormat(Paths.font("aller.ttf"), 32, 0xFFA17FFF, "left");
        add(epics);

        sicks = new FlxText(rightX, judgY, 340, Language.getPhrase('judgement_sicks', 'Sicks') + ': 0', 32);
        sicks.setFormat(Paths.font("aller.ttf"), 32, 0xFF7FC9FF, "left");
        add(sicks);

        goods = new FlxText(leftX, judgY + judgSpacing, 340, Language.getPhrase('judgement_goods', 'Goods') + ': 0', 32);
        goods.setFormat(Paths.font("aller.ttf"), 32, 0xFF7FFF8E, "left");
        add(goods);

        bads = new FlxText(rightX, judgY + judgSpacing, 340, Language.getPhrase('judgement_bads', 'Bads') + ': 0', 32);
        bads.setFormat(Paths.font("aller.ttf"), 32, 0xFF888888, "left");
        add(bads);

        shits = new FlxText(leftX, judgY + judgSpacing * 2, 340, Language.getPhrase('judgement_shits', 'Shits') + ': 0', 32);
        shits.setFormat(Paths.font("aller.ttf"), 32, 0xFFFF7F7F, "left");
        add(shits);

        misses = new FlxText(rightX, judgY + judgSpacing * 2, 340, Language.getPhrase('judgement_misses', 'Misses') + ': 0', 32);
        misses.setFormat(Paths.font("aller.ttf"), 32, FlxColor.RED, "left");
        add(misses);

        comboText = new FlxText(leftX, judgY + judgSpacing * 3 - 14, 700, Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': 0', 26);
        comboText.setFormat(Paths.font("aller.ttf"), 32, FlxColor.WHITE, "left");
        add(comboText);

        accText = new FlxText(leftX, judgY + judgSpacing * 3 + 20, 700, Language.getPhrase('results_accuracy', 'Accuracy') + ': 0%', 26);
        accText.setFormat(Paths.font("aller.ttf"), 32, FlxColor.WHITE, "left");
        add(accText);

        var ratingLetter = params.ratingName != null ? params.ratingName : "";
        var ratingFC = params.ratingFC != null ? params.ratingFC : "";
        var ratingW = 400;
        var ratingX = FlxG.width - 525; 
        var ratingY = judgY + 25;
        var ratingText = new FlxText(ratingX, ratingY, ratingW, ratingLetter, 70);
        ratingText.setFormat(Paths.font("aller.ttf"), 70, FlxColor.YELLOW, "center");
        add(ratingText);

        var fcText = new FlxText(ratingX, ratingY + 90, ratingW, ratingFC, 54); 
        fcText.setFormat(Paths.font("aller.ttf"), 54, FlxColor.CYAN, "center");
        add(fcText);

        var yBottom = FlxG.height - 110;
        if (params.isPractice != null && params.isPractice) {
            var practiceText = new FlxText(0, yBottom, FlxG.width, Language.getPhrase('results_practice_mode', 'Played in practice mode'), 22);
            practiceText.setFormat(Paths.font("aller.ttf"), 22, FlxColor.YELLOW, "center");
            add(practiceText);
            yBottom += 28;
        }

        var engineInfo = Language.getPhrase('psych_engine_version', 'Psych Engine v') + MainMenuState.psychEngineVersion + "\n" + Language.getPhrase('fnf_version', 'Friday Night Funkin\' v') + "0.2.8";
        var engineText = new FlxText(0, FlxG.height - 100, FlxG.width, engineInfo, 25);
        engineText.setFormat(Paths.font("aller.ttf"), 25, FlxColor.CYAN, "center");
        add(engineText);

        #if mobile
        var continueText = new FlxText(50, FlxG.height - 75, 0, Language.getPhrase('results_press_enter_mobile', 'Press A\nto Continue'), 26);
        #else
        var continueText = new FlxText(50, FlxG.height - 75, 0, Language.getPhrase('results_press_enter', 'Press Enter\nto Continue'), 26);
        #end
        continueText.setFormat(Paths.font("aller.ttf"), 26, FlxColor.WHITE, "center");
        add(continueText);

        #if mobile
        addTouchPad('NONE', 'A');
        #end
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (animatedScore < params.score) {
            animatedScore += Math.ceil((params.score - animatedScore) * 0.2 + 1);
            if (animatedScore > params.score) animatedScore = params.score;
            scoreText.text = StringTools.lpad(Std.string(animatedScore), "0", 8);
            return;
        }
        scoreText.text = StringTools.lpad(Std.string(animatedScore), "0", 8);

        if (animatedEpics < params.epics) {
            animatedEpics = animateInt(animatedEpics, params.epics);
            epics.text = Language.getPhrase('judgement_epics', 'Epics') + ': $animatedEpics';
            return;
        }
        epics.text = Language.getPhrase('judgement_epics', 'Epics') + ': $animatedEpics';

        if (animatedSicks < params.sicks) {
            animatedSicks = animateInt(animatedSicks, params.sicks);
            sicks.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';
            return;
        }
        sicks.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';

        if (animatedGoods < params.goods) {
            animatedGoods = animateInt(animatedGoods, params.goods);
            goods.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';
            return;
        }
        goods.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';

        if (animatedBads < params.bads) {
            animatedBads = animateInt(animatedBads, params.bads);
            bads.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';
            return;
        }
        bads.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';

        if (animatedShits < params.shits) {
            animatedShits = animateInt(animatedShits, params.shits);
            shits.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';
            return;
        }
        shits.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';

        if (animatedMisses < params.misses) {
            animatedMisses = animateInt(animatedMisses, params.misses);
            misses.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';
            return;
        }
        misses.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';

        if (animatedCombo < params.maxCombo) {
            animatedCombo = animateInt(animatedCombo, params.maxCombo);
            comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';
            return;
        }
        comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';

        if (animatedAccuracy < params.accuracy) {
            animatedAccuracy += (params.accuracy - animatedAccuracy) * 0.2 + 0.1;
            if (animatedAccuracy > params.accuracy) animatedAccuracy = params.accuracy;
            
            var accPercent:Float = Math.round(animatedAccuracy * 1000) / 10;
            accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': ' + Std.string(accPercent) + '%';
            return;
        }
        
        var accPercent:Float = Math.round(animatedAccuracy * 1000) / 10;
        accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': ' + Std.string(accPercent) + '%';

        var shouldContinue:Bool = false;
        
        if (FlxG.keys.justPressed.ENTER) shouldContinue = true;
        
        if (controls.ACCEPT) shouldContinue = true;
        
        #if mobile
        if (TouchUtil.justPressed) shouldContinue = true;
        
        if (FlxG.touches.getFirst() != null && FlxG.touches.getFirst().justPressed) shouldContinue = true;
        #end
        
        if (shouldContinue)
        {
            #if MODS_ALLOWED
            backend.Mods.currentModDirectory = '';
            #end
            MusicBeatState.switchState(new FreeplayState());
        }
    }

    function animateInt(current:Int, target:Int):Int {
        if (current < target)
            return current + Math.ceil((target - current) * 0.2 + 1);
        return target;
    }

    function loadDeviceDateTimeSettings() {
        #if windows
        try {
            var process = new sys.io.Process("reg", ["query", "HKCU\\Control Panel\\International", "/v", "sShortDate"]);
            var output = process.stdout.readAll().toString();
            if (output.indexOf("sShortDate") != -1) {
                var lines = output.split("\n");
                for (line in lines) {
                    if (line.indexOf("sShortDate") != -1) {
                        var parts = line.split("REG_SZ");
                        if (parts.length > 1) {
                            dateFormat = StringTools.trim(parts[1]);
                            break;
                        }
                    }
                }
            }
            process.close();

            var process2 = new sys.io.Process("reg", ["query", "HKCU\\Control Panel\\International", "/v", "iTime"]);
            var output2 = process2.stdout.readAll().toString();
            if (output2.indexOf("iTime") != -1) {
                var lines = output2.split("\n");
                for (line in lines) {
                    if (line.indexOf("iTime") != -1) {
                        var parts = line.split("REG_SZ");
                        if (parts.length > 1) {
                            use24HourFormat = (StringTools.trim(parts[1]) == "1");
                            break;
                        }
                    }
                }
            }
            process2.close();
        } catch(e:Dynamic) {
            trace("Could not read Windows registry, using defaults: " + e);
        }
        #elseif android
        dateFormat = "MM/DD/YYYY";
        use24HourFormat = true;
        #end
    }

    function formatDateTimeAccordingToDevice(date:Date):String {
        var dayNames = [
            Language.getPhrase("day_sunday", "Sunday"),
            Language.getPhrase("day_monday", "Monday"), 
            Language.getPhrase("day_tuesday", "Tuesday"),
            Language.getPhrase("day_wednesday", "Wednesday"),
            Language.getPhrase("day_thursday", "Thursday"),
            Language.getPhrase("day_friday", "Friday"),
            Language.getPhrase("day_saturday", "Saturday")
        ];
        var monthNames = [
            Language.getPhrase("month_january", "January"),
            Language.getPhrase("month_february", "February"),
            Language.getPhrase("month_march", "March"),
            Language.getPhrase("month_april", "April"),
            Language.getPhrase("month_may", "May"),
            Language.getPhrase("month_june", "June"),
            Language.getPhrase("month_july", "July"),
            Language.getPhrase("month_august", "August"),
            Language.getPhrase("month_september", "September"),
            Language.getPhrase("month_october", "October"),
            Language.getPhrase("month_november", "November"),
            Language.getPhrase("month_december", "December")
        ];
        
        var dayName = dayNames[date.getDay()];
        var monthName = monthNames[date.getMonth()];
        var day = date.getDate();
        var month = date.getMonth() + 1;
        var year = date.getFullYear();
        var hours = date.getHours();
        var minutes = date.getMinutes();

        var minutesStr = (minutes < 10) ? "0" + minutes : Std.string(minutes);

        var timeStr = "";
        if (use24HourFormat) {
            timeStr = '$hours:$minutesStr';
        } else {
            var amPm = hours >= 12 ? "PM" : "AM";
            var hour12 = hours % 12;
            if (hour12 == 0) hour12 = 12;
            timeStr = '$hour12:$minutesStr $amPm';
        }
        
        var dateStr = "";
        switch (dateFormat.toUpperCase()) {
            case "MM/DD/YYYY":
                dateStr = '$monthName $day, $year';
            case "DD/MM/YYYY":
                dateStr = '$day $monthName $year';
            case "YYYY-MM-DD":
                dateStr = '$year-$month-$day';
            case "DD.MM.YYYY":
                dateStr = '$day.$month.$year';
            default:
                dateStr = '$dayName - $monthName $day, $year';
        }
        
        return '$dateStr - $timeStr';
    }
}
