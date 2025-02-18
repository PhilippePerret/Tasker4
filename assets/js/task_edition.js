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
    minute: ['at-minute']
  , hour:   ['at-minute']
  , day:    ['at-minute', 'at-hour']
  , week:   ['at-minute', 'at-hour', 'at-day']
  , month:  ['at-minute', 'at-hour', 'at-day', 'at-mday']
  , year:   ['at-minute', 'at-hour', 'at-day', 'at-mday', 'at-month']
}

const CRON_PROPERTIES = ['uFreq', 'uFreqValue', 'hMin','dHour','mDay','wDay','yMonth'];

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
   * 
   * @param {String} state 'ON' ou 'OFF'
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
    this.field_uFreq.addEventListener('change', this.onChangeRepeatUnit.bind(this))
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
    console.info("uFreq", uFreq)
    if ( uFreq == "" ) {
      try { throw new Error("Pour le backtrace")}
      catch(err){console.log("erreur", err)}
    }
    FieldsPerRepeatUnit[uFreq].forEach( fieldId => {
      DGet(`span.repeat-property.${fieldId}`, this.obj).style.visibility = 'visible'
    })
  }

  onChangeRepeatUnit(ev){
    this.maskAllProperties()
    this.showRequiredProperties(this.field_uFreq.value /* "day", "week", etc. */)
  }

  /**
   * Fonction pour récupérer les valeurs de l'interface au niveau du composant cron et générer le crontab correspondant
   * 
   * @return {String} Un crontab valide, comme "10 * * * 2"
   */
  getCronUI(){
    const cronData = {}
    CRON_PROPERTIES.forEach( prop => {
      let value = this['field_' + prop].value ;
      if ( !['wDay', 'uFreq'].includes(prop) ) value = Number(value)
      cronData[prop] = value == "---" ? null : value ;
    })
    console.info("conData = ", cronData)
    return this.genCronExpression(cronData)
  }
  /**
   * Fonction pour régler l'interface du composant cron dans le formulaire de tâche.
   * 
   * @param {String} cron Un cron valide (p.e. "10 * * * 2")
   * @return void
   */
  setCronUI(cron) {
    const cronData = this.parseAndShowCronExpression(cron)
  }

  genCronExpression(dataCron) {
    let {uFreq, uFreqValue, hMin, dHour, mDay, wDay, yMonth} = dataCron;
    let freqValue ;
    if ( uFreqValue > 1 && uFreq == 'week') {
      uFreq = 'day'
      freqValue = `*/${uFreqValue * 7}`
    } else {
      freqValue = uFreqValue > 1 ? `*/${uFreqValue}` : "*";
    }
  
    return [
      uFreq === "minute" ? freqValue : (hMin    === null ? "0" : hMin),
      uFreq === "hour"   ? freqValue : (dHour   === null ? "*" : dHour),
      uFreq === "day"    ? freqValue : (mDay    === null ? "*" : mDay),
      uFreq === "month"  ? freqValue : (yMonth  === null ? "*" : yMonth),
      uFreq === "week"   ? freqValue : (wDay    === null ? "*" : wDay)
    ].join(" ");
  }

  parseAndShowCronExpression(cron) {
    const [hMin, dHour, mDay, yMonth, wDay] = cron.split(" ");
    const table_frequences = {
        hMin:   {raw: hMin    , value: undefined, uFreq: 'minute' , frequential: undefined}
      , dHour:  {raw: dHour   , value: undefined, uFreq: 'hour'   , frequential: undefined}
      , mDay:   {raw: mDay    , value: undefined, uFreq: 'day'    , frequential: undefined}
      , yMonth: {raw: yMonth  , value: undefined, uFreq: 'month'  , frequential: undefined}
      , wDay:   {raw: wDay    , value: undefined, uFreq: null     , frequential: false}
    }
    const resultats = {
        uFreq:      'minute'
      , uFreqValue: 1
      , hMin:       undefined
      , dHour:      undefined
      , mDay:       undefined
      , wDay:       undefined
      , yMonth:     undefined

    }

    Object.keys(table_frequences).forEach( key => {
      const row = table_frequences[key];
      const rawValue = row.raw
      row.frequential = rawValue.startsWith('*/')
      if ( row.frequential ) {
        resultats.uFreq = String(row.uFreq)
        resultats. uFreqValue = Number(rawValue.split('/')[1])
        row.value  = '---' // valeur de menu pour "rien"
      } else if (rawValue == '*') {
        row.value  = '---'
      } else {
        row.value  = Number(rawValue) // Number est superflu
      }
      // On peut définir les menus directement ici
      this['field_' + key].value = row.value
      // Et les valeurs retournées
      resultats[key] = row.value == '---' ? null : row.value;
    });
    // On renseigne les deux derniers menus
    ;['uFreq', 'uFreqValue'].forEach(key => this[`field_${key}`].value = resultats[key])

    // Affichage des champs nécessaires pour ce crontab
    this.showRequiredProperties(resultats.uFreq)

    // Affichage du résumé humain
    this.showResumeHumain(resultats)

    return resultats ;
  }

  /**
   * Affiche le résumé humain
   */
  showResumeHumain(crondata){
    let sum = []
    sum.push(LANG.Summary + LANG["[SPACE]"] + ":") 
    sum.push(LANG["tasker_Repeat this task"])
    sum.push(LANG.every)
    sum.push(crondata.uFreqValue > 1 ? String(crondata.uFreqValue) : "")
    sum.push(LANG['ilya_'+crondata.uFreq] + "s")
    if ( crondata.wDay ) {
      sum.push(LANG['ilya_on (day)'])
      sum.push(LANG['ilya_'+crondata.wDay])
    }
    DGet('div#repeat-summary').innerHTML = sum.join(" ")
  }


  get field_uFreq(){return this._menuufreq || (this._menuufreq = DGet('.repeat-frequency-unit', this.obj) ) }
  get field_uFreqValue(){return this._fieldufreqv || (this._fieldufreqv = DGet('input[name="frequency-value"]', this.obj))}
  get field_hMin(){return this._menuhmin || (this._menuhmin = DGet('select[name="at-minute"]', this.obj))}
  get field_dHour(){return this._menudhour || (this._menudhour = DGet('select[name="at-hour"]', this.obj))}
  get field_mDay(){return this._menumday || (this._menumday = DGet('select[name="at-mday"]', this.obj))}
  get field_wDay(){return this._menuwday || (this._menuwday = DGet('select[name="at-day"]', this.obj))}
  get field_yMonth(){return this._menuymonth || (this._menuymonth = DGet('select[name="at-month"]', this.obj))}

  get hiddenField(){return this._hiddenfield || (this._hiddenfield = DGet('input#task-recurrence'))}

  get data(){
    return this.obj.dataset
  }

}//class Repeat


