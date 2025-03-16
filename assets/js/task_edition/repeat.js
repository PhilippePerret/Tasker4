'use strict';


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

const CRON_PROPERTIES = ['uFreq', 'uFreqValue', 'hMin','dHour','mDay','wDay','yMonth'];

class Repeat {
static onChange(cb){
  const isChecked = cb.checked
  this.repeater.toggleState()
}

/**
 * Méthode appelée au chargement du formulaire d'édition de la tâche, désignée pour régler le composant Crontab si nécessaire.
 * Attention, la bloc de récurrence n'existe pas à la création de la tâche.
 * Note : on part du principe, maintenant, qu'il y a une seule récurrence possible
 */
static onLoad(){
  if ( this.container ) {
    this.repeater = new Repeat(this.container)
    this.repeater.setState()
  }
}

static get container(){return this._cont || (this._cont = DGet('div#recurrence-container'))}

// --- Instance ---

constructor(mainConteneur){
  this.obj = mainConteneur;
  if ( ! this.data.prepared ) this.prepare()
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
    var cron = NullIfEmpty(this.hiddenField.value)
    // Si la valeur est définie, on régle l'interface
    if ( cron ) this.setCronUI(cron)
    this.onChangeRepeatField(null)
  }
  this.activeCB.checked = isActif
  this.obj.classList[isActif ? 'remove' : 'add']("hidden")
}

toggleState(){
  this.state = this.state == 'ON' ? 'OFF' : 'ON'
  this.setState(this.state)
}

getState(){
  var cron = NullIfEmpty(this.hiddenField.value)
  return cron ? 'ON' : 'OFF'
}
prepare(){
  this.data.prepared = true
  CRON_PROPERTIES.forEach(key => {
    this['field_'+key].addEventListener('change', this.onChangeRepeatField.bind(this))
  })
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

/**
 * Fonction appelée à chaque changement de la valeur de récurrence, qui :
 *  - relève la valeur des champs
 *  - fabrique le crontab correspondant
 *  - renseigne la propriété cachée conservant le crontab pour 
 *    l'enregistrer
 *  - affiche ce crontab à titre de renseignement
 *  - construit le texte humain et l'affichage
 */
onChangeRepeatField(ev){
  const cronData = this.getCronData()
  const crontab = this.genCronExpression(cronData)
  this.hiddenField.value = crontab
  DGet('#crontab-shower').innerHTML = crontab
  this.maskAllProperties()
  this.showRequiredProperties(this.field_uFreq.value /* "day", "week", etc. */)    
  this.showResumeHumain(cronData)
}

/**
 * Fonction pour récupérer les valeurs de l'interface au niveau du composant cron et générer le crontab correspondant
 * 
 * Ce qu'il faut comprendre à ce niveau-là c'est que toutes les valeurs ne
 * sont pas prises en compte. En fonction du menu uFreq, on prend 
 * les informations jusqu'à un certain point.
 * Exactement :
 *  si uFreq =      on prend…
 *  hour            hMin
 *  day             hMin et dHour
 *  week            hMin, dHour et wDay
 *  month           hMin, dHour, wDay, yMonth
 *  year            idem
 * si uFreq = 
 * @return {String} Un crontab valide, comme "10 * * * 2"
 */
getCronUI(){
  const cronData = this.getCronData()
  return this.genCronExpression(cronData)
}

getCronData(){
  const cronData = {uFreq: null, uFreqValue: null, hMin: null, dHour: null, wDay: null, mDay: null, yMonth: null}
  const dataReleve = {}
  CRON_PROPERTIES.forEach( prop => {
    let value_str = this['field_' + prop].value, value ;
    if ( value_str == '---' ) {
      value = null
    } else {
      value = ['wDay', 'uFreq'].includes(prop) ? value_str : Number(value_str)
    }
    dataReleve[prop] = value ;
  })

  const ufreq = dataReleve.uFreq
  cronData.uFreq      = ufreq
  cronData.uFreqValue = dataReleve.uFreqValue
  cronData.hMin = dataReleve.hMin
  if ( ufreq != 'hour' ) cronData.dHour = dataReleve.dHour
  if ( ['week','month','year'].includes(ufreq)){ 
    cronData.wDay = dataReleve.wDay
    cronData.mDay = dataReleve.mDay
  }
  if ( ['month', 'year'].includes(ufreq)) { cronData.yMonth = dataReleve.yMonth }
  return cronData
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
      hMin:   {raw: hMin    , value: undefined, uFreq: 'hour'  , frequential: undefined}
    , dHour:  {raw: dHour   , value: undefined, uFreq: 'day'   , frequential: undefined}
    , mDay:   {raw: mDay    , value: undefined, uFreq: 'month' , frequential: undefined}
    , wDay:   {raw: wDay    , value: undefined, uFreq: 'month' , frequential: false}
    , yMonth: {raw: yMonth  , value: undefined, uFreq: 'year'  , frequential: undefined}
  }
  const resultats = {
      uFreq:      'hour'
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
    if ( row.uFreq && rawValue != '*') {
      resultats.uFreq = String(row.uFreq)
      resultats.uFreqValue = 1
    }
    if ( row.frequential ) {
      resultats.uFreqValue = Number(rawValue.split('/')[1])
      row.value  = '---' // valeur de menu pour "rien"
    } else if (rawValue == '*') {
      row.value  = '---'
    } else {
      row.value  = rawValue // Number est superflu
    }
    // On peut définir les menus directement ici
    this['field_' + key].value = row.value
    // Et les valeurs retournées
    resultats[key] = row.value == '---' ? null : row.value;
  });
  // On renseigne les deux champs de fréquence
  ;['uFreq', 'uFreqValue'].forEach(key => this[`field_${key}`].value = resultats[key])

  // Affichage des champs nécessaires pour ce crontab
  this.showRequiredProperties(resultats.uFreq)

  // Affichage du résumé humain
  this.showResumeHumain(resultats)

  return resultats ;
}

