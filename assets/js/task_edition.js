'use strict'; 
/**
 * Script pour la gestion de l'édition JS de la tâche
 * Ce fichier a été initié pour gérer les notes.
 */
function StopEvent(ev){
  ev.stopPropagation();
  ev.preventDefault();
  return false
}

class Task {
  static init(){
    // D'abord il faut empêcher de soumettre le formulaire en
    // jouer 'Enter' sur un champ de formulaire
    DGetAll('input[type="text"]').forEach(input => {
      input.addEventListener('keydown', this.stopEnterKey.bind(this))
    })
  }

  /**
   * Fonction appelée quand on clique sur un des boutons pour enregistrer la tâche
   * On peut faire quelques opération et vérifications.
   * 
   * @return true en cas de succès, pour pouvoir soumettre le formulaire.
   */
  static beforeSave(ev){
    console.info("Ce que je dois faire avant de sauver.")
    Repeat.repeater.setRecurrenceValue()
    return true
  }
  static stopEnterKey(ev){
    if (ev.key == 'Enter'){ return StopEvent(ev) }
  }
}

class Notes {
  static create(){
    const title = DGet('#new_note_title').value.trim()
    if ( title == "" ) {
      return alert("Il faut donner un titre à la note !")
    }
    const details = DGet('#new_note_details').value
    const taskSpecId = DGet('#new_note_task_spec_id')
    const dataNote = {
        title: title
      , details: details
      , task_spec_id: taskSpecId 
    }
    ServerTalk.dial({
      route: "/tools/create_note",
      data: {script_args: dataNote},
      callback: this.afterCreateNote.bind(this)
    })
  }
  static afterCreateNote(retour){
    if (retour.ok) {
      console.info("La note a été créée")
    } else {
      console.error("La note n'a pas pu être créée.")
    }
  }
}

/**
 * Les champs visibles en fonction de la fréquence de répétition
 */
const FieldsPerRepeatUnit = {
    hour:   ['at-minute']
  , day:    ['at-minute', 'at-hour']
  , week:   ['at-minute', 'at-hour', 'at-day']
  , month:  ['at-minute', 'at-hour', 'at-day', 'at-mday']
  , year:   ['at-minute', 'at-hour', 'at-day', 'at-mday', 'at-month']
}

const CRON_PROPERTIES = ['uFreq', 'hMin','dHour','mDay','wDay','yMonth'];

class Repeat {
  static onChange(cb){
    const isChecked = cb.checked
    this.repeater.toggleState()
  }

  /**
   * Méthode appelée au chargement du formulaire d'édition de la tâche, désignée pour régler le composant Crontab si nécessaire.
   * 
   * Note : on part du principe, maintenant, qu'il y a une seule récurrence possible
   */
  static onLoad(){
    this.repeater = new Repeat(DGet('div#recurrence-container'))
    this.repeater.setState()
  }

  // --- Instance ---

  constructor(mainConteneur){
    this.obj = mainConteneur;
    this.activeCB = this.obj.previousSibling
    if ( ! this.data.prepared ) this.prepare()
  }

  /**
   * Fonction appelée par le bouton "Enregistrer la tâche" qui va régler la
   * valeur du champ récurrence
   */
  setRecurrenceValue(){
    this.hiddenField.value = this.getCronUI()
  }

  /**
   * Fonction appelée au chargement du formulaire pour régler l'état du composant récurrence
   */
  setState(state){
    state = state || this.getState()
    const isActif = state == 'ON'
    if ( isActif ) {
      var cron = this.hiddenField.value
      cron = cron == "" ? undefined : cron
      // Si la valeur est définie, on régle l'interface
      if ( cron ) this.setCronUI(cron)
    }
    this.activeCB.checked = isActif
    this.obj.classList[isActif ? 'remove' : 'add']("hidden")
    this.onChangeRepeatUnit(null)
  }

  toggleState(){
    this.state = this.state == 'ON' ? 'OFF' : 'ON'
    this.setState(this.state)
  }

  getState(){
    var cron = this.hiddenField.value
    return cron == "" ? 'OFF' : 'ON'
  }
  prepare(){
    this.data.prepared = true
    this.menu_uFreq.addEventListener('change', this.onChangeRepeatUnit.bind(this))
    this.maskAllProperties()
  }

