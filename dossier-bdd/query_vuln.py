import psycopg

conn = psycopg.connect(dbname="queenbee")

code = input("Code ruche : ")
sql = ("SELECT r.code, s.nom FROM ruche r JOIN site s ON s.id = r.site_id "
       "WHERE r.code = '" + code + "'")
print("Requête envoyée :", sql)

rows = conn.execute(sql).fetchall()
for row in rows:
    print(row)
print(len(rows), "ligne(s)")

conn.close()
