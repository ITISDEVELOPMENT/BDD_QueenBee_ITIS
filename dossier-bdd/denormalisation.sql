-- 7.2
CREATE MATERIALIZED VIEW synthese_site_jour AS
SELECT r.site_id,
       (m.horodatage AT TIME ZONE 'UTC')::date AS jour,
       count(*)            AS nb_mesures,
       avg(m.poids_kg)     AS poids_moyen,
       min(m.poids_kg)     AS poids_min,
       min(m.batterie_pct) AS batterie_min
FROM mesure m
JOIN ruche r ON r.id = m.ruche_id
GROUP BY r.site_id, (m.horodatage AT TIME ZONE 'UTC')::date;

CREATE UNIQUE INDEX synthese_site_jour_pk ON synthese_site_jour (site_id, jour);

--7.3
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE cle_pseudonymisation (
  id  int PRIMARY KEY CHECK (id = 1),
  cle text NOT NULL
);

INSERT INTO cle_pseudonymisation VALUES (1, encode(gen_random_bytes(32), 'hex'));
REVOKE ALL ON cle_pseudonymisation FROM PUBLIC;
 
CREATE VIEW v_export_bailleur AS
SELECT left(encode(hmac(a.id::text, k.cle, 'sha256'), 'hex'), 12) AS apicultrice_id_pseudo, pays
       r.code AS ruche_code,
       (m.horodatage AT TIME ZONE 'UTC')::date AS jour,
       count(*)            AS nb_mesures,
       avg(m.poids_kg)     AS poids_moyen,
       min(m.poids_kg)     AS poids_min,
       min(m.batterie_pct) AS batterie_min;