# Normalisation J2

## Étape 6.1 · Analyser la table reçue (`formation_plat`)

### Dépendances

- `(telephone, theme) -> formateur` : pour un thème, une apicultrice n'a qu'un formateur.
- `formateur -> theme` : un formateur n'enseigne qu'un thème.

Les trois tests `GROUP BY … HAVING` renvoient 0 ligne : les données respectent ces règles.

![Tests 6.1](../images/tests6-1.png)


### Clés candidates

- `(telephone, theme)`
- `(telephone, formateur)`

### 3NF ? BCNF ?

- **3NF : oui**, car `theme` fait partie d'une clé candidate.
- **BCNF : non**, car `formateur -> theme` part de `formateur`, qui n'est pas une clé.

### Anomalie

Dans une transaction annulée (`BEGIN` … `ROLLBACK`), On a passé Moussa Sarr en `capteurs` sur la ligne
`+221 77 100 00 02`. Résultat : `Moussa Sarr | {capteurs,varroa}`.

La table accepte la modification sans erreur : Moussa Sarr enseigne deux thèmes, et la règle
`formateur -> theme` est violée.
