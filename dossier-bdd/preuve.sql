-- Vue qui recompose extrait_plat
CREATE OR REPLACE VIEW norm.reconstruit AS
SELECT r.ruche_code, s.site_id, s.site_nom, s.pays,
       a.apicultrice, a.telephone, a.cooperative,
       m.horodatage, m.poids_kg, m.temp_int_c
FROM norm.mesure m
JOIN norm.ruche r        USING (ruche_code)
JOIN norm.site s         USING (site_id)
JOIN norm.apicultrice a  USING (telephone);

-- Sans perte : attendu 0 ligne
(SELECT * FROM extrait_plat EXCEPT SELECT * FROM norm.reconstruit)
UNION ALL
(SELECT * FROM norm.reconstruit EXCEPT SELECT * FROM extrait_plat);

-- Second pays pour un site existant : refusé
INSERT INTO norm.site VALUES (2, 'Kolda', 'Senegal');

-- Site sans ruche : accepté (annulé ensuite)
BEGIN;
INSERT INTO norm.site VALUES (5, 'Douala', 'Cameroun');
ROLLBACK;

-- Enquête par pays : attendu 3 pays
SELECT s.pays, count(*) AS nb_mesures, round(avg(m.poids_kg), 2) AS poids_moyen
FROM norm.mesure m
JOIN norm.ruche r USING (ruche_code)
JOIN norm.site s  USING (site_id)
GROUP BY s.pays ORDER BY s.pays;
