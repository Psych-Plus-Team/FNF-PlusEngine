package states;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import openfl.utils.Assets;
import states.FreeplayState;
import backend.CustomFadeTransition;
import backend.Song;
import states.PlayState;
import backend.MusicBeatState;
import backend.Paths; // ← Agregar import
import DateTools;

#if mobile
import mobile.backend.TouchUtil;
#end

class ResultsState extends MusicBeatState
{
    // Variables para las capas de fondo
    var menuBG:FlxSprite;
    var backdropImage:FlxSprite;
    var flxGroupImage:FlxSprite;
    
    var songInstrumental:String = "";
    var canRetry:Bool = true;

    var params:Dynamic;

    // Variables animadas
    var animatedScore:Int = 0;
    var animatedEpics:Int = 0;
    var animatedSicks:Int = 0;
    var animatedGoods:Int = 0;
    var animatedBads:Int = 0;
    var animatedShits:Int = 0;
    var animatedMisses:Int = 0;
    var animatedCombo:Int = 0;
    var animatedAccuracy:Float = 0;

    // Referencias a los textos
    var scoreText:FlxText;
    var epics:FlxText;
    var sicks:FlxText;
    var goods:FlxText;
    var bads:FlxText;
    var shits:FlxText;
    var misses:FlxText;
    var comboText:FlxText;
    var accText:FlxText;

    public function new(params:Dynamic)
    {
        super();
        this.params = params;
    }

    override public function create()
    {
        super.create();

        // --- Configurar mod directory para Paths ---
        #if MODS_ALLOWED
        if (params.isMod && params.modFolder != null && params.modFolder != "") {
            backend.Mods.currentModDirectory = params.modFolder;
        }
        #end

        // --- CAPAS DE FONDO EN ORDEN CORRECTO ---
        
        // 1. CAPA MÁS ATRÁS: menuBG (alpha 1.0)
        menuBG = new FlxSprite();
        menuBG.loadGraphic(Paths.image('menuBG'));
        menuBG.setGraphicSize(FlxG.width, FlxG.height);
        menuBG.updateHitbox();
        menuBG.alpha = 1.0;
        add(menuBG);

        // 2. CAPA MEDIA: backdrop.png (alpha 0.8)
        backdropImage = new FlxSprite();
        backdropImage.loadGraphic(Paths.image('backdrop'));
        backdropImage.setGraphicSize(FlxG.width, FlxG.height + 1);
        backdropImage.updateHitbox();
        backdropImage.alpha = 0.8;
        add(backdropImage);

        // 3. CAPA SUPERIOR (pero debajo del texto): flxgroup.png (alpha 0.8)
        flxGroupImage = new FlxSprite();
        flxGroupImage.loadGraphic(Paths.image('flxgroup'));
        flxGroupImage.setGraphicSize(FlxG.width, FlxG.height + 1);
        flxGroupImage.updateHitbox();
        flxGroupImage.alpha = 0.4;
        add(flxGroupImage);

        // --- NO REPRODUCIR MÚSICA INSTRUMENTAL - Solo mantener freakyMenu ---
        // Comentado: playResultsMusic();
        
        // Asegurar que freakyMenu esté reproduciéndose
        if (!FlxG.sound.music.playing || FlxG.sound.music.length <= 0) {
            FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7, true);
        }

        // --- Info superior centrada y más pequeña ---
        var infoWidth = 700;
        var infoX = (FlxG.width - infoWidth) / 2;
        var songAndDiff = '${params.songName} [${params.difficulty}]';
        var modOrGame = params.isMod && params.modFolder != null && params.modFolder != "" ? params.modFolder : "Friday Night Funkin'";
        var now = Date.now();
        
        // ← USAR TRADUCCIONES PARA FECHA
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
        
