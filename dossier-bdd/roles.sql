-- 8.4
UPDATE utilisateur SET login = 'aminata.diop.casa'
WHERE apicultrice_id = (SELECT id FROM apicultrice WHERE telephone = '+221 77 100 00 01');
UPDATE utilisateur SET login = 'aminata.diop.kold'
WHERE apicultrice_id = (SELECT id FROM apicultrice WHERE telephone = '+221 77 200 00 01');
UPDATE utilisateur SET login = 'awa.diop'
WHERE apicultrice_id = (SELECT id FROM apicultrice WHERE telephone = '+221 77 100 00 02');
UPDATE utilisateur SET login = 'f.ba'
WHERE apicultrice_id = (SELECT id FROM apicultrice WHERE telephone = '+221 77 100 03 03');
UPDATE utilisateur SET login = 'coord.sn' WHERE login = 'coord.casamance';
UPDATE utilisateur SET login = 'admin.beeafrica' WHERE login = 'admin';

INSERT INTO utilisateur (login, mot_de_passe_hash, role)
SELECT 'gest.beeafrica', 'hash_demo_non_reel', 'gestionnaire'
WHERE NOT EXISTS (SELECT 1 FROM utilisateur WHERE login = 'gest.beeafrica');

ALTER TABLE utilisateur DROP CONSTRAINT IF EXISTS utilisateur_login_unique;
ALTER TABLE utilisateur ADD CONSTRAINT utilisateur_login_unique UNIQUE (login);

ALTER TABLE recolte ALTER COLUMN statut SET DEFAULT 'déclarée';

-- 1. Les groupes, puis les personnes
CREATE ROLE qb_apicultrice NOLOGIN;
CREATE ROLE qb_coordinateur NOLOGIN;
CREATE ROLE qb_gestionnaire NOLOGIN;
CREATE ROLE qb_admin NOLOGIN;
CREATE ROLE "f.ba" LOGIN PASSWORD 'Ruche-fb-2027' IN ROLE qb_apicultrice;
CREATE ROLE "awa.diop" LOGIN PASSWORD 'Ruche-ad-2027' IN ROLE qb_apicultrice;
CREATE ROLE "coord.sn" LOGIN PASSWORD 'Ruche-coord-2027' IN ROLE qb_coordinateur;
CREATE ROLE "gest.beeafrica" LOGIN PASSWORD 'Ruche-gest-2027' IN ROLE qb_gestionnaire;
CREATE ROLE "admin.beeafrica" LOGIN PASSWORD 'Ruche-admin-2027' IN ROLE qb_admin;

-- 2. Tout fermer, puis ouvrir le minimum (sur la base courante, quel que soit son nom)
SELECT current_database() AS base \gset
REVOKE CONNECT ON DATABASE :"base" FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE :"base" TO qb_apicultrice, qb_coordinateur, qb_gestionnaire, qb_admin;
GRANT USAGE ON SCHEMA public TO qb_apicultrice, qb_coordinateur, qb_gestionnaire, qb_admin;
GRANT EXECUTE ON FUNCTION qui() TO qb_apicultrice, qb_coordinateur, qb_gestionnaire, qb_admin;

-- 3. Chacun ne voit que ses lignes, et les colonnes utiles
CREATE OR REPLACE VIEW v_moi AS
SELECT id, login, role, apicultrice_id FROM utilisateur WHERE login = qui();

CREATE OR REPLACE VIEW v_mes_ruches AS
SELECT r.id, r.code, r.latitude, r.longitude
FROM ruche r
JOIN utilisateur u ON u.apicultrice_id = r.apicultrice_id
WHERE u.login = qui();

CREATE OR REPLACE VIEW v_mes_mesures AS
SELECT m.ruche_id, m.horodatage, m.poids_kg, m.batterie_pct
FROM mesure m
WHERE m.ruche_id IN (SELECT id FROM v_mes_ruches);

