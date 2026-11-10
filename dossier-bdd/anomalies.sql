-- Avant : relancer plat.sql. Exécuter ensuite chaque commande une par une.

-- 1. Mise à jour
SELECT pays, count(*) AS nb_mesures, round(avg(poids_kg), 2) AS poids_moyen
FROM extrait_plat GROUP BY pays ORDER BY pays;          -- 3 pays

UPDATE extrait_plat SET pays = 'Senegal'
WHERE ruche_code = 'SN-KOLD-011'
  AND horodatage = (SELECT min(horodatage) FROM extrait_plat WHERE ruche_code = 'SN-KOLD-011');

UPDATE extrait_plat SET telephone = '+221 77 999 99 99'
WHERE ruche_code = 'SN-KOLD-011'
  AND horodatage = (SELECT max(horodatage) FROM extrait_plat WHERE ruche_code = 'SN-KOLD-011');

SELECT pays, count(*) AS nb_mesures, round(avg(poids_kg), 2) AS poids_moyen
FROM extrait_plat GROUP BY pays ORDER BY pays;          -- 4 pays

-- 2. Suppression : Awa Diop disparaît (attendu : 0 ligne)
BEGIN;
DELETE FROM extrait_plat WHERE apicultrice = 'Awa Diop';
SELECT count(*) FROM extrait_plat WHERE telephone = '+221 77 100 00 02';
ROLLBACK;

-- 3. Insertion : un site sans ruche est refusé (ruche_code nul)
ALTER TABLE extrait_plat ADD PRIMARY KEY (ruche_code, horodatage);
INSERT INTO extrait_plat (site_id, site_nom, pays) VALUES ('CM-DOUA', 'Douala', 'Cameroun');

-- 5.2 Nettoyage, après l'échec de migration_3nf.sql (duplicate key)
SELECT site_id, array_agg(DISTINCT pays) FROM extrait_plat
GROUP BY site_id HAVING count(DISTINCT pays) > 1;       -- SN-KOLD : Senegal / Sénégal

SELECT ruche_code, array_agg(DISTINCT telephone) FROM extrait_plat
GROUP BY ruche_code HAVING count(DISTINCT telephone) > 1;   -- SN-KOLD-011

UPDATE extrait_plat SET pays = 'Sénégal' WHERE pays = 'Senegal';
UPDATE extrait_plat SET telephone = '+221 77 200 00 01' WHERE telephone = '+221 77 999 99 99';
-- puis relancer migration_3nf.sql : 4 sites, 8 apicultrices, 11 ruches, 528 mesures
