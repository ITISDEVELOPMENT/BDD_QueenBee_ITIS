# Queen Bee – Dossier de conception, jour 2 – Groupe Loïc, Alice et Victor

## Les 5 parties

1. Schéma normalisé : `1_schema_normalise/` (schéma complet exporté dans `schema_j2.sql`, labs 6 et 7, `ON DELETE`
   et `CHECK` du lab 8)
2. Rôles et privilèges : `2_roles_privileges/` (4 rôles, 7 vues filtrantes, 1 fonction de validation :
   `valider_recolte`)
3. Trigger d'audit : `3_trigger_audit/` (tables auditées : `recolte` et `utilisateur`)
4. Test de concurrence : `4_test_concurrence/` (2 sessions avant, 1 après)
5. Revue de sécurité : `5_revue_securite/` (7 constats : 3 failles démontrées et 4 constats de grille ; 5 corrigés,
   2 discutés)

## Reconstruire (après la base du jour 1)

Depuis `dossier-bdd/` :

```bash
psql -h localhost -U postgres -d queenbee -f jour2/1_schema_normalise/formation.sql
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f jour2/1_schema_normalise/volume.sql \
  -f jour2/1_schema_normalise/denormalisation.sql -f jour2/1_schema_normalise/references.sql
psql -h localhost -U postgres -d queenbee -f jour2/1_schema_normalise/check.sql
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f jour2/3_trigger_audit/audit.sql
psql -h localhost -U postgres -d queenbee -f jour2/2_roles_privileges/roles.sql
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f jour2/4_test_concurrence/jeton.sql \
  -f jour2/5_revue_securite/corrections.sql
```

1. formation.sql   2. volume.sql (une fois)   3. denormalisation.sql   4. references.sql puis check.sql
5. audit.sql   6. roles.sql   7. jeton.sql   8. corrections.sql

`formation.sql`, `check.sql` et `roles.sql` se lancent sans `ON_ERROR_STOP` : `formation.sql` et `check.sql`
finissent par des tests qui doivent être refusés, et les `CREATE ROLE` de `roles.sql` répondent « existe déjà » si
les rôles ont déjà été créés sur le serveur. `corrections.sql` passe toujours après `roles.sql`, qui recrée les vues
et efface leur `security_barrier`.

## Nos choix principaux

- **BCNF + trigger pour les formations** : on découpe `formation_plat` en `formateur` et `suivi_formation` pour que
  « un formateur, un thème » soit garanti par `UNIQUE`, et un trigger rétablit la règle perdue (un seul formateur
  par thème pour une apicultrice).
- **La synthèse est rafraîchie la nuit, le vol est détecté sur les mesures brutes** : la vue matérialisée rend le
  tableau de bord 1 600 fois plus rapide, mais un vol n'y apparaît qu'au prochain `REFRESH`.
- **Un export pseudonymisé par HMAC** : le bailleur a des chiffres, sans nom, sans téléphone et avec une position
  arrondie à 11 km ; la clé est dans une table fermée à tous.
- **La base fait respecter les règles** : `RESTRICT` sur les preuves, `CHECK` sur les valeurs, journal en ajout seul,
  vues de moindre privilège avec `security_barrier`, et `UNIQUE (jeton_id)` contre la course au jeton.

## Limites connues

- Un superutilisateur peut désactiver les triggers du journal : le journal doit aussi être copié hors de la base,
  vers le SIEM du cahier des charges.
- Le trigger du lab 6 est un « vérifier, puis agir » : deux insertions simultanées peuvent le contourner.
- Les mots de passe des 5 comptes de démonstration sont en clair dans `roles.sql` (constat R3).
- La synthèse est en retard jusqu'au prochain rafraîchissement.
