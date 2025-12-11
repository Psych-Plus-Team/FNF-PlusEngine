package states;

import backend.WeekData;
import backend.Mods;
import objects.AttachedSprite;
import options.ModSettingsSubState;
import substates.RestartConfirmSubState;
import states.MainMenuState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.ui.FlxVirtualPad;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import openfl.display.BitmapData;
import lime.utils.Assets;
import haxe.io.Path;

class ModsMenuState extends MusicBeatState
{
	var bg:FlxSprite;
	var gradientOverlay:FlxSprite;

	var headerBg:FlxSprite;
	var headerText:FlxText;
	var modCountText:FlxText;

	var modListPanel:FlxSprite;
	var modDetailsPanel:FlxSprite;
	var controlPanel:FlxSprite;

	var modsGroup:FlxTypedGroup<ModCard>;
	var curSelectedMod:Int = 0;
	var scrollBar:FlxSprite;
	var scrollBarTrack:FlxSprite;

	var modIcon:FlxSprite;
	var modIconBg:FlxSprite;
	var modName:Alphabet;
	var modAuthor:FlxText;
	var modVersion:FlxText;
	var modDesc:FlxText;
	var modStats:FlxText;
	var restartWarning:FlxText;

	var buttonToggle:MobileButton;
	var buttonMoveUp:MobileButton;
	var buttonMoveDown:MobileButton;
	var buttonMoveTop:MobileButton;
	var buttonSettings:MobileButton;
	var buttonReload:MobileButton;
	var buttonEnableAll:MobileButton;
	var buttonDisableAll:MobileButton;
	var buttonBack:MobileButton;
	
	var controlButtons:Array<MobileButton> = [];

	var hoveringOnMods:Bool = true;
	var curSelectedButton:Int = -1;
	var modsList:ModsList = null;
	var _lastControllerMode:Bool = false;
	var startMod:String = null;

	var pulseSine:Float = 0;

	var touchAreaMods:FlxSprite;
	var touchAreaControls:FlxSprite;
	
	var lastTouchY:Float = 0;
	var touchStartY:Float = 0;
	
	public function new(startMod:String = null)
	{
		this.startMod = startMod;
		super();
	}
	
	override function create()
	{
		persistentUpdate = true;
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Managing Mods", null);
		#end
		
		modsList = Mods.parseList();
		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF1A1A2E;
		bg.alpha = 0.9;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		add(bg);

		gradientOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		gradientOverlay.scrollFactor.set();
		gradientOverlay.alpha = 0.3;
		add(gradientOverlay);

		headerBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, 120, 0xFF0F3460);
		headerBg.alpha = 0.8;
		add(headerBg);
		
