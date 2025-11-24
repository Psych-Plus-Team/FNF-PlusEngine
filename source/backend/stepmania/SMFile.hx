package backend.stepmania;

import backend.Song;
import backend.stepmania.SMHeader;

class SMFile {
	public var header:SMHeader;
	public var difficulties:Array<SMDifficulty> = [];
	public var isValid:Bool = true;
	
	private var fileData:Array<String>;
	
	public function new(data:String) {
		fileData = data.split('\n');
		parseFile();
	}
	
	public static function loadFile(path:String):SMFile {
		#if sys
		if (!sys.FileSystem.exists(path)) {
			trace('SM file not found: ' + path);
			return null;
		}
		
		var content = sys.io.File.getContent(path);
		return new SMFile(content);
		#else
		trace('SM files not supported on this platform');
		return null;
		#end
	}
	
	function parseFile():Void {
		try {
			var headerData = '';
			var inc = 0;
			
			while (inc < fileData.length && !fileData[inc].contains('#NOTES')) {
				headerData += fileData[inc] + '\n';
				inc++;
			}
			
			header = new SMHeader(headerData);
			
			if (!header.MUSIC.toLowerCase().endsWith('.ogg')) {
				trace('ERROR: Music file must be .ogg format!');
				isValid = false;
				return;
			}
			
			while (inc < fileData.length) {
				while (inc < fileData.length && !fileData[inc].contains('#NOTES')) {
					inc++;
				}
				
				if (inc >= fileData.length) break;
				
				inc++;
				
				if (inc >= fileData.length) break;
				var chartType = fileData[inc].trim().toLowerCase();
				var isDouble = chartType.contains('dance-double');
				
				if (!chartType.contains('dance-single') && !chartType.contains('dance-double')) {
					trace('Skipping unsupported chart type: $chartType');
					while (inc < fileData.length && !fileData[inc].contains(';')) {
						inc++;
					}
					inc++;
					continue;
				}
				
				inc++; 
				if (inc >= fileData.length) break;
				
				inc++; 
				if (inc >= fileData.length) break;
				
				var difficultyRaw = fileData[inc].trim().replace(':', '');
				var difficultyName = 'Normal';
				if (difficultyRaw.length > 0) {
					difficultyName = difficultyRaw.charAt(0).toUpperCase() + difficultyRaw.substr(1).toLowerCase();
				}
				
				inc += 3;
				
				var measures:Array<SMMeasure> = [];
				var currentMeasure = '';
				
				while (inc < fileData.length) {
					var line = fileData[inc].trim();
					
					if (line == ',' || line == ';') {
						if (currentMeasure.length > 0) {
							measures.push(new SMMeasure(currentMeasure.split('\n')));
							currentMeasure = '';
						}
						if (line == ';') {
							inc++;
							break; 
						}
					} else if (line.length > 0 && !line.startsWith('//')) {
						currentMeasure += line + '\n';
					}
					
					inc++;
				}
				
				difficulties.push({
					name: difficultyName,
					isDouble: isDouble,
					measures: measures
				});
				
			}
			
			if (difficulties.length == 0) {
				trace('ERROR: No valid difficulties found in SM file');
				isValid = false;
				return;
			}
			
			
		} catch (e:Dynamic) {
			trace('Error parsing SM file: ' + e);
			isValid = false;
		}
	}
	