window.Task = Task
window.Notes = Notes
window.Repeat = Repeat

Task.init()
Repeat.onLoad()

Repeat.ctest = function(){
  if (!this.activited ) {
    this.activited = true
    return active_lib_testor(Repeat)
  }
  /* === DÉBUT DES TESTS === */
  const r = Repeat.repeater;
  const hf = r.hiddenField;

  t("--- Tests de la gestion du CRON ---");

  hf.value = "5 * * * *"
  r.setState('ON')

  ;[
      ['0 * * * *', {uFreq: 'hour', uFreqValue: 1, hMin: null, dHour: null, mDay: null, wDay: null, yMonth: null}, {uFreq: 'hour', uFreqValue: 1, hMin: 0, dHour: null, mDay: null, wDay: null, yMonth: null}]
    , ['5 * * * *', {uFreq: 'hour', uFreqValue: 1, hMin: 5, dHour: null, mDay: null, wDay: null, yMonth: null}]
    , ['0 * */21 * *', {uFreq: 'week', uFreqValue: 3, hMin: null, dHour: null, mDay: null, wDay: null, yMonth: null}, {uFreq: 'day', uFreqValue: 21, hMin: 0, dHour: null, mDay: null, wDay: null, yMonth: null}]
  ].forEach(paire => {
    let [cron, data, toData] = paire
    toData = toData || data
    equal(r.genCronExpression(data), cron, "Le cron ne correspond pas")
    equal(r.parseAndShowCronExpression(cron), toData, "Les dataCron ne correspondent pas")
  })

}