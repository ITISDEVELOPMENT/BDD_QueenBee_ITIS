-- 9.2
DROP TABLE IF EXISTS session_app, jeton;

CREATE TABLE jeton (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id uuid NOT NULL CONSTRAINT jeton_utilisateur_fk REFERENCES utilisateur(id),
    valeur text NOT NULL UNIQUE,
    expire_le timestamptz NOT NULL,
    utilise_le timestamptz
);

CREATE TABLE session_app (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    utilisateur_id uuid NOT NULL CONSTRAINT session_app_utilisateur_fk REFERENCES utilisateur(id),
    jeton_id uuid NOT NULL CONSTRAINT session_app_jeton_fk REFERENCES jeton(id),
    ouverte_le timestamptz NOT NULL DEFAULT clock_timestamp()
);

INSERT INTO jeton (utilisateur_id, valeur, expire_le)
SELECT id, 'RT-f.ba-' || n, now() + INTERVAL '1 day'
FROM utilisateur CROSS JOIN generate_series(1, 30) AS n
WHERE login = 'f.ba';

-- 9.4 : un jeton ne peut ouvrir qu'une session, quel que soit le programme
ALTER TABLE session_app ADD CONSTRAINT session_jeton_unique UNIQUE (jeton_id);
