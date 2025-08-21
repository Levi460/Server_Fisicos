#!/bin/bash

# Script para subir todos los archivos del Codespace al repositorio de GitHub

# Configuración de usuario (cambia esto por tus datos si no está configurado en git)
git config --global user.name "Levi460"
git config --global user.email "kevinojeda52546046@gmail.com"

# Asegurarse de estar en la rama principal (puede ser main o master, ajusta si hace falta)
git checkout main 2>/dev/null || git checkout master

# Agregar todos los archivos
git add .

# Commit con fecha y hora
git commit -m "Auto-commit desde Codespace: $(date '+%Y-%m-%d %H:%M:%S')"

# Subir cambios al repositorio remoto
git push origin HEAD
