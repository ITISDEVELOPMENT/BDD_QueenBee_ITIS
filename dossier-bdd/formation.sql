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
INSERT INTO formateur (nom, theme) VALUES
  ('Moussa Sarr', 'varroa'),
  ('Khady Ndiaye', 'recolte'),
  ('Oumar Diallo', 'capteurs'),
  ('Ibrahima Fall', 'varroa'),
  ('Kouassi Yao', 'varroa')
  ;
  

INSERT INTO suivi_formation (apicultrice_id, formateur_id) VALUES
  ((SELECT id FROM apicultrice WHERE telephone = '+221 77 100 00 01'), (SELECT id FROM formateur WHERE nom = 'Moussa Sarr')),
  ((SELECT id FROM apicultrice WHERE telephone = '+221 77 100 00 01'), (SELECT id FROM formateur WHERE nom = 'Khady Ndiaye')),
  ((SELECT id FROM apicultrice WHERE telephone = '+221 77 100 00 02'), (SELECT id FROM formateur WHERE nom = 'Moussa Sarr')),
  ((SELECT id FROM apicultrice WHERE telephone = '+221 77 200 00 01'), (SELECT id FROM formateur WHERE nom = 'Ibrahima Fall')),
  ((SELECT id FROM apicultrice WHERE telephone = '+221 77 200 00 01'), (SELECT id FROM formateur WHERE nom = 'Oumar Diallo')),
  ((SELECT id FROM apicultrice WHERE telephone = '+225 07 100 00 01'), (SELECT id FROM formateur WHERE nom = 'Kouassi Yao')),
  ((SELECT id FROM apicultrice WHERE telephone = '+225 07 100 00 02'), (SELECT id FROM formateur WHERE nom = 'Oumar Diallo')),
  ((SELECT id FROM apicultrice WHERE telephone = '+225 07 100 00 02'), (SELECT id FROM formateur WHERE nom = 'Khady Ndiaye'))
  ;