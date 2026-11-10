# Dépendances fonctionnelles – Groupe Loïc, Alice et Victor

La table de travail est `extrait_plat` (528 lignes, 10 colonnes) : `ruche_code`, `site_id`, `site_nom`, `pays`,
`apicultrice`, `telephone`, `cooperative`, `horodatage`, `poids_kg`, `temp_int_c`.

## Les DF de extrait_plat

| DF | En français |
|-------------------------------|-------------|
| site_id -> site_nom, pays | un site a un seul nom et un seul pays |
| ruche_code -> site_id, site_nom, pays, apicultrice, telephone, cooperative | une ruche est installée sur un seul site et appartient à une seule apicultrice (qui a un seul téléphone et une coopérative) |
| telephone -> apicultrice, cooperative | un numéro de téléphone désigne une seule apicultrice, rattachée à une seule coopérative |
| ruche_code, horodatage -> poids_kg, temp_int_c | une seule mesure par ruche et par instant (c'est la règle anti-rejeu) |

Hypothèses derrière ces DF (à rappeler dans le rendu) :
- une ruche est sur le même site que son apicultrice (hypothèse du lab 1) ;
- dans le jeu d'essai, chaque apicultrice adhère à **une seule** coopérative, celle de son site. Le MCD autorise
  plusieurs coopératives (association n,n) : `telephone -> cooperative` est donc une règle du jeu d'essai, pas une
  loi du modèle. Si une apicultrice pouvait adhérer à deux coopératives, il faudrait la retirer et garder
  `adhesion` comme table à part ;
- deux apicultrices n'ont jamais le même téléphone.

Fausse dépendance, volontairement écartée : `apicultrice -> telephone` (le nom ne détermine pas la personne :
deux « Aminata Diop », une à Casamance, une à Kolda, avec deux téléphones différents).

## Fermetures et clé candidate

Colonnes (10) : ruche_code, site_id, site_nom, pays, apicultrice, telephone, cooperative, horodatage, poids_kg, temp_int_c.

### {site_id}⁺

| Tour | DF utilisée | {site_id}⁺ |
|------|-------------|------------|
| 0 | aucune | {site_id} |
| 1 | site_id → site_nom, pays | + site_nom, pays |
| 2 | plus rien ne s'ajoute | 3 colonnes sur 10 : **pas une clé** |

### {ruche_code}⁺

| Tour | DF utilisée | {ruche_code}⁺ |
|------|-------------|---------------|
| 0 | aucune | {ruche_code} |
| 1 | ruche_code → site_id, site_nom, pays, apicultrice, telephone, cooperative | + site_id, site_nom, pays, apicultrice, telephone, cooperative |
| 2 | site_id → …, telephone → … | rien de nouveau (déjà présents) |
| 3 | plus rien ne s'ajoute | 7 colonnes sur 10 : **pas une clé** (manquent horodatage, poids_kg, temp_int_c) |

### {ruche_code, horodatage}⁺

| Tour | DF utilisée | {ruche_code, horodatage}⁺ |
|------|-------------|---------------------------|
| 0 | aucune | {ruche_code, horodatage} |
| 1 | ruche_code → site_id, site_nom, pays, apicultrice, telephone, cooperative | + site_id, site_nom, pays, apicultrice, telephone, cooperative |
| 2 | ruche_code, horodatage → poids_kg, temp_int_c | + poids_kg, temp_int_c |
| 3 | plus rien ne s'ajoute | **10 colonnes sur 10 : clé** |

### Clé candidate

**{ruche_code, horodatage}** est la clé candidate, et c'est la seule.
On ne peut rien en retirer :
- sans `horodatage`, {ruche_code}⁺ ne contient que 7 colonnes : les mesures (poids, température) manquent, et chaque
  ruche a 48 lignes ;
- sans `ruche_code`, {horodatage}⁺ = {horodatage} : une même heure existe pour les 11 ruches, rien n'est déterminé.

Vérifié sur les données : aucun doublon sur le couple (`ruche_code`, `horodatage`) ; 528 lignes pour 11 ruches.

## Confrontation aux données (étape 4.3)

Les requêtes sont dans `contraintes.sql`. Résultat : 0 ligne pour chacune des quatre DF ; la fausse
`apicultrice -> telephone` renvoie « Aminata Diop » avec 2 téléphones.

**Que se passerait-il si l'application identifiait les apicultrices par leur nom ?**
Les deux « Aminata Diop » seraient confondues : leurs ruches, leurs inspections et leurs comptes seraient mélangés.
Une apicultrice verrait, ou modifierait, les données de l'autre site (S, E, I selon STRIDE), et une récolte ou une
inspection ne pourrait plus être attribuée à une personne précise (R). Un regroupement sur le nom compterait aussi
les ruches des deux personnes ensemble. Il faut identifier par l'`id` (clé primaire), jamais par le nom.

## Logins uniques (étape 4.4)

Le jeu d'essai produit trois `a.diop` (Aminata Diop Casamance, Awa Diop, Aminata Diop Kolda). `UNIQUE (login)` est
refusé tant que les doublons existent. Après correction (`aminata.diop.casa`, `aminata.diop.kold`, `a.diop` pour Awa),
la contrainte passe. `A.Diop` passe encore (la majuscule rend la valeur différente) ; l'index unique sur
`lower(login)` le refuse.
