BEGIN;
SELECT setseed(0.42);

INSERT INTO site (id, nom, pays) VALUES
  ('SN-CASA', 'Casamance',  'Sénégal'),
  ('SN-KOLD', 'Kolda',      'Sénégal'),
  ('CI-BOUA', 'Bouaké',     'Côte d''Ivoire'),
  ('CM-BAFO', 'Bafoussam',  'Cameroun');

INSERT INTO cooperative (nom, site_id) VALUES
  ('Coopérative Miel de Casamance', (SELECT id FROM site WHERE nom = 'Casamance')),
  ('Coopérative Abeilles de Kolda', (SELECT id FROM site WHERE nom = 'Kolda')),
  ('Coopérative Bouaké Apicole',    (SELECT id FROM site WHERE nom = 'Bouaké')),
  ('Coopérative Ouest Cameroun',    (SELECT id FROM site WHERE nom = 'Bafoussam'));

INSERT INTO apicultrice (nom, telephone, site_id) VALUES
  ('Aminata Diop',   '+221 77 100 00 01', (SELECT id FROM site WHERE nom = 'Casamance')),
  ('Awa Diop',       '+221 77 100 00 02', (SELECT id FROM site WHERE nom = 'Casamance')),
  ('Fatou Sow',      '+221 77 100 03 03', (SELECT id FROM site WHERE nom = 'Casamance')),
  ('Aminata Diop',   '+221 77 200 00 01', (SELECT id FROM site WHERE nom = 'Kolda')),
  ('Mariama Ba',     '+221 77 200 05 05', (SELECT id FROM site WHERE nom = 'Kolda')),
  ('Adjoua Kone',    '+225 07 100 00 01', (SELECT id FROM site WHERE nom = 'Bouaké')),
  ('Akissi Traore',  '+225 07 100 00 02', (SELECT id FROM site WHERE nom = 'Bouaké')),
  ('Nadège Mbarga',  '+237 6 77 100 01', (SELECT id FROM site WHERE nom = 'Bafoussam'));

INSERT INTO adhesion (apicultrice_id, cooperative_id, date_adhesion)
SELECT a.id, c.id, DATE '2025-01-15' + (row_number() OVER (ORDER BY a.telephone))::int * 10
FROM apicultrice a JOIN cooperative c ON c.site_id = a.site_id;

INSERT INTO ruche (code, latitude, longitude, date_installation, site_id, apicultrice_id) VALUES
  ('SN-CASA-014', 12.55000, -16.27000, '2025-02-10', (SELECT site_id FROM apicultrice WHERE telephone = '+221 77 100 01 01'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 100 01 01')),
  ('SN-CASA-099', 12.55210, -16.27340, '2025-03-02', (SELECT site_id FROM apicultrice WHERE telephone = '+221 77 100 01 01'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 100 01 01')),
  ('SN-CASA-021', 12.56010, -16.26120, '2025-03-18', (SELECT site_id FROM apicultrice WHERE telephone = '+221 77 100 02 02'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 100 02 02')),
  ('SN-CASA-032', 12.54320, -16.28010, '2025-04-05', (SELECT site_id FROM apicultrice WHERE telephone = '+221 77 100 03 03'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 100 03 03')),
  ('SN-KOLD-011', 12.88330, -14.95000, '2025-02-25', (SELECT site_id FROM apicultrice WHERE telephone = '+221 77 200 04 04'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 200 04 04')),
  ('SN-KOLD-012', 12.88510, -14.95420, '2025-02-25', (SELECT site_id FROM apicultrice WHERE telephone = '+221 77 200 04 04'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 200 04 04')),
  ('SN-KOLD-020', 12.89010, -14.94010, '2025-05-12', (SELECT site_id FROM apicultrice WHERE telephone = '+221 77 200 05 05'), (SELECT id FROM apicultrice WHERE telephone = '+221 77 200 05 05')),
  ('CI-BOUA-005',  7.69000,  -5.03000, '2025-04-20', (SELECT site_id FROM apicultrice WHERE telephone = '+225 07 300 06 06'), (SELECT id FROM apicultrice WHERE telephone = '+225 07 300 06 06')),
  ('CI-BOUA-006',  7.69320,  -5.03510, '2025-04-20', (SELECT site_id FROM apicultrice WHERE telephone = '+225 07 300 07 07'), (SELECT id FROM apicultrice WHERE telephone = '+225 07 300 07 07')),
  ('CM-BAFO-003',  5.47780,  10.41760, '2025-06-01', (SELECT site_id FROM apicultrice WHERE telephone = '+237 6 70 40 08 08'), (SELECT id FROM apicultrice WHERE telephone = '+237 6 70 40 08 08')),
  ('CM-BAFO-004',  5.48010,  10.42200, '2025-06-01', (SELECT site_id FROM apicultrice WHERE telephone = '+237 6 70 40 08 08'), (SELECT id FROM apicultrice WHERE telephone = '+237 6 70 40 08 08'));

-- 48 mesures par ruche (toutes les 30 min sur 24 h)
INSERT INTO mesure (ruche_id, horodatage, poids_kg, temp_int_c, temp_ext_c, humidite_pct, activite_sonore, batterie_pct)
SELECT r.id,
       TIMESTAMPTZ '2026-11-08 00:00+00' + h * INTERVAL '30 minutes',
       round((25 + r.n * 1.3 + h * 0.02 + random() * 0.4)::numeric, 2),
       round((34 + random() * 2)::numeric, 1),
       round((22 + 8 * sin(h * pi() / 24) + random())::numeric, 1),
       55 + floor(random() * 20)::int,
       30 + floor(random() * 40)::int,
       100 - (h / 6)::int
FROM (SELECT id, row_number() OVER (ORDER BY code) AS n FROM ruche) AS r  -- n : rang de la ruche (1 à 11)
CROSS JOIN generate_series(0, 47) AS h;

INSERT INTO utilisateur (login, mot_de_passe_hash, role, site_id, apicultrice_id)
SELECT lower(left(a.nom, 1)) || '.' || lower(split_part(a.nom, ' ', 2)),
       'hash_demo_non_reel', 'apicultrice', a.site_id, a.id
FROM apicultrice a;
INSERT INTO utilisateur (login, mot_de_passe_hash, role, site_id) VALUES
  ('coord.casamance', 'hash_demo_non_reel', 'coordinateur',  (SELECT id FROM site WHERE nom = 'Casamance'));
INSERT INTO utilisateur (login, mot_de_passe_hash, role) VALUES
  ('admin', 'hash_demo_non_reel', 'administrateur');

-- 5 ruches jamais inspectées
INSERT INTO inspection (date_inspection, etat_colonie, presence_reine, observations, ruche_id, apicultrice_id)
SELECT d.dt, d.etat, d.reine, d.obs, r.id, r.apicultrice_id
FROM (VALUES
  ('SN-CASA-014', DATE '2026-10-05', 'forte',     true,  'RAS'),
  ('SN-CASA-021', DATE '2026-10-07', 'moyenne',   true,  'Peu de couvain'),
  ('SN-CASA-032', DATE '2026-10-09', 'forte',     true,  'Hausse de miel prévue'),
  ('SN-KOLD-011', DATE '2026-10-12', 'faible',    false, 'Reine non vue, colonie nerveuse'),
  ('CI-BOUA-005', DATE '2026-10-15', 'moyenne',   true,  'Varroa suspectée'),
  ('CM-BAFO-003', DATE '2026-10-20', 'forte',     true,  'RAS')
) AS d(code, dt, etat, reine, obs)
JOIN ruche r ON r.code = d.code;

INSERT INTO recolte (date_recolte, quantite_kg, statut, date_validation, ruche_id, validee_par) VALUES
  ('2026-10-25', 42.50, 'validée',  '2026-10-27', (SELECT id FROM ruche WHERE code = 'SN-CASA-014'), (SELECT id FROM utilisateur WHERE login = 'coord.casamance')),
  ('2026-10-30', 18.00, 'déclarée', NULL,         (SELECT id FROM ruche WHERE code = 'SN-KOLD-011'), NULL),
  ('2026-11-02', 27.30, 'déclarée', NULL,         (SELECT id FROM ruche WHERE code = 'CI-BOUA-005'), NULL);

-- 2 alertes ouvertes, sur 2 sites
INSERT INTO alerte (type_alerte, niveau_confiance, date_alerte, statut, ruche_id) VALUES
  ('essaimage',          85, '2026-11-07', 'ouverte',  (SELECT id FROM ruche WHERE code = 'SN-CASA-014')),
  ('vol',                70, '2026-11-08', 'ouverte',  (SELECT id FROM ruche WHERE code = 'CI-BOUA-005')),
  ('capteur silencieux', 95, '2026-10-28', 'résolue',  (SELECT id FROM ruche WHERE code = 'SN-KOLD-012')),
  ('essaimage',          60, '2026-10-30', 'résolue',  (SELECT id FROM ruche WHERE code = 'CM-BAFO-003'));

COMMIT;
