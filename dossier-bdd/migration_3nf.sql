BEGIN;
DROP SCHEMA IF EXISTS norm CASCADE;
CREATE SCHEMA norm;

CREATE TABLE norm.site (
    site_id   varchar(10)  PRIMARY KEY,
    site_nom  varchar(50)  NOT NULL,
    pays      varchar(255) NOT NULL
);

CREATE TABLE norm.apicultrice (
    telephone    varchar(50) PRIMARY KEY,
    apicultrice  varchar(50) NOT NULL,
    cooperative  varchar(50) NOT NULL
);

CREATE TABLE norm.ruche (
    ruche_code  varchar(50) PRIMARY KEY,
    site_id     varchar(10) NOT NULL REFERENCES norm.site(site_id),
    telephone   varchar(50) NOT NULL REFERENCES norm.apicultrice(telephone)
);

CREATE TABLE norm.mesure (
    ruche_code  varchar(50)  NOT NULL REFERENCES norm.ruche(ruche_code),
    horodatage  timestamptz  NOT NULL,
    poids_kg    numeric(6,2),
    temp_int_c  numeric(4,1),
    PRIMARY KEY (ruche_code, horodatage)
);

INSERT INTO norm.site        SELECT DISTINCT site_id, site_nom, pays FROM extrait_plat;
INSERT INTO norm.apicultrice SELECT DISTINCT telephone, apicultrice, cooperative FROM extrait_plat;
INSERT INTO norm.ruche       SELECT DISTINCT ruche_code, site_id, telephone FROM extrait_plat;
INSERT INTO norm.mesure      SELECT DISTINCT ruche_code, horodatage, poids_kg, temp_int_c FROM extrait_plat;
COMMIT;
