package states.editors.content;

import backend.Conductor;
import backend.Song.SwagSection;
import backend.Song.SwagSong;

class ChartEditorTiming
{
	public static inline var DEFAULT_BPM:Float = 150;

	public static function createBlankSection(bpm:Float, mustHit:Bool):SwagSection
	{
		return {
			sectionNotes: [],
			sectionBeats: 4,
			mustHitSection: mustHit,
			bpm: bpm,
			changeBPM: false,
			altAnim: false,
			gfSection: false
		};
	}

	public static function ensureSongBasics(song:SwagSong):SwagSong
	{
		if (song == null)
			return null;

		if (Math.isNaN(song.bpm) || song.bpm <= 0)
			song.bpm = DEFAULT_BPM;
		if (song.notes == null || song.notes.length < 1)
			song.notes = [createBlankSection(song.bpm, true)];
		if (song.events == null)
			song.events = [];

		for (section in song.notes)
		{
			if (section == null)
				continue;
			if (section.sectionNotes == null)
				section.sectionNotes = [];
			if (Math.isNaN(section.sectionBeats) || section.sectionBeats <= 0)
				section.sectionBeats = 4;
			if (section.changeBPM && (Math.isNaN(section.bpm) || section.bpm <= 0))
				section.bpm = song.bpm;
		}
		return song;
	}

	public static function syncConductor(song:SwagSong, ?mapChanges:Bool = true):Void
	{
		if (song == null)
			return;

		ensureSongBasics(song);
		Conductor.bpm = song.bpm;
		Conductor.bpmChangeMap = [];
		if (mapChanges)
			Conductor.mapBPMChanges(song);
	}
}
