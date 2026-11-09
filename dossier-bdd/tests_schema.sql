-- Test 1 : une ruche dont l'apicultrice n'existe pas. Attendu : refus
INSERT INTO ruche (code, site_id, apicultrice_id)
VALUES ('SN-CASA-T01', 'SN-CASA', gen_random_uuid());

-- Test 2 : supprimer une apicultrice qui a des ruches. Attendu : refus
DELETE FROM apicultrice WHERE telephone = '+221 77 100 01 01';

-- Test 3 : une ruche sans apicultrice. Attendu : refus
INSERT INTO ruche (code, site_id) VALUES ('SN-CASA-T03', 'SN-CASA');

-- Test 4 : sans clé étrangère, une ruche orpheline est acceptée puis devient invisible.
DROP TABLE IF EXISTS ruche_sans_fk;
CREATE TABLE ruche_sans_fk (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code           VARCHAR(50) NOT NULL,
    apicultrice_id uuid NOT NULL          -- pas de REFERENCES
);
INSERT INTO ruche_sans_fk (code, apicultrice_id) VALUES ('SN-CASA-T04', gen_random_uuid());
SELECT r.code, a.nom FROM ruche_sans_fk r JOIN apicultrice a ON a.id = r.apicultrice_id;
DROP TABLE ruche_sans_fk;

-- Test 5 : un identifiant serial se devine. Attendu : 1, 2, 3
DROP TABLE IF EXISTS demo_serial;
CREATE TABLE demo_serial (id serial PRIMARY KEY, code VARCHAR(50));
INSERT INTO demo_serial (code) VALUES ('A'), ('B'), ('C');
SELECT id, code FROM demo_serial ORDER BY id;
DROP TABLE demo_serial;

-- Test 6 : rejouer une mesure déjà reçue (même ruche, même instant). Attendu : refus
INSERT INTO mesure (ruche_id, horodatage, poids_kg)
SELECT ruche_id, horodatage, 99.99 FROM mesure
WHERE ruche_id = (SELECT id FROM ruche WHERE code = 'SN-CASA-014')
ORDER BY horodatage LIMIT 1;

-- Test 7 : les ruches dont le site diffère de celui de leur apicultrice.
SELECT r.code, r.site_id AS site_ruche, a.site_id AS site_apicultrice
FROM ruche r JOIN apicultrice a ON a.id = r.apicultrice_id
WHERE r.site_id <> a.site_id;

-- Test 8 : passer une récolte « déclarée » à « validée » sans validateur. Attendu : refus
UPDATE recolte SET statut = 'validée'
WHERE ruche_id = (SELECT id FROM ruche WHERE code = 'SN-KOLD-011');

