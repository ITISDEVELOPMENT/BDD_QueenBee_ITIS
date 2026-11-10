-- 6.1  Analyser la table reçue : Provoquer l’anomalie
BEGIN;
UPDATE formation_plat SET theme = 'capteurs' WHERE telephone = '+221 77 100 00 02';
SELECT formateur, array_agg(DISTINCT theme) FROM formation_plat
GROUP BY formateur HAVING count(DISTINCT theme) > 1;
ROLLBACK;

