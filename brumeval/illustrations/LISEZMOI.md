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
| `vesperine_crique/`, `vesperine_libre/`, `vesperine_capturee/` | la nuit de Vesperine (son id : `VES019`) |
| `nourrir_pain/`, `nourrir_poisson/`, `guider/` | la nourrir, la guider chez Agnès |
| `offrande_pierre/`, `offrande_pain/`, `offrande_mures/`, `fee_benir/`, `fee_mepris/`, `brume_egare/` | les fées (ids `FEE001` Brumelle, `FEE002` Lirelle, `FEE003` Mousse) |
| `voyager/`, `nuit_margo/`, `manger/` | Pierrefane : le sentier côtier, Margo (`PIE004`), la soupe du Mouillage |
| `lien_liaison/`, `lien_couple/`, `lien_fin/`, `lien_ouvert/`, `lien_rupture/`, `lien_reconciliation/`, `lien_infidelite/` | les amours des habitants entre eux, quand tu es là (`BRU008+BRU012.png`, puis chacun) |
| `lien_trahison/`, `lien_pardon/`, `lien_ouvert/`, `lien_rupture/` | ton couple t'a trompé·e, et ce que tu en fais |
| `lien_invitation/` | un couple ouvert t'invite à les suivre |
| `ragots/`, `confidences/`, `entremetteur/`, `denoncer/`, `couvrir/`, `chantage/`, `consoler/`, `reconcilier/`, `zizanie/` | ce que tu fais de leurs amours |
| `maison_1/` … `maison_4/`, `maison_demander/`, `maison_dormir/`, `maison_coffre/`, `maison_bain/`, `maison_betes/`, `maison_inviter/`, `maison_renvoyer/` | ta maison de la falaise, étape par étape |
| `bien_<id>/`, `bien_offert/`, `bien_vendre/`, `negocier/`, `louer/`, `preter_refus/` | acheter, négocier, louer, se faire prêter (ids de `data/biens.csv`) |
| `bien_lanternes/`, `bien_lanternes_libre/`, `bien_lanternes_contrats/` | la Maison des Lanternes achetée, et ses contrats |
| `dette_racheter/`, `liberer/`, `contrat_travail/`, `contrat_equipe/`, `contrat_garde/` | les contrats de dette |
