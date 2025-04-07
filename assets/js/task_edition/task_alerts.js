'use strict';
/**
 * Gestion des alertes de tâche
 * 
 * Les alertes sont consignées dans deux champs dans la table :
 * :alert_at    Qui définit la prochaine alerte comme une date naïve
 * :alerts      Qui est une liste JSON contenant des tables 
 *              définissant chaque alerte (on peut en mettre autant
 *              qu'on veut)
 * 
 */
class AlertsBlock {

  /**
   * Pour initialiser l'interface
   */
  static init(){
    this.btnAddAlert.addEventListener('click', this.addAlert.bind(this))
    // On désactive tous les champs d'alerte. Il ne seront activés
    // que lorsqu'une date de début sera définie
    this.disableAlertFields()
  }

  static enabledAlertFields(){ this.setableAlertFields(true)}
  static disableAlertFields(){ this.setableAlertFields(false)}
  static setableAlertFields(enable){
    ['input.alert-at', 'select.alert-unity','input.alert-quantity'].forEach(nfield => {
      DGetAll(nfield, this.obj).forEach(o => o.disabled = !enable)
    })
  }

  /**
   * Au chargement de la tâche (ou demande de nouvelle)
   * 
   * N1 Le bloc d'alertes n'est pas défini lorsqu'on crée une 
   * nouvelle tâche.
   */
  static onLoad(){
    this.obj /*N1*/ && this.setState()
  }

  static setState(){
    let data = NullIfEmpty(this.alertsField.value)
    if ( !data ) return ;
    data = JSON.parse(data)
  }

  /**
   * Fonction appelée pour ajouter une alerte à la tâche courante
   */
  static addAlert(ev){
    if ( Task.getStartAt() === null ) {
      return Flash.error(LOC("To set an alert, you need to define the task’s start time."))
    }

    return stopEvent(ev)
  }

  static get alertsField(){return this._datafield || (this._datafield = DGet('input#alerts-values', this.obj))}
  static get btnAddAlert(){return this._btnaddalert || (this._btnaddalert = DGet('button.btn-add-alert', this.obj))}
  static get obj(){return this._obj || (this._obj = DGet('div#alerts-container'))}

  // ==== I N S T A N C E Alerts (pluriel) =====
  constructor(task){
    this.task = task
    this.data = task.alerts || []
  }
}

// ==================================================================

/**
 * Class Alert
 * ===========
 * Pour une alerte unique
 */
class Alert {
  constructor(task, data){
    this.task = task
    this.data = data
  }
}
window.AlertsBlock = AlertsBlock