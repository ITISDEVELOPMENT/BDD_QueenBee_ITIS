# Durabilité et sauvegarde

## Étape 9.5

<!-- IMG : SHOW fsync; SHOW synchronous_commit; SHOW wal_level; (on, on, replica) -->
<!-- ![Paramètres 9.5](../images/parametres9-5.png) -->

<!-- IMG : sauvegarde, restauration, nombre de lignes du journal, DELETE refusé, queenbee_j2.dump: OK -->
<!-- ![Sauvegarde 9.5](../images/sauvegarde9-5.png) -->

- **Avec `synchronous_commit = off`, on perdrait :** _à compléter_
- **Pourquoi garder l'empreinte ailleurs que dans la sauvegarde :** _à compléter_
- **Ce que `pg_dump` ne sauvegarde pas :** les rôles (`pg_dumpall --roles-only`).
- **Durabilité et sauvegarde :** la durabilité permet de survivre à une panne ; la sauvegarde permet de survivre à la perte du disque, à une erreur ou à un rançongiciel.
