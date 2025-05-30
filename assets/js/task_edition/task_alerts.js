'use strict';
/**
 * Gestion des alertes de tâche dans le formulaire d'édition
 * 
 * NB : Pour voir les alertes dans le travail courant, voir le 
 * fichier atwork/alerts.js
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
    // On règle l'accessibilité des champs d'alerte. Ils ne sont
    // activés si une date de début est définie
    this.setableAlertFields()
    // On initialise la variables qui va contenir toutes les 
    // instances d'alerte
    this.alerts = []
  }

  /**
   * Au moment de l'enregistrement de la tâche, on appelle cette
   * fonction pour obtenir les données des alertes.
   * 
   * @return {Array<Table>} Une liste de tables contenant la 
   * définition de chaque alerte.
   */
  static getData(){
    const data = [] 
    let alertAt = null
    this.alerts.forEach(alert => {
      if (alert.defined){
        const alertData = alert.getData()
        if ( alertAt === null && alertData.at ) alertAt = alertData.at ;
        data.push(alertData)
      }
    })
    this.alertsField.value = JSON.stringify(data)
  }

  /**
   * Méthode appelée dès qu'on change la valeur du champ "Début" de 
   * la tâche.
   * Cela a pour conséquence de régler l'enabilité des champs 
   * d'alerte ainsi que de vérifier que les alertes soient réalistes
   * et de les recalculer si nécessaire.
   */
  static onChangeStartAt(startAt){
    this.setableAlertFields(!!startAt)
    if (startAt){
      this.createAlert()
    } else {
      this.resetAll()
    }
  }

  /**
   * Fonction appelée pour ajouter une alerte à la tâche courante
   */
  static addAlert(ev){
    if ( Task.getStartAt() === null ) {
      Flash.error(LOC("To set an alert, you need to define the task’s start time."))
    } else if ( this.lastAlert && !this.lastAlertIsDefined() ) {
      Flash.error(LOC('The last alert must be defined!'))
    } else {
      this.createAlert()
    }
    return stopEvent(ev)
  }

  static createAlert(){ 
    const alert = new Alert({index: this.alerts.length})
    alert.build()
    this.alerts.push(alert)
  }

  static lastAlertIsDefined(){
    return this.lastAlert && this.lastAlert.defined;
  }
  static get lastAlert(){
    var len;
    if ( (len = this.alerts.length) ) {
      return this.alerts[len - 1]
    } else { return null }
  }

  /**
   * On efface toutes les alertes.
   */
  static resetAll(){
    this.alertsField.value = ""
    this.alertAtField.value = ""
    this.alerts.forEach(alert => alert.remove())
    this.alerts = []
  }

  static enabledAlertFields(){ this.setableAlertFields(true)}
  static disableAlertFields(){ this.setableAlertFields(false)}
  static setableAlertFields(enable){
    if ( undefined === enable) enable = !!Task.getStartAt();
    ['input.alert-at', 'select.alert-unit','input.alert-quantity'].forEach(nfield => {
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
    const alertAtValue = NullIfEmpty(this.alertAtField.value);
    console.log("alertAtValue", alertAtValue)
    if ( alertAtValue ) {
      this.createNewAlert({at: alertAtValue})
    }
    let data = this.alertsField.value
    if ( data && (data = JSON.parse(data)) ) {
      data.forEach(alertData => {
        console.log("alertData.at = ", alertData.at)
        if ( alertAtValue && alertData.at && `${alertData.at}:00` == alertAtValue ) return ;
        this.createNewAlert(alertData)
      })
    }
  }
  static createNewAlert(data){
    const i = this.alerts.length
    const alert = new Alert(Object.assign(data, {index: i}))
    this.alerts.push(alert)
    alert.build()
    alert.setValues()
}


  static get listing(){return this._listing || (this._listing = DGet('div#alerts', this.obj))}
  static get alertsField(){return this._datafield || (this._datafield = DGet('input#alerts-values', this.obj))}
  static get alertAtField(){return this._alrtfieldfield || (this._alrtfieldfield = DGet('input#alert_at-value', this.obj))}
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
 * Pour une alerte unique, sa gestion complète dans l'éditeur de
 * tâche.
 */
class Alert {
  constructor(data){
    this.data = data
  }

  /** 
   * @return True si cette alerte est définie
   */
  get defined(){
    return this.alertAt || this.lapsBefore
  }

  /**
   * @return {Object} La table des données de l'alerte
   */
  getData(){
    return {
        unit:     this.unitField.value
      , quantity: NullIfEmpty(this.quantityField.value)
      , at:       this.alertAt || this.calcAlertAt()
    }
  }
  calcAlertAt(){
    return new Date(Task.getStartAt() - (this.lapsBefore * 60 * 1000))
  }

  get alertAt(){
    return NullIfEmpty(this.alertAtField.value)
  }
  /**
   * Retourne le laps de temps avant, toujours en minutes
   */
  get lapsBefore(){
    const quant = NullIfEmpty(this.quantityField.value)
    if ( !quant ) return null
    const unit = Number(this.unitField.value)
    return quant * unit
  }

  build(){
    let o;
    o = DGet('div#alerts div.alert')
    if ( this.index > 0 ) {
      // Ce n'est pas la première, on fait un clone de la première
      o = o.cloneNode(true)
    }
    this.obj = o
    if ( this.index > 0 ) {
      AlertsBlock.listing.appendChild(this.obj)
      this.reset()
    }
    this.observe()
  }

  observe(){
    this.alertAtField.addEventListener('change', this.onChangeAlertAt.bind(this))
  }

  /**
   * Méthode appelée quand on modifie le champ "alert-at". Il ne faut
   * pas que ce temps soit après le début de la tâche.
   */
  onChangeAlertAt(){
    const alertat = this.alertAt
    try {
      if ( alertat ){
        if ( alertat > Task.getStartAt() ) {
          this.alertAtField.value = ""
          raise(LOC("The alert cannot be set after the task has started, come on…"), this.alertAtField)
        }
      }
    } catch(err){}
  }

  /**
   * Remplit le formulaire de l'alerte (édition)
   */
  setValues(){
    this.data.at        && this.setValue('alertAtField', this.data.at)
    this.data.unit      && this.setValue('unitField', this.data.unit)
    this.data.quantity  && this.setValue('quantityField', this.data.quantity)
  }
  setValue(fieldName, fieldValue){
    this[fieldName].value = fieldValue
  }

  reset(){
    this.alertAtField.value = ""
    this.unitField.value = "1"
    this.quantityField.value = ""
  }

  remove(){
    if (this.index > 0 ){ this.obj.remove() }
  }

  get index(){return this.data.index}

  get alertAtField(){return this._altatfield || (this._altatfield = DGet('input.alert-at', this.obj))}
  get unitField(){ return this._unitField || (this._unitField = DGet('select.alert-unit', this.obj))}
  get quantityField(){ return this._quantField || (this._quantField = DGet('input.alert-quantity', this.obj))}
}
window.AlertsBlock = AlertsBlock