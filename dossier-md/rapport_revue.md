# Revue de sécurité de notre base – Groupe Loïc, Alice et Victor

## Synthèse

Contrôles passés : ___ / 12  
Constats : ___ critique(s), ___ haute(s), ___ moyenne(s), ___ basse(s)

## Étape 10.1 · L'injection par le tri

`recherche_vuln.py` demande un site (paramétré avec `%s`) et un tri, recopié dans la requête (`"ORDER BY " + tri`).
Le téléphone `+221 77 100 00 02` de l'énoncé (Fatou Ba) est celui d'Awa Diop chez nous : on attaque avec
`nom = 'Awa Diop'`.

**Usage normal** : site `SN-CASA`, tri `code` : les quatre ruches de SN-CASA (014, 021, 032, 099).

![Usage normal 10.1](../images/revue/vuln-normal10-1.png)

**Par erreur** : tri `cast((SELECT telephone FROM apicultrice WHERE nom = 'Awa Diop') AS int)`. La conversion échoue
et le message d'erreur, affiché tel quel, contient le téléphone : `« +221 77 100 00 02 »`.

![Attaque par erreur 10.1](../images/revue/attaque-erreur10-1.png)

**À l'aveugle** : tri `CASE WHEN (SELECT substr(telephone, 6, 2) FROM apicultrice WHERE nom = 'Awa Diop') = '77'
THEN code ELSE longitude::text END`. Avec `'77'`, les ruches sortent triées par code (014, 021, 032, 099) : la réponse
est oui. Avec `'78'`, elles sortent triées par longitude (021, 014, 099, 032) : la réponse est non. Chiffre par
chiffre, on reconstitue le numéro sans jamais l'afficher.

![Attaque à l'aveugle 10.1](../images/revue/attaque-aveugle10-1.png)

**Empilée** : tri `code; DROP TABLE journal_audit`. Refusée par PostgreSQL : `ne peut pas insérer les commandes
multiples dans une instruction préparée`. Une requête qui a des paramètres ne peut contenir qu'une seule commande : la
table `journal_audit` est intacte.

![Attaque empilée 10.1](../images/revue/attaque-empilee10-1.png)

**Version corrigée** : `recherche.py` choisit le tri dans une liste blanche (`code` ou `date_installation`), le passe
avec `sql.Identifier`, et n'affiche plus l'erreur de la base. L'attaque par erreur donne
`Tri refusé : choisissez code ou date_installation`.

![Version corrigée 10.1](../images/revue/recherche-corrige10-1.png)

## Étape 10.2 · La vue qui en dit trop

**La vue trop large** : un collègue pressé ajoute `v_carte_ruches` (code, position, nom et téléphone de toutes les
ruches) et la donne à `qb_apicultrice`. En `f.ba`, la table `apicultrice` est refusée, mais la vue s'exécute avec
les droits de son propriétaire : elle montre les 11 ruches et les 8 téléphones. C'est une élévation de privilège.

![Vue trop large 10.2](../images/revue/vue-large10-2.png)

**La fonction espion** : toujours en `f.ba`, une fonction temporaire `pg_temp.espion(code, latitude, longitude)` qui
affiche ce qu'elle reçoit, placée dans le `WHERE` sur `v_mes_ruches`. Le résultat ne montre que SN-CASA-032 (la
SN-CASA-013 de l'énoncé n'existe pas chez nous), mais les `NOTICE` donnent la position GPS des 11 ruches : PostgreSQL
a évalué la fonction avant le filtre de la vue. Pour un voleur, c'est la carte complète.

![Espion 10.2](../images/revue/espion10-2.png)

**Les corrections** (`corrections.sql`, lancé en `postgres`) : la vue réécrite (ses ruches seulement, sans nom ni
téléphone), `security_barrier` sur les 7 vues filtrantes, et `REVOKE TEMPORARY ON DATABASE queenbee FROM PUBLIC`.
Retest dans la même session : la vue ne montre plus qu'une ligne sans téléphone, et l'espion ne voit plus que
SN-CASA-032. Dans une nouvelle session : `droit refusé pour la création de tables temporaires`.

Retest dans la même session `f.ba`, juste après `corrections.sql` :

```
queenbee=> SELECT * FROM v_carte_ruches;
    code     | latitude | longitude
-------------+----------+-----------
 SN-CASA-032 | 12.54320 | -16.28010
(1 ligne)

