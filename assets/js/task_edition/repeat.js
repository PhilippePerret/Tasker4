'use strict';
/**
 * Gestion du crontab
 * 
 * Notes
 * -----
 *  - le formulaire est définie par la fonction recurrence_form/1 dans
 *    le fichier task_html.ex
 */

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

const EnglishWeekday = ['sunday', 'monday','tuesday','wednesday','thursday','friday','saturday'];
const EnglishMonth = ['january','february','march','april','may','june','july','august','september','october','november','december'];
const MOIS  = []
const WDAYS = []
const TABLE_WDAYS = {}

class Repeat {

  /**
   * Initialisation du formulaire de récurrence
   */
  static init(){
    EnglishMonth.forEach(m => {MOIS.push(LOC(m))})
    EnglishWeekday.forEach(m => {
      const loc_m = LOC(m)
      Object.assign(TABLE_WDAYS, {[m]: loc_m})
      WDAYS.push(loc_m)
    })

  }

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
    // Le bouton pour "Plusieurs", s'il existe
    const btnSeveral = DGet(`div[prop="${key}"] button.several`, this.obj)
    if ( btnSeveral ) {
      console.info("Ce bouton several existe", btnSeveral)
      btnSeveral.addEventListener('click', this.onClickSeveralButton.bind(this, key))
    }
  })
  this.maskAllProperties()
}

onClickSeveralButton(key, ev){
  console.log("Clé pour several", key)
  const built_prop  = `cboxier_${key}_built`
  const fct_prop    = `buildCBoxier_${key}`
  const boxier_prop = `cboxier_${key}`
  // Si le cboxier n'est pas construit, il faut le faire
  this[built_prop] || this[fct_prop]()
  // Et on l'ouvre
  this[boxier_prop].show()
}

// Construction du CBoxier pour les jours de la semaine
buildCBoxier_wDay(){
  const data = {
      values: TABLE_WDAYS
    , container: DGet('#cron-container-several-wday div.cboxier-container')
    , onOk: this.onChoose_wDays.bind(this)
  }
  const options = {
      item_width: 120
    , return_checked_keys: true
  }
  this.cboxier_wDay = new CBoxier(data, options)
  this.cboxier_wDay_built = true
}
onChoose_wDays(wdays){
  console.info("Je dois faire avec les jours de la semaine",wdays)
}

buildCBoxier_mDay(){
  const JoursMois = []
  for (var j = 1; j < 32; ++j ){
    JoursMois.push({key: String(j), label: String(j), checked: false})
  }
  const data = {
      values: JoursMois
    , container: DGet('#cron-container-several-mday div.cboxier-container')
    , onOk: this.onChoose_mDays.bind(this)
  }
  const options = {
      item_width: 60
    , return_checked_keys: true
  }
  this.cboxier_mDay = new CBoxier(data, options)
  this.cboxier_mDay_built = true  
}
onChoose_mDays(mdays){
  console.info("Je dois faire avec les jours du mois", mdays)
}

buildCBoxier_dHour(){
  const dayHours = []
  for (var h = 1; h < 25; ++h ){dayHours.push({key: String(h), label: String(h)})}
  const data = {
      values: dayHours
    , onOk: this.onChoose_dHours.bind(this)
    , container: DGet('#cron-container-several-hours div.cboxier-container')
  }
  const options = {
      item_width: 60
    , return_checked_keys: true
  }
  this.cboxier_dHour = new CBoxier(data, options)
  this.cboxier_dHour_built = true
}
onChoose_dHours(dhours){
  console.info("Je dois faire avec les heures du jour",dhours)
}

buildCBoxier_yMonth(){
  const yearMonths = []
  for (var i in EnglishMonth){
    yearMonths.push({key: EnglishMonth[i], label: MOIS[i], checked: false})
  }
  const data = {
      values: yearMonths
    , container: DGet('#cron-container-several-months div.cboxier-container')
    , onOk: this.onChoose_yMonth.bind(this)
  }
  const options = {
      width: 440
    , item_width: 140
    , return_checked_keys: true
  }
  this.cboxier_yMonth = new CBoxier(data, options)
  this.cboxier_yMonth_built = true
}
onChoose_yMonth(ymonths){
  console.info("Je dois faire avec les mois de l'année", ymonths)
}






