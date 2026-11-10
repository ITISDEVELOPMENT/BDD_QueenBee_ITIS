-- 7.2
CREATE MATERIALIZED VIEW synthese_site_jour AS
SELECT site_id, jour, nb_mesures, poids_moyen, poids_min, batterie_min
FROM (
    SELECT site_id, 
           DATE(horodatage) AS jour,
           COUNT(*) AS nb_mesures,
           AVG(poids_kg) AS poids_moyen,
           MIN(poids_kg) AS poids_min,
           MIN(batterie_pct) AS batterie_min
    FROM mesure
    GROUP BY site_id, DATE(horodatage)
);
CREATE UNIQUE INDEX synthese_site_jour_idx ON synthese_site_jour(site_id, jour);
EXPLAIN ANALYZE;

--7.3
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE cle_pseudonymisation (
  id  int PRIMARY KEY CHECK (id = 1),
  cle text NOT NULL
);

INSERT INTO cle_pseudonymisation VALUES (1, encode(gen_random_bytes(32), 'hex'));
REVOKE ALL ON cle_pseudonymisation FROM PUBLIC;
 
CREATE VIEW v_export_bailleur AS
SELECT left(encode(hmac(e.id::text, k.cle, 'sha256'), 'hex'), 12) AS bailleur_pseudo
FROM exploitant e
CROSS JOIN cle_pseudonymisation k;