  /**
   * Masque tous les champs du crontab
   */
  maskAllProperties(){
    DGetAll('span.repeat-property', this.obj).forEach(span => span.style.visibility = 'hidden')
  }
  /**
   * N'affiche que les champs utiles du crontab en fonction de l'unité choisie
   * 
   * @param {String} uFreq  Fréquence générale du crontab ("minute", "day", "week", etc.)
   */
  showRequiredProperties(uFreq){
    FieldsPerRepeatUnit[uFreq].forEach( fieldId => {
      DGet(`span.repeat-property.${fieldId}`, this.obj).style.visibility = 'visible'
    })
  }

  onChangeRepeatUnit(ev){
    this.maskAllProperties()
    this.showRequiredProperties(this.menu_uFreq.value /* "day", "week", etc. */)
  }

  /**
   * Fonction pour récupérer les valeurs de l'interface au niveau du composant cron et générer le crontab correspondant
   * 
   * @return {String} Un crontab valide, comme "10 * * * 2"
   */
  getCronUI(){
    const cronData = {}
    CRON_PROPERTIES.forEach( prop => {
      const value = this['menu_' + prop].value ;
      cronData[prop] = value == "---" ? undefined : value ;
    })
    return this.genCronExpression(cronData)
  }
  /**
   * Fonction pour régler l'interface du composant cron dans le formulaire de tâche.
   * 
   * @param {String} cron Un cron valide (p.e. "10 * * * 2")
   * @return void
   */
  setCronUI(cron) {
    const cronData = this.parseCronExpression(cron)
    this.showRequiredProperties(cronData.uFreq)
    CRON_PROPERTIES.forEach( prop => {
      this['menu_'  + prop].value = cronData[prop] || '---' 
    })
  }

  genCronExpression(dataCron) {
    const {uFreq, hMin, dHour, mDay, wDay, yMonth} = dataCron
    return [
      hMin !== undefined ? hMin : 0,
      dHour !== undefined ? dHour : "*",
      uFreq === "month" ? (mDay !== undefined ? mDay : 1) : "*",
      yMonth !== undefined ? yMonth : "*",
      uFreq === "week" ? (wDay !== undefined ? wDay : "*") : "*"
    ].join(" ")
  }

  parseCronExpression(cron) {
    const [hMin, dHour, mDay, yMonth, wDay] = cron.split(" ");

    let uFreq ;
    if (wDay !== "*") {
        uFreq = "week";
    } else if (mDay !== "*" && yMonth !== "*") {
        uFreq = "year";
    } else if (mDay !== "*") {
        uFreq = "month";
    } else if (dHour !== "*") {
        uFreq = "day";
    } else {
        uFreq = "hour";
    }

    return {
          uFreq
        , hMin:   hMin === "*" ? undefined : parseInt(hMin) // minute de l'heure
        , dHour:  dHour === "*" ? undefined : parseInt(dHour) // heure du jour
        , mDay:   mDay === "*" ? undefined : parseInt(mDay) // jour du mois
        , wDay:   wDay === "*" ? undefined : parseInt(wDay) // jour de la semaine
        , yMonth: yMonth === "*" ? undefined : parseInt(yMonth) // mois de l'année
    };
  }

  get menu_uFreq(){return this._menuufreq || (this._menuufreq = DGet('.repeat-frequency-unit', this.obj) ) }
  get menu_hMin(){return this._menuhmin || (this._menuhmin = DGet('select[name="at-minute"]', this.obj))}
  get menu_dHour(){return this._menudhour || (this._menudhour = DGet('select[name="at-hour"]', this.obj))}
  get menu_mDay(){return this._menumday || (this._menumday = DGet('select[name="at-mday"]', this.obj))}
  get menu_wDay(){return this._menuwday || (this._menuwday = DGet('select[name="at-day"]', this.obj))}
  get menu_yMonth(){return this._menuymonth || (this._menuymonth = DGet('select[name="at-month"]', this.obj))}

  get hiddenField(){return this._hiddenfield || (this._hiddenfield = DGet('input#task-recurrence'))}

  get data(){
    return this.obj.dataset
  }

}

window.Task = Task
window.Notes = Notes
window.Repeat = Repeat

Task.init()
Repeat.onLoad()