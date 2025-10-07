package options;

/**
 * Submenu for modcharting-related options.
 * Allows users to configure settings that affect modchart performance and quality.
 */
class ModchartOptionsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Modchart Settings';
		rpcTitle = 'Modchart Options Menu'; // for Discord Rich Presence

		// Enable Modchart option
		var option:Option = new Option('Enable Modchart Manager',
			'Enables the Funkin Modchart system.\nSome functions that have to do with notes, whether playerStrums or opponentStrums, and their variables may not be valid while this is active, only the "noteTween*" will work.',
			'enableModcharting',
			BOOL);
		addOption(option);

		// Hold Subdivisions option
		var option:Option = new Option('Hold Subdivisions',
			'Subdivides hold/sustain tails for smoother visuals.\nHigher values improve quality but can hurt performance.\n(Recommended: 4-8)',
			'holdSubdivisions',
			INT);
		option.scrollSpeed = 1;
		option.minValue = 1;
		option.maxValue = 32;
		option.changeValue = 1;
		option.decimals = 0;
		option.showCondition = function() return ClientPrefs.data.enableModcharting;
		addOption(option);

		super();
	}
}