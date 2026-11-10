# 10.1.1
import psycopg

conn = psycopg.connect(dbname="queenbee")

sql = ("SELECT code, exploitation_id, surface_m2 FROM serre "
       "WHERE exploitation_id = %s ORDER BY " + tri)        # valeur paramétrée, tri recopié
try:
    for row in conn.execute(sql, (exploitation,)):
        print(row)
except psycopg.Error as e:
    print("Erreur :", e)
    
TRIS = {"code": sql.Identifier("code"), "surface_m2": sql.Identifier("surface_m2")}
if tri not in TRIS:
    print("Tri refusé : choisissez code ou surface_m2")
    raise SystemExit(1)
requete = sql.SQL("SELECT code, exploitation_id, surface_m2 FROM serre "
                    "WHERE exploitation_id = %s ORDER BY {}").format(TRIS[tri])