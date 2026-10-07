# Illustrations

Une image ou une animation s'affiche à chaque action. Sans fichier, l'écran est noir avec la description de l'action.

Range tes fichiers ici, un dossier par action (le nom de l'action est la colonne `id` de `data/actions.csv`) :

```
illustrations/
  parler/
    BRU001.png        ← quand tu parles à Mara (id du PNJ)
    taverne.png       ← quand tu parles à quelqu'un à la taverne (cle du lieu)
    defaut.png        ← pour tout le reste
  pecher/
    defaut.ogv        ← une vidéo
  seduire/
    BRU013/           ← une animation : un dossier d'images numérotées
      01.png
      02.png
      fps.txt         ← facultatif, 12 par défaut
  seduire_refus/
    defaut.png        ← quand le PNJ dit non (id de l'action + _refus)
```

Ordre de recherche : le PNJ, puis le lieu, puis `defaut`.

Formats : png, jpg, webp ; vidéo en .ogv (Theora : convertis avec `ffmpeg -i video.mp4 -q:v 6 video.ogv`) ; animation en dossier d'images.

Tu peux aussi les mettre dans le dossier utilisateur de Godot (`user://illustrations`, même structure) : ils sont lus sans avoir à rouvrir l'éditeur.

## Les dossiers de l'intime et des événements

Chaque action a son dossier (son `id` dans `data/actions.csv`), et un dossier `<id>_refus` quand on te dit non. En plus :

| Dossier | Quand |
| --- | --- |
| `scene_<geste>/` | un geste pendant une nuit (`id` de `data/gestes.csv`), ex. `scene_embrasser/BRU013.png` |
| `scene_a_plusieurs/` | une nuit à plusieurs : nomme le fichier avec les ids triés, ex. `BRU013+BRU022/` |
| `passer_la_nuit/` | l'image de fond d'une nuit, quand le geste n'a pas la sienne |
| `passer_la_nuit_fin/` | le récit du lendemain |
| `se_soulager/` | tu surprends quelqu'un qui se soulage seul |
| `surpris_ensemble/` | tu surprends deux PNJ ensemble (`BRU002+BRU019.png`) |
| `se_montrer/`, `partir_sans_bruit/` | ce que tu choisis ensuite |
| `travailler_nuit/`, `danser/` | le métier de nuit, la danse à la taverne |

Pour une nuit, l'ordre de recherche est : les ids des participants (`BRU013+BRU022`), puis chacun, puis le lieu, puis `defaut`.
| `suivre/`, `laisser/` | un compagnon te rejoint, ou rentre chez lui |
| `habiller_nu/`, `habiller_BRV040/` … `habiller_BRV044/` | tu habilles ou déshabilles un compagnon (ids des accessoires dans `data/objets.csv`) |
| `defi_<id>/`, `defi_<id>_victoire/`, `defi_<id>_echec/` | un défi (id de `data/defis.csv`) : accepté, gagné, perdu |
| `entrainement/` | une heure d'entraînement |
