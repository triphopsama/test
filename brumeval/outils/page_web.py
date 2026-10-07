# Ajoute à la page web exportée le recollage des morceaux du moteur, et le titre.
import re
import sys

source, sortie, morceaux = sys.argv[1], sys.argv[2], int(sys.argv[3])
page = open(source, encoding="utf-8").read()
recollage = """<script>
// Le moteur est découpé en morceaux (index.morceauN.wasm) : on les recolle avant de le donner à Godot.
// Le paquet du jeu est servi sous le nom index.pck.wasm.
(function () {
	const fetchOrigine = window.fetch.bind(window);
	window.fetch = async function (url, opts) {
		if (typeof url === 'string' && url.endsWith('index.wasm')) {
			const base = url.slice(0, -'index.wasm'.length);
			const numeros = Array.from({ length: %d }, (_, i) => i);
			const morceaux = await Promise.all(numeros.map((i) => fetchOrigine(base + 'index.morceau' + i + '.wasm').then((r) => {
				if (!r.ok) throw new Error('morceau ' + i + ' : ' + r.status);
				return r.arrayBuffer();
			})));
			const blob = new Blob(morceaux, { type: 'application/wasm' });
			return new Response(blob, { status: 200, headers: { 'Content-Type': 'application/wasm', 'Content-Length': String(blob.size) } });
		}
		if (typeof url === 'string' && url.endsWith('index.pck')) {
			return fetchOrigine(url + '.wasm', opts);
		}
		return fetchOrigine(url, opts);
	};
})();
</script>
		<script src="index.js"></script>""" % morceaux
page = page.replace('<script src="index.js"></script>', recollage, 1)
page = re.sub(r"<title>.*?</title>", "<title>Brumeval</title>", page)
open(sortie, "w", encoding="utf-8").write(page)