CREATE OR REPLACE VIEW v_mes_recoltes AS
SELECT rc.id, rc.ruche_id, rc.date_recolte, rc.quantite_kg, rc.statut
FROM recolte rc
WHERE rc.ruche_id IN (SELECT id FROM v_mes_ruches)
WITH CHECK OPTION;

CREATE OR REPLACE VIEW v_ruches_site AS
SELECT r.id, r.code, a.nom AS apicultrice, a.telephone
FROM ruche r
JOIN apicultrice a ON a.id = r.apicultrice_id
WHERE r.site_id = (SELECT site_id FROM utilisateur WHERE login = qui());

CREATE OR REPLACE VIEW v_recoltes_site AS
SELECT rc.id, r.code AS ruche_code, rc.date_recolte, rc.quantite_kg, rc.statut
FROM recolte rc
JOIN ruche r ON r.id = rc.ruche_id
WHERE r.site_id = (SELECT site_id FROM utilisateur WHERE login = qui());

-- 4. Les droits
GRANT SELECT ON v_moi TO qb_apicultrice, qb_coordinateur, qb_gestionnaire, qb_admin;
GRANT SELECT ON v_mes_ruches, v_mes_mesures TO qb_apicultrice;
GRANT SELECT, INSERT (ruche_id, date_recolte, quantite_kg) ON v_mes_recoltes TO qb_apicultrice;
GRANT SELECT ON v_ruches_site, v_recoltes_site TO qb_coordinateur;
GRANT SELECT ON synthese_site_jour, v_export_bailleur TO qb_gestionnaire;
GRANT EXECUTE ON FUNCTION hmac(text, text, text) TO qb_gestionnaire;
GRANT SELECT, INSERT, UPDATE ON utilisateur TO qb_admin;
GRANT SELECT ON journal_audit TO qb_admin;

-- Tests du 8.4
SELECT g.rolname AS groupe, r.rolname AS personne
FROM pg_auth_members m
JOIN pg_roles r ON r.oid = m.member
JOIN pg_roles g ON g.oid = m.roleid
WHERE g.rolname LIKE 'qb\_%' ORDER BY 1, 2;
-- Résultat : 5 lignes, une par personne



-- 8.5
CREATE OR REPLACE FUNCTION valider_recolte(p_recolte uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_coord utilisateur;
  n int;
BEGIN
  SELECT * INTO v_coord FROM utilisateur WHERE login = qui();
  IF v_coord.role IS DISTINCT FROM 'coordinateur' THEN
    RAISE EXCEPTION 'seul un coordinateur peut valider une récolte';
  END IF;

  UPDATE recolte rc
  SET statut = 'validée', validee_par = v_coord.id, date_validation = now()
  FROM ruche r
  WHERE rc.id = p_recolte
    AND r.id = rc.ruche_id
    AND r.site_id = v_coord.site_id
    AND rc.statut = 'déclarée';

  GET DIAGNOSTICS n = ROW_COUNT;
  IF n = 0 THEN
    RAISE EXCEPTION 'récolte introuvable, déjà traitée ou hors de votre site';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION valider_recolte(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION valider_recolte(uuid) TO qb_coordinateur;

-- Tests du 8.5
BEGIN;
SET ROLE "f.ba";
INSERT INTO v_mes_recoltes (ruche_id, date_recolte, quantite_kg)
SELECT id, '2026-11-10', 12.5 FROM v_mes_ruches;
RESET ROLE;
SET ROLE "coord.sn";
SELECT valider_recolte(id) FROM v_recoltes_site WHERE statut = 'déclarée';
SELECT ruche_code, quantite_kg, statut FROM v_recoltes_site ORDER BY ruche_code;
SELECT valider_recolte(id) FROM v_recoltes_site WHERE ruche_code = 'SN-CASA-032';
ROLLBACK;
-- Résultat : la récolte de f.ba (SN-CASA-032) passe en validée, puis la revalider est refusé :
-- ERREUR: récolte introuvable, déjà traitée ou hors de votre site
