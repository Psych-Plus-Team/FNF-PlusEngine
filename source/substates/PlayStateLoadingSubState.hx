package substates;

import backend.Paths;
import backend.ui.md3.MaterialWavyProgressIndicator;
import backend.ui.md3.MaterialWavyProgressIndicator.WavyProgressType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxColor;
import options.OptionsMenuTheme;

class PlayStateLoadingSubState extends MusicBeatSubstate
{
	var overlay:FlxSprite;
	var panel:FlxSprite;
	var title:FlxText;
	var status:FlxText;
	var indicator:MaterialWavyProgressIndicator;

	public function new(?initialStatus:String = 'Preparing PlayState...')
	{
		super();
		updateStatus(initialStatus);
	}

	override function create():Void
	{
		super.create();

		overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.alpha = 0.54;
		overlay.scrollFactor.set();
		add(overlay);

		var panelW:Float = 520;
		var panelH:Float = 220;
		panel = new FlxSprite((FlxG.width - panelW) * 0.5, (FlxG.height - panelH) * 0.5);
		panel.makeGraphic(Std.int(panelW), Std.int(panelH), FlxColor.BLACK);
		panel.alpha = 0.46;
		panel.scrollFactor.set();
		add(panel);

		indicator = new MaterialWavyProgressIndicator(FlxG.width * 0.5 - 42, panel.y + 34, WavyProgressType.CIRCULAR, 84);
		indicator.indeterminate = true;
		indicator.scrollFactor.set();
		indicator.setTrackColor((Std.int(0.25 * 255) << 24) | (OptionsMenuTheme.loadingOverlayTrackColor() & 0x00FFFFFF));
		indicator.setWaveColor(OptionsMenuTheme.loadingOverlayWaveColor());
		add(indicator);

		title = new FlxText(panel.x + 28, panel.y + 126, panelW - 56, 'Loading gameplay', 26);
		title.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.borderSize = 1.5;
		title.scrollFactor.set();
		add(title);

		status = new FlxText(panel.x + 28, panel.y + 164, panelW - 56, '', 18);
		status.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		status.borderSize = 1;
		status.alpha = 0.86;
		status.scrollFactor.set();
		add(status);

		updateStatus(statusText);
	}

	var statusText:String = '';

	public function updateStatus(text:String):Void
	{
		statusText = text;
		if (status != null)
			status.text = text;
	}
}
