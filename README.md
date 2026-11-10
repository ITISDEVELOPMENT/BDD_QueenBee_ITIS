# BDD_QueenBee_ITIS

Base de données PostgreSQL du projet Queen Bee (association BeeAfrica : suivi de ruches connectées au Sénégal,
en Côte d'Ivoire et au Cameroun), réalisée en TP de base de données.

## Organisation

- `docs/` : MCD (`mcd.png`, `MCD.svg`) et MLD (`mld.drawio`)
- `dossier-bdd/` : les scripts SQL
- `dossier-md/` : nos réponses
  - `annotations.md` : jour 1, labs 1 et 2 (MCD, MLD, STRIDE)
  - `dependances.md` et `normalisation.md` : jour 1, labs 4 et 5
  - `normalisation_j2.md` : jour 2, labs 6 et 7
  - `matrice_droits.md` : jour 2, lab 8 (droits et limites du journal)
- `images/` : les captures d'écran citées dans les `.md`

## Construire la base

Depuis `dossier-bdd/`, avec PostgreSQL 18 :

```bash
psql -h localhost -U postgres -d postgres -c "CREATE DATABASE queenbee;"
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f schema.sql -f donnees.sql
psql -h localhost -U postgres -d queenbee -f formation.sql
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f volume.sql -f denormalisation.sql -f references.sql
psql -h localhost -U postgres -d queenbee -f check.sql
psql -h localhost -U postgres -d queenbee -f audit.sql
psql -h localhost -U postgres -d queenbee -f roles.sql
```

`formation.sql`, `check.sql` et `audit.sql` se lancent sans `ON_ERROR_STOP` : leurs tests, à la fin du fichier,
contiennent des commandes qui doivent être refusées. `roles.sql` aussi : les rôles sont communs à tout le serveur,
donc si la base est reconstruite, ses `CREATE ROLE` répondent « existe déjà » et le reste du fichier passe.

L'ordre compte : `denormalisation.sql` recrée `journal_audit` (`DROP TABLE ... CASCADE`). Si on le relance après
`audit.sql`, le journal est vidé et perd ses triggers de protection, et les droits donnés par `roles.sql` sur les
vues du lab 7 disparaissent : il faut alors relancer `audit.sql` puis `roles.sql`.

| Fichier | Contenu |
|---|---|
| `schema.sql` | les tables du jour 1 |
| `donnees.sql` | le jeu d'essai (4 sites, 8 apicultrices, 11 ruches, 528 mesures) |
| `formation.sql` | lab 6 : `formation_plat`, découpage BCNF, triggers, puis les tests du lab 6 |
| `volume.sql` | 7.1 : 90 jours de mesures (47 520 lignes), à ne lancer qu'une fois, puis les tests du 7.1 |
| `denormalisation.sql` | 7.2 à 7.4 : vue matérialisée, export pseudonymisé, journal d'audit, puis leurs tests |
| `references.sql` | 8.1 : `ON DELETE CASCADE` sur les adhésions, `RESTRICT` sur les preuves |
| `check.sql` | 8.2 : contraintes `CHECK` sur les mesures, rôles et statuts |
| `audit.sql` | 8.3 : trigger d'audit sur `recolte` et `utilisateur`, journal en ajout seul |
| `roles.sql` | 8.4 : logins uniques, 4 groupes et 5 comptes, fermeture à `PUBLIC`, vues de moindre privilège et droits |

Tous les fichiers se relancent, sauf `volume.sql` : la contrainte anti-rejeu de `mesure` refuse les doublons.
`audit.sql` ajoute une ligne au journal à chaque lancement (son test modifie une récolte), ce qui est voulu : le
journal ne peut pas être vidé.

## Les tests

Le résultat attendu est en commentaire sous chaque requête. Ceux qui doivent être refusés se lancent sans
`ON_ERROR_STOP`.

- `tests_schema.sql` : jour 1, lab 2
- `requetes.sql`, `query_vuln.py`, `query.py` : jour 1, lab 3 (requêtes et injection SQL)
- `plat.sql`, `contraintes.sql` : jour 1, lab 4
- `anomalies.sql`, `migration_3nf.sql`, `preuve.sql` : jour 1, lab 5
- jour 2 : à la fin de chaque fichier (`formation.sql`, `volume.sql`, `denormalisation.sql`, `references.sql`,
  `check.sql`, `audit.sql`, `roles.sql`)
