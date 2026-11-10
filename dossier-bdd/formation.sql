DROP TABLE IF EXISTS suivi_formation, formateur, formation_plat CASCADE;

-- 6.1.1
CREATE TABLE formation_plat (
    telephone  VARCHAR(50) NOT NULL,
    theme      VARCHAR(50) NOT NULL,
    formateur  VARCHAR(50) NOT NULL,
    PRIMARY KEY (telephone, theme)
);

INSERT INTO formation_plat (telephone, theme, formateur) VALUES
  ('+221 77 100 00 01', 'varroa', 'Moussa Sarr'),
  ('+221 77 100 00 01', 'recolte', 'Khady Ndiaye'),
  ('+221 77 100 00 02', 'varroa', 'Moussa Sarr'),
  ('+221 77 200 00 01', 'varroa', 'Ibrahima Fall'),
  ('+221 77 200 00 01', 'capteurs', 'Oumar Diallo'),
  ('+225 07 100 00 01', 'varroa', 'Kouassi Yao'),
  ('+225 07 100 00 02', 'capteurs', 'Oumar Diallo'),
  ('+237 6 77 100 01', 'recolte', 'Khady Ndiaye')
;

-- 6.2.1
CREATE TABLE formateur (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nom VARCHAR(50) UNIQUE NOT NULL,
    theme VARCHAR(50) NOT NULL CHECK (theme IN ('varroa', 'recolte', 'capteurs'))
);

CREATE TABLE suivi_formation (
    apicultrice_id uuid NOT NULL CONSTRAINT suivi_formation_apicultrice_fk REFERENCES apicultrice(id),
    formateur_id uuid NOT NULL CONSTRAINT suivi_formation_formateur_fk REFERENCES formateur(id),
    PRIMARY KEY (apicultrice_id, formateur_id)
);

-- 6.2.2
INSERT INTO formateur (nom, theme)
SELECT DISTINCT formateur, theme FROM formation_plat;

INSERT INTO suivi_formation (apicultrice_id, formateur_id)
SELECT a.id, f.id
FROM formation_plat p
JOIN apicultrice a ON a.telephone = p.telephone
JOIN formateur f   ON f.nom = p.formateur;

-- 6.3
CREATE OR REPLACE FUNCTION suivi_un_formateur_par_theme() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
     SELECT 1
     FROM suivi_formation s
     JOIN formateur f ON f.id = s.formateur_id
     JOIN formateur nouveau ON nouveau.id = NEW.formateur_id
     WHERE s.apicultrice_id = NEW.apicultrice_id
       AND s.formateur_id <> NEW.formateur_id
       AND f.theme = nouveau.theme
  ) THEN
     RAISE EXCEPTION 'DF violée : cette apicultrice a déjà un formateur pour ce thème';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER suivi_formation_df
BEFORE INSERT OR UPDATE ON suivi_formation
FOR EACH ROW EXECUTE FUNCTION suivi_un_formateur_par_theme();

CREATE OR REPLACE FUNCTION formateur_theme_sans_doublon() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
     SELECT 1
     FROM suivi_formation s
     JOIN suivi_formation autre ON autre.apicultrice_id = s.apicultrice_id
                               AND autre.formateur_id <> s.formateur_id
     JOIN formateur f ON f.id = autre.formateur_id
     WHERE s.formateur_id = NEW.id
       AND f.theme = NEW.theme
  ) THEN
     RAISE EXCEPTION 'DF violée : une apicultrice de ce formateur a déjà un formateur pour ce thème';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER formateur_theme_df
BEFORE UPDATE OF theme ON formateur
FOR EACH ROW EXECUTE FUNCTION formateur_theme_sans_doublon();

-- Tests du lab 6 : lancer le fichier sans ON_ERROR_STOP, les deux refus du 6.3 sont attendus.

-- 6.1 Test 1 : (telephone, theme) -> formateur
SELECT telephone, theme FROM formation_plat
GROUP BY 1, 2 HAVING count(DISTINCT formateur) > 1;
-- Résultat : 0 ligne

-- 6.1 Test 2 : formateur -> theme
SELECT formateur FROM formation_plat
GROUP BY formateur HAVING count(DISTINCT theme) > 1;
-- Résultat : 0 ligne

-- 6.1 Test 3 : (telephone, formateur) clé candidate
SELECT telephone, formateur FROM formation_plat
GROUP BY 1, 2 HAVING count(*) > 1;
-- Résultat : 0 ligne

-- 6.1 Anomalie : Moussa Sarr passe en capteurs sur une seule ligne
BEGIN;
UPDATE formation_plat SET theme = 'capteurs' WHERE telephone = '+221 77 100 00 02';
SELECT formateur, array_agg(DISTINCT theme) FROM formation_plat
GROUP BY formateur HAVING count(DISTINCT theme) > 1;
ROLLBACK;
-- Résultat : UPDATE 1, puis Moussa Sarr | {capteurs,varroa}

-- 6.2 Mauvais découpage
CREATE TEMP TABLE p1 AS SELECT DISTINCT telephone, theme FROM formation_plat;
CREATE TEMP TABLE p2 AS SELECT DISTINCT theme, formateur FROM formation_plat;
-- Résultat : SELECT 8, puis SELECT 5

SELECT count(*) FROM p1 JOIN p2 USING (theme);
-- Résultat : 16

