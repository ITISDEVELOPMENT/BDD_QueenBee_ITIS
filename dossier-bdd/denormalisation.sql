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
