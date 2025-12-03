# Script para configurar SScript settings.cocoa en Windows
# Esto resuelve el problema "Invalid char '' at position 0" en compilaciones de CI/CD

$userProfile = $env:USERPROFILE
$settingsFile = Join-Path $userProfile "settings.cocoa"

# Crear las configuraciones por defecto de SScript
# Format: showMacro:Bool, loopCost:Int, includeAll:Bool
# Serializado con haxe.Serializer

$settings = @{
    showMacro = $false
    loopCost = 25
    includeAll = $false
}

# Generar la cadena serializada
# Haxe Serializer format: ayy... (array) or oy... (object)
# Para un objeto simple: {showMacro:false, loopCost:25, includeAll:false}
# Formato serializado: oy3s10showMacroz0y3s8loopCosti25y3s10includeAllz0

$serialized = "oy3s10showMacroz0y3s8loopCosti25y3s10includeAllz0"

# Guardar el archivo
Set-Content -Path $settingsFile -Value $serialized -NoNewline -Encoding ASCII

Write-Host "SScript settings.cocoa created at: $settingsFile"
Write-Host "Content: $serialized"
