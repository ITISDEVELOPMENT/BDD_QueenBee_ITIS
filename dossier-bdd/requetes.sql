-- Q1. Les ruches du site SN-CASA, avec leur position
-- Algèbre : π code, latitude, longitude ( σ site_id = 'SN-CASA' ( ruche ) )
SELECT code, latitude, longitude
FROM ruche
WHERE site_id = 'SN-CASA'
ORDER BY code;
-- Résultat : 4 lignes

-- Q2. Chaque apicultrice et son nombre de ruches
-- Algèbre : γ apicultrice.id ; count(ruche.id) ( ( apicultrice ⋈ site ) ⟕ ruche )
SELECT a.nom, s.nom AS site, count(r.id) AS nb_ruches
FROM apicultrice a
JOIN site s ON s.id = a.site_id
LEFT JOIN ruche r ON r.apicultrice_id = a.id
GROUP BY a.id, a.nom, s.nom
ORDER BY nb_ruches DESC, a.nom;
-- Résultat : 8 lignes (les deux Aminata Diop séparées)

-- Q3. Les ruches jamais inspectées
-- Algèbre : π code ( ruche ) − π code ( ruche ⋈ inspection )
SELECT code FROM ruche
EXCEPT
SELECT r.code FROM ruche r JOIN inspection i ON i.ruche_id = r.id
ORDER BY code;
-- Résultat : 5 lignes

-- Q4. Les sites qui ont au moins une alerte ouverte
-- Algèbre : π site.nom ( σ statut = 'ouverte' ( alerte ⋈ ruche ⋈ site ) )
SELECT DISTINCT s.nom
FROM alerte al
JOIN ruche r ON r.id = al.ruche_id
JOIN site s  ON s.id = r.site_id
WHERE al.statut = 'ouverte'
ORDER BY s.nom;
-- Résultat : 2 lignes

-- Q5. Vue coordinateur : code, site, dernière pesée (ni nom ni téléphone)
-- Algèbre : π code, site.nom, horodatage, poids_kg ( ( ruche ⋈ site ) ⟕ mesure )
CREATE OR REPLACE VIEW v_ruche_coordinateur AS
SELECT DISTINCT ON (r.id)
       r.code, s.nom AS site, m.horodatage AS derniere_pesee, m.poids_kg
FROM ruche r
JOIN site s ON s.id = r.site_id
LEFT JOIN mesure m ON m.ruche_id = r.id
ORDER BY r.id, m.horodatage DESC;

SELECT * FROM v_ruche_coordinateur ORDER BY code;
-- Résultat : 11 lignes

-- Pourquoi jamais SELECT * sur les apicultrices : on exposerait le téléphone (donnée personnelle)
-- et toute colonne ajoutée plus tard. On ne sélectionne que les colonnes utiles (moindre privilège).
