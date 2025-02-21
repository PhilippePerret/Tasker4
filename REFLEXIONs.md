# Réflexions

## Boutons

* Repousser à plus tard (sans autre précision)
* Repousser à demain
* Repousser en bas de la pile du jour
* Repousser après la suivante
* Exclure complètement de la sessions
* Remettre systématiquement après la suivante (jusqu'à ce qu'on la fasse) (un bouton disant "Toujours en tâche suivante")

## Algorithme

Je vais l'appeler le module `Tasker.TaskAlgorithm`

Les paramètres qui peuvent agir sur l'affichage ou la relève de la tâche

### Critéres de relève dans la base

* [OUT] La tâche doit être effectuée dans un futur trop lointain
* [IN ] La tâche est dans un futur proche (< une semaine — réglable dans les paramètres du travailleur ?) ET il y a un nombre de tâches réduit (< 5)
* [OUT] La tâche dépend d'une tâche non terminée
* [IN] La tâche a été démarrée même si elle est dans le futur
* [IN] La date de début de la tâche est dans le passé
* [IN] La date de fin de la tâche est dans un futur proche (même s'il y a peu de tâches)
* [IN] La tâche est périmée (date de fin dans le passé)
* [IN] Une tâche sans échéance
* [OUT] Une tâche clairement attribuée à quelqu'un d'autre

### Critères de précédence des tâches

Bien comprendre qu'il y a deux sortes de critères, ou plutôt deux actions de critère (pour augmenter leur importance hierarchique) : 

1. Les critères qui s'appliquent à la relève des tâches
2. Les criètres qui s'appliquent à la session, au cours de la session de travail courante (ces critères disparaissent déjà la fin de la session ou au rechargement de la page)

#### Critères positifs

* Tâche à urgence max (augmente avec proximité du début si headline)
* Tâche à priorité max (idem)
* Tâche appartenant à un projet mis en avant (à cette session)
* Une tâche périmée (deadline dans le passé)
* Tâche doit terminer aujourd'hui (deadline fixe — augmente si hier, avant-hier, etc.)
* Tâche doit commencer aujourd'hui (headline fixe - augment si hier, avant-hier, etc.)
* Tâche à deadline qui approche (sans headline ou headline future ou passée)
* Une tâche sans échéance mais depuis trop longtemps dans la liste des tâches
* Une tâche presque finie (temps restant < 10 % du temps estimé)
* Tâche courte quand le travailleur les privilégie
* Tâche de même nature que tâche précédente quand le travailleur les privilégie (sinon, c'est un critère discriminant)
* Une tâche trop repoussée
* Tâche dont d'autres tâches dépendent

#### Critères négatifs

* Le temps de travail restant sur la tâche est supérieur au temps de travail restant avant la pause (remonter les horaires) et le temps de travail est inféieur à une demi-heure
* Tâche longue alors que le travailleur privilégie les tâches courtes
* Nature de tâche proche de la dernière ou des dernières (condition qui peut être exclusive si le travailleur le décide)
* Tâche de difficulté équivalente (suivant réglage préférences)

#### Critère immédiat

* repoussée juste après la suivante
* repoussée en bas de la pile
* repoussée à un autre jour

#### Filtres directs (côté client)

* seulement les tâches de telle et telle nature
* seulement les tâches de tel projet
* seulement les tâches de telle durée (courte/longue/moyenne)
* filtre de difficulté : ne pas afficher les tâches de difficulté supérieure à D ou, inversement, seulement des tâches supérieures à la difficulté D
* prioriser les tâches d'un certain projet
* filtre sur les projets (par exclusions ou inclusions)
* peut-être imaginer un filtre qui reprend tous les critères de tri ci-dessus ?

> Note : possibilité de conserver ces filtres pour les applicaquer à la prochaine session.

## Propriétés à ajouter

* [task_spec] nature du travail : parmi des catégories proposées (choisies en préférences parmi un nombre considérable de sujets différents)
* [task_spec] difficulté : de 1 à 5
* [task_time] seuil critique : booléen qui détermine si la tâche non achevée à temps déclenche le seuil critique et passe en priorité maximmale. Le bouton n'apparait que lorsque la date d'échéance et fixée. Il faut bien expliquer ce bouton dans l'interface.

## Préférences

En même temps que je réfléchis à l'algorithme je consigne les conditions paramétrables.

Note : parler de "Contraintes" dans l'interface

* **Limite de nombres de tâche** Peut-être une limite sur le nombre de tâches : soit vraiment en nombre (pas plus de 10 tâches par session) soit en durée de travail (dynamique = en fonction de l'heure et des horaires du travailleur, soit de façon fixe : "je veux des tâches pour 30 minutes")
* **Filtre sur le durée** : Priorité aux tâches courtes ou longue ou moyennes.
* **Natures exclusives**. Un paramètre permet au travailleur de décider de travailler exclusivement sur des tâches de nature différente. Plusieurs degrée : "Ne jamais enchainer de tâche de même nature", "Éviter d'enchainer les tâches de même nature", "Aucune contrainte sur les natures"
* **Future proche** (le définir en nombre de jours, 7 par défaut)
* **Début de la jourée** (heure — 9 par défaut)
* **Fin de la matinée** (heure — midi par défaut)
* **Fin de la journée** (heure — 17 par défaut)
