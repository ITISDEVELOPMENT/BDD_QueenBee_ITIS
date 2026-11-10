-- 7.1
INSERT INTO mesure (ruche_id, horodatage, poids_kg, temp_int_c, temp_ext_c,
                    humidite_pct, activite_sonore, batterie_pct)
SELECT r.id,
       TIMESTAMPTZ '2026-12-14 00:00:00+00' + h * INTERVAL '30 minutes',
       round((30 + random() * 5)::numeric, 2),
       round((34 + random() - 0.5)::numeric, 1),
       round((22 + random() * 8)::numeric, 1),
       55 + floor(random() * 20)::int,
       30 + floor(random() * 40)::int,
       90
FROM ruche r
CROSS JOIN generate_series(0, 90 * 48 - 1) AS h;
ANALYZE mesure;

-- Tests du 7.1 (le temps change à chaque essai)

-- 7.1 Tableau de bord du gestionnaire (UC-G01) sur la table mesure
SELECT r.site_id,
       (m.horodatage AT TIME ZONE 'UTC')::date AS jour,
       count(*) AS nb_mesures,
       round(avg(m.poids_kg), 2) AS poids_moyen,
       min(m.poids_kg) AS poids_min,
       min(m.batterie_pct) AS batterie_min
FROM mesure m
JOIN ruche r ON r.id = m.ruche_id
WHERE r.site_id = 'SN-CASA'
GROUP BY 1, 2
ORDER BY jour DESC
LIMIT 3;
-- Résultat : 3 lignes (13, 12 et 11 mars 2027), 192 mesures par jour (4 ruches x 48)
--  SN-CASA | 2027-03-13 | 192 | 32.60 | 30.01 | 90

EXPLAIN ANALYZE
SELECT r.site_id,
       (m.horodatage AT TIME ZONE 'UTC')::date AS jour,
       count(*) AS nb_mesures,
       round(avg(m.poids_kg), 2) AS poids_moyen,
       min(m.poids_kg) AS poids_min,
       min(m.batterie_pct) AS batterie_min
FROM mesure m
JOIN ruche r ON r.id = m.ruche_id
WHERE r.site_id = 'SN-CASA'
GROUP BY 1, 2
ORDER BY jour DESC
LIMIT 3;
-- Résultat : Seq Scan on mesure (les 48048 lignes sont lues), Execution Time entre 15 et 46 ms selon les essais
