# Concurrence

## Étape 9.1 · L'action et sa trace ensemble

1. `journal_appli` : l'UPDATE est refusé, mais le journal de l'application affirme la validation.
2. Transaction : +1 ligne dans `journal_audit`, puis `current transaction is aborted` après `SELECT 1 / 0;`, 
tout revient après le `ROLLBACK`.

<!-- IMG : journal_appli et UPDATE refusé -->
<!-- ![Journal appli 9.1](../images/journal-appli9-1.png) -->

<!-- IMG : comptages avant / dans la transaction / après l'erreur / après ROLLBACK -->
<!-- ![Transaction 9.1](../images/transaction9-1.png) -->

## Étape 9.2 · La course au jeton, dans deux terminaux

Jeton `RT-f.ba-1` : 2 sessions ouvertes. 
| Temps | Terminal A | Terminal B |
|-------|------------|------------|
| T1 | ___ | ___ |
| T2 | ___ | ___ |
| T3 | ___ | ___ |
| T4 | ___ | ___ |

<!-- IMG : terminal A -->
<!-- ![Terminal A 9.2](../images/course-a9-2.png) -->

<!-- IMG : terminal B -->
<!-- ![Terminal B 9.2](../images/course-b9-2.png) -->

## Étape 9.3 · La course par un programme

- `course_jeton.py` (RT-f.ba-10 et -11) : 2 sessions à chaque fois.
- `course_jeton_corrige.py` (RT-f.ba-12 et -13) : un accepté, un refusé, 1 session.

<!-- IMG : course_jeton.py : 2 sessions -->
<!-- ![Course 9.3](../images/course-py9-3.png) -->

<!-- IMG : course_jeton_corrige.py : 1 session -->
<!-- ![Course corrigée 9.3](../images/course-corrige9-3.png) -->

## Étape 9.4 · Les quatre corrections

<!-- IMG : correction 1, FOR UPDATE (RT-f.ba-2) -->
<!-- ![FOR UPDATE 9.4](../images/correction1-9-4.png) -->

<!-- IMG : correction 2, UPDATE … RETURNING (RT-f.ba-3) -->
<!-- ![RETURNING 9.4](../images/correction2-9-4.png) -->

<!-- IMG : correction 3, UNIQUE (refus, nettoyage, puis RT-f.ba-14) -->
<!-- ![UNIQUE 9.4](../images/correction3-9-4.png) -->

<!-- IMG : correction 4, REPEATABLE READ (RT-f.ba-4) -->
<!-- ![REPEATABLE READ 9.4](../images/correction4-9-4.png) -->

| Correction | Où agit-elle ? | Que voit la seconde requête ? | Avantage | Limite |
|------------|----------------|-------------------------------|----------|--------|
| `SELECT … FOR UPDATE` | ___ | ___ | ___ | ___ |
| `UPDATE … WHERE … RETURNING` | ___ | ___ | ___ | ___ |
| `UNIQUE (jeton_id)` | ___ | ___ | ___ | ___ |
| `REPEATABLE READ` | ___ | ___ | ___ | ___ |

Le trigger du lab 6 est aussi un « vérifier, puis agir ». Deux insertions simultanées peuvent-elles le contourner ?
Quelle correction le protégerait ? _À compléter._
