# Annotations du MCD Queen Bee - Groupe Loïc, Alice et Victor

MCD : [`docs/mcd.png`](../docs/mcd.png) (source Mocodo : [`docs/MCD.svg`](../docs/MCD.svg)),
MLD : [`docs/mld.drawio`](../docs/mld.drawio).

## Lab 1 · Partie A : comprendre le sujet

### Question 1 : de quoi le système doit-il se souvenir ?

9 choses : site, coopérative, apicultrice, ruche, mesure, inspection, récolte, alerte, utilisateur (compte de
connexion).

Le poids, la température ou le niveau de confiance n'en sont pas : ce sont des informations sur une mesure ou une
alerte. Les deux entités sans équivalent dans GreenFarm sont RÉCOLTE (déclarée puis validée par un
coordinateur : il faut savoir qui a validé) et ALERTE (déclenchée par le système sur une ruche, avec un niveau
de confiance).

### Question 2 : que garde-t-on, et qu'est-ce qui distingue chaque chose ?

| Chose | Ce qu'on garde | Ce qui la distingue |
|-------|----------------|---------------------|
| site | nom, pays | un code lisible (SN-CASA) |
| coopérative | nom | un numéro attribué |
| apicultrice | nom, téléphone | un numéro attribué (deux « Aminata Diop » : le nom ne suffit pas) |
| ruche | code, latitude, longitude, date d'installation | un numéro attribué (le code SN-CASA-014 est aussi unique) |
| mesure | horodatage, poids, températures intérieure et extérieure, humidité, activité sonore, batterie | la ruche et l'instant |
| inspection | date, état de la colonie, présence de la reine, observations | un numéro attribué |
| récolte | date, quantité, statut, date de validation | un numéro attribué |
| alerte | type, niveau de confiance, date, statut | un numéro attribué |
| utilisateur | login, mot de passe (haché), rôle | un numéro attribué (le login devra aussi être unique) |

### Question 3 : comment sont-elles liées ?

