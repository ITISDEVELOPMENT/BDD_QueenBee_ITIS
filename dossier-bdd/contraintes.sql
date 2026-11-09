-- 4.3 : tests des DF (attendu : 0 ligne)
SELECT site_id FROM extrait_plat GROUP BY site_id
HAVING count(DISTINCT (site_nom, pays)) > 1;
-- Résultat : 0 ligne

SELECT ruche_code FROM extrait_plat GROUP BY ruche_code
HAVING count(DISTINCT (site_id, site_nom, pays, apicultrice, telephone, cooperative)) > 1;
-- Résultat : 0 ligne

SELECT telephone FROM extrait_plat GROUP BY telephone
HAVING count(DISTINCT (apicultrice, cooperative)) > 1;
-- Résultat : 0 ligne

SELECT ruche_code, horodatage FROM extrait_plat GROUP BY ruche_code, horodatage
HAVING count(DISTINCT (poids_kg, temp_int_c)) > 1;
-- Résultat : 0 ligne

-- fausse DF apicultrice -> telephone
SELECT apicultrice, count(DISTINCT telephone) AS nb_telephones
FROM extrait_plat GROUP BY apicultrice HAVING count(DISTINCT telephone) > 1;
-- Résultat : Aminata Diop | 2

-- 4.4 : logins uniques, à exécuter dans l'ordre
-- 1. logins en double
SELECT u.login, a.nom, a.site_id
FROM utilisateur u LEFT JOIN apicultrice a ON a.id = u.apicultrice_id
WHERE u.login IN (SELECT login FROM utilisateur GROUP BY login HAVING count(*) > 1)
ORDER BY u.login, a.site_id;
-- Résultat : a.diop x3

-- 2. refusé (doublons)
ALTER TABLE utilisateur ADD CONSTRAINT utilisateur_login_unique UNIQUE (login);

-- 3. un login par personne (Awa Diop garde a.diop)
UPDATE utilisateur u SET login = 'aminata.diop.casa'
FROM apicultrice a
WHERE a.id = u.apicultrice_id AND a.nom = 'Aminata Diop' AND a.telephone = '+221 77 100 01 01';
UPDATE utilisateur u SET login = 'aminata.diop.kold'
FROM apicultrice a
WHERE a.id = u.apicultrice_id AND a.nom = 'Aminata Diop' AND a.telephone = '+221 77 200 04 04';

-- 4. acceptée
ALTER TABLE utilisateur ADD CONSTRAINT utilisateur_login_unique UNIQUE (login);

-- 5. A.Diop accepté (majuscule), puis supprimé
INSERT INTO utilisateur (login, mot_de_passe_hash, role) VALUES ('A.Diop', 'hash_demo_non_reel', 'apicultrice');
DELETE FROM utilisateur WHERE login = 'A.Diop';

-- 6. index insensible à la casse, puis A.Diop refusé
CREATE UNIQUE INDEX utilisateur_login_ci ON utilisateur (lower(login));
INSERT INTO utilisateur (login, mot_de_passe_hash, role) VALUES ('A.Diop', 'hash_demo_non_reel', 'apicultrice');

-- STRIDE d'un login partagé : S (usurpation), R (actions non attribuables), I (données de l'autre), E (droits de l'autre)
