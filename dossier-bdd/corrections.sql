DROP VIEW IF EXISTS v_carte_ruches;

-- 10.2.4 et 10.3.3

CREATE VIEW v_carte_ruches WITH (security_barrier = true) AS
SELECT r.code, r.latitude, r.longitude
FROM ruche r
JOIN apicultrice a ON a.id = r.apicultrice_id
WHERE a.login = qui();

GRANT SELECT ON v_carte_ruches TO qb_apicultrice;

ALTER VIEW v_moi SET (security_barrier = true);
ALTER VIEW v_mes_ruches SET (security_barrier = true);
ALTER VIEW v_mes_recoltes SET (security_barrier = true);
ALTER VIEW v_mes_mesures SET (security_barrier = true);

REVOKE TEMPORARY ON DATABASE queenbee FROM PUBLIC;