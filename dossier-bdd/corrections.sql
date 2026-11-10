-- 10.2 : à lancer en postgres, après roles.sql (roles.sql recrée les vues et efface leur security_barrier).

-- La vue du collègue pressé, réécrite : ses ruches seulement, sans nom ni téléphone
DROP VIEW IF EXISTS v_carte_ruches;
CREATE VIEW v_carte_ruches WITH (security_barrier = true) AS
SELECT r.code, r.latitude, r.longitude
FROM ruche r
JOIN utilisateur u ON u.apicultrice_id = r.apicultrice_id
WHERE u.login = qui();
GRANT SELECT ON v_carte_ruches TO qb_apicultrice;

-- Le filtre des vues passe avant toute condition ajoutée par l'utilisateur
ALTER VIEW v_moi SET (security_barrier = true);
ALTER VIEW v_mes_ruches SET (security_barrier = true);
ALTER VIEW v_mes_mesures SET (security_barrier = true);
ALTER VIEW v_mes_recoltes SET (security_barrier = true);
ALTER VIEW v_ruches_site SET (security_barrier = true);
ALTER VIEW v_recoltes_site SET (security_barrier = true);

-- Plus de fonction temporaire (pg_temp) pour personne
REVOKE TEMPORARY ON DATABASE queenbee FROM PUBLIC;

-- Tests du 10.2
SET ROLE "f.ba";
SELECT * FROM v_carte_ruches;
-- Résultat : une seule ligne, SN-CASA-032, sans nom ni téléphone
RESET ROLE;

SELECT relname, reloptions FROM pg_class
WHERE relkind = 'v' AND relname IN ('v_moi', 'v_mes_ruches', 'v_mes_mesures', 'v_mes_recoltes',
                                    'v_ruches_site', 'v_recoltes_site', 'v_carte_ruches')
ORDER BY relname;
-- Résultat : security_barrier=true sur les 7 vues filtrantes

SELECT has_database_privilege('qb_apicultrice', 'queenbee', 'TEMPORARY') AS apicultrice_peut_creer_pg_temp;
-- Résultat : f
