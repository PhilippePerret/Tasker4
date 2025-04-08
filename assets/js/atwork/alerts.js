'use strict';
/**
 * Gestion des alertes dans le travail courant
 * 
 * NB: Pour la gestion des alertes dans le formulaire d'édition de la
 * tâche, voir task_edition/task_alerts.js
 * 
 * TODO
 *  - quand l'alerte a été donnée, il faut passer la suivante en
 *    prochaine alerte.
 */

class Alerts {

  static schedule(){
    console.log("-> Alerts.schedule")
    if ( ALERTES.length == 0 ) return ;
    spy("Programmation des alertes", ALERTES)
  }

}
window.Alerts = Alerts