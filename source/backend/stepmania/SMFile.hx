package backend.stepmania;

import backend.Song;
import backend.stepmania.SMHeader;

/**
 * Parser para archivos .sm de StepMania
 * Convierte charts de StepMania al formato de FNF
 * Soporta múltiples dificultades en un solo archivo
 */
class SMFile {
	public var header:SMHeader;
	public var difficulties:Array<SMDifficulty> = [];
	public var isValid:Bool = true;
	
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
			
			// Verificar que el archivo de música es .ogg
			if (!header.MUSIC.toLowerCase().endsWith('.ogg')) {
				trace('ERROR: Music file must be .ogg format!');
				isValid = false;
				return;
			}
			
			// Parsear todas las dificultades
			while (inc < fileData.length) {
				// Buscar siguiente #NOTES
				while (inc < fileData.length && !fileData[inc].contains('#NOTES')) {
					inc++;
				}
				
				if (inc >= fileData.length) break;
				
				// Saltar la línea #NOTES
				inc++;
				
				// Leer tipo de chart (dance-single, dance-double, etc.)
				if (inc >= fileData.length) break;
				var chartType = fileData[inc].trim().toLowerCase();
				var isDouble = chartType.contains('dance-double');
				
				// Verificar que sea single o double
				if (!chartType.contains('dance-single') && !chartType.contains('dance-double')) {
					trace('Skipping unsupported chart type: $chartType');
					// Saltar hasta el siguiente ; para ignorar esta dificultad
					while (inc < fileData.length && !fileData[inc].contains(';')) {
						inc++;
					}
					inc++;
					continue;
				}
				
				inc++; // Saltar a author/description
				if (inc >= fileData.length) break;
				
				inc++; // Saltar a difficulty
				if (inc >= fileData.length) break;
				
				var difficultyRaw = fileData[inc].trim().replace(':', '');
				var difficultyName = 'Normal';
				if (difficultyRaw.length > 0) {
					difficultyName = difficultyRaw.charAt(0).toUpperCase() + difficultyRaw.substr(1).toLowerCase();
				}
				
				inc += 3; // Saltar meter + groove radar para llegar a las notas
				
				// Parsear medidas de esta dificultad
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
							break; // Fin de esta dificultad
						}
					} else if (line.length > 0 && !line.startsWith('//')) {
						currentMeasure += line + '\n';
					}
					
					inc++;
				}
				
				// Agregar esta dificultad
				difficulties.push({
					name: difficultyName,
					isDouble: isDouble,
					measures: measures
				});
				
				trace('Loaded difficulty: $difficultyName (${isDouble ? "Double" : "Single"}) with ${measures.length} measures');
			}
			
			if (difficulties.length == 0) {
				trace('ERROR: No valid difficulties found in SM file');
				isValid = false;
				return;
			}
			
			trace('Successfully loaded ${difficulties.length} difficulties');
			
		} catch (e:Dynamic) {
			trace('Error parsing SM file: ' + e);
			isValid = false;
		}
	}
	
	/**
	 * Convierte una dificultad específica del archivo SM a formato JSON de FNF
	 * @param songName Nombre de la canción
	 * @param difficultyIndex Índice de la dificultad a convertir (0 = primera dificultad)
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
		
		// Inicializar TimingStruct con los BPM del header
		TimingStruct.clearTimings();
		
		// Cargar todos los BPM del header
		var bpmChanges:Array<backend.stepmania.SMHeader.BPMChange> = header.bpmChanges;
		if (bpmChanges.length == 0) {
			// Si no hay cambios de BPM, crear uno inicial
			TimingStruct.addTiming(0, bpm, 999999, 0);
		} else {
			// Ordenar por beat
			bpmChanges.sort((a, b) -> a.beat < b.beat ? -1 : (a.beat > b.beat ? 1 : 0));
			
			// Agregar cada cambio de BPM
			for (i in 0...bpmChanges.length) {
				var change = bpmChanges[i];
				var startBeat = change.beat;
				var endBeat = (i < bpmChanges.length - 1) ? bpmChanges[i + 1].beat : 999999;
				
				// El campo 'time' ya contiene el offset de tiempo calculado
				var timeOffset:Float = change.time;
				
				TimingStruct.addTiming(startBeat, change.bpm, endBeat, timeOffset);
			}
		}
		
		trace('Initialized TimingStruct with ${TimingStruct.allTimings.length} timing segments');

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
		
		var section:SwagSection = createNewSection(isDouble);
		
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
		
		// Agregar eventos de cambio de BPM si existen (convertir tiempo a milisegundos)
		if (header.bpmChanges.length > 1) { // Solo si hay más de un BPM (el primero ya está en song.bpm)
			for (i in 1...header.bpmChanges.length) {
				var change = header.bpmChanges[i];
				var timeInMs = change.time * 1000; // Convertir a milisegundos
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

// Typedef para almacenar información de cada dificultad
typedef SMDifficulty = {
	var name:String;
	var isDouble:Bool;
	var measures:Array<SMMeasure>;
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
