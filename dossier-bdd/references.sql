-- 8.1.3
BEGIN;

ALTER TABLE adhesion DROP CONSTRAINT adhesion_apicultrice_fk,
ADD CONSTRAINT adhesion_apicultrice_fk FOREIGN KEY (apicultrice_id) 
REFERENCES apicultrice(id) ON DELETE CASCADE;

ALTER TABLE adhesion DROP CONSTRAINT adhesion_cooperative_fk,
ADD CONSTRAINT adhesion_cooperative_fk FOREIGN KEY (cooperative_id) 
REFERENCES cooperative(id) ON DELETE CASCADE;

ALTER TABLE mesure DROP CONSTRAINT mesure_ruche_fk,
ADD CONSTRAINT mesure_ruche_fk FOREIGN KEY (ruche_id) 
REFERENCES ruche(id) ON DELETE RESTRICT;

ALTER TABLE recolte DROP CONSTRAINT recolte_ruche_fk,
ADD CONSTRAINT recolte_ruche_fk FOREIGN KEY (ruche_id) 
REFERENCES ruche(id) ON DELETE RESTRICT;

ALTER TABLE alerte DROP CONSTRAINT alerte_ruche_fk,
ADD CONSTRAINT alerte_ruche_fk FOREIGN KEY (ruche_id) 
REFERENCES ruche(id) ON DELETE RESTRICT;

ALTER TABLE inspection DROP CONSTRAINT inspection_ruche_fk,
ADD CONSTRAINT inspection_ruche_fk FOREIGN KEY (ruche_id) 
REFERENCES ruche(id) ON DELETE RESTRICT;

ROLLBACK;