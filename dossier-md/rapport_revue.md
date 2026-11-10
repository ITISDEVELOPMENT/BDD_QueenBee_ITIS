# Revue de sécurité de notre base – Groupe ___

## Synthèse

Contrôles passés : ___ / 12  
Constats : ___ critique(s), ___ haute(s), ___ moyenne(s), ___ basse(s)

## Étape 10.1 · L'injection par le tri

Test normal : `SN-CASA` puis `code` (les quatre ruches de SN-CASA).

<!-- IMG : recherche_vuln.py, usage normal -->
<!-- ![Usage normal 10.1](../images/vuln-normal10-1.png) -->

<!-- IMG : attaque par erreur (le téléphone de Fatou Ba) -->
<!-- ![Attaque par erreur 10.1](../images/attaque-erreur10-1.png) -->

<!-- IMG : attaque à l'aveugle ('77' puis '78') -->
<!-- ![Attaque à l'aveugle 10.1](../images/attaque-aveugle10-1.png) -->

<!-- IMG : attaque empilée (cannot insert multiple commands…) -->
<!-- ![Attaque empilée 10.1](../images/attaque-empilee10-1.png) -->

<!-- IMG : recherche.py corrigé : Tri refusé -->
<!-- ![Version corrigée 10.1](../images/recherche-corrigee10-1.png) -->

## Étape 10.2 · La vue qui en dit trop

<!-- IMG : f.ba lit apicultrice (refusé) puis v_carte_ruches (11 ruches, tous les téléphones) -->
<!-- ![Vue trop large 10.2](../images/vue-large10-2.png) -->

<!-- IMG : fonction espion sur v_mes_ruches (NOTICE avec les positions GPS) -->
<!-- ![Espion 10.2](../images/espion10-2.png) -->

<!-- IMG : retest après corrections.sql -->
<!-- ![Retest 10.2](../images/retest10-2.png) -->

## Failles démontrées (étapes 10.1 et 10.2)

| ID | Faille | Preuve | Correction | Retest |
|----|--------|--------|------------|--------|
| P1 | injection par le tri | ___ | ___ | ___ |
| P2 | vue `v_carte_ruches` trop large | ___ | ___ | ___ |
| P3 | fuite par fonction espion | ___ | ___ | ___ |



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

