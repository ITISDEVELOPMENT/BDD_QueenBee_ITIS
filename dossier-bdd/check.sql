-- 8.2
ALTER TABLE mesure
  DROP CONSTRAINT IF EXISTS mesure_batterie_0_100,
  DROP CONSTRAINT IF EXISTS mesure_humidite_0_100,
  DROP CONSTRAINT IF EXISTS mesure_poids_positif,
  ADD CONSTRAINT mesure_batterie_0_100 CHECK (batterie_pct BETWEEN 0 AND 100),
  ADD CONSTRAINT mesure_humidite_0_100 CHECK (humidite_pct BETWEEN 0 AND 100),
  ADD CONSTRAINT mesure_poids_positif CHECK (poids_kg >= 0);


ALTER TABLE utilisateur
  DROP CONSTRAINT IF EXISTS utilisateur_role_check,
  DROP CONSTRAINT IF EXISTS utilisateur_role_valide,
  ADD CONSTRAINT utilisateur_role_valide
    CHECK (role IN ('apicultrice', 'coordinateur', 'gestionnaire', 'administrateur'));

ALTER TABLE alerte
  DROP CONSTRAINT IF EXISTS alerte_statut_check,
  DROP CONSTRAINT IF EXISTS alerte_statut_valide,
  ADD CONSTRAINT alerte_statut_valide CHECK (statut IN ('ouverte', 'en_cours', 'résolue'));

ALTER TABLE recolte
  DROP CONSTRAINT IF EXISTS recolte_statut_check,
  DROP CONSTRAINT IF EXISTS recolte_statut_valide,
  ADD CONSTRAINT recolte_statut_valide CHECK (statut IN ('déclarée', 'validée', 'écart'));

-- Tests du 8.2 (lancer sans ON_ERROR_STOP : refusé)
INSERT INTO mesure (ruche_id, horodatage, poids_kg, batterie_pct)
SELECT id, '2027-03-16 06:00+00', 30.00, 150 FROM ruche WHERE code = 'SN-CASA-014';
-- Résultat : ERREUR: la nouvelle ligne de la relation « mesure » viole la contrainte de vérification « mesure_batterie_0_100 »

UPDATE alerte SET statut = 'fermée' WHERE statut = 'résolue';
-- Résultat : ERREUR: la nouvelle ligne de la relation « alerte » viole la contrainte de vérification « alerte_statut_valide »
