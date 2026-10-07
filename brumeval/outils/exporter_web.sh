#!/bin/sh
# Exporte le jeu pour le navigateur dans export/web_publie/.
# Le moteur (index.wasm, 35 Mo) est coupé en morceaux de 12 Mo, recollés par la page au chargement.
# Les morceaux et le paquet du jeu portent l'extension .wasm pour être servis tels quels par une page Artifact.
# Usage : outils/exporter_web.sh /chemin/vers/godot   (modèles d'export web 4.3 installés)
set -e
cd "$(dirname "$0")/.."
GODOT="${1:-godot}"
rm -rf export/web export/web_publie
mkdir -p export/web export/web_publie
"$GODOT" --headless --export-release Web export/web/index.html
cd export/web
split -b 12000000 -d -a 1 --additional-suffix=.wasm index.wasm ../web_publie/index.morceau
cp index.pck ../web_publie/index.pck.wasm
cp index.js index.png index.icon.png index.apple-touch-icon.png index.audio.worklet.js ../web_publie/
python3 ../../outils/page_web.py index.html ../web_publie/index.html "$(ls ../web_publie/index.morceau* | wc -l)"