		headerText = new FlxText(0, 20, FlxG.width, 'MODS MANAGER', 48);
		headerText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF16213E);
		headerText.borderSize = 3;
		add(headerText);

		var modCount = modsList.all.length;
		var enabledCount = modsList.enabled.length;
		modCountText = new FlxText(20, 80, FlxG.width - 40, 
			Language.getPhrase('mods_count', 'Mods: {0} total, {1} enabled', [modCount, enabledCount]), 20);
		modCountText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.CYAN, LEFT);
		add(modCountText);

		var panelPadding = 20;
		var panelY = 130;
		var panelHeight = FlxG.height - panelY - 100;

		modListPanel = new FlxSprite(panelPadding, panelY);
		modListPanel.makeGraphic(400, panelHeight, 0xFF16213E);
		modListPanel.alpha = 0.85;
		FlxSpriteUtil.drawRoundRect(modListPanel, 0, 0, modListPanel.width, modListPanel.height, 20, 20, 0xFF0F3460);
		add(modListPanel);

		var detailsX = modListPanel.x + modListPanel.width + panelPadding;
		var detailsWidth = FlxG.width - detailsX - panelPadding;
		modDetailsPanel = new FlxSprite(detailsX, panelY);
		modDetailsPanel.makeGraphic(Std.int(detailsWidth), panelHeight, 0xFF16213E);
		modDetailsPanel.alpha = 0.85;
		FlxSpriteUtil.drawRoundRect(modDetailsPanel, 0, 0, modDetailsPanel.width, modDetailsPanel.height, 20, 20, 0xFF0F3460);
		add(modDetailsPanel);

		controlPanel = new FlxSprite(0, FlxG.height - 90);
		controlPanel.makeGraphic(FlxG.width, 90, 0xFF0F3460);
		controlPanel.alpha = 0.9;
		add(controlPanel);

		createModList();

		createModDetails();

		createControlButtons();

		if (controls.mobileC) {
			createTouchAreas();
		}

		var footerText = new FlxText(0, FlxG.height - 30, FlxG.width, 
			Language.getPhrase('mods_footer_hint', 'Use arrow keys to navigate, ENTER to select, ESC to go back'), 16);
		footerText.setFormat(Paths.font("vcr.ttf"), 16, 0xFFD3D3D3, CENTER);
		add(footerText);

		if (modsList.all.length > 0) {
			if (startMod != null) {
				var idx = modsList.all.indexOf(startMod);
				if (idx >= 0) curSelectedMod = idx;
			}
			changeSelectedMod();
		}

		if (controls.mobileC) {
			addMobileControls();
		}
		
		super.create();
	}
	
	function createModList()
	{
		modsGroup = new FlxTypedGroup<ModCard>();

		var listTitle = new FlxText(modListPanel.x + 20, modListPanel.y + 15, 
			Language.getPhrase('mods_list_title', 'INSTALLED MODS'), 24);
		listTitle.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		add(listTitle);

		scrollBarTrack = new FlxSprite(modListPanel.x + modListPanel.width - 10, modListPanel.y + 50);
		scrollBarTrack.makeGraphic(8, Std.int(modListPanel.height - 70), 0x88446688);
		add(scrollBarTrack);
		
		scrollBar = new FlxSprite(scrollBarTrack.x, scrollBarTrack.y);
		scrollBar.makeGraphic(8, 100, 0xFF4CC9F0);
		add(scrollBar);

		for (i => modName in modsList.all)
		{
			var modCard = new ModCard(modName, i);
			modCard.x = modListPanel.x + 10;
			modCard.y = modListPanel.y + 50 + (i * 110);
			modsGroup.add(modCard);
			
			if (modsList.disabled.contains(modName)) {
				modCard.setDisabled();
			}
		}
		
		add(modsGroup);

		if (modsList.all.length == 0) {
			var noModsText = new FlxText(modListPanel.x, modListPanel.y + 100, modListPanel.width,
				Language.getPhrase('no_mods_installed', 'No mods installed\n\nAdd mods to the "mods" folder\nand restart the game'), 32);
			noModsText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.GRAY, CENTER);
			add(noModsText);
		}
	}
	
	function createModDetails()
	{
		var panel = modDetailsPanel;
		var padding = 20;

		modIconBg = new FlxSprite(panel.x + padding, panel.y + padding);
		modIconBg.makeGraphic(140, 140, 0xFF1E3A5F);
		FlxSpriteUtil.drawRoundRect(modIconBg, 0, 0, 140, 140, 15, 15, 0xFF0F3460);
		add(modIconBg);
		
		modIcon = new FlxSprite(modIconBg.x + 10, modIconBg.y + 10);
		modIcon.makeGraphic(120, 120, 0xFFFFFFFF);
		add(modIcon);

		modName = new Alphabet(panel.x + padding + 160, panel.y + padding + 10, "", true);
		modName.scaleX = modName.scaleY = 0.8;
		add(modName);

		modAuthor = new FlxText(panel.x + padding + 160, panel.y + padding + 70, panel.width - 180, "", 18);
		modAuthor.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.CYAN);
		add(modAuthor);
		
		modVersion = new FlxText(panel.x + padding + 160, panel.y + padding + 95, panel.width - 180, "", 16);
		modVersion.setFormat(Paths.font("vcr.ttf"), 16, 0xFFD3D3D3);
		add(modVersion);

		var descBg = new FlxSprite(panel.x + padding, panel.y + 180);
		descBg.makeGraphic(Std.int(panel.width - padding * 2), 180, 0xFF1E3A5F);
		FlxSpriteUtil.drawRoundRect(descBg, 0, 0, descBg.width, descBg.height, 10, 10);
		add(descBg);
		
		var descTitle = new FlxText(descBg.x + 10, descBg.y + 10, Language.getPhrase('description', 'DESCRIPTION'), 20);
		descTitle.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		add(descTitle);
		
		modDesc = new FlxText(descBg.x + 15, descBg.y + 40, descBg.width - 30, "", 18);
		modDesc.setFormat(Paths.font("vcr.ttf"), 18, 0xFFD3D3D3, LEFT);
		modDesc.wordWrap = true;
		add(modDesc);

		var statsBg = new FlxSprite(panel.x + padding, panel.y + 370);
		statsBg.makeGraphic(Std.int(panel.width - padding * 2), 80, 0xFF1E3A5F);
		FlxSpriteUtil.drawRoundRect(statsBg, 0, 0, statsBg.width, statsBg.height, 10, 10);
		add(statsBg);
		
		modStats = new FlxText(statsBg.x + 15, statsBg.y + 15, statsBg.width - 30, "", 16);
		modStats.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		add(modStats);

		restartWarning = new FlxText(panel.x + padding, panel.y + panel.height - 40, panel.width - padding * 2,
			Language.getPhrase('mod_restart_warning', '* Changes to this mod require restart'), 20);
		restartWarning.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFA500, CENTER);
		restartWarning.visible = false;
		add(restartWarning);
	}
	
	function createControlButtons()
	{
		var panel = controlPanel;
		var buttonWidth = 80;
		var buttonHeight = 70;
		var spacing = 10;
		var startX = (FlxG.width - (buttonWidth * 7 + spacing * 6)) / 2;

		buttonToggle = new MobileButton(startX, panel.y + 10, buttonWidth, buttonHeight, 
            "", 'ui/modIcons/toggle', toggleCurrentMod);
		controlButtons.push(buttonToggle);
		add(buttonToggle);

		buttonMoveUp = new MobileButton(startX + buttonWidth + spacing, panel.y + 10, buttonWidth, buttonHeight,
            "", 'ui/modIcons/up', () -> moveMod(-1));
		controlButtons.push(buttonMoveUp);
		add(buttonMoveUp);

		buttonMoveDown = new MobileButton(startX + (buttonWidth + spacing) * 2, panel.y + 10, buttonWidth, buttonHeight,
            "", 'ui/modIcons/down', () -> moveMod(1));
		controlButtons.push(buttonMoveDown);
		add(buttonMoveDown);

		buttonMoveTop = new MobileButton(startX + (buttonWidth + spacing) * 3, panel.y + 10, buttonWidth, buttonHeight,
            "", 'ui/modIcons/top', () -> moveModToPosition(0));
		controlButtons.push(buttonMoveTop);
		add(buttonMoveTop);

		buttonSettings = new MobileButton(startX + (buttonWidth + spacing) * 4, panel.y + 10, buttonWidth, buttonHeight,
            "", 'ui/modIcons/settings', openSettings);
		controlButtons.push(buttonSettings);
		add(buttonSettings);

		buttonEnableAll = new MobileButton(startX + (buttonWidth + spacing) * 5, panel.y + 10, buttonWidth, buttonHeight,
			Language.getPhrase('enable_all_short', 'ALL ON'), null, enableAllMods);
		buttonEnableAll.setColor(0xFF00AA00);
		controlButtons.push(buttonEnableAll);
		add(buttonEnableAll);

		buttonDisableAll = new MobileButton(startX + (buttonWidth + spacing) * 6, panel.y + 10, buttonWidth, buttonHeight,
			Language.getPhrase('disable_all_short', 'ALL OFF'), null, disableAllMods);
		buttonDisableAll.setColor(0xFFFF4444);
		controlButtons.push(buttonDisableAll);
		add(buttonDisableAll);

		buttonBack = new MobileButton(FlxG.width - 120, panel.y + 10, 100, buttonHeight,
			Language.getPhrase('back', 'BACK'), null, exitState);
		buttonBack.setColor(0xFF6666FF);
		add(buttonBack);

		updateButtonStates();
	}
	
	function createTouchAreas()
	{
		touchAreaMods = new FlxSprite(modListPanel.x, modListPanel.y);
		touchAreaMods.makeGraphic(Std.int(modListPanel.width), Std.int(modListPanel.height), FlxColor.TRANSPARENT);
		touchAreaMods.scrollFactor.set();
		add(touchAreaMods);

		touchAreaControls = new FlxSprite(controlPanel.x, controlPanel.y);
		touchAreaControls.makeGraphic(Std.int(controlPanel.width), Std.int(controlPanel.height), FlxColor.TRANSPARENT);
		touchAreaControls.scrollFactor.set();
		add(touchAreaControls);
	}
	
	override function addMobileControls(defaultDrawTarget:Bool = false)
    {
		var virtualPad = new FlxVirtualPad(FULL, A_B);
		virtualPad.alpha = 0.6;
		if (defaultDrawTarget) {
			add(virtualPad);
		} else {
			insert(members.indexOf(controlPanel), virtualPad);
		}

		virtualPad.y = FlxG.height - virtualPad.height - 10;

		var swipeArea = new FlxSprite(0, 130);
		swipeArea.makeGraphic(FlxG.width, FlxG.height - 230, FlxColor.TRANSPARENT);
		swipeArea.scrollFactor.set();
		add(swipeArea);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		pulseSine += elapsed * 5;
		if (modsGroup.members[curSelectedMod] != null) {
			modsGroup.members[curSelectedMod].updateSelection(pulseSine);
		}

		if (Math.abs(FlxG.mouse.deltaX) > 5 || Math.abs(FlxG.mouse.deltaY) > 5) {
			controls.controllerMode = false;
			if (!FlxG.mouse.visible) FlxG.mouse.visible = true;
		}
		
		if (controls.controllerMode != _lastControllerMode) {
			_lastControllerMode = controls.controllerMode;
		}

		if (modsList.all.length > 0) {
			if (hoveringOnMods) {
				handleModNavigation(elapsed);
			} else {
				handleButtonNavigation();
			}

			if (controls.UI_RIGHT_P) {
				if (hoveringOnMods) {
					hoveringOnMods = false;
					curSelectedButton = 0;
					updateButtonSelection();
				}
			} else if (controls.UI_LEFT_P) {
				if (!hoveringOnMods) {
					hoveringOnMods = true;
					updateModSelectionVisual();
				}
			}

			if (controls.ACCEPT) {
				if (hoveringOnMods) {
					toggleCurrentMod();
				} else if (curSelectedButton >= 0 && curSelectedButton < controlButtons.length) {
					var btn = controlButtons[curSelectedButton];
					if (btn.onClick != null) btn.onClick();
				}
			}
		}

		if (controls.BACK) {
			exitState();
		}

		if (controls.mobileC) {
			handleMobileTouch();
		}

		updateScrollbar();
	}
	
	function handleModNavigation(elapsed:Float)
	{
		var shiftMult:Int = (FlxG.keys.pressed.SHIFT) ? 5 : 1;
		
		if (controls.UI_UP_P) {
			changeSelectedMod(-shiftMult);
		} else if (controls.UI_DOWN_P) {
			changeSelectedMod(shiftMult);
		} else if (FlxG.mouse.wheel != 0) {
			changeSelectedMod(-FlxG.mouse.wheel * shiftMult);
		}

		if (FlxG.keys.justPressed.HOME) {
			curSelectedMod = 0;
			changeSelectedMod();
		} else if (FlxG.keys.justPressed.END) {
			curSelectedMod = modsList.all.length - 1;
			changeSelectedMod();
		}
	}
	
	function handleButtonNavigation()
	{
		if (controls.UI_LEFT_P) {
			curSelectedButton = Std.int(Math.max(0, curSelectedButton - 1));
			updateButtonSelection();
		} else if (controls.UI_RIGHT_P) {
			curSelectedButton = Std.int(Math.min(controlButtons.length - 1, curSelectedButton + 1));
			updateButtonSelection();
		} else if (controls.UI_UP_P) {
			hoveringOnMods = true;
			updateModSelectionVisual();
		}
	}
	
	function handleMobileTouch()
	{
		if (FlxG.touches.justStarted().length > 0) {
			var touch = FlxG.touches.justStarted()[0];

			for (i => modCard in modsGroup.members) {
				if (modCard.exists && touch.overlaps(modCard)) {
					curSelectedMod = i;
					changeSelectedMod();
					break;
				}
			}

			for (i => button in controlButtons) {
				if (button.exists && touch.overlaps(button)) {
					if (button.onClick != null) button.onClick();
					break;
				}
			}

			if (buttonBack != null && touch.overlaps(buttonBack)) {
				exitState();
			}
		}

		if (FlxG.touches.list.length > 0) {
			var touch = FlxG.touches.list[0];
			if (touchAreaMods != null && touch.overlaps(touchAreaMods)) {
				if (touch.justPressed) {
					lastTouchY = touch.screenY;
					touchStartY = touch.screenY;
				} else if (touch.pressed) {
					var deltaY = touch.screenY - lastTouchY;
					if (Math.abs(deltaY) > 10) {
						var scrollAmount = Std.int(deltaY / 10);
						changeSelectedMod(scrollAmount);
						lastTouchY = touch.screenY;
					}
				}
			}
		}
	}
	
	function changeSelectedMod(change:Int = 0)
	{
		if (modsList.all.length == 0) return;
		
		var lastSelected = curSelectedMod;
		curSelectedMod += change;
		
		if (curSelectedMod < 0) curSelectedMod = 0;
		if (curSelectedMod >= modsList.all.length) curSelectedMod = modsList.all.length - 1;
		
		if (curSelectedMod != lastSelected) {
			updateModDetails();
			updateModSelectionVisual();
			updateButtonStates();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}
	}
	
	function updateModDetails()
	{
		var modCard = modsGroup.members[curSelectedMod];
		if (modCard == null) return;

		modIcon.loadGraphic(modCard.icon.graphic);
		modIcon.antialiasing = modCard.icon.antialiasing;

		modName.text = modCard.name;

		modName.x = modIconBg.x + modIconBg.width + 20;
		modName.y = modIconBg.y + 10;

		modAuthor.text = Language.getPhrase('author', 'Author: ') + (modCard.author != null ? modCard.author : "Unknown");
		modVersion.text = Language.getPhrase('version', 'Version: ') + (modCard.version != null ? modCard.version : "1.0.0");
		modDesc.text = modCard.desc;

		var statusText = modCard.isEnabled ? 
			Language.getPhrase('status_enabled', 'ENABLED') : 
			Language.getPhrase('status_disabled', 'DISABLED');
		var priorityText = Language.getPhrase('priority', 'Priority: {0}', [curSelectedMod + 1]);
		modStats.text = '$statusText\n$priorityText';

		restartWarning.visible = modCard.mustRestart;

		buttonToggle.setColor(modCard.isEnabled ? 0xFFFF4444 : 0xFF00AA00);
	}
	
	function updateModSelectionVisual()
	{
		for (i => modCard in modsGroup.members) {
			modCard.setSelected(i == curSelectedMod && hoveringOnMods);
		}
	}
	
	function updateButtonSelection()
	{
		for (i => button in controlButtons) {
			button.setSelected(i == curSelectedButton);
		}
	}
	
	function updateButtonStates()
	{
		var hasMods = modsList.all.length > 0;
		var curMod = hasMods ? modsGroup.members[curSelectedMod] : null;

		buttonToggle.enabled = hasMods;
		buttonMoveUp.enabled = hasMods && curSelectedMod > 0;
		buttonMoveDown.enabled = hasMods && curSelectedMod < modsList.all.length - 1;
		buttonMoveTop.enabled = hasMods && curSelectedMod > 0;
		buttonSettings.enabled = hasMods && curMod != null && curMod.settings != null && curMod.settings.length > 0;
		buttonEnableAll.enabled = modsList.disabled.length > 0;
		buttonDisableAll.enabled = modsList.enabled.length > 0;

		if (hasMods && curMod != null) {
			if (buttonToggle.text != null) {
				buttonToggle.text.text = curMod.isEnabled ? 
					Language.getPhrase('disable', 'OFF') : 
					Language.getPhrase('enable', 'ON');
			}
		}
	}
	
	function updateScrollbar()
	{
		if (modsList.all.length <= 5) {
			scrollBar.visible = false;
			scrollBarTrack.visible = false;
			return;
		}
		
		var visibleHeight = modListPanel.height - 70;
		var totalHeight = modsList.all.length * 110;
		var scrollPercent = curSelectedMod / (modsList.all.length - 1);
		
		scrollBar.height = Math.max(50, visibleHeight * (visibleHeight / totalHeight));
		scrollBar.y = scrollBarTrack.y + (scrollBarTrack.height - scrollBar.height) * scrollPercent;
	}
	
	function toggleCurrentMod()
	{
		if (modsList.all.length == 0) return;
		
		var modCard = modsGroup.members[curSelectedMod];
		var modName = modsList.all[curSelectedMod];
		
		if (modsList.disabled.contains(modName)) {
			modsList.disabled.remove(modName);
			modsList.enabled.push(modName);
			modCard.setEnabled();
		} else {
			modsList.enabled.remove(modName);
			modsList.disabled.push(modName);
			modCard.setDisabled();
		}
		
		if (modCard.mustRestart) {
			showRestartNotification();
		}
		
		updateModDetails();
		updateButtonStates();
		updateModCount();
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}
	
	function moveMod(change:Int)
	{
		if (modsList.all.length < 2) return;
		
		var newPos = curSelectedMod + change;
		if (newPos < 0) newPos = modsList.all.length - 1;
		if (newPos >= modsList.all.length) newPos = 0;
		
		moveModToPosition(newPos);
	}
	
	function moveModToPosition(position:Int)
	{
		if (position < 0 || position >= modsList.all.length || position == curSelectedMod) return;
		
		var modName = modsList.all[curSelectedMod];
		var modCard = modsGroup.members[curSelectedMod];

		modsList.all.remove(modName);
		modsList.all.insert(position, modName);

		modsGroup.remove(modCard, true);
		modsGroup.insert(position, modCard);

		for (i => card in modsGroup.members) {
			card.y = modListPanel.y + 50 + (i * 110);
		}
		
		curSelectedMod = position;
		updateModDetails();
		updateButtonStates();
		
		if (modCard.mustRestart) {
			showRestartNotification();
		}
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}
	
	function enableAllMods()
	{
		for (modName in modsList.disabled) {
			modsList.disabled.remove(modName);
			modsList.enabled.push(modName);
		}
		
		for (card in modsGroup.members) {
			card.setEnabled();
		}
		
		updateModDetails();
		updateButtonStates();
		updateModCount();
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}
	
	function disableAllMods()
	{
		for (modName in modsList.enabled) {
			modsList.enabled.remove(modName);
			modsList.disabled.push(modName);
		}
		
		for (card in modsGroup.members) {
			card.setDisabled();
		}
		
		updateModDetails();
		updateButtonStates();
		updateModCount();
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
	}
	
	function openSettings()
	{
		var modCard = modsGroup.members[curSelectedMod];
		if (modCard == null || modCard.settings == null || modCard.settings.length == 0) return;
		
		openSubState(new ModSettingsSubState(modCard.settings, modCard.folder, modCard.name));
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}
	
	function exitState()
	{
		saveModsList();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		
		if (needsRestart) {
			showRestartConfirmation();
		} else {
			MusicBeatState.switchState(new MainMenuState());
		}
	}
	
	function saveModsList() {
		try {
			var fileStr = '';
			for (mod in modsList.all) {
				if (mod.trim().length < 1) continue;
				
				var status = modsList.disabled.contains(mod) ? '0' : '1';
				fileStr += '$mod|$status\n';
			}
			
			var path = Paths.mods('modsList.txt');
			File.saveContent(path, fileStr);
			Mods.parseList();
			Mods.loadTopMod();
		} catch (e:Dynamic) {
			trace('Failed to save mods list: $e');
		}
	}
	
	function updateModCount()
	{
		var total = modsList.all.length;
		var enabled = modsList.enabled.length;
		modCountText.text = Language.getPhrase('mods_count', 'Mods: {0} total, {1} enabled', [total, enabled]);
	}
	
	function showRestartNotification()
	{
		needsRestart = true;
	}
	
	function showRestartConfirmation() {
			#if desktop
			openSubState(new RestartConfirmSubState());
			#else
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
			#end
		}
		
	var needsRestart:Bool = false;
}

