# | Saisie                                            | query_vuln.py | query.py |
# | code normal                                       | 1 ligne       | 1 ligne  |
# | ' OR '1'='1                                       | 11 lignes     | 0 ligne  |
# | ' UNION SELECT nom, telephone FROM apicultrice -- | 8 lignes      | 0 ligne  |
# Pourquoi query.py résiste : la valeur est envoyée à part (%s), elle n'est jamais lue comme du SQL.
import psycopg

conn = psycopg.connect(dbname="queenbee")

code = input("Code ruche : ")
rows = conn.execute(
    "SELECT r.code, s.nom FROM ruche r JOIN site s ON s.id = r.site_id WHERE r.code = %s",
    (code,),
).fetchall()

for row in rows:
    print(row)
print(len(rows), "ligne(s)")

conn.close()
