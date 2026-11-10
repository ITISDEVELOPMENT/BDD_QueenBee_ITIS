# BDD_QueenBee_ITIS

Base de données PostgreSQL du projet Queen Bee (association BeeAfrica : suivi de ruches connectées au Sénégal,
en Côte d'Ivoire et au Cameroun), réalisée en TP de base de données.

## Organisation

- `docs/` : MCD (`mcd.png`, `MCD.svg`) et MLD (`mld.drawio`)
- `dossier-bdd/` : les scripts SQL et Python du jour 1, et le dossier de conception du jour 2
  - `jour2/` : le jour 2, en 5 parties (voir `dossier-bdd/jour2/README.md`)
    - `1_schema_normalise/` : labs 6 et 7, et le schéma complet exporté (`schema_j2.sql`)
    - `2_roles_privileges/` : lab 8 (rôles, vues, tests de contournement)
    - `3_trigger_audit/` : lab 8.3 (journal d'audit et ses tests)
    - `4_test_concurrence/` : lab 9 (transactions, course au jeton, sauvegarde)
    - `5_revue_securite/` : lab 10 (revue de sécurité)
- `dossier-md/` : nos réponses du jour 1
  - `annotations.md` : labs 1 et 2 (MCD, MLD, STRIDE)
  - `dependances.md` et `normalisation.md` : labs 4 et 5
- `images/` : les captures d'écran citées dans les `.md`

## Construire la base

Depuis `dossier-bdd/`, avec PostgreSQL 18 :

```bash
psql -h localhost -U postgres -d postgres -c "CREATE DATABASE queenbee;"
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f schema.sql -f donnees.sql
psql -h localhost -U postgres -d queenbee -f jour2/1_schema_normalise/formation.sql
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f jour2/1_schema_normalise/volume.sql \
  -f jour2/1_schema_normalise/denormalisation.sql -f jour2/1_schema_normalise/references.sql
psql -h localhost -U postgres -d queenbee -f jour2/1_schema_normalise/check.sql
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f jour2/3_trigger_audit/audit.sql
psql -h localhost -U postgres -d queenbee -f jour2/2_roles_privileges/roles.sql
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f jour2/4_test_concurrence/jeton.sql \
  -f jour2/5_revue_securite/corrections.sql
```

`formation.sql` et `check.sql` se lancent sans `ON_ERROR_STOP` : leurs tests, à la fin du fichier, contiennent des
commandes qui doivent être refusées. `roles.sql` aussi : les rôles sont communs à tout le serveur, donc si la base est
reconstruite, ses `CREATE ROLE` répondent « existe déjà » et le reste du fichier passe.

L'ordre compte : `denormalisation.sql` recrée `journal_audit` (`DROP TABLE ... CASCADE`). Si on le relance après
`audit.sql`, le journal est vidé et perd ses triggers de protection, et les droits donnés par `roles.sql` sur les
vues du lab 7 disparaissent : il faut alors relancer `audit.sql` puis `roles.sql`. De même, `roles.sql` recrée les
vues et efface leur `security_barrier` : après lui, il faut toujours relancer `corrections.sql`.

| Fichier | Contenu |
|---|---|
| `schema.sql` | les tables du jour 1 |
| `donnees.sql` | le jeu d'essai (4 sites, 8 apicultrices, 11 ruches, 528 mesures) |
| `jour2/1_schema_normalise/formation.sql` | lab 6 : `formation_plat`, découpage BCNF, triggers, puis les tests du lab 6 |
| `jour2/1_schema_normalise/volume.sql` | 7.1 : 90 jours de mesures (47 520 lignes), à ne lancer qu'une fois, puis les tests du 7.1 |
| `jour2/1_schema_normalise/denormalisation.sql` | 7.2 à 7.4 : vue matérialisée, export pseudonymisé, journal d'audit, puis leurs tests |
| `jour2/1_schema_normalise/references.sql` | 8.1 : `ON DELETE CASCADE` sur les adhésions, `RESTRICT` sur les preuves |
| `jour2/1_schema_normalise/check.sql` | 8.2 : contraintes `CHECK` sur les mesures, rôles et statuts |
| `jour2/3_trigger_audit/audit.sql` | 8.3 : trigger d'audit sur `recolte` et `utilisateur`, journal en ajout seul |
| `jour2/2_roles_privileges/roles.sql` | 8.4 et 8.5 : logins uniques, 4 groupes et 5 comptes, fermeture à `PUBLIC`, vues de moindre privilège, droits et `valider_recolte` |
| `jour2/4_test_concurrence/jeton.sql` | 9.2 à 9.4 : tables `jeton` et `session_app`, 30 jetons pour f.ba, contrainte `UNIQUE (jeton_id)` |
| `jour2/5_revue_securite/corrections.sql` | 10.2 et 10.3 : vue de carte réécrite, `security_barrier` sur les vues filtrantes, `REVOKE TEMPORARY` |

Tous les fichiers se relancent, sauf `volume.sql` : la contrainte anti-rejeu de `mesure` refuse les doublons.

## Les tests

Le résultat attendu est en commentaire sous chaque requête. Ceux qui doivent être refusés se lancent sans
`ON_ERROR_STOP`.

Jour 1, dans `dossier-bdd/` :

- `tests_schema.sql` : lab 2
- `requetes.sql`, `query_vuln.py`, `query.py` : lab 3 (requêtes et injection SQL)
- `plat.sql`, `contraintes.sql` : lab 4
- `anomalies.sql`, `migration_3nf.sql`, `preuve.sql` : lab 5

Jour 2, dans `dossier-bdd/jour2/` :

- à la fin de `formation.sql`, `volume.sql`, `denormalisation.sql`, `references.sql`, `check.sql` et `roles.sql`
- `3_trigger_audit/tests_audit.sql` : lab 8.3, la trace d'une modification et les trois effacements refusés. Chaque
  lancement ajoute une ligne au journal (il modifie une récolte), ce qui est voulu : le journal ne peut pas être vidé.
- `2_roles_privileges/tests_contournement.sql` : lab 8.6, les 12 tentatives de contournement (lancé en `postgres`,
  après `roles.sql`). Il modifie la base exprès : chaque lancement ajoute une récolte validée et deux lignes au journal.
- `4_test_concurrence/course_jeton.py` et `course_jeton_corrige.py` : lab 9.3, deux requêtes simultanées avec le même
  jeton (`python3 course_jeton.py RT-f.ba-10`, avec `PGUSER`, `PGPASSWORD` et `PGHOST` définis). Chaque lancement
  consomme le jeton donné.
- `5_revue_securite/recherche_vuln.py` et `recherche.py` : lab 10.1, l'injection par le tri, puis la version
  corrigée (liste blanche et `sql.Identifier`).
- `5_revue_securite/grille.sql` : lab 10.3, la grille de contrôle de la base (C1 à C7 et C10).

## Sauvegarde

`dossier-bdd/jour2/4_test_concurrence/queenbee_j2.dump.sha256` est l'empreinte de la sauvegarde du lab 9.5. La sauvegarde
elle-même (`queenbee_j2.dump`) n'est pas dans le dépôt : elle contient des données personnelles (`*.dump` dans
`.gitignore`). Pour la vérifier, depuis ce dossier : `sha256sum -c queenbee_j2.dump.sha256`.
