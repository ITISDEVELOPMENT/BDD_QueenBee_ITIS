-- Tests de l'étape 8.3 (points 2 à 4), à lancer en postgres après audit.sql,
-- sans ON_ERROR_STOP : les trois effacements du journal doivent être refusés.
-- Chaque lancement ajoute une ligne au journal (le point 2 modifie une récolte) : c'est voulu, le journal ne se vide pas.

-- Point 2 : une modification de récolte et sa trace (SN-CASA-014 : la SN-CASA-011 de l'énoncé n'existe pas chez nous)
UPDATE recolte SET quantite_kg = 45.00
WHERE ruche_id = (SELECT id FROM ruche WHERE code = 'SN-CASA-014');

SELECT acteur, table_cible, operation,
       avant ->> 'quantite_kg' AS avant, apres ->> 'quantite_kg' AS apres
FROM journal_audit ORDER BY id DESC LIMIT 1;
-- Résultat (premier lancement) : postgres | recolte | UPDATE | 42.50 | 45.00

-- Point 3 : effacer ses traces
SELECT count(*) AS avant FROM journal_audit;
UPDATE journal_audit SET acteur = 'personne';
DELETE FROM journal_audit;
TRUNCATE journal_audit;
SELECT count(*) AS apres FROM journal_audit;
-- Résultat : trois ERREUR « journal_audit est en ajout seul : UPDATE / DELETE / TRUNCATE interdit »,
-- et le même nombre de lignes avant et après

-- Point 4 : le propriétaire peut désactiver la protection
ALTER TABLE journal_audit DISABLE TRIGGER journal_ajout_seul;
ALTER TABLE journal_audit ENABLE TRIGGER journal_ajout_seul;
-- Résultat : ALTER TABLE deux fois. Limite notée dans matrice_droits.md : le journal doit aussi partir vers le SIEM.
