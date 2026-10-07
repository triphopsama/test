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
