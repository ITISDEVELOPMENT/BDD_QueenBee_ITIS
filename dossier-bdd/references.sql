-- 8.1

-- Une adhésion n'a pas de valeur sans l'apicultrice : elle part avec elle.
ALTER TABLE adhesion DROP CONSTRAINT adhesion_apicultrice_fk,
  ADD CONSTRAINT adhesion_apicultrice_fk FOREIGN KEY (apicultrice_id)
  REFERENCES apicultrice (id) ON DELETE CASCADE;

-- Même chose si la coopérative disparaît.
ALTER TABLE adhesion DROP CONSTRAINT adhesion_cooperative_fk,
  ADD CONSTRAINT adhesion_cooperative_fk FOREIGN KEY (cooperative_id)
  REFERENCES cooperative (id) ON DELETE CASCADE;

-- Les mesures prouvent l'état de la ruche (un vol par exemple) : on refuse de supprimer la ruche.
ALTER TABLE mesure DROP CONSTRAINT mesure_ruche_fk,
  ADD CONSTRAINT mesure_ruche_fk FOREIGN KEY (ruche_id)
  REFERENCES ruche (id) ON DELETE RESTRICT;

-- Une inspection est une trace du travail de l'apicultrice : on la garde.
ALTER TABLE inspection DROP CONSTRAINT inspection_ruche_fk,
  ADD CONSTRAINT inspection_ruche_fk FOREIGN KEY (ruche_id)
  REFERENCES ruche (id) ON DELETE RESTRICT;

-- Une récolte sert de base aux paiements : elle ne doit pas disparaître avec la ruche.
ALTER TABLE recolte DROP CONSTRAINT recolte_ruche_fk,
  ADD CONSTRAINT recolte_ruche_fk FOREIGN KEY (ruche_id)
  REFERENCES ruche (id) ON DELETE RESTRICT;

-- Une alerte (vol, essaimage) est une preuve : on la garde.
ALTER TABLE alerte DROP CONSTRAINT alerte_ruche_fk,
  ADD CONSTRAINT alerte_ruche_fk FOREIGN KEY (ruche_id)
  REFERENCES ruche (id) ON DELETE RESTRICT;

-- Tests du 8.1
SELECT conrelid::regclass AS table_, conname,
       CASE confdeltype WHEN 'a' THEN 'NO ACTION' WHEN 'r' THEN 'RESTRICT'
            WHEN 'c' THEN 'CASCADE' WHEN 'n' THEN 'SET NULL' END AS on_delete
FROM pg_constraint
WHERE contype = 'f' AND connamespace = 'public'::regnamespace
ORDER BY on_delete, 1;
-- Résultat : 2 CASCADE (adhesion), 4 RESTRICT (mesure, inspection, recolte, alerte), le reste en NO ACTION