	/**
	 * Convert the SMFile to a FNF SwagSong format
	 * @param songName 
	 * @param difficultyIndex 
	 */
	public function convertToFNF(songName:String, difficultyIndex:Int = 0):SwagSong {
		if (!isValid) {
			trace('Cannot convert invalid SM file');
			return null;
		}
		
		if (songName == null || songName.trim() == "") {
			trace('Invalid song name for conversion');
			return null;
		}
		
		if (header == null) {
			trace('No header data available for conversion');
			return null;
		}
		
		if (difficultyIndex < 0 || difficultyIndex >= difficulties.length) {
			trace('Invalid difficulty index: $difficultyIndex (total: ${difficulties.length})');
			return null;
		}
		
		var diff = difficulties[difficultyIndex];
		var isDouble = diff.isDouble;
		var measures = diff.measures;
		
		var bpm = header.getBPM(0);
		if (bpm <= 0 || Math.isNaN(bpm)) {
			trace('Invalid BPM detected, using default of 120');
			bpm = 120;
		}
		
		TimingStruct.clearTimings();
		
		var bpmChanges:Array<backend.stepmania.SMHeader.BPMChange> = header.bpmChanges;
		if (bpmChanges.length == 0) {
			TimingStruct.addTiming(0, bpm, 999999, 0);
		} else {
			bpmChanges.sort((a, b) -> a.beat < b.beat ? -1 : (a.beat > b.beat ? 1 : 0));
			
			for (i in 0...bpmChanges.length) {
				var change = bpmChanges[i];
				var startBeat = change.beat;
				var endBeat = (i < bpmChanges.length - 1) ? bpmChanges[i + 1].beat : 999999;
				
				var timeOffset:Float = change.time;
				
				TimingStruct.addTiming(startBeat, change.bpm, endBeat, timeOffset);
			}
		}
		
		trace('Initialized TimingStruct with ${TimingStruct.allTimings.length} timing segments');
		
		var offsetValue:Float = Std.parseFloat(header.OFFSET);
		if (Math.isNaN(offsetValue)) offsetValue = 0;
		
		var fnfOffset:Float = -offsetValue * 1000; 

		var song:SwagSong = {
			song: songName,
			notes: [],
			events: [],
			bpm: bpm,
			needsVoices: false,
			player1: 'bf',
			player2: 'dad',
			gfVersion: 'gf',
			speed: 2.0,
			stage: 'notitg',
			format: 'psych_v1',
			offset: fnfOffset
		};		var heldNotes:Array<Array<Dynamic>> = isDouble ? [[], [], [], [], [], [], [], []] : [[], [], [], []];
		var currentBeat:Float = 0;
		var measureIndex:Int = 0;
		
		var section:SwagSection = createNewSection(isDouble);
		
		if (measures == null || measures.length == 0) {
			trace('No measures found in SM file');
			return song;
		}
		
		for (measure in measures) {
			if (measure == null || measure.noteRows == null) {
				trace('Invalid measure found, skipping');
				continue;
			}
			
			var lengthInRows = Math.floor(192 / (measure.noteRows.length));
			if (lengthInRows <= 0) lengthInRows = 1; 
			
			var rowIndex = 0;
			
			for (row in measure.noteRows) {
				if (row == null || row.length == 0) {
					rowIndex++;
					continue;
				}
				
				var noteRow = (measureIndex * 192) + (lengthInRows * rowIndex);
				currentBeat = noteRow / 48;
				
				if (currentBeat % 4 == 0 && rowIndex == 0 && measureIndex > 0) {
					song.notes.push(section);
					section = createNewSection();
				}
				
				var seg = TimingStruct.getTimingAtBeat(currentBeat);
				if (seg == null) {
					trace('No timing data found for beat $currentBeat');
					rowIndex++;
					continue;
				}
				
				var beatsSinceStart = currentBeat - seg.startBeat;
				var secondsPerBeat = 60.0 / seg.bpm;
				var timeInSec = seg.startTime + (beatsSinceStart * secondsPerBeat);
				
				timeInSec -= (-offsetValue);
				
				var rowTime = timeInSec * 1000;
				
				if (Math.isNaN(rowTime) || rowTime < 0) {
					trace('Invalid time calculated: $rowTime (beat: $currentBeat, seg.startBeat: ${seg.startBeat}, seg.startTime: ${seg.startTime}, seg.bpm: ${seg.bpm})');
					rowIndex++;
					continue;
				}
				
				for (i in 0...row.length) {
					var note = row.charAt(i);
					
					if (note == '0') continue;
					
					var lane = i;
					
					if (note == 'M') {
						section.sectionNotes.push([rowTime, lane, 0, 'Hurt Note']);
						continue;
					}
					
					var noteType = Std.parseInt(note);
					if (noteType == null || Math.isNaN(noteType)) continue;
					
					switch (noteType) {
						case 1: 
							section.sectionNotes.push([rowTime, lane, 0]);
							
						case 2: 
							heldNotes[lane] = [rowTime, lane, 0];
							
						case 3:
							if (heldNotes[lane].length > 0) {
								var holdStart = heldNotes[lane];
								var duration = rowTime - holdStart[0];
								if (duration > 0) { 
									holdStart[2] = duration;
									section.sectionNotes.push(holdStart);
								}
								heldNotes[lane] = [];
							}
							
						case 4: 
							heldNotes[lane] = [rowTime, lane, 0];
							
					}
				}
				
				rowIndex++;
			}
			measureIndex++;
		}
		
		if (section.sectionNotes.length > 0) {
			song.notes.push(section);
		}
		
		if (header.bpmChanges.length > 1) { 
			for (i in 1...header.bpmChanges.length) {
				var change = header.bpmChanges[i];
				var timeInMs = change.time * 1000; 
				song.events.push([
					timeInMs,
					[['Change BPM', Std.string(change.bpm), '']]
				]);
				trace('Added BPM change event: ${change.bpm} at ${timeInMs}ms');
			}
		}
		
		return song;
	}
	
	function createNewSection(isDouble:Bool = false):SwagSection {
		return {
			sectionNotes: [],
			sectionBeats: 4,
			mustHitSection: !isDouble,
			gfSection: false,
			bpm: 0,
			changeBPM: false,
			altAnim: false
		};
	}
}

typedef SMDifficulty = {
	var name:String;
	var isDouble:Bool;
	var measures:Array<SMMeasure>;
}

class TimingStruct {
	public static var allTimings:Array<TimingData> = [];
	
	public static function clearTimings():Void {
		allTimings = [];
	}
	
	public static function addTiming(startBeat:Float, bpm:Float, endBeat:Float, offset:Float):Void {
		allTimings.push({
			startBeat: startBeat,
			bpm: bpm,
			endBeat: endBeat,
			startTime: offset,
			length: 0
		});
	}
	
	public static function getTimingAtBeat(beat:Float):TimingData {
		for (timing in allTimings) {
			if (beat >= timing.startBeat && beat < timing.endBeat) {
				return timing;
			}
		}
		return allTimings.length > 0 ? allTimings[0] : {
			startBeat: 0,
			bpm: 100,
			endBeat: 999999,
			startTime: 0,
			length: 0
		};
	}
}

typedef TimingData = {
	var startBeat:Float;
	var bpm:Float;
	var endBeat:Float;
	var startTime:Float;
	var length:Float;
}
