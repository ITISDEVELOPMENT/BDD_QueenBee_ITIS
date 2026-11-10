-- 8.2
ALTER TABLE mesure  ADD CONSTRAINT mesure_batterie_0_100 CHECK (batterie BETWEEN 0 AND 100),
                    ADD CONSTRAINT mesure_humidite_0_100 CHECK (humidite BETWEEN 0 AND 100);

ALTER TABLE utilisateur ADD CONSTRAINT utilisateur_role CHECK (role IN ('apicultrice', 'coordinateur', 'gestionnaire', 'admin'));

ALTER TABLE alerte ADD CONSTRAINT alerte_statut_valide CHECK (statut IN ('ouverte', 'en_cours', 'traitee'));

ALTER TABLE recolte ADD CONSTRAINT recolte_statut_valide CHECK (statut IN ('declaree', 'validee', 'ecart'));