queenbee=> SELECT code FROM v_mes_ruches WHERE pg_temp.espion(code, latitude, longitude);
NOTICE:  espion : SN-CASA-032 12.54320 -16.28010
    code
-------------
 SN-CASA-032
(1 ligne)
```

Puis dans une nouvelle session :

![Retest 10.2](../images/revue/retest10-2.png)

## Failles démontrées (étapes 10.1 et 10.2)

| ID | Faille | Preuve | Correction | Retest |
|----|--------|--------|------------|--------|
| P1 | injection par le tri | `recherche_vuln.py` : le téléphone d'Awa Diop dans le message d'erreur, et l'ordre des lignes qui répond oui/non | `recherche.py` : liste blanche, `sql.Identifier`, erreur de la base masquée | « Tri refusé : choisissez code ou date_installation » |
| P2 | vue `v_carte_ruches` trop large | en `f.ba`, `apicultrice` refusée mais la vue montre 11 ruches et 8 téléphones | vue réécrite : ses ruches seulement, sans nom ni téléphone, `security_barrier` | une seule ligne (SN-CASA-032), sans téléphone |
| P3 | fuite par fonction espion | `pg_temp.espion` sur `v_mes_ruches` : 1 ligne affichée, 11 positions GPS dans les `NOTICE` | `security_barrier` sur les 7 vues filtrantes, `REVOKE TEMPORARY ... FROM PUBLIC` | l'espion ne voit plus que SN-CASA-032 ; nouvelle session : droit refusé pour les tables temporaires |



## Étape 10.3 · La grille de contrôle

| N° | Contrôle | Résultat | Constat ouvert ? |
|----|----------|----------|------------------|
| C1 | aucune fonction exécutable par PUBLIC | à lancer (requête C1) | ___ |
| C2 | toute fonction SECURITY DEFINER fixe son `search_path` | OK dans les fichiers (`audit_ligne`, `valider_recolte`) ; à confirmer avec la requête C2 | non |
| C3 | les vues filtrantes sont des barrières | échec probable : aucun `security_barrier` dans `roles.sql` ; à confirmer avec la requête C3 | oui (R1) |
| C4 | aucune vue ne montre des données hors périmètre | ___ | ___ |
| C5 | le journal est en ajout seul | ___ | ___ |
| C6 | le journal nomme le vrai acteur | ___ | ___ |
| C7 | une apicultrice n'écrit pas chez une autre | ___ | ___ |
| C8 | un jeton ne sert qu'une fois | ___ | ___ |
| C9 | pas de requête construite par `+` ou f" | `query_vuln.py` concatène (version volontairement vulnérable du jour 1) ; `query.py` est sûr | non si `query_vuln.py` reste hors rendu, sinon oui (R2) |
| C10 | les preuves ne partent pas en cascade | ___ | ___ |
| C11 | pas de mot de passe dans le dépôt | échec : 5 mots de passe en clair dans `roles.sql` (`git grep -i password`) | oui (R3), à discuter |
| C12 | la base se reconstruit avec vos fichiers | ___ | ___ |

<!-- IMG : C1 à C3 -->
<!-- ![C1-C3](../images/grille-c1-c3.png) -->

<!-- IMG : C4 à C7 -->
<!-- ![C4-C7](../images/grille-c4-c7.png) -->

<!-- IMG : C8 à C12 -->
<!-- ![C8-C12](../images/grille-c8-c12.png) -->

## Constats de la grille

| ID | Contrôle | Gravité | Constat | Preuve (commande et résultat) | Correction | Retest |
|----|----------|---------|---------|-------------------------------|------------|--------|
| R1 | C3 | moyenne | les vues filtrantes (`v_moi`, `v_mes_ruches`, `v_mes_mesures`, `v_mes_recoltes`, `v_ruches_site`, `v_recoltes_site`) n'ont pas `security_barrier` : une fonction piégée peut lire des lignes avant le filtre | requête C3 : `reloptions` vide | `ALTER VIEW … SET (security_barrier = true);` | rejouer la requête C3 |
| R2 | C9 | basse | `query_vuln.py` construit sa requête par `+` | `grep -n '+ ' query_vuln.py` | garder ce fichier comme démonstration, ne pas l'utiliser en production | _à compléter_ |
| R3 | C11 | moyenne | mots de passe en clair dans `roles.sql` (versionné dans git) | `git grep -i password` : 5 lignes | mots de passe tirés au hasard hors dépôt (variable d'environnement), à changer | _à compléter_ |

