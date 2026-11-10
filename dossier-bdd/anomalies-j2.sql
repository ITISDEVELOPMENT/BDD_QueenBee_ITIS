-- 6.1  Analyser la table reçue : Provoquer l’anomalie
BEGIN;
UPDATE formation_plat SET theme = 'capteurs' WHERE telephone = '+221 77 100 00 02';
SELECT telephone,theme,formateur FROM formation_plat HAVING COUNT(theme) > 1;
ROLLBACK;

