# 10.1.1
import psycopg
import sys

site = sys.argv[1] if len(sys.argv) > 1 else input("Site : ")
tri = input("Trier par (code ou date_installation) : ")

try:
    with psycopg.connect(dbname="queenbee", user="postgres") as conn:
        sql_query = (
            "SELECT code, site_id, date_installation FROM ruche "
            "WHERE site_id = %s ORDER BY " + tri
        )
        for row in conn.execute(sql_query, (site,)):
            print(row)
except psycopg.Error as e:
    print("Erreur :", e)