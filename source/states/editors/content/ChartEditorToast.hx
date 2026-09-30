package states.editors.content;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class ChartEditorToast extends FlxSpriteGroup
{
	static inline var MIN_WIDTH:Int = 280;
	static inline var SIDE_MARGIN:Int = 80;
	static inline var BOTTOM_MARGIN:Int = 44;
	static inline var HIDE_DELAY:Float = 3;

	var background:FlxSprite;
	var label:FlxText;

	public function new(camera:FlxCamera)
	{
		super();
		scrollFactor.set();
		cameras = [camera];
		visible = false;
		active = false;

		background = new FlxSprite();
		background.scrollFactor.set();
		background.cameras = [camera];
		background.alpha = 0;
		add(background);

		label = new FlxText(0, 0, FlxG.width - 160, '', 18);
		label.alignment = CENTER;
		label.scrollFactor.set();
		label.cameras = [camera];
		label.alpha = 0;
		add(label);
	}

	public function show(message:String, isError:Bool = false):Void
	{
		FlxTween.cancelTweensOf(background);
		FlxTween.cancelTweensOf(label);

		var toastWidth:Int = Std.int(FlxMath.bound(Math.max(MIN_WIDTH, message.length * 9), MIN_WIDTH, FlxG.width - SIDE_MARGIN));
		label.text = message;
		label.fieldWidth = toastWidth - 36;
		label.color = FlxColor.WHITE;
		label.updateHitbox();

		var toastHeight:Int = Std.int(Math.max(48, label.height + 24));
		var toastX:Float = (FlxG.width - toastWidth) * 0.5;
		var toastY:Float = FlxG.height - toastHeight - BOTTOM_MARGIN;

		background.makeGraphic(toastWidth, toastHeight, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRoundRect(background, 0, 0, toastWidth, toastHeight, 18, 18, isError ? 0xFFE84D4F : 0xEE202124);
		background.setPosition(toastX, toastY + 12);
		label.setPosition(toastX + 18, toastY + ((toastHeight - label.height) * 0.5) + 12);
		background.alpha = label.alpha = 0;
		visible = active = true;

		FlxTween.tween(background, {alpha: isError ? 0.96 : 0.92, y: toastY}, 0.16, {ease: FlxEase.quadOut});
		FlxTween.tween(label, {alpha: 1, y: toastY + ((toastHeight - label.height) * 0.5)}, 0.16, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				FlxTween.tween(label, {alpha: 0, y: label.y + 8}, 0.22, {startDelay: HIDE_DELAY, ease: FlxEase.quadIn});
				FlxTween.tween(background, {alpha: 0, y: background.y + 8}, 0.22, {
					startDelay: HIDE_DELAY,
					ease: FlxEase.quadIn,
					onComplete: function(_)
					{
						visible = active = false;
					}
				});
			}
		});
	}

	override function destroy():Void
	{
		FlxTween.cancelTweensOf(background);
		FlxTween.cancelTweensOf(label);
		super.destroy();
	}
}
