-- 8.6 Tests de contournement : à lancer en postgres, sans ON_ERROR_STOP (les refus sont attendus).
-- Fatou Ba de l'énoncé = Fatou Sow chez nous (login f.ba, ruche SN-CASA-032).

-- En postgres, on range deux identifiants que f.ba et coord.sn n'ont pas le droit de lire
SELECT id AS ruche_autre FROM ruche WHERE code = 'SN-KOLD-011' \gset
SELECT rc.id AS recolte_autre FROM recolte rc JOIN ruche r ON r.id = rc.ruche_id
WHERE r.code = 'SN-KOLD-011' \gset

SET ROLE "f.ba";

-- 1. f.ba lit apicultrice directement
SELECT nom, telephone FROM apicultrice;
-- Résultat : ERREUR: droit refusé pour la table apicultrice. Attendu.

-- 2. f.ba lit v_mes_ruches
SELECT code FROM v_mes_ruches;
-- Résultat : SN-CASA-032 seulement. Attendu.

-- 3. f.ba déclare une récolte sur sa ruche
INSERT INTO v_mes_recoltes (ruche_id, date_recolte, quantite_kg)
SELECT id, '2026-11-10', 12.5 FROM v_mes_ruches;
SELECT id AS recolte_fba FROM v_mes_recoltes WHERE statut = 'déclarée' \gset
-- Résultat : INSERT 0 1, la récolte part en « déclarée ». Attendu.

-- 4. f.ba déclare une récolte sur la ruche d'une autre (SN-KOLD-011)
INSERT INTO v_mes_recoltes (ruche_id, date_recolte, quantite_kg)
VALUES (:'ruche_autre', '2026-11-10', 12.5);
-- Résultat : ERREUR: la nouvelle ligne viole la contrainte de vérification pour la vue « v_mes_recoltes »
-- (WITH CHECK OPTION). Attendu.

-- 5. f.ba déclare une récolte déjà validée (statut validée chez nous)
INSERT INTO v_mes_recoltes (ruche_id, date_recolte, quantite_kg, statut)
SELECT id, '2026-11-10', 12.5, 'validée' FROM v_mes_ruches;
-- Résultat : ERREUR: droit refusé pour la vue v_mes_recoltes (pas de droit sur la colonne statut). Attendu.

-- 6. f.ba modifie la quantité dans la table (quantite_kg chez nous)
UPDATE recolte SET quantite_kg = 99;
-- Résultat : ERREUR: droit refusé pour la table recolte. Attendu.

-- 7. f.ba valide elle-même une récolte
SELECT valider_recolte(:'recolte_fba');
-- Résultat : ERREUR: droit refusé pour la fonction valider_recolte. Attendu.

-- 8. f.ba écrit une fausse ligne dans le journal
INSERT INTO journal_audit (acteur, table_cible, operation) VALUES ('coord.sn', 'recolte', 'UPDATE');
-- Résultat : ERREUR: droit refusé pour la table journal_audit. Attendu.

-- 9. f.ba coupe l'audit
ALTER TABLE recolte DISABLE TRIGGER recolte_audit;
-- Résultat : ERREUR: doit être le propriétaire de la table recolte. Attendu.

RESET ROLE;
SET ROLE "coord.sn";

-- 10. coord.sn valide la récolte du test 3, puis la revalide
SELECT valider_recolte(:'recolte_fba');
SELECT valider_recolte(:'recolte_fba');
-- Résultat : la première passe, la seconde : ERREUR: récolte introuvable, déjà traitée ou hors de votre site. Attendu.

-- 11. coord.sn valide une récolte d'un autre site (SN-KOLD-011 : CM-BAF n'a pas de récolte chez nous)
SELECT valider_recolte(:'recolte_autre');
-- Résultat : ERREUR: récolte introuvable, déjà traitée ou hors de votre site. Attendu.

RESET ROLE;
SET ROLE "admin.beeafrica";

-- 12. admin.beeafrica lit le journal, puis supprime un utilisateur
SELECT acteur, table_cible, operation, apres ->> 'statut' AS statut
FROM journal_audit WHERE table_cible = 'recolte' ORDER BY id;
DELETE FROM utilisateur WHERE login = 'f.ba';
-- Résultat : le journal est lu, avec f.ba | recolte | INSERT et coord.sn | recolte | UPDATE : les vrais acteurs,
-- même quand la validation passe par une fonction exécutée avec les droits de postgres.
-- Le DELETE : ERREUR: droit refusé pour la table utilisateur. Attendu.

RESET ROLE;
