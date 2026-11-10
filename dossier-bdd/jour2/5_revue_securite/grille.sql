-- 10.3 Grille de contrôle : à lancer en postgres, sans ON_ERROR_STOP (C5 et C7 doivent être refusés).
-- C8, C9, C11 et C12 se vérifient hors de psql : voir rapport_revue.md.

-- C1 : aucune fonction exécutable par PUBLIC
SELECT proname FROM pg_proc
WHERE pronamespace = 'public'::regnamespace AND has_function_privilege('public', oid, 'EXECUTE');
-- Résultat : 0 ligne

-- C2 : toute fonction SECURITY DEFINER fixe son search_path
SELECT proname, proconfig FROM pg_proc
WHERE pronamespace = 'public'::regnamespace AND prosecdef;
-- Résultat : audit_ligne et valider_recolte, toutes deux avec search_path=public, pg_temp

-- C3 : les vues filtrantes sont des barrières
SELECT relname, reloptions FROM pg_class
WHERE relkind = 'v' AND relnamespace = 'public'::regnamespace ORDER BY relname;
-- Résultat : security_barrier=true sur les 7 vues filtrantes (après corrections.sql).
-- v_export_bailleur n'en a pas : elle ne filtre pas par utilisateur et n'est donnée qu'au gestionnaire.

-- C4 : aucune vue ne montre des données hors périmètre
SET ROLE "f.ba";
SELECT 'v_moi' AS vue, count(*) FROM v_moi
UNION ALL SELECT 'v_mes_ruches', count(*) FROM v_mes_ruches
UNION ALL SELECT 'v_mes_mesures', count(*) FROM v_mes_mesures
UNION ALL SELECT 'v_mes_recoltes', count(*) FROM v_mes_recoltes
UNION ALL SELECT 'v_carte_ruches', count(*) FROM v_carte_ruches;
SELECT DISTINCT r.code FROM v_mes_mesures m JOIN v_mes_ruches r ON r.id = m.ruche_id;
SELECT count(*) FROM v_ruches_site;
RESET ROLE;
-- Résultat : son compte, sa ruche (SN-CASA-032) et ses 4368 mesures, ses récoltes, une seule ruche sur la carte ;
-- v_ruches_site (vue du coordinateur) : droit refusé

-- C5 : le journal est en ajout seul
SELECT count(*) FROM journal_audit;
UPDATE journal_audit SET acteur = 'x';
DELETE FROM journal_audit;
TRUNCATE journal_audit;
SELECT count(*) FROM journal_audit;
-- Résultat : trois refus « journal_audit est en ajout seul », le nombre de lignes ne bouge pas

-- C6 : le journal nomme le vrai acteur (dans une transaction annulée)
BEGIN;
SET ROLE "f.ba";
INSERT INTO v_mes_recoltes (ruche_id, date_recolte, quantite_kg) SELECT id, '2026-11-10', 3 FROM v_mes_ruches;
RESET ROLE;
SELECT acteur, operation FROM journal_audit ORDER BY id DESC LIMIT 1;
ROLLBACK;
-- Résultat : f.ba | INSERT

-- C7 : une apicultrice n'écrit pas chez une autre
SELECT id AS ruche_autre FROM ruche WHERE code = 'SN-KOLD-011' \gset
SET ROLE "f.ba";
INSERT INTO v_mes_recoltes (ruche_id, date_recolte, quantite_kg) VALUES (:'ruche_autre', '2026-11-10', 1);
RESET ROLE;
-- Résultat : ERREUR: la nouvelle ligne viole la contrainte de vérification pour la vue « v_mes_recoltes »

-- C10 : les preuves ne partent pas en cascade
SELECT conrelid::regclass AS table_, conname,
       CASE confdeltype WHEN 'a' THEN 'NO ACTION' WHEN 'r' THEN 'RESTRICT'
            WHEN 'c' THEN 'CASCADE' WHEN 'n' THEN 'SET NULL' END AS on_delete
FROM pg_constraint
WHERE contype = 'f' AND connamespace = 'public'::regnamespace AND confdeltype <> 'a'
ORDER BY on_delete, 1;
-- Résultat : CASCADE seulement sur les deux clés d'adhesion ; RESTRICT sur mesure, inspection, recolte, alerte
