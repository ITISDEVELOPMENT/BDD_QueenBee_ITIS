-- 9.2.1
CREATE TABLE jeton (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id uuid NOT NULL CONSTRAINT jeton_utilisateur_fk REFERENCES utilisateur(id),
    valeur text NOT NULL UNIQUE,
    utilise_le timestamptz NOT NULL DEFAULT now(),
    expire_le timestamptz NOT NULL
);

CREATE TABLE session_app (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id uuid NOT NULL CONSTRAINT session_app_utilisateur_fk REFERENCES utilisateur(id),
    jeton_id uuid NOT NULL CONSTRAINT session_app_jeton_fk REFERENCES jeton(id),
    ouverte_le timestamptz NOT NULL DEFAULT clock_timestamp(),
);

INSERT INTO jeton (utilisateur_id, valeur, expire_le)
    SELECT u.id, 'RT-f.ba-' || n, now() + INTERVAL '1 day'
    FROM utilisateur u
    JOIN apicultrice a ON a.id = u.apicultrice_id
    CROSS JOIN generate_series(1, 30) AS n
    WHERE a.telephone = '+221 77 100 00 02';

