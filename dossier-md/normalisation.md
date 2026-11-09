# Normalisation de extrait_plat – Groupe ___

Clé candidate : **{ruche_code, horodatage}** (lab 4).

## 1. Les trois anomalies et la dépendance qui les cause

| Anomalie | Ce qu'on a fait | Ce qui s'est passé | Dépendance du lab 4 en cause |
|----------|-----------------|--------------------|------------------------------|
| Mise à jour | `pays` modifié sur 1 ligne (`Sénégal` → `Senegal`), téléphone modifié sur 1 autre | l'enquête par pays passe de 3 à 4 pays ; la ruche SN-KOLD-011 a deux téléphones | `site_id -> site_nom, pays` et `ruche_code -> …, telephone` : le même fait est recopié sur des dizaines de lignes |
| Suppression | suppression des 48 lignes de mesure d'Awa Diop (une seule ruche) | son téléphone et son existence disparaissent de la base | `telephone -> apicultrice, cooperative` : la fiche de l'apicultrice n'existe que dans les lignes de mesure |
| Insertion | ajout d'un site sans ruche (`Douala`) | refusé (`null value in column "ruche_code"`) | `site_id -> site_nom, pays` : un site n'existe que s'il a une ruche et une mesure, car la clé exige `ruche_code` et `horodatage` |

## 2. Classement des dépendances par forme normale

La clé est composée de deux colonnes, donc la 2NF compte.

| Forme normale | Règle | Vos dépendances qui la violent |
|---------------|-------|--------------------------------|
| 1NF | chaque case contient une seule valeur | aucune : chaque colonne est atomique (un nom, un pays, un poids par case) |
| 2NF | aucune colonne ne dépend d'une **partie** de la clé | `ruche_code -> site_id, site_nom, pays, apicultrice, telephone, cooperative` : `ruche_code` n'est qu'une partie de la clé {ruche_code, horodatage} |
| 3NF | aucune colonne ne dépend d'une colonne qui n'est pas la clé | `site_id -> site_nom, pays` ; `telephone -> apicultrice, cooperative` (la ruche détermine `site_id` et `telephone`, qui à leur tour déterminent d'autres colonnes : dépendances transitives) |
| BCNF | la partie gauche de toute dépendance est une clé | les quatre dépendances ci-dessus, sauf `ruche_code, horodatage -> poids_kg, temp_int_c` dont la partie gauche est la clé |

Pourquoi `ruche_code -> site_id` viole la 2NF : `site_id` dépend de `ruche_code` seul, c'est-à-dire d'une partie de la
clé. Elle est recopiée sur chacune des 48 mesures de la ruche.

## 3. Le découpage : une table par déterminant

| Table (schéma `norm`) | Clé primaire | Colonnes | Dépendance |
|-----------------------|--------------|----------|------------|
| `norm.site` | `site_id` | `site_nom`, `pays` | `site_id -> site_nom, pays` |
| `norm.apicultrice` | `telephone` | `apicultrice`, `cooperative` | `telephone -> apicultrice, cooperative` |
| `norm.ruche` | `ruche_code` | `site_id` (→ `norm.site`), `telephone` (→ `norm.apicultrice`) | `ruche_code -> site_id, telephone` |
| `norm.mesure` | `ruche_code, horodatage` | `poids_kg`, `temp_int_c` | `ruche_code, horodatage -> poids_kg, temp_int_c` |

Les colonnes `site_nom`, `pays`, `apicultrice` et `cooperative` ne sont plus recopiées : chaque fait est écrit une
seule fois.

## 4. Vérification BCNF, table par table

| Table | Dépendances qui s'y appliquent | La partie gauche est-elle une clé ? | BCNF |
|-------|--------------------------------|--------------------------------------|------|
| `norm.site` | `site_id -> site_nom, pays` | oui (`site_id` est la clé primaire) | oui |
| `norm.apicultrice` | `telephone -> apicultrice, cooperative` | oui (`telephone` est la clé primaire) | oui |
| `norm.ruche` | `ruche_code -> site_id, telephone` | oui (`ruche_code` est la clé primaire) | oui |
| `norm.mesure` | `ruche_code, horodatage -> poids_kg, temp_int_c` | oui (clé primaire composée) | oui |

Aucune dépendance ne reste dont la partie gauche n'est pas une clé : les quatre tables sont en BCNF.

Remarque de limite : `apicultrice -> telephone` est fausse (deux « Aminata Diop »), donc `apicultrice` n'est pas un
déterminant et ne pose pas de problème. `telephone` sert de clé dans `norm.apicultrice` parce que le jeu d'essai donne
un téléphone distinct à chaque apicultrice ; en production, une clé technique (`id`) serait plus sûre, car deux
personnes peuvent partager un numéro.

## 5. La migration

`migration_3nf.sql` crée les quatre tables puis les remplit avec `INSERT … SELECT DISTINCT`.

- Lancée sur les données **corrompues** (1 ligne `Senegal`, 1 ligne avec un autre téléphone), elle **échoue** :
  `ERROR: duplicate key value violates unique constraint "site_pkey" — Key (site_id)=(2) already exists`.
  La clé primaire refuse qu'un site ait deux pays. Une fois le pays corrigé, elle échoue sur la ruche :
  `"ruche_pkey" — Key (ruche_code)=(SN-KOLD-011) already exists` (deux téléphones pour une ruche).
- Après nettoyage (`UPDATE` des deux valeurs minoritaires), elle passe : **4 sites, 8 apicultrices, 11 ruches, 528 mesures**.

## 6. Preuve que rien n'est perdu (`preuve.sql`)

La vue `norm.reconstruit` rejoint les quatre tables, avec les mêmes colonnes dans le même ordre que `extrait_plat`.
La comparaison dans les deux sens :

```sql
(SELECT * FROM extrait_plat EXCEPT SELECT * FROM norm.reconstruit)
UNION ALL
(SELECT * FROM norm.reconstruit EXCEPT SELECT * FROM extrait_plat);
```

Résultat : **0 ligne**. Le découpage est sans perte : la jointure des morceaux redonne exactement la table de départ.

## 7. Les attaques rejouées sur les tables normalisées

| Attaque | Sur `extrait_plat` | Sur `norm` |
|---------|--------------------|------------|
| Un second pays pour un site existant | accepté (3 → 4 pays) | **refusé** : `site_pkey` |
| Un site sans ruche | refusé (`ruche_code` nul) | **accepté** (`norm.site` seule) |
| Supprimer les mesures d'Awa Diop | son téléphone disparaît | elle reste dans `norm.apicultrice` |
| Enquête par pays | 4 pays après une seule modification | de nouveau **3 pays** (96 / 96 / 336 mesures) |

## Conclusion

Une seule ligne modifiée a fait passer l'enquête de **3 à 4 pays**. Une base non normalisée ne peut pas servir de
preuve.
