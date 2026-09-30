#!/usr/bin/env bash
# courses.sh — remplit le panier Auchan Drive à partir de courses.txt
# Usage : ./courses.sh
set -euo pipefail
cd "$(dirname "$0")"

LISTE="courses.txt"
MCP_DIST="mcp-auchan-drive/dist/index.js"

if [[ ! -f "$MCP_DIST" ]]; then
  echo "Erreur : le serveur MCP n'est pas compilé ($MCP_DIST manquant)."
  echo "  cd mcp-auchan-drive && npm install && npm run build"
  exit 1
fi

if [[ ! -s "$LISTE" ]]; then
  echo "Erreur : $LISTE absent ou vide. Écris ta liste de courses dedans, puis relance."
  exit 1
fi

exec vibe --trust \
  -p "Remplis mon panier Auchan Drive à partir de la liste courses.txt, en suivant ton workflow d'agent." \
  --agent courses \
  --output text