/**
 * Affiche le résumé humain de la récurrence.
 * Ce résumé est construit en fonction des choix de récurrence.
 */
showResumeHumain(crondata){
  let sum = []
  sum.push(LANG.Summary + LANG["[SPACE]"] + ":") 
  sum.push(LANG["tasker_Repeat this task"])
  // Pour le message 
  if ( crondata.uFreqValue > 1 ) {
    sum.push(LANG['every' + (['day','month'].includes(crondata.uFreq) ? '' : '_fem')])
    sum.push(String(crondata.uFreqValue))
    sum.push(LANG[crondata.uFreq] + "s")
  } else {
    sum.push(LANG['each'])
    sum.push(LANG['ilya_'+crondata.uFreq])
  }
  // -- minute --
  // On ne l'affiche seule que si l'heure n'est pas déterminée
  if ( crondata.dHour == null && crondata.hMin > 0) {
    sum.push("à la " + crondata.hMin + "e minute") // "at minute %{minute}" -> "à la %{minute}e minute"
  }
  
  if ( crondata.wDay ) {
    sum.push(LANG['ilya_on (day)'])
    sum.push(LANG['ilya_'+crondata.wDay])
  }
  // Est-ce qu'une heure est déterminée
  if ( crondata.dHour ) {
    sum.push("à")
    sum.push(`${crondata.dHour} h ${crondata.hMin}`)
  }
  DGet('div#repeat-summary').innerHTML = sum.join(" ") + "."
}


get field_uFreq(){return this._menuufreq || (this._menuufreq = DGet('.repeat-frequency-unit', this.obj) ) }
get field_uFreqValue(){return this._fieldufreqv || (this._fieldufreqv = DGet('input[name="frequency-value"]', this.obj))}
get field_hMin(){return this._menuhmin || (this._menuhmin = DGet('select[name="at-minute"]', this.obj))}
get field_dHour(){return this._menudhour || (this._menudhour = DGet('select[name="at-hour"]', this.obj))}
get field_mDay(){return this._menumday || (this._menumday = DGet('select[name="at-mday"]', this.obj))}
get field_wDay(){return this._menuwday || (this._menuwday = DGet('select[name="at-day"]', this.obj))}
get field_yMonth(){return this._menuymonth || (this._menuymonth = DGet('select[name="at-month"]', this.obj))}
get activeCB(){return this._cb || (this._cb = DGet('input#cb-recurrence'))}

get hiddenField(){return this._hiddenfield || (this._hiddenfield = DGet('input#task-recurrence'))}

get data(){
  return this.obj.dataset
}

} // /class Repeat

window.Repeat = Repeat

