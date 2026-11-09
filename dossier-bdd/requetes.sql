SELECT r.code, r.latitude, r.longitude
FROM ruche r
JOIN site s ON s.id = r.site_id
WHERE s.nom = 'Casamance'
ORDER BY r.code;

SELECT a.nom, s.nom AS site, count(r.id) AS nb_ruches
FROM apicultrice a
JOIN site s ON s.id = a.site_id
LEFT JOIN ruche r ON r.apicultrice_id = a.id
GROUP BY a.id, a.nom, s.nom
ORDER BY nb_ruches DESC, a.nom;


SELECT code FROM ruche
EXCEPT
SELECT r.code FROM ruche r JOIN inspection i ON i.ruche_id = r.id
ORDER BY code;

SELECT DISTINCT s.nom
FROM alerte al
JOIN ruche r ON r.id = al.ruche_id
JOIN site s  ON s.id = r.site_id
WHERE al.statut = 'ouverte'
ORDER BY s.nom;

CREATE OR REPLACE VIEW v_ruche_coordinateur AS
SELECT DISTINCT ON (r.id)
       r.code, s.nom AS site, m.horodatage AS derniere_pesee, m.poids_kg
FROM ruche r
JOIN site s ON s.id = r.site_id
LEFT JOIN mesure m ON m.ruche_id = r.id
ORDER BY r.id, m.horodatage DESC;

SELECT * FROM v_ruche_coordinateur ORDER BY code;