        var dayName = dayNames[now.getDay()];
        var monthName = monthNames[now.getMonth()];
        var day = now.getDate();
        var year = now.getFullYear();
        var hours = now.getHours();
        var minutes = now.getMinutes();
        var minutesStr = (minutes < 10) ? "0" + minutes : Std.string(minutes);
        var dateStr = '$dayName - $monthName $day, $year $hours:${minutesStr}hrs';

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

        // --- Score y texto a la izquierda ---
        var scoreY = 130;
        var scoreStr = StringTools.lpad("0", "0", 8);
        var scoreLabel = new FlxText(60, scoreY, 400, Language.getPhrase('results_score', 'Score') + ':', 34);
        scoreLabel.setFormat(Paths.font("aller.ttf"), 34, FlxColor.WHITE, "left");
        add(scoreLabel);

        scoreText = new FlxText(240, scoreY - 10, 400, scoreStr, 44);
        scoreText.setFormat(Paths.font("aller.ttf"), 44, FlxColor.WHITE, "left");
        add(scoreText);

        // --- Judgements en dos columnas, más grandes y más separados ---
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

        // --- Highest Combo y Accuracy más abajo y grandes ---
        comboText = new FlxText(leftX, judgY + judgSpacing * 3 - 14, 700, Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': 0', 26);
        comboText.setFormat(Paths.font("aller.ttf"), 32, FlxColor.WHITE, "left");
        add(comboText);

        accText = new FlxText(leftX, judgY + judgSpacing * 3 + 20, 700, Language.getPhrase('results_accuracy', 'Accuracy') + ': 0%', 26);
        accText.setFormat(Paths.font("aller.ttf"), 32, FlxColor.WHITE, "left");
        add(accText);

        // --- Rating grande, fuente menor y ancho ajustado ---
        var ratingLetter = params.ratingName != null ? params.ratingName : "";
        var ratingFC = params.ratingFC != null ? params.ratingFC : "";
        var ratingW = 400;
        var ratingX = FlxG.width - 525; // Más a la izquierda (ajusta el 340 a tu gusto)
        var ratingY = judgY + 25;
        var ratingText = new FlxText(ratingX, ratingY, ratingW, ratingLetter, 70);
        ratingText.setFormat(Paths.font("aller.ttf"), 70, FlxColor.YELLOW, "center");
        add(ratingText);

        var fcText = new FlxText(ratingX, ratingY + 90, ratingW, ratingFC, 54); // Fuente más grande
        fcText.setFormat(Paths.font("aller.ttf"), 54, FlxColor.CYAN, "center");
        add(fcText);

        // --- Mensaje de práctica ---
        var yBottom = FlxG.height - 110;
        if (params.isPractice != null && params.isPractice) {
            var practiceText = new FlxText(0, yBottom, FlxG.width, Language.getPhrase('results_practice_mode', 'Played in practice mode'), 22);
            practiceText.setFormat(Paths.font("aller.ttf"), 22, FlxColor.YELLOW, "center");
            add(practiceText);
            yBottom += 28;
        }

        // --- Versiones arriba del texto de continuar ---
        var engineInfo = Language.getPhrase('plus_engine_version', 'Plus Engine v') + MainMenuState.plusEngineVersion + "\n" + Language.getPhrase('psych_engine_version', 'Psych Engine v') + MainMenuState.psychEngineVersion + "\n" + Language.getPhrase('fnf_version', 'Friday Night Funkin\' v') + "0.2.8";
        var engineText = new FlxText(0, FlxG.height - 115, FlxG.width, engineInfo, 25);
        engineText.setFormat(Paths.font("aller.ttf"), 25, FlxColor.CYAN, "center");
        add(engineText);

        // --- Instrucciones para continuar (diferentes para móvil y PC) ---
        #if mobile
        var continueText = new FlxText(50, FlxG.height - 75, 0, Language.getPhrase('results_press_enter_mobile', 'Touch anywhere or press A\nto Continue'), 26);
        #else
        var continueText = new FlxText(50, FlxG.height - 75, 0, Language.getPhrase('results_press_enter', 'Press Enter\nfor Continue'), 26);
        #end
        continueText.setFormat(Paths.font("aller.ttf"), 26, FlxColor.WHITE, "center");
        add(continueText);

