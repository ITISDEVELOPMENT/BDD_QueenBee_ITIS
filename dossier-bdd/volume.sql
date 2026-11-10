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