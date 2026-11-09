DROP TABLE IF EXISTS adhesion, inspection, mesure, cooperative, apicultrice, site, ruche, alerte, utilisateur, recolte CASCADE;

CREATE TABLE site (
    id   uuid PRIMARY KEY,
    nom  VARCHAR(50)  NOT NULL,
    pays VARCHAR(255) NOT NULL
);

CREATE TABLE apicultrice (
    id        uuid PRIMARY KEY,
    nom       VARCHAR(50) NOT NULL,
    telephone VARCHAR(50) NOT NULL,
    site_id   INTEGER NOT NULL CONSTRAINT apicultrice_site_fk REFERENCES site(id)
);

CREATE TABLE cooperative (
    id      uuid PRIMARY KEY,
    nom     VARCHAR(50) NOT NULL,
    site_id INTEGER NOT NULL CONSTRAINT cooperative_site_fk REFERENCES site(id)
);

CREATE TABLE adhesion (
    apicultrice_id INTEGER NOT NULL CONSTRAINT adhesion_apicultrice_fk REFERENCES apicultrice(id),
    cooperative_id INTEGER NOT NULL CONSTRAINT adhesion_cooperative_fk REFERENCES cooperative(id),
    date_adhesion  DATE NOT NULL DEFAULT current_date,
    PRIMARY KEY (apicultrice_id, cooperative_id)
);

CREATE TABLE ruche (
    id                uuid PRIMARY KEY,
    code              VARCHAR(50) NOT NULL UNIQUE,
    latitude          numeric(8,5),
    longitude         numeric(8,5),
    date_installation DATE,
    site_id           INTEGER NOT NULL CONSTRAINT ruche_site_fk REFERENCES site(id),
    apicultrice_id    INTEGER NOT NULL CONSTRAINT ruche_apicultrice_fk REFERENCES apicultrice(id)
);

CREATE TABLE alerte (
    id               uuid PRIMARY KEY,
    type_alerte      VARCHAR(255) NOT NULL,
    niveau_confiance SMALLINT NOT NULL CHECK (niveau_confiance BETWEEN 0 AND 100),
    date_alerte      DATE NOT NULL,
    statut           VARCHAR(60) NOT NULL CHECK (statut IN ('ouverte', 'résolue')),
    ruche_id         INTEGER NOT NULL CONSTRAINT alerte_ruche_fk REFERENCES ruche(id)
);

CREATE TABLE mesure (
    id              uuid PRIMARY KEY,
    horodatage      timestamptz NOT NULL,
    poids_kg        numeric(6,2),
    temp_int_c      numeric(4,1),
    temp_ext_c      numeric(4,1),
    humidite_pct    SMALLINT,
    activite_sonore SMALLINT,
    batterie_pct    SMALLINT,
    ruche_id        INTEGER NOT NULL CONSTRAINT mesure_ruche_fk REFERENCES ruche(id),
    CONSTRAINT mesure_anti_rejeu UNIQUE (ruche_id, horodatage)
);

CREATE TABLE inspection (
    id              uuid PRIMARY KEY,
    date_inspection DATE NOT NULL,
    etat_colonie    VARCHAR(255),
    presence_reine  BOOLEAN,
    observations    TEXT,
    ruche_id        INTEGER NOT NULL CONSTRAINT inspection_ruche_fk REFERENCES ruche(id),
    apicultrice_id  INTEGER NOT NULL CONSTRAINT inspection_apicultrice_fk REFERENCES apicultrice(id)
);

-- login non unique : contrainte posée au lab 4
CREATE TABLE utilisateur (
    id                uuid PRIMARY KEY,
    login             VARCHAR(100) NOT NULL,
    mot_de_passe_hash VARCHAR(255) NOT NULL,
    role              VARCHAR(100) NOT NULL
                      CHECK (role IN ('apicultrice', 'coordinateur', 'gestionnaire', 'administrateur')),
    site_id           INTEGER CONSTRAINT utilisateur_site_fk REFERENCES site(id),
    apicultrice_id    INTEGER UNIQUE CONSTRAINT utilisateur_apicultrice_fk REFERENCES apicultrice(id)
);

CREATE TABLE recolte (
    id              uuid PRIMARY KEY,
    date_recolte    DATE NOT NULL,
    quantite_kg     numeric(8,2) NOT NULL CHECK (quantite_kg >= 0),
    statut          VARCHAR(100) NOT NULL CHECK (statut IN ('déclarée', 'validée')),
    date_validation DATE,
    site_id         INTEGER NOT NULL CONSTRAINT recolte_site_fk REFERENCES site(id),
    validee_par     INTEGER CONSTRAINT recolte_validee_par_fk REFERENCES utilisateur(id),
    CONSTRAINT recolte_validation_complete
        CHECK (statut <> 'validée' OR (validee_par IS NOT NULL AND date_validation IS NOT NULL))
);
