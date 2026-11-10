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
- `images/` : les captures d'écran citées dans les `.md`

## Construire la base

Depuis `dossier-bdd/`, avec PostgreSQL 18 :

```bash
psql -h localhost -U postgres -d postgres -c "CREATE DATABASE queenbee;"
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f schema.sql -f donnees.sql
psql -h localhost -U postgres -d queenbee -f formation.sql
psql -h localhost -U postgres -d queenbee -v ON_ERROR_STOP=1 -f volume.sql -f denormalisation.sql
```

`formation.sql` se lance sans `ON_ERROR_STOP` : ses tests, à la fin du fichier, contiennent deux insertions qui
doivent être refusées par les triggers.

| Fichier | Contenu |
|---|---|
| `schema.sql` | les tables du jour 1 |
| `donnees.sql` | le jeu d'essai (4 sites, 8 apicultrices, 11 ruches, 528 mesures) |
| `formation.sql` | lab 6 : `formation_plat`, découpage BCNF, triggers, puis les tests du lab 6 |
| `volume.sql` | 7.1 : 90 jours de mesures (47 520 lignes), à ne lancer qu'une fois, puis les tests du 7.1 |
| `denormalisation.sql` | 7.2 et 7.3 : vue matérialisée, export pseudonymisé, puis leurs tests |

`schema.sql`, `formation.sql` et `denormalisation.sql` se relancent sans erreur. `volume.sql` non : la contrainte
anti-rejeu de `mesure` refuse les doublons.

## Les tests

Le résultat attendu est en commentaire sous chaque requête. Ceux qui doivent être refusés se lancent sans
`ON_ERROR_STOP`.

- `tests_schema.sql` : jour 1, lab 2
- `requetes.sql`, `query_vuln.py`, `query.py` : jour 1, lab 3 (requêtes et injection SQL)
- `plat.sql`, `contraintes.sql` : jour 1, lab 4
- `anomalies.sql`, `migration_3nf.sql`, `preuve.sql` : jour 1, lab 5
- jour 2 : à la fin de `formation.sql`, `volume.sql` et `denormalisation.sql`
