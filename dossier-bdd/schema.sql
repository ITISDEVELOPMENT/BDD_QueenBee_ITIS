DROP TABLE IF EXISTS adhesion, inspection, mesure, cooperative, apicultrice, site, ruche, alerte, utilisateur, recolte CASCADE;

CREATE TABLE site (
    id SERIAL PRIMARY KEY, 
    nom VARCHAR(50) NOT NULL, 
    pays VARCHAR(255) NOT NULL
);

CREATE TABLE apicultrice (
    id SERIAL PRIMARY KEY, 
    nom VARCHAR(50), 
    telephone VARCHAR(50),
    site_id SERIAL references site(id)
);

CREATE TABLE cooperative (
    id SERIAL PRIMARY KEY, 
    nom VARCHAR(50), 
    site_id SERIAL references site(id)
);

CREATE TABLE adhesion (
    apicultrice_id SERIAL references apicultrice(id),
    cooperative_id SERIAL references cooperative(id),
    date_adhesion DATE,
    PRIMARY KEYS (apicultrice_id, cooperative_id)
);

CREATE TABLE ruche (
    id SERIAL PRIMARY KEY, 
    code VARCHAR(50) UNIQUE,
    latitude numeric(8,5), 
    longitude numeric(8,5), 
    date_installation DATE,
    site_id SERIAL references site(id),
    apicultrice_id SERIAL references apicultrice(id)
);
CREATE TABLE alerte (
    id SERIAL PRIMARY KEY,
    type_alerte VARCHAR(255),
    niveau_confiance SERIAL,
    date_alerte DATE,
    statut VARCHAR(60),
    ruche_id SERIAL references ruche(id)
);
CREATE TABLE mesure (
    id SERIAL PRIMARY KEY,
    horodatage timestamptz, 
    poids_kg SERIAL, 
    temp_int_c SERIAL, 
    temp_ext_c SERIAL, 
    humidite_pct SERIAL,
    activite_sonore SERIAL,
    batterie_pct SERIAL,
    ruche_id SERIAL references ruche(id)
);
CREATE TABLE inspection (
    id SERIAL PRIMARY KEY,
    date_inspection DATE,
    etat_colonie VARCHAR(255),
    presence_reine BOOLEAN,
    observations TEXT,
    ruche_id SERIAL references ruche(id),
    apicultrice_id SERIAL references apicultrice(id)
);
CREATE TABLE utilisateur (
    id SERIAL PRIMARY KEY, 
    login VARCHAR(100) UNIQUE,
    mot_de_passe_hash VARCHAR(255),
    role VARCHAR(100),
    site_id SERIAL references site(id),
    apicultrice_id SERIAL references apicultrice(id) UNIQUE

);
CREATE TABLE recolte (
    id SERIAL PRIMARY KEY,
    date_recolte DATE,
    quantite_kg SERIAL,
    statut VARCHAR(100),
    date_validation DATE, 
    site_id SERIAL references site(id),
    validee_par SERIAL references utilisateur(id)
);