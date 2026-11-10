# 10.1.3
import sys
import psycopg
from psycopg import sql

TRIS = {
    "code": sql.Identifier("code"),
    "date_installation": sql.Identifier("date_installation"),
}

site = sys.argv[1] if len(sys.argv) > 1 else input("Site : ")
tri = input("Trier par (code ou date_installation) : ")

if tri not in TRIS:
    print("Tri refusé : choisissez code ou date_installation")
    raise SystemExit(1)

try:
    with psycopg.connect(dbname="queenbee", user="postgres") as conn:
        query = sql.SQL(
            "SELECT code, site_id, date_installation FROM ruche "
            "WHERE site_id = %s ORDER BY {}"
        ).format(TRIS[tri])
        for row in conn.execute(query, (site,)):
            print(row)
except psycopg.Error as e:
    print("Erreur technique lors de la recherche.")