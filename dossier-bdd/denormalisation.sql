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