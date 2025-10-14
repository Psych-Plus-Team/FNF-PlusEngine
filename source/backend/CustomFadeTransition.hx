package backend;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxCamera;
import states.MainMenuState;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	var isTransIn:Bool = false;
    
    // ← MEJORADO: Sistema de bloqueo más robusto
    public static var isTransitioning:Bool = false;
    public static var currentTransition:CustomFadeTransition = null; // ← NUEVO: Referencia global
    
    // Elementos de la puerta morada
    var topDoor:FlxSprite;
    var bottomDoor:FlxSprite;
    var waterMark:FlxText;
    var eventText:FlxText;
    var iconSprite:FlxSprite;
    
    // Colores morados inspirados en Psych Engine para gradientes
    static final DOOR_COLOR_LIGHT:FlxColor = 0xFF8B5CF6;   // Morado claro
    static final DOOR_COLOR_MAIN:FlxColor = 0xFF6B46C1;    // Morado principal
    static final DOOR_COLOR_DARK:FlxColor = 0xFF4C1D95;    // Morado oscuro
    static final DOOR_COLOR_DARKER:FlxColor = 0xFF2D1B69;  // Morado muy oscuro

	var duration:Float;
    var holdTime:Float = 0.5;
    
    // Tweens para mejor control
    var topDoorTween:FlxTween;
    var bottomDoorTween:FlxTween;
    var textTween:FlxTween;
    var holdTween:FlxTween;
    var iconTween:FlxTween;
    
    // Objeto dummy para el hold tween
    var holdDummy:FlxSprite;
    
    var isDestroyed:Bool = false;
    var isClosing:Bool = false;
    
    // Lista de todos los tweens activos
    var activeTweens:Array<FlxTween> = [];
    
    // ← NUEVO: ID único para cada transición
    var transitionId:String;
    
    // ← NUEVO: Función para generar ID único
    static function generateId():String {
        return 'transition_' + Date.now().getTime() + '_' + Math.floor(Math.random() * 1000);
    }
    
    // ← NUEVO: Función estática para cancelar transición actual
    public static function cancelCurrentTransition():Void {
        if (currentTransition != null && !currentTransition.isDestroyed) {
            trace('Canceling current transition: ${currentTransition.transitionId}');
            currentTransition.forceClose();
        }
        
        // ← RESETEAR ESTADOS GLOBALES
        isTransitioning = false;
        currentTransition = null;
        finishCallback = null;
    }
    
    // Función para registrar tweens
    function addTween(tween:FlxTween):FlxTween {
        if (tween != null) {
            activeTweens.push(tween);
        }
        return tween;
    }

    public function new(duration:Float = 0.3, isTransIn:Bool, ?holdTime:Float = 0.2)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
        this.holdTime = holdTime;
        this.activeTweens = [];
        this.transitionId = generateId();
        
        // ← CANCELAR TRANSICIÓN ANTERIOR ANTES DE CREAR NUEVA
        if (currentTransition != null && currentTransition != this) {
            trace('Canceling previous transition before creating new one');
            cancelCurrentTransition();
        }
        
        // ← ESTABLECER COMO TRANSICIÓN ACTUAL
        currentTransition = this;
        isTransitioning = true;
        
		super();
	}

	override function create()
	{
        super.create();
        
        // ← VERIFICAR QUE SEGUIMOS SIENDO LA TRANSICIÓN ACTUAL
        if (currentTransition != this) {
            trace('This transition is no longer current, destroying');
            forceClose();
            return;
        }
        try {
            // Crear objeto dummy para el hold tween
            holdDummy = new FlxSprite();
            holdDummy.makeGraphic(1, 1, 0x00FFFFFF);
            holdDummy.alpha = 0;
            add(holdDummy);
            
            // Crear cámara dedicada con configuración móvil mejorada
            var cam:FlxCamera = new FlxCamera();
            cam.bgColor = 0x00;
            
            #if mobile
            // Configuración específica para móviles para evitar problemas de input
            cam.followLerp = 0;
            cam.pixelPerfectRender = false;
            #end
            
            FlxG.cameras.add(cam, false);
            cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
            
            var width:Int = FlxG.width;
            var height:Int = FlxG.height;
            
            // Crear puertas con imágenes personalizadas
            topDoor = new FlxSprite();
            topDoor.loadGraphic(Paths.image('ui/transUp'));
            topDoor.scrollFactor.set();
            topDoor.setGraphicSize(width, height);
            topDoor.updateHitbox();
            topDoor.antialiasing = ClientPrefs.data.antialiasing;
            
            bottomDoor = new FlxSprite();
            bottomDoor.loadGraphic(Paths.image('ui/transDown'));
            bottomDoor.scrollFactor.set();
            bottomDoor.setGraphicSize(width, height);
            bottomDoor.updateHitbox();
            bottomDoor.antialiasing = ClientPrefs.data.antialiasing;
            
            // Crear ícono central
            iconSprite = new FlxSprite();
            iconSprite.loadGraphic(Paths.image('loading_screen/icon'));
            iconSprite.scrollFactor.set();
            iconSprite.scale.set(0.5, 0.5);
            iconSprite.screenCenter();
            
            // Crear textos informativos
            waterMark = new FlxText(0, height - 140, 300, 'Psych Engine v${MainMenuState.psychEngineVersion}\nPlus Engine v${MainMenuState.plusEngineVersion}', 32);
            waterMark.x = (width - waterMark.width) / 2;
            waterMark.setFormat(Paths.font("aller.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            waterMark.scrollFactor.set();
            waterMark.borderSize = 2;
            
            eventText = new FlxText(50, height - 60, 300, '', 28);
            eventText.x = (width - eventText.width) / 2;
            eventText.setFormat(Paths.font("aller.ttf"), 28, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            eventText.scrollFactor.set();
            eventText.borderSize = 2;
            
            if(isTransIn) {
                // TRANSITION IN: Empezar cerrado, luego abrir
                createTransitionIn(width, height);
            } else {
                // TRANSITION OUT: Empezar abierto, luego cerrar
                createTransitionOut(width, height);
            }
            
        } catch(e:Dynamic) {
            trace('Error creating transition: $e');
            forceUnlock();
        }
    }
    
    function createTransitionIn(width:Int, height:Int):Void {
        topDoor.y = 0;
        bottomDoor.y = 0;
        iconSprite.alpha = 1;
        
        waterMark.alpha = 1;
        eventText.alpha = 1;
        eventText.text = Language.getPhrase('trans_opening', 'Opening...');
        
        add(topDoor);
        add(bottomDoor);
        add(iconSprite);
        add(waterMark);
        add(eventText);
        
        // Sonido de apertura
        try {
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        } catch(e:Dynamic) {}
        
        // Tweens de apertura
        topDoorTween = addTween(FlxTween.tween(topDoor, {y: -height}, duration, {
            ease: FlxEase.linear,
            startDelay: 0,
            onStart: function(tween:FlxTween) {
                if(isValidTransition() && eventText != null) 
                    eventText.text = Language.getPhrase('trans_completed', 'Completed!');
            }
        }));
        
        bottomDoorTween = addTween(FlxTween.tween(bottomDoor, {y: height}, duration, {
            ease: FlxEase.linear,
            startDelay: 0,
            onComplete: function(tween:FlxTween) {
                if(isValidTransition()) {
                    safeClose();
	}
            }
        }));
        
        textTween = addTween(FlxTween.tween(waterMark, {y: waterMark.y + 100, alpha: 0}, duration * 0.8, {
            ease: FlxEase.linear,
            startDelay: 0
        }));
        
        addTween(FlxTween.tween(eventText, {y: eventText.y + 100, alpha: 0}, duration * 0.8, {
            ease: FlxEase.linear,
            startDelay: 0
        }));
        
        iconTween = addTween(FlxTween.tween(iconSprite, {alpha: 0}, duration * 0.6, {
            ease: FlxEase.sineOut,
            startDelay: 0
        }));
    }
    
    function createTransitionOut(width:Int, height:Int):Void {
        topDoor.y = -height;
        bottomDoor.y = height;
        iconSprite.alpha = 0;
        eventText.text = Language.getPhrase('trans_loading', 'Loading...');
        
        var originalWaterMarkY = height - 140;
        var originalEventTextY = height - 60;
        waterMark.y = originalWaterMarkY + 100;
        waterMark.alpha = 0;
        eventText.y = originalEventTextY + 100;
        eventText.alpha = 0;
        
        add(topDoor);
        add(bottomDoor);
        add(iconSprite);
        add(waterMark);
        add(eventText);
        
        // Sonido de cierre
        try {
            FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
        } catch(e:Dynamic) {}
        
        // Tweens de cierre
        textTween = addTween(FlxTween.tween(waterMark, {y: originalWaterMarkY, alpha: 1}, duration * 0.6, {
            ease: FlxEase.linear,
            startDelay: 0
        }));
        
        addTween(FlxTween.tween(eventText, {y: originalEventTextY, alpha: 1}, duration * 0.6, {
            ease: FlxEase.linear,
            startDelay: 0
        }));
        
        topDoorTween = addTween(FlxTween.tween(topDoor, {y: 0}, duration, {
            ease: FlxEase.linear,
            startDelay: 0
        }));
        
        bottomDoorTween = addTween(FlxTween.tween(bottomDoor, {y: 0}, duration, {
            ease: FlxEase.linear,
            startDelay: 0,
            onComplete: function(tween:FlxTween) {
                if(!isValidTransition()) return;
                
                iconTween = addTween(FlxTween.tween(iconSprite, {alpha: 1}, 0.2, {
                    ease: FlxEase.sineIn,
                    startDelay: 0
                }));
                
                // Esperar cerrado, luego callback
                if (holdTime > 0) {
                    try {
                        holdTween = addTween(FlxTween.tween(holdDummy, {alpha: 0}, holdTime, {
                            onComplete: function(tween:FlxTween) {
                                if(isValidTransition()) {
                                    safeFinishCallback();
                                }
                            }
                        }));
                    } catch(e:Dynamic) {
                        safeFinishCallback();
                    }
                } else {
                    safeFinishCallback();
                }
            }
        }));
    }
    
    // ← NUEVO: Verificar si esta transición sigue siendo válida
    function isValidTransition():Bool {
        return !isDestroyed && !isClosing && currentTransition == this;
    }
    
    // ← NUEVO: Función para forzar desbloqueo
    function forceUnlock():Void {
        trace('Force unlocking transition: $transitionId');
        
        if (currentTransition == this) {
            isTransitioning = false;
            currentTransition = null;
        }
        
        finishCallback = null;
        
        cancelAllTweens();
        
        if (!isDestroyed) {
            forceClose();
        }
    }
    
    // ← NUEVO: Función para forzar cierre inmediato
    function forceClose():Void {
        if ( isDestroyed || isClosing) return;
        
        isClosing = true;
        
        trace('Force closing transition: $transitionId');
        
        // Desbloquear si somos la transición actual
        if (currentTransition == this) {
            isTransitioning = false;
            currentTransition = null;
        }
        
        cancelAllTweens();
        
        try {
			close();
        } catch(e:Dynamic) {
            trace('Error force closing: $e');
		}
	}

    // Función segura para ejecutar callback
    function safeFinishCallback():Void {
        if(!isValidTransition()) return;
        
        
        // ← DESBLOQUEAR ANTES DEL CALLBACK
        if (currentTransition == this) {
            isTransitioning = false;
            currentTransition = null;
        }
        
        if(finishCallback != null) {
            var callback = finishCallback;
            finishCallback = null;
            try {
                callback();
            } catch(e:Dynamic) {
                trace("Error in finish callback: " + e);
            }
        }
    }

    // Función segura para cerrar
    function safeClose():Void {
        if(!isValidTransition()) return;
        
        isClosing = true;
        
        // Desbloquear si somos la transición actual
        if (currentTransition == this) {
            isTransitioning = false;
            currentTransition = null;
        }
        
        cancelAllTweens();
        
        try {
            close();
        } catch(e:Dynamic) {
            trace("Error closing transition: " + e);
        }
    }

    // Cancelar todos los tweens de forma segura
    function cancelAllTweens():Void {
        try {
            for(tween in activeTweens) {
                if(tween != null && !tween.finished) {
                    tween.cancel();
                }
            }
            activeTweens = [];
            
            // También cancelar tweens individuales por si acaso
            if(topDoorTween != null) {
                topDoorTween.cancel();
                topDoorTween = null;
            }
            if(bottomDoorTween != null) {
                bottomDoorTween.cancel();
                bottomDoorTween = null;
            }
            if(textTween != null) {
                textTween.cancel();
                textTween = null;
            }
            if(holdTween != null) {
                holdTween.cancel();
                holdTween = null;
            }
            if(iconTween != null) {
                iconTween.cancel();
                iconTween = null;
            }
        } catch(e:Dynamic) {
            trace("Error canceling tweens: " + e);
        }
    }

	override function close():Void
	{
        if(isDestroyed) return;
        
        isDestroyed = true;
        isClosing = true;
        
        // Desbloquear si somos la transición actual
        if (currentTransition == this) {
            isTransitioning = false;
            currentTransition = null;
        }
        
        try {
            cancelAllTweens();
            finishCallback = null;
		super.close();
        } catch(e:Dynamic) {
            trace("Error in close: " + e);
            // Forzar desbloqueo en caso de error
            isTransitioning = false;
            currentTransition = null;
        }
    }

    override function destroy():Void
    {
        if(isDestroyed) return;
        
        isDestroyed = true;
        isClosing = true;
        
        // Desbloquear si somos la transición actual
        if (currentTransition == this) {
            isTransitioning = false;
            currentTransition = null;
        }
        
        try {
            cancelAllTweens();
			finishCallback = null;
            
            // Limpiar objetos de forma segura
            if(topDoor != null) {
                topDoor.destroy();
                topDoor = null;
            }
            if(bottomDoor != null) {
                bottomDoor.destroy();
                bottomDoor = null;
            }
            if(waterMark != null) {
                waterMark.destroy();
                waterMark = null;
            }
            if(eventText != null) {
                eventText.destroy();
                eventText = null;
            }
            if(iconSprite != null) {
                iconSprite.destroy();
                iconSprite = null;
            }
            if(holdDummy != null) {
                holdDummy.destroy();
                holdDummy = null;
            }
            
            super.destroy();
            
        } catch(e:Dynamic) {
            trace("Error in destroy: " + e);
            // Forzar desbloqueo incluso en error
            isTransitioning = false;
            currentTransition = null;
		}
	}
}