        // --- Agregar touchPad para dispositivos móviles ---
        #if mobile
        addTouchPad('NONE', 'A');
        #end
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        // 1. Score
        if (animatedScore < params.score) {
            animatedScore += Math.ceil((params.score - animatedScore) * 0.2 + 1);
            if (animatedScore > params.score) animatedScore = params.score;
            scoreText.text = StringTools.lpad(Std.string(animatedScore), "0", 8);
            return;
        }
        scoreText.text = StringTools.lpad(Std.string(animatedScore), "0", 8);

        // 2. Epics
        if (animatedEpics < params.epics) {
            animatedEpics = animateInt(animatedEpics, params.epics);
            epics.text = Language.getPhrase('judgement_epics', 'Epics') + ': $animatedEpics';
            return;
        }
        epics.text = Language.getPhrase('judgement_epics', 'Epics') + ': $animatedEpics';

        // 3. Sicks
        if (animatedSicks < params.sicks) {
            animatedSicks = animateInt(animatedSicks, params.sicks);
            sicks.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';
            return;
        }
        sicks.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';

        // 4. Goods
        if (animatedGoods < params.goods) {
            animatedGoods = animateInt(animatedGoods, params.goods);
            goods.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';
            return;
        }
        goods.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';

        // 5. Bads
        if (animatedBads < params.bads) {
            animatedBads = animateInt(animatedBads, params.bads);
            bads.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';
            return;
        }
        bads.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';

        // 6. Shits
        if (animatedShits < params.shits) {
            animatedShits = animateInt(animatedShits, params.shits);
            shits.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';
            return;
        }
        shits.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';

        // 7. Misses
        if (animatedMisses < params.misses) {
            animatedMisses = animateInt(animatedMisses, params.misses);
            misses.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';
            return;
        }
        misses.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';

        // 8. Highest Combo
        if (animatedCombo < params.maxCombo) {
            animatedCombo = animateInt(animatedCombo, params.maxCombo);
            comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';
            return;
        }
        comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';

        // 9. Accuracy
        if (animatedAccuracy < params.accuracy) {
            animatedAccuracy += (params.accuracy - animatedAccuracy) * 0.2 + 0.1;
            if (animatedAccuracy > params.accuracy) animatedAccuracy = params.accuracy;
            accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': ' + Std.string(Math.round(animatedAccuracy * 1000) / 10) + '%';
            return;
        }
        accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': ' + Std.string(Math.round(animatedAccuracy * 1000) / 10) + '%';

        // --- Transición con múltiples controles (teclado, gamepad, móvil) ---
        var shouldContinue:Bool = false;
        
        // Controles de teclado
        if (FlxG.keys.justPressed.ENTER) shouldContinue = true;
        
        // Controles de gamepad y móviles (botón A en touchPad)
        if (controls.ACCEPT) shouldContinue = true;
        
        #if mobile
        // Toque directo en la pantalla
        if (TouchUtil.justPressed) shouldContinue = true;
        
        // Alternativa con FlxG.touches para mayor compatibilidad
        if (FlxG.touches.getFirst() != null && FlxG.touches.getFirst().justPressed) shouldContinue = true;
        #end
        
        if (shouldContinue)
        {
            // NO parar la música: FlxG.sound.music.stop();
            
            // Resetear mod directory antes de ir a freeplay
            #if MODS_ALLOWED
            backend.Mods.currentModDirectory = '';
            #end
            
            // Ir directamente a FreeplayState manteniendo la música
            MusicBeatState.switchState(new FreeplayState());
        }
    }

    // Función auxiliar para animar enteros
    function animateInt(current:Int, target:Int):Int {
        if (current < target)
            return current + Math.ceil((target - current) * 0.2 + 1);
        return target;
    }
}

