DROP VIEW IF EXISTS v_export_bailleur;
DROP TABLE IF EXISTS cle_pseudonymisation;
DROP MATERIALIZED VIEW IF EXISTS synthese_site_jour;

-- 7.2
CREATE MATERIALIZED VIEW synthese_site_jour AS
SELECT r.site_id,
       (m.horodatage AT TIME ZONE 'UTC')::date AS jour,
       count(*) AS nb_mesures,
       avg(m.poids_kg) AS poids_moyen,
       min(m.poids_kg) AS poids_min,
       min(m.batterie_pct) AS batterie_min
FROM mesure m
JOIN ruche r ON r.id = m.ruche_id
GROUP BY r.site_id, (m.horodatage AT TIME ZONE 'UTC')::date;

CREATE UNIQUE INDEX synthese_site_jour_pk ON synthese_site_jour (site_id, jour);

-- 7.3
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE cle_pseudonymisation (
    id  int PRIMARY KEY CHECK (id = 1),
    cle text NOT NULL
);

INSERT INTO cle_pseudonymisation VALUES (1, encode(gen_random_bytes(32), 'hex'));
REVOKE ALL ON cle_pseudonymisation FROM PUBLIC;

CREATE VIEW v_export_bailleur AS
SELECT left(encode(hmac(a.id::text, k.cle, 'sha256'), 'hex'), 12) AS apicultrice_pseudo,
       s.pays,
       s.nom AS site,
       round(r.latitude, 1) AS latitude,
       round(r.longitude, 1) AS longitude,
       sum(rc.quantite_kg) FILTER (WHERE rc.statut = 'validée') AS recolte_validee_kg
FROM ruche r
JOIN apicultrice a ON a.id = r.apicultrice_id
JOIN site s ON s.id = r.site_id
LEFT JOIN recolte rc ON rc.ruche_id = r.id
CROSS JOIN cle_pseudonymisation k
GROUP BY 1, 2, 3, 4, 5;

-- Tests du lab 7 : les poids, les temps et les pseudonymes (clé tirée au hasard) changent à chaque fois.

-- 7.2 Le même tableau de bord dans la vue matérialisée
SELECT * FROM synthese_site_jour
WHERE site_id = 'SN-CASA' ORDER BY jour DESC LIMIT 3;
-- Résultat : les mêmes chiffres qu'en 7.1 (moyenne non arrondie)
--  SN-CASA | 2027-03-13 | 192 | 32.6007812500000000 | 30.01 | 90

EXPLAIN ANALYZE
SELECT * FROM synthese_site_jour
WHERE site_id = 'SN-CASA' ORDER BY jour DESC LIMIT 3;
-- Résultat : Index Scan Backward using synthese_site_jour_pk, Execution Time entre 0.015 et 0.028 ms

-- 7.2 Le vol (UC-CY04) : SN-CASA-014 à la place de SN-CASA-011, qui n'existe pas chez nous
BEGIN;
INSERT INTO mesure (ruche_id, horodatage, poids_kg, batterie_pct)
SELECT id, '2027-03-15 06:00+00', 8.40, 90 FROM ruche WHERE code = 'SN-CASA-014';
SELECT * FROM synthese_site_jour
WHERE site_id = 'SN-CASA' ORDER BY jour DESC LIMIT 2;
REFRESH MATERIALIZED VIEW CONCURRENTLY synthese_site_jour;
SELECT * FROM synthese_site_jour
WHERE site_id = 'SN-CASA' ORDER BY jour DESC LIMIT 2;
ROLLBACK;
-- Résultat : INSERT 0 1
--  avant le REFRESH : 13 et 12 mars, pas de 15 mars
--  après le REFRESH : SN-CASA | 2027-03-15 | 1 | 8.40 | 8.40 | 90, puis le 13 mars

-- 7.3 Casser un haché simple : Awa Diop (Fatou Ba dans l'énoncé)
SELECT nom, encode(sha256(convert_to(telephone, 'UTF8')), 'hex') AS pseudo
FROM apicultrice WHERE telephone = '+221 77 100 00 02';
-- Résultat : Awa Diop | ef9a4fc1992b103c9ba32f3987851d1e17d7c95031fb7423593b37b274f83051

\timing on
SELECT '+221 77 1' || substr(to_char(n, 'FM000000'), 1, 2) || ' '
       || substr(to_char(n, 'FM000000'), 3, 2) || ' '
       || substr(to_char(n, 'FM000000'), 5, 2) AS telephone_retrouve
FROM generate_series(0, 999999) AS n
WHERE encode(sha256(convert_to('+221 77 1' || substr(to_char(n, 'FM000000'), 1, 2) || ' '
       || substr(to_char(n, 'FM000000'), 3, 2) || ' '
       || substr(to_char(n, 'FM000000'), 5, 2), 'UTF8')), 'hex')
    = 'ef9a4fc1992b103c9ba32f3987851d1e17d7c95031fb7423593b37b274f83051';
\timing off
-- Résultat : +221 77 100 00 02, en 2,1 s (Durée : 2146,899 ms)

-- 7.3 L'export du bailleur
SELECT * FROM v_export_bailleur ORDER BY pays, site, latitude;
-- Résultat : 8 lignes pour 11 ruches, sans nom ni téléphone
--  438c3d939d95 | Cameroun      | Bafoussam |  5.5 |  10.4 |
--  283c00c959f6 | Côte d'Ivoire | Bouaké    |  7.7 |  -5.0 |
--  946cd5dc3520 | Côte d'Ivoire | Bouaké    |  7.7 |  -5.0 |
--  8c9627f523fe | Sénégal       | Casamance | 12.5 | -16.3 |
--  c520855fa486 | Sénégal       | Casamance | 12.6 | -16.3 |
--  e0da04e9221b | Sénégal       | Casamance | 12.6 | -16.3 | 42.50
--  5532b27b6181 | Sénégal       | Kolda     | 12.9 | -14.9 |
--  3c4060ad575f | Sénégal       | Kolda     | 12.9 | -15.0 |

SELECT position((SELECT cle FROM cle_pseudonymisation) IN definition) > 0 AS contient_la_cle
FROM pg_views WHERE viewname = 'v_export_bailleur';
-- Résultat : f (la clé n'est pas écrite dans la vue)

-- 7.4
DROP TABLE IF EXISTS journal_audit CASCADE;
CREATE TABLE journal_audit (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    horodatage  timestamptz NOT NULL DEFAULT clock_timestamp(),
    acteur      text NOT NULL,
    table_cible text NOT NULL,
    operation   text NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    ligne_id    text,
    avant       jsonb,
    apres       jsonb
);
REVOKE ALL ON journal_audit FROM PUBLIC;

-- 7.4 Le journal existe et personne d'autre que postgres n'y a accès
SELECT count(*) FROM journal_audit;
-- Résultat : 0 (il sera rempli par le trigger d'audit au lab 8)

SELECT has_table_privilege('public', 'journal_audit', 'SELECT') AS public_peut_lire;
-- Résultat : f