SELECT * FROM p1 JOIN p2 USING (theme)
EXCEPT
SELECT theme, telephone, formateur FROM formation_plat
ORDER BY 2, 3;
-- Résultat : 8 lignes inventées, toutes en varroa
--  varroa | +221 77 100 00 01 | Ibrahima Fall
--  varroa | +221 77 100 00 01 | Kouassi Yao
--  varroa | +221 77 100 00 02 | Ibrahima Fall   (Awa Diop)
--  varroa | +221 77 100 00 02 | Kouassi Yao     (Awa Diop)
--  varroa | +221 77 200 00 01 | Kouassi Yao
--  varroa | +221 77 200 00 01 | Moussa Sarr
--  varroa | +225 07 100 00 01 | Ibrahima Fall
--  varroa | +225 07 100 00 01 | Moussa Sarr

DROP TABLE p1, p2;

-- 6.2 Preuve sans perte
(SELECT telephone, theme, formateur FROM formation_plat
 EXCEPT
 SELECT a.telephone, f.theme, f.nom
 FROM suivi_formation s
 JOIN apicultrice a ON a.id = s.apicultrice_id
 JOIN formateur f ON f.id = s.formateur_id)
UNION ALL
(SELECT a.telephone, f.theme, f.nom
 FROM suivi_formation s
 JOIN apicultrice a ON a.id = s.apicultrice_id
 JOIN formateur f ON f.id = s.formateur_id
 EXCEPT
 SELECT telephone, theme, formateur FROM formation_plat);
-- Résultat : 0 ligne

-- 6.3 Règle perdue (trigger désactivé le temps du test)
BEGIN;
ALTER TABLE suivi_formation DISABLE TRIGGER suivi_formation_df;
INSERT INTO suivi_formation
SELECT a.id, f.id FROM apicultrice a, formateur f
WHERE a.telephone = '+221 77 100 00 02' AND f.nom = 'Ibrahima Fall';
SELECT a.nom, f.theme, array_agg(f.nom ORDER BY f.nom) AS formateurs
FROM suivi_formation s
JOIN apicultrice a ON a.id = s.apicultrice_id
JOIN formateur f ON f.id = s.formateur_id
GROUP BY a.id, a.nom, f.theme
HAVING count(*) > 1;
ROLLBACK;
-- Résultat : INSERT 0 1, puis Awa Diop | varroa | {"Ibrahima Fall","Moussa Sarr"}

-- 6.3 Trigger : second formateur varroa pour Awa Diop
INSERT INTO suivi_formation
SELECT a.id, f.id FROM apicultrice a, formateur f
WHERE a.telephone = '+221 77 100 00 02' AND f.nom = 'Ibrahima Fall';
-- Résultat : ERREUR:  DF violée : cette apicultrice a déjà un formateur pour ce thème

-- 6.3 Trigger : thème nouveau pour Awa Diop
BEGIN;
INSERT INTO suivi_formation
SELECT a.id, f.id FROM apicultrice a, formateur f
WHERE a.telephone = '+221 77 100 00 02' AND f.nom = 'Khady Ndiaye';
ROLLBACK;
-- Résultat : INSERT 0 1

-- 6.3 Pour aller plus loin : changer le thème d'un formateur contourne suivi_formation_df
BEGIN;
ALTER TABLE formateur DISABLE TRIGGER formateur_theme_df;
UPDATE formateur SET theme = 'recolte' WHERE nom = 'Moussa Sarr';
SELECT a.nom, f.theme, array_agg(f.nom ORDER BY f.nom) AS formateurs
FROM suivi_formation s
JOIN apicultrice a ON a.id = s.apicultrice_id
JOIN formateur f ON f.id = s.formateur_id
GROUP BY a.id, a.nom, f.theme
HAVING count(*) > 1;
ROLLBACK;
-- Résultat : UPDATE 1, puis Aminata Diop | recolte | {"Khady Ndiaye","Moussa Sarr"}

-- 6.3 Avec formateur_theme_df actif
UPDATE formateur SET theme = 'recolte' WHERE nom = 'Moussa Sarr';
-- Résultat : ERREUR:  DF violée : une apicultrice de ce formateur a déjà un formateur pour ce thème

-- 6.4 Sites des ruches de chaque apicultrice
SELECT a.nom, a.site_id AS site_apicultrice,
       array_agg(DISTINCT r.site_id) AS sites_de_ses_ruches
FROM apicultrice a
JOIN ruche r ON r.apicultrice_id = a.id
GROUP BY a.id, a.nom, a.site_id
ORDER BY a.nom;
-- Résultat : 8 lignes, chaque apicultrice n'a de ruches que sur son site
--  Adjoua Kone   | CI-BOUA | {CI-BOUA}
--  Akissi Traore | CI-BOUA | {CI-BOUA}
--  Aminata Diop  | SN-KOLD | {SN-KOLD}
--  Aminata Diop  | SN-CASA | {SN-CASA}
--  Awa Diop      | SN-CASA | {SN-CASA}
--  Fatou Sow     | SN-CASA | {SN-CASA}
--  Mariama Ba    | SN-KOLD | {SN-KOLD}
--  Nadège Mbarga | CM-BAFO | {CM-BAFO}

-- 6.4 utilisateur.site_id face au site de l'apicultrice
SELECT u.login, u.site_id AS site_utilisateur, a.site_id AS site_apicultrice
FROM utilisateur u
JOIN apicultrice a ON a.id = u.apicultrice_id
WHERE u.site_id IS DISTINCT FROM a.site_id;
-- Résultat : 0 ligne (les deux copies sont identiques, mais rien ne l'impose)
