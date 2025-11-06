package states.stages;

import backend.BaseStage;

class NotITG extends BaseStage
{
	override function create()
	{
		// Stage completamente negro para niveles de StepMania NotITG
		// Sin elementos visuales adicionales para máximo rendimiento
		
		// Establecer color de fondo negro
		camGame.bgColor = 0xFF000000;
		
		// Configurar zoom por defecto
		defaultCamZoom = 0.9;
		
		// No agregar sprites de fondo ni elementos decorativos
		// Esto asegura máximo rendimiento para charts de StepMania
	}
	
	override function createPost()
	{
		// Asegurar que el fondo permanezca negro
		camGame.bgColor = 0xFF000000;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		// Mantener el fondo negro en todo momento
		if (camGame.bgColor != 0xFF000000)
			camGame.bgColor = 0xFF000000;
	}
}