function getText(key:String, fallback:String):String {
	#if LANG_ALLOWED
	return Language.getPhrase(key, fallback);
	#else
	return fallback;
	#end
}

class ModCard extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var icon:FlxSprite;
	public var nameText:FlxText;
	public var statusText:FlxText;
	public var highlight:FlxSprite;
	
	public var folder:String;
	public var name:String;
	public var author:String;
	public var version:String;
	public var desc:String;
	public var mustRestart:Bool;
	public var settings:Array<Dynamic>;
	public var isEnabled:Bool = true;
	
	public function new(modFolder:String, index:Int)
	{
		super();
		
		this.folder = modFolder;

		var pack = Mods.getPack(modFolder);
		
		this.name = modFolder;
		this.desc = "No description provided.";
		this.author = "Unknown";
		this.version = "1.0.0";
		this.mustRestart = false;
		
		if (pack != null) {
			if (pack.name != null) this.name = pack.name;
			if (pack.description != null) this.desc = pack.description;
			if (pack.author != null) this.author = pack.author;
			if (pack.version != null) this.version = pack.version;
			if (pack.restart == true) this.mustRestart = true;

			var settingsPath = Paths.mods('$modFolder/data/settings.json');
			if (FileSystem.exists(settingsPath)) {
				try {
					settings = tjson.TJSON.parse(File.getContent(settingsPath));
				} catch (e:Dynamic) {
					trace('Failed to load settings for $modFolder: $e');
				}
			}
		}

		bg = new FlxSprite(0, 0);
		bg.makeGraphic(380, 100, 0xFF1E3A5F);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, 380, 100, 15, 15, 0xFF0F3460);
		add(bg);

		highlight = new FlxSprite(0, 0);
		highlight.makeGraphic(384, 104, 0xFFFFFFFF);
		highlight.alpha = 0;
		highlight.x = -2;
		highlight.y = -2;
		add(highlight);

		icon = new FlxSprite(10, 10);
		var iconPath = Paths.mods('$modFolder/pack.png');
		if (FileSystem.exists(iconPath)) {
			icon.loadGraphic(iconPath);
		} else {
			icon.loadGraphic(Paths.image('unknownMod'));
		}
		icon.scale.set(0.5, 0.5);
		icon.updateHitbox();
		add(icon);

		nameText = new FlxText(90, 15, 270, this.name, 22);
		nameText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT);
		add(nameText);

		statusText = new FlxText(90, 45, 270, "ENABLED", 16);
		statusText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GREEN, LEFT);
		add(statusText);

		var versionText = new FlxText(90, 65, 270, "v" + this.version, 14);
		versionText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFD3D3D3, LEFT);
		add(versionText);
	}
	
	public function setSelected(selected:Bool)
	{
		highlight.alpha = selected ? 0.3 : 0;
	}
		
	public function setEnabled()
	{
		isEnabled = true;
		statusText.text = Language.getPhrase('enabled', "ENABLED");
		statusText.color = FlxColor.GREEN;
		bg.color = 0xFF1E3A5F;
	}
		
	public function setDisabled()
	{
		isEnabled = false;
		statusText.text = Language.getPhrase('disabled', "DISABLED");
		statusText.color = FlxColor.RED;
		bg.color = 0xFF3A1E3A;
	}
		
	public function updateSelection(pulseSine:Float)
	{
		if (highlight.alpha > 0) {
			highlight.alpha = 0.3 + 0.1 * Math.sin(pulseSine);
		}
	}
}

