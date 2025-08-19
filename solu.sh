#!/usr/bin/env bash
set -euo pipefail

# --- Ajusta aquí si tu commit "bueno" fuera otro ---
GOOD_COMMIT="4c76bf4"
# --------------------------------------------------

TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
BACKUP_BRANCH="backup-before-restore-${TIMESTAMP}"
POINT_BRANCH="restore-point-${GOOD_COMMIT}-${TIMESTAMP}"
RESTORE_TREE_BRANCH="restore-tree-${GOOD_COMMIT}-${TIMESTAMP}"

echo "1) Asegurando estado actual y creando backup branch: $BACKUP_BRANCH"
git checkout main
git pull --ff-only origin main
git branch "${BACKUP_BRANCH}" main
git push -u origin "${BACKUP_BRANCH}"

echo "2) Creando rama que apunta directamente al commit bueno: $POINT_BRANCH"
git branch -f "${POINT_BRANCH}" "${GOOD_COMMIT}"
git push -u origin "${POINT_BRANCH}"

echo "3) Creando rama basada en main y aplicando el árbol de $GOOD_COMMIT (commit de restauración)"
git checkout -b "${RESTORE_TREE_BRANCH}" main

# Quitar los archivos rastreados actuales del índice (no toca .git)
# luego traer los archivos del GOOD_COMMIT al working tree
git rm -rf --ignore-unmatch .
git checkout "${GOOD_COMMIT}" -- .

# Asegurarse de que haya algo para commitear (si no hay cambios, se avisará)
if git add -A && git diff --cached --quiet; then
  echo "No hay cambios para commitear: el árbol en main ya coincide con ${GOOD_COMMIT}."
  echo "Igualmente se ha creado la rama ${POINT_BRANCH} que apunta a ${GOOD_COMMIT}."
else
  git commit -m "Restaurar contenido a partir del commit ${GOOD_COMMIT} (recuperación automática) [${TIMESTAMP}]"
  git push -u origin "${RESTORE_TREE_BRANCH}"
  echo "Rama con commit de restauración subida: ${RESTORE_TREE_BRANCH}"
fi

# Mostrar enlaces útiles
ORIGIN_URL=$(git config --get remote.origin.url || echo "")
REPO_PATH=""
if [[ $ORIGIN_URL =~ github.com[:/](.*)\.git ]]; then
  REPO_PATH="${BASH_REMATCH[1]}"
fi

echo
echo "Resumen de ramas creadas / subidas:"
echo "  Backup branch:    ${BACKUP_BRANCH}"
echo "  Point branch:     ${POINT_BRANCH}   (apunta directamente a ${GOOD_COMMIT})"
if git show-ref --verify --quiet "refs/heads/${RESTORE_TREE_BRANCH}"; then
  echo "  Restore branch:   ${RESTORE_TREE_BRANCH} (contiene commit que aplica los archivos de ${GOOD_COMMIT})"
else
  echo "  Restore branch:   (no se creó commit porque no había cambios entre main y ${GOOD_COMMIT})"
fi

if [[ -n "$REPO_PATH" ]]; then
  echo
  echo "Abrir PR desde la rama de restauración hacia main (opción recomendada):"
  if git show-ref --verify --quiet "refs/heads/${RESTORE_TREE_BRANCH}"; then
    echo "  https://github.com/${REPO_PATH}/pull/new/${RESTORE_TREE_BRANCH}"
  else
    echo "  https://github.com/${REPO_PATH}/pull/new/${POINT_BRANCH}"
  fi
else
  echo
  echo "No pude detectar la URL del remoto para construir el link al PR."
  echo "Abre GitHub y crea un PR desde la rama '${RESTORE_TREE_BRANCH}' (o '${POINT_BRANCH}')."
fi

echo
echo "TERMINADO. Revisa el PR en GitHub y mergea cuando estés seguro."