/**
 * Masque tous les champs du crontab
 * 
 * Rappel : ils ne s'affichent qu'au besoin, pour une plus grande clarté.
 */
maskAllProperties(){
  DGetAll('.cron-property', this.obj).forEach(span => span.style.visibility = 'hidden')
}
/**
 * N'affiche que les champs utiles du crontab en fonction de l'unité choisie
 * 
 * @param {String} uFreq  Fréquence générale du crontab ("minute", "day", "week", etc.)
 */
showRequiredProperties(uFreq){
  FieldsPerRepeatUnit[uFreq].forEach( fieldId => {
    DGetAll(`.cron-property.cron-${fieldId}`, this.obj).forEach(o => o.style.visibility = 'visible')
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
  DGet('#cron-shower').innerHTML = crontab
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
    } else if ( value_str == 'all' ) {
      value = 'all'
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
    uFreq === "hour"   ? freqValue : ([null,'all'].includes(dHour) ? "*" : dHour),
    uFreq === "day"    ? freqValue : (mDay    === null ? "*" : mDay),
    uFreq === "month"  ? freqValue : (yMonth  === null ? "*" : yMonth),
    (wDay === null ? "*" : wDay)
    // uFreq === "week"   ? freqValue : (wDay    === null ? "*" : wDay)
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
  // console.log("-> Construction du résumé du cron avec", crondata)
  let sum = [], key;
  sum.push(LOC('Summary') + LOC("[SPACE]") + ":") 
  sum.push(LOC("Repeat this task"))
  // Pour le message 
  if ( crondata.uFreqValue > 1 ) {
    sum.push(LOC('every' + (['day','month'].includes(crondata.uFreq) ? '' : '_fem')))
    sum.push(String(crondata.uFreqValue))
    sum.push(LOC(crondata.uFreq) + (crondata.uFreq == 'month' ? '' : 's'))
  } else {
    sum.push(LOC('each'))
    sum.push(LOC(crondata.uFreq))
  }

  // Est-ce qu'une heure est déterminée
  switch(crondata.dHour){
    case 'all':
      sum.push(LOC('every_fem') + ' ' + LOC('hour') + 's')
      break
    case null: break;
    default:
      const min = crondata.hMin < 10 ? `0${crondata.hMin}` : crondata.hMin;
      sum.push(LOC("at"))
      sum.push(`${crondata.dHour} h ${min}`)
  }

  // -- minute --
  // On ne l'affiche seule que si l'heure n'est pas déterminée
  if ( crondata.hMin == 0 ) {
    sum.push(LOC("(at the top of the hour)"))
  } else if ( [null,'all'].includes(crondata.dHour) && crondata.hMin > 0) {
    sum.push(LOC("at the $1<sup>th</sup> minute", [crondata.hMin]))
  }
  
  if ( crondata.wDay ) {
    sum.push(LOC('on (day)'))
    sum.push(LOC(EnglishWeekday[crondata.wDay]))
  }

  if (crondata.mDay || crondata.yMonth) sum.push(", ")

  if ( crondata.mDay && ['fr'].includes(LANG) ) {
    sum = this.le_jour_du_mois(crondata, sum)
  }

  if ( crondata.yMonth ) {
    const mois = MOIS[crondata.yMonth - 1]
    key = [4, 8, 10].includes(crondata.yMonth) ? "d’$1" : "de $1";
    sum.push(LOC("du mois") + ' ' + LOC(key, [mois]))
  }

  if ( crondata.mDay && !['fr'].includes(LANG) ) {
    sum = this.le_jour_du_mois(crondata, sum)
  }


  sum = sum.join(" ") + ".";
  sum = sum.replace(" , ", ", ")
  DGet('div#cron-summary').innerHTML = sum
}

// Car utilisé à plusieurs endroits
le_jour_du_mois(crondata, sum){
  const key = crondata.mDay == 1 ? "the first" : "the $1" ;
  sum.push(LOC(key, [crondata.mDay]))
  if ( !crondata.yMonth ) sum.push(LOC("du mois")) ;
  return sum
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

window.addEventListener('load', function(){
  Repeat.init()
})