| Lien | Dans un sens | Dans l'autre sens |
|------|--------------|-------------------|
| ruche - apicultrice | une ruche appartient à une seule apicultrice | une apicultrice possède zéro, une ou plusieurs ruches |
| site - ruche | une ruche est installée sur un seul site | un site héberge zéro, une ou plusieurs ruches |
| apicultrice - coopérative | une apicultrice adhère à une ou plusieurs coopératives | une coopérative a zéro, un ou plusieurs adhérents |
| ruche - mesure | une mesure est émise par une seule ruche | une ruche émet zéro, une ou plusieurs mesures |
| ruche - récolte | une récolte provient d'une seule ruche | une ruche produit zéro, une ou plusieurs récoltes |
| coordinateur - récolte validée | une récolte est validée par au plus un coordinateur (aucun tant qu'elle est déclarée) | un coordinateur valide zéro, une ou plusieurs récoltes |
| apicultrice - compte de connexion | une apicultrice a au plus un compte | un compte appartient au plus à une apicultrice (les comptes coordinateur et administrateur n'en ont pas) |

Autres liens du MCD : une apicultrice est rattachée à un seul site ; une coopérative appartient à un seul site ;
un compte coordinateur est rattaché à au plus un site ; une inspection concerne une seule ruche et est réalisée par
une seule apicultrice ; une alerte est déclenchée sur une seule ruche.

### Question 4 : ce que le sujet ne dit pas

| Question au client | Notre hypothèse |
|--------------------|-----------------|
| Une ruche peut-elle changer de site ? | oui, mais on ne garde que le site actuel (pas d'historique des déplacements) |
| Une ruche est-elle toujours sur le site de son apicultrice ? | oui (vérifié par le test 7 de `tests_schema.sql`, mais aucune contrainte ne l'impose) |
| Qui peut valider une récolte ? | un compte de rôle coordinateur ; la récolte garde le validateur et la date de validation |
| Une récolte validée peut-elle être modifiée ? | non : une fois validée, elle sert de preuve (verrouillage prévu au jour 2) |
| Une apicultrice peut-elle travailler sur deux sites ? | non : elle est rattachée à un seul site ; une homonyme sur un autre site est une autre personne |
| Une ruche peut-elle changer d'apicultrice ? | oui, mais on ne garde que l'apicultrice actuelle |
| Que fait-on des mesures d'un capteur remplacé ? | elles restent attachées à la ruche, pas au capteur (le capteur n'est pas une entité) |

### Question 5 : ce qui intéresserait un voleur ou un fraudeur

1. La position GPS des ruches (latitude, longitude) : retrouver les ruches isolées et les voler.
2. Le téléphone des apicultrices : hameçonnage, faux appels « de l'association », démarchage.
3. Les mesures et les récoltes (poids, quantité) : rejouer d'anciennes mesures pour masquer un vol, gonfler une
   récolte déclarée, ou la faire passer pour validée sans validateur.
4. Le login et le mot de passe : se connecter à la place d'un coordinateur pour valider ses propres récoltes.

Ces attributs sont en rouge sur le MCD.

## Lab 1 · Partie C : sensibilité et menaces (STRIDE)

Rôles : A = apicultrice, C = coordinateur de site, G = gestionnaire de l'association, Ad = administrateur.

| Entité | Sensibilité | Qui lit | Qui modifie | Menace STRIDE et ce que gagne l'attaquant |
|--------|-------------|---------|-------------|-------------------------------------------|
| SITE | interne | tous | Ad | T : changer le pays d'un site fausse les statistiques par pays (lab 5) |
| COOPÉRATIVE | interne | tous | G, Ad | T : rattacher une coopérative à un autre site pour détourner des adhésions |
| APICULTRICE | confidentielle (nom + téléphone = donnée personnelle) | A (elle-même), C (son site), G | A (son téléphone), G, Ad | I : nom et téléphone pour l'hameçonnage ; S : se faire passer pour une homonyme |
| ADHÉSION | interne | A (les siennes), C, G | G | T : adhésion antidatée pour toucher des aides |
| RUCHE | confidentielle (GPS) | A (les siennes), C (son site), G | A, C | I : connaître la position GPS pour voler la ruche |
| MESURE | interne, intégrité critique | A (ses ruches), C, G | capteurs uniquement (insertion) | T : une mesure rejouée (ancien poids renvoyé) masque un vol ou un essaimage ; D : saturer la table de fausses mesures |
| INSPECTION | interne | A, C | A (la sienne) | R : l'apicultrice nie avoir constaté la perte de la reine ; T : fausse observation |
| RÉCOLTE | critique (sert de preuve et de base aux paiements) | A (les siennes), C, G | A (déclare), C (valide) | R : une récolte validée sans qu'on sache par qui ; T : gonfler la quantité ; E : une apicultrice qui valide sa propre récolte |
| ALERTE | interne | A, C, G | système, C (résout) | T / D : clore une alerte de vol pour gagner du temps ; D : capteur coupé (alerte « capteur silencieux ») |
| UTILISATEUR | critique | Ad | Ad | S : se connecter à la place d'un autre ; E : passer son rôle à administrateur ; R : effacement de l'historique des actions (journal supprimé ou modifié, plus aucune preuve de qui a fait quoi) |

Lettres utilisées : S, T, R, I, D, E (les six). Principe : chacun ne voit que ce dont il a besoin (moindre
privilège) ; l'apicultrice ne voit que ses ruches, le coordinateur que son site.

### Testez-vous · Lab 1

1. La date d'adhésion appartient au lien entre l'apicultrice et la coopérative (association ADHÈRE).
2. Le nom n'est pas unique (deux « Aminata Diop ») et il peut changer : il ne distingue pas les personnes.
3. Le rejeu d'une ancienne mesure de poids : T (altération des données).
4. « Une ruche appartient à une seule apicultrice » : 1,1 du côté de RUCHE.

## Schéma relationnel (lab 2)

### Les quatre règles appliquées

| Table | Clé primaire | Autres colonnes | Clés étrangères (vers quelle table) |
|-------|--------------|-----------------|-------------------------------------|
| site | id (code lisible : SN-CASA) | nom, pays | aucune |
| cooperative | id (uuid) | nom | site_id (site) |
| apicultrice | id (uuid) | nom, telephone | site_id (site) |
| adhesion | (apicultrice_id, cooperative_id) | date_adhesion | apicultrice_id (apicultrice), cooperative_id (cooperative) |
| ruche | id (uuid) | code UNIQUE, latitude, longitude, date_installation | site_id (site), apicultrice_id (apicultrice) |
| mesure | id (bigint auto) | horodatage, poids_kg, temp_int_c, temp_ext_c, humidite_pct, activite_sonore, batterie_pct | ruche_id (ruche) |
| inspection | id (uuid) | date_inspection, etat_colonie, presence_reine, observations | ruche_id (ruche), apicultrice_id (apicultrice) |
| utilisateur | id (uuid) | login, mot_de_passe_hash, role | site_id (site), apicultrice_id UNIQUE (apicultrice) |
| recolte | id (uuid) | date_recolte, quantite_kg, statut, date_validation | ruche_id (ruche), validee_par (utilisateur) |
| alerte | id (uuid) | type_alerte, niveau_confiance, date_alerte, statut | ruche_id (ruche) |

- Règle 1 (entité -> table) : 9 tables, une par entité. Le site garde un code lisible (court, stable, pas secret) ; tout ce que
  l'application exposera a un UUID, qui ne se devine pas (`/ruches/42` -> `/ruches/43` ne marche pas). La mesure,
  jamais exposée seule et très volumineuse, a un identifiant séquentiel.
- Règle 2 (1,1 - 0,n -> clé étrangère côté 1,1) : `site_id` dans cooperative, apicultrice, ruche ;
  `apicultrice_id` dans ruche et inspection ; `ruche_id` dans mesure, inspection, recolte, alerte ; `validee_par`
  dans recolte (0,1 : nullable tant que la récolte est déclarée) ; `site_id` dans utilisateur (0,1 : nullable).
- Règle 3 (n,n -> table) : ADHÈRE devient la table adhesion, clé primaire (apicultrice_id,
  cooperative_id), avec date_adhesion.
- Règle 4 (0,1 - 0,1 -> clé étrangère UNIQUE) : `utilisateur.apicultrice_id UNIQUE` : une apicultrice n'a
  jamais deux comptes.

Total : 10 tables, 14 clés étrangères, toutes nommées `table_colonne_fk`.

### Règles de sécurité dans le schéma

| Règle | Ce qu'elle refuse |
|-------|-------------------|
| `ruche.code UNIQUE` | deux ruches avec le même code |
| `mesure_anti_rejeu UNIQUE (ruche_id, horodatage)` | une mesure rejouée |
| `CHECK (quantite_kg >= 0)` | une récolte négative |
| `recolte_validation_complete` | une récolte « validée » sans validateur ni date |
| `CHECK (niveau_confiance BETWEEN 0 AND 100)` | un niveau de confiance absurde |
| `CHECK (role IN (...))`, `CHECK (statut IN (...))` | un rôle ou un statut inventé |

### Relancer `donnees.sql` une seconde fois

Le script est refusé dès la première insertion : `ERREUR: la valeur d'une clé dupliquée rompt la contrainte
unique « site_pkey »` (la clé SN-CASA existe déjà). Grâce à `BEGIN; ... COMMIT;`, rien n'est enregistré : la base ne contient pas de
doublons. Plus loin, `ruche.code UNIQUE` et `mesure_anti_rejeu` auraient aussi refusé.

### Testez-vous · Lab 2

1. La clé étrangère d'une association 1,1 - 0,n va dans la table du côté 1,1 (la ruche garde `apicultrice_id`).
2. La clé primaire d'une table d'association réunit les deux clés étrangères : un couple (apicultrice,
   coopérative) n'existe qu'une fois, et aucune des deux colonnes seule n'est unique.
3. `UNIQUE (ruche_id, horodatage)` protège contre le rejeu : une même mesure ne peut pas être reçue deux fois.
4. `site` est créée avant `ruche` parce que `REFERENCES site(id)` exige que la table visée existe déjà.