class MobileButton extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var onClick:Void->Void;
	public var enabled(default, set):Bool = true;
	
	public function new(x:Float, y:Float, width:Int, height:Int, label:String, ?iconPath:String, ?onClick:Void->Void)
	{
		super(x, y);
		
		this.onClick = onClick;

		bg = new FlxSprite(0, 0);
		bg.makeGraphic(width, height, 0xFF4CC9F0);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, width, height, 10, 10, 0xFF3A8FB9);
		add(bg);
		
		if (iconPath != null) {
			icon = new FlxSprite();
			icon.loadGraphic(iconPath);
			icon.scale.set(0.8, 0.8);
			icon.updateHitbox();
			icon.x = width / 2 - icon.width / 2;
			icon.y = height / 2 - icon.height / 2;
			add(icon);
		} else if (label != null) {
			text = new FlxText(0, 0, width, label, 18);
			text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
			text.y = height / 2 - text.height / 2;
			add(text);
		}

		if (Controls.instance.mobileC) {
			screenCenter(X);
		}
	}
	
	public function setColor(color:Int)
	{
		bg.color = color;
	}
	
	public function setSelected(selected:Bool)
	{
		if (selected) {
			bg.alpha = 1;
			if (text != null) text.alpha = 1;
			if (icon != null) icon.alpha = 1;
		} else {
			bg.alpha = enabled ? 0.8 : 0.4;
			if (text != null) text.alpha = enabled ? 0.9 : 0.4;
			if (icon != null) icon.alpha = enabled ? 0.9 : 0.4;
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
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}

		if (Controls.instance.mobileC && enabled) {
			for (touch in FlxG.touches.list) {
				if (touch.justPressed && touch.overlaps(this)) {
					if (onClick != null) onClick();
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					break;
				}
			}
		}
	}
}