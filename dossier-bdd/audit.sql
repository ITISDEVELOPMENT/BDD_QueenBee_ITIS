-- 8.3
CREATE OR REPLACE FUNCTION qui() RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT CASE WHEN current_setting('role') = 'none' THEN session_user::text
              ELSE current_setting('role') END
$$;

CREATE OR REPLACE FUNCTION audit_ligne() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO journal_audit (acteur, table_cible, operation, ligne_id, avant, apres)
  VALUES (qui(), TG_TABLE_NAME, TG_OP,
          CASE WHEN TG_OP = 'DELETE' THEN OLD.id::text ELSE NEW.id::text END,
          CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
          CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END);
  RETURN NULL;
END;
$$;

-- La récolte est une preuve de production (UC-C02), utilisateur trace la gestion des comptes.
DROP TRIGGER IF EXISTS recolte_audit ON recolte;
CREATE TRIGGER recolte_audit
AFTER INSERT OR UPDATE OR DELETE ON recolte
FOR EACH ROW EXECUTE FUNCTION audit_ligne();

DROP TRIGGER IF EXISTS utilisateur_audit ON utilisateur;
CREATE TRIGGER utilisateur_audit
AFTER INSERT OR UPDATE OR DELETE ON utilisateur
FOR EACH ROW EXECUTE FUNCTION audit_ligne();

CREATE OR REPLACE FUNCTION journal_interdit() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'journal_audit est en ajout seul : % interdit', TG_OP;
END;
$$;

DROP TRIGGER IF EXISTS journal_ajout_seul ON journal_audit;
CREATE TRIGGER journal_ajout_seul
BEFORE UPDATE OR DELETE ON journal_audit
FOR EACH ROW EXECUTE FUNCTION journal_interdit();

DROP TRIGGER IF EXISTS journal_sans_truncate ON journal_audit;
CREATE TRIGGER journal_sans_truncate
BEFORE TRUNCATE ON journal_audit
FOR EACH STATEMENT EXECUTE FUNCTION journal_interdit();

-- Tests du 8.3 (lancer sans ON_ERROR_STOP : les trois effacements doivent être refusés)
UPDATE recolte SET quantite_kg = 45.00
WHERE ruche_id = (SELECT id FROM ruche WHERE code = 'SN-CASA-014');

SELECT acteur, table_cible, operation,
       avant ->> 'quantite_kg' AS avant, apres ->> 'quantite_kg' AS apres
FROM journal_audit;
-- Résultat : postgres | recolte | UPDATE | 42.50 | 45.00 (SN-CASA-014, la SN-CASA-011 de l'énoncé n'existe pas)

UPDATE journal_audit SET acteur = 'personne';
DELETE FROM journal_audit;
TRUNCATE journal_audit;
-- Résultat : trois ERREUR « journal_audit est en ajout seul : UPDATE / DELETE / TRUNCATE interdit »

SELECT count(*) FROM journal_audit;
-- Résultat : 1, le nombre de lignes n'a pas bougé

ALTER TABLE journal_audit DISABLE TRIGGER journal_ajout_seul;
ALTER TABLE journal_audit ENABLE TRIGGER journal_ajout_seul;
-- Résultat : ALTER TABLE deux fois, le propriétaire peut désactiver la protection
