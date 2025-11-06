package backend.stepmania;

import backend.Song;

/**
 * Parser para archivos .sm de StepMania
 * Convierte charts de StepMania al formato de FNF
 */
class SMFile {
	public var header:SMHeader;
	public var measures:Array<SMMeasure> = [];
	public var isValid:Bool = true;
	public var isDouble:Bool = false;
	public var difficulty:String = 'Normal'; // Almacenar la dificultad del chart
	
	private var fileData:Array<String>;
	
	public function new(data:String) {
		fileData = data.split('\n');
		parseFile();
	}
	
	/**
	 * Carga un archivo .sm desde una ruta
	 */
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
	
	/**
	 * Parsea el contenido del archivo .sm
	 */
	function parseFile():Void {
		try {
			// Extraer header
			var headerData = '';
			var inc = 0;
			
			// Buscar hasta encontrar la sección de NOTES
			while (inc < fileData.length && !fileData[inc].contains('#NOTES')) {
				headerData += fileData[inc] + '\n';
				inc++;
			}
			
			header = new SMHeader(headerData);
			
			// Validar que solo hay 1 dificultad
			var notesCount = 0;
			for (line in fileData) {
				if (line.contains('#NOTES'))
					notesCount++;
			}
			
			if (notesCount > 1) {
				trace('ERROR: SM file has more than one difficulty! Only single difficulty charts are supported.');
				isValid = false;
				return;
			}
			
			// Verificar que el archivo de música es .ogg
			if (!header.MUSIC.toLowerCase().endsWith('.ogg')) {
				trace('ERROR: Music file must be .ogg format!');
				isValid = false;
				return;
			}
			
			// Saltar a la sección de notas (la primera línea después de #NOTES es el tipo de chart)
			inc += 1; // Saltar solo 1 línea después de #NOTES
			
			// Verificar tipo de chart
			var chartType = fileData[inc].trim().toLowerCase();
			
			if (chartType.contains('dance-double') || chartType == 'dance-double:') {
				isDouble = true;
				trace('Double chart detected');
			} else if (chartType.contains('dance-single') || chartType == 'dance-single:') {
				//trace('Single chart detected');
			} else {
				trace('ERROR: Chart must be dance-single or dance-double! Found: "$chartType"');
				isValid = false;
				return;
			}
			
			// Capturar la dificultad (línea inc+2: inc+1 es author/description, inc+2 es difficulty)
			inc += 2;
			var difficultyRaw = fileData[inc].trim().replace(':', '');
			if (difficultyRaw.length > 0) {
				// Capitalizar primera letra
				difficulty = difficultyRaw.charAt(0).toUpperCase() + difficultyRaw.substr(1).toLowerCase();
			}
			
			inc += 3; // Saltar a las notas (meter + groove radar)
			
			// Parsear medidas
			var currentMeasure = '';
			for (i in inc...fileData.length) {
				var line = fileData[i].trim();
				
				if (line == ',' || line == ';') {
					if (currentMeasure.length > 0) {
						measures.push(new SMMeasure(currentMeasure.split('\n')));
						currentMeasure = '';
					}
					if (line == ';') break; // Fin de la chart
				} else if (line.length > 0 && !line.startsWith('//')) {
					currentMeasure += line + '\n';
				}
			}
			
			
		} catch (e:Dynamic) {
			trace('Error parsing SM file: ' + e);
			isValid = false;
		}
	}
	
	/**
	 * Convierte el archivo SM a formato JSON de FNF
	 */
	public function convertToFNF(songName:String):SwagSong {
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
		
		var bpm = header.getBPM(0);
		if (bpm <= 0 || Math.isNaN(bpm)) {
			trace('Invalid BPM detected, using default of 120');
			bpm = 120;
		}

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
			stage: 'notitg', // Usar stage NotITG para canciones de StepMania
			format: 'psych_v1',
			offset: 0
		};		var heldNotes:Array<Array<Dynamic>> = isDouble ? [[], [], [], [], [], [], [], []] : [[], [], [], []];
		var currentBeat:Float = 0;
		var measureIndex:Int = 0;
		
		var section:SwagSection = createNewSection();
		
		if (measures == null || measures.length == 0) {
			trace('No measures found in SM file');
			return song; // Retornar canción vacía pero válida
		}
		
		for (measure in measures) {
			if (measure == null || measure.noteRows == null) {
				trace('Invalid measure found, skipping');
				continue;
			}
			
			var lengthInRows = Math.floor(192 / (measure.noteRows.length));
			if (lengthInRows <= 0) lengthInRows = 1; // Evitar división por cero
			
			var rowIndex = 0;
			
			for (row in measure.noteRows) {
				if (row == null || row.length == 0) {
					rowIndex++;
					continue;
				}
				
				var noteRow = (measureIndex * 192) + (lengthInRows * rowIndex);
				currentBeat = noteRow / 48;
				
				// Crear nueva sección cada 4 beats
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
				
				var timeInSec = (seg.startTime + ((currentBeat - seg.startBeat) / (seg.bpm / 60)));
				var rowTime = timeInSec * 1000;
				
				if (Math.isNaN(rowTime) || rowTime < 0) {
					trace('Invalid time calculated: $rowTime');
					rowIndex++;
					continue;
				}
				
				// Procesar cada nota en la fila
				for (i in 0...row.length) {
					var note = row.charAt(i);
					
					// Ignorar espacios vacíos
					if (note == '0') continue;
					
					var lane = i;
					
					// Manejar minas como Hurt Notes
					if (note == 'M') {
						section.sectionNotes.push([rowTime, lane, 0, 'Hurt Note']);
						continue;
					}
					
					var noteType = Std.parseInt(note);
					if (noteType == null || Math.isNaN(noteType)) continue;
					
					switch (noteType) {
						case 1: // Nota normal (tap)
							section.sectionNotes.push([rowTime, lane, 0]);
							
						case 2: // Inicio de hold normal
							heldNotes[lane] = [rowTime, lane, 0];
							
						case 3: // Fin de hold normal
							if (heldNotes[lane].length > 0) {
								var holdStart = heldNotes[lane];
								var duration = rowTime - holdStart[0];
								if (duration > 0) { // Solo agregar holds válidos
									holdStart[2] = duration;
									section.sectionNotes.push(holdStart);
								}
								heldNotes[lane] = [];
							}
							
						case 4: // Inicio de roll (tratar como hold normal)
							heldNotes[lane] = [rowTime, lane, 0];
							
						// Nota: El tipo 3 sirve tanto para finalizar holds (2) como rolls (4)
						// Por eso no necesitamos un case separado para finalizar rolls
					}
				}
				
				rowIndex++;
			}
			measureIndex++;
		}
		
		// Agregar última sección
		if (section.sectionNotes.length > 0) {
			song.notes.push(section);
		}
		
		// Agregar eventos de cambio de BPM si existen
		if (header.bpmChanges.length > 0) {
			for (change in header.bpmChanges) {
				song.events.push([
					change.time,
					[['Change BPM', Std.string(change.bpm), '']]
				]);
			}
		}
		
		return song;
	}
	
	function createNewSection():SwagSection {
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

/**
 * Clase auxiliar para manejar timings
 */
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
		// Retornar el primer timing si no se encuentra ninguno
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
