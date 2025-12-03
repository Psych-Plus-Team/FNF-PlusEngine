#!/bin/bash
# Script para configurar SScript settings.cocoa en Linux/Mac
# Esto resuelve el problema "Invalid char '' at position 0" en compilaciones de CI/CD

SETTINGS_FILE="$HOME/settings.cocoa"

# Generar la cadena serializada de SScript
# Formato serializado Haxe: oy3s10showMacroz0y3s8loopCosti25y3s10includeAllz0
SERIALIZED="oy3s10showMacroz0y3s8loopCosti25y3s10includeAllz0"

# Guardar el archivo
echo -n "$SERIALIZED" > "$SETTINGS_FILE"

echo "SScript settings.cocoa created at: $SETTINGS_FILE"
echo "Content: $SERIALIZED"
