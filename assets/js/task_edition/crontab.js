'use strict';
/**
 * TODO
 * ----
 *    - tenir compte des propriétés "several" pour affiner le crontab
 *      - réduire les valeurs de several. Par exemple : [1,2,3] => 1-3
 *      - définir le crontab
 *      - régler un crontab complexe
 *          => construire le cboxier
 *          => cocher les case
 *          => définir la valeur this.several_<identifiant>
 * 
 * 
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
    this.onChangeCrontabField(null)
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
    this['field_'+key].addEventListener('change', this.onChangeCrontabField.bind(this))
    // Le bouton pour "Plusieurs", s'il existe
    const btnSeveral = DGet(`div[prop="${key}"] button.several`, this.obj)
    if ( btnSeveral ) {
      btnSeveral.addEventListener('click', this.onClickSeveralButton.bind(this, key))
    }
  })
  this.maskAllProperties()
}

onClickSeveralButton(key, ev){
  const built_prop  = `cboxier_${key}_built`
  const fct_prop    = `buildCBoxier_${key}`
  const boxier_prop = `cboxier_${key}`
  // Si le cboxier n'est pas construit, il faut le faire
  this[built_prop] || this[fct_prop]()
  // Et on l'ouvre
  this[boxier_prop].show()
}

/**
 * Fonction générique de construction des CBoxiers pour les valeurs 
 * multiples.
 * 
 * @param {String} keyField Le nom du champ (wDay, mDay, etc.)
 * @param {Array} values Liste des valeurs qui produiront les cases à cocher
 * @param {Table} options Les options d'affichage
 * @param {Integer} options.item_width  Largeur à donner à chaque élément.
 */
buildCBoxier(keyField, values, options){
  const data = {
      values: values
    , container: DGet(`#cron-container-several-${keyField} div.cboxier-container`)
    , onOk: this.onChooseSeveral.bind(this, keyField)
  }
  Object.assign(options, {return_checked_keys: true})
  this[`cboxier_${keyField}`] = new CBoxier(data, options)
  this[`cboxier_${keyField}_built`] = true
}

// Construction du cboxier pour les jours de la semaine (sunday-saturday)
buildCBoxier_wDay(){
  this.buildCBoxier('wDay', TABLE_WDAYS, {item_width: 120})
}
// Construction du cboxier pour les jours du mois (1-31)
buildCBoxier_mDay(){
  const JoursMois = []
  for (var j = 1; j < 32; ++j ){
    JoursMois.push({key: String(j), label: String(j), checked: false})
  }
  this.buildCBoxier('mDay', JoursMois, {item_width: 60})
}
// Construction du cboxier pour les heures du jour (0-23)
buildCBoxier_dHour(){
  const dayHours = []
  for (var h = 1; h < 25; ++h ){
    dayHours.push({key: String(h), label: String(h)})
  }
  this.buildCBoxier('dHour', dayHours, {item_width: 60})
}
// Construction du cboxier pour les mois de l'année (janvier-décembre)
buildCBoxier_yMonth(){
  const yearMonths = []
  for (var i in EnglishMonth){
    yearMonths.push({key: EnglishMonth[i], label: MOIS[i], checked: false})
  }
  this.buildCBoxier('yMonth', yearMonths, {item_width: 140})
}

/**
 * Fonction utilisées par les fonctions onChoose_<type field> pour
 * déterminer la valeur final à donner à several_<type field> et 
 * traiter les cas particuliers, lorsque la liste est vide ou ne 
 * contient qu'un seul élément.
 */
onChooseSeveral(keyField, several){
  console.info("several choisis pour %s", keyField, several)
  const len = several.length;
  var lst = [];
  this[`several_${keyField}`] = ((sev, kfd) => {
    if (len == 0) { 
      // <= Aucun item n'a été choisi
      // => several est laissé (ou mis) à null
      return null 
    } else if (len == 1) {
      // <= un seul item a été choisi
      // => Ce n'est pas du "several", on règle le menu du champ avec
      //    la valeur choisie et on met several à null.
      DGet(`select#cron-value-${keyField}`).value = several[0]
      return null
    } else {
      // Cas normal où plusieurs éléments on été choisis
      switch(kfd){
        case 'yMonth':
          for (var ym of sev) { lst.push(EnglishMonth.indexOf(ym))}
          return lst
        case 'dHour':
        case 'mDay':
          return sev.map(x => {return parseInt(x)})
        case 'wDay':
          for (var wday of sev) {lst.push(EnglishWeekday.indexOf(wday))}
          return lst.sort()      
        default:
          return sev
      }
    }  
  })(several, keyField)
  
  this.onChangeCrontabField()
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
onChangeCrontabField(ev){
  console.log("-> onChangeCrontabField")
  const cronData = this.getCronData()
  console.info("[onChangeCrontagField] cronData = ", cronData)
  const crontab = this.generateCronExpression(cronData)
  this.hiddenField.value = crontab
  DGet('#cron-shower').innerHTML = crontab
  this.maskAllProperties()
  this.showRequiredProperties(this.field_uFreq.value /* "day", "week", etc. */)    
  this.showResumeHumain(cronData)
  console.log("<- onChangeCrontabField")
}

/**
 * Fonction pour récupérer les valeurs de l'interface au niveau du 
 * composant cron et générer le crontab correspondant.
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
  return this.generateCronExpression(cronData)
}

getCronData(){
  const cronData = {uFreq: null, uFreqValue: null, hMin: null, dHour: null, wDay: null, mDay: null, yMonth: null}
  const dataReleve = {}
  CRON_PROPERTIES.forEach( prop => {
    let value_str     = this['field_' + prop].value, value ;
    let value_several = this['several_' + prop]; // par exemple several_dHour
    // console.info("value_several de %s = ", prop, value_several)

    if ( value_several ) {
      value = value_several
    } else if ( value_str == '---' ) {
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

generateCronExpression(dataCron) {
  let {uFreq, uFreqValue, hMin, dHour, mDay, wDay, yMonth} = dataCron;
  let freqValue ;
  if ( uFreqValue > 1 && uFreq == 'week') {
    uFreq = 'day'
    freqValue = `*/${uFreqValue * 7}`
  } else {
    freqValue = uFreqValue > 1 ? `*/${uFreqValue}` : "*";
  }

  return [
    uFreq === "minute" ? freqValue : this.finalizeCronFieldValue(hMin, 'hMin'),
    uFreq === "hour"   ? freqValue : this.finalizeCronFieldValue(dHour, 'dHour'),
    uFreq === "day"    ? freqValue : this.finalizeCronFieldValue(mDay, 'mDay'),
    uFreq === "month"  ? freqValue : this.finalizeCronFieldValue(yMonth, 'yMonth'),
    this.finalizeCronFieldValue(wDay, 'wDay')
  ].join(" ");
}

/**
 * @param {Any} value La valeur du champ
 * @param {String} type Le type du champ ('hMin', 'mDay', etc.)
 */
finalizeCronFieldValue(value, type){
  console.log("finalizeCronFieldValue(%s, %s)", value, type)
  if ( value === null || value == 'all') return '*';
  else if ( 'number' == typeof value) return value;
  else if ( value == '---') return null
  else if ( value.length ) return value.join(", ")
  else raise(`Valeur de ${type} inconnue : ${value}`)
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
    } else if (rawValue.indexOf(",") < 0) {
      row.value  = rawValue // Ne pas transformer en nombre
    } else {
      // Une valeur several
      row.value = rawValue.split(",").map(x => {return parseInt(x.trim())})
    }
    // On peut définir les menus directement ici
    if ( 'string' == typeof row.value) {
      this['field_' + key].value = row.value
    } else {
      this['several_' + key] = row.value
      this[`cboxier_${key}_built`] || this[`buildCBoxier_${key}`]()
      const cboxier = this[`cboxier_${key}`]
      cboxier.uncheckAll({except: row.value})
    }
    // Et les valeurs retournées
    resultats[key] = this.finalizeCronFieldValue(row.value, key)
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
  console.log("-> Construction du résumé du cron avec", crondata)
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
  
  // --- Jour(s) de la semaine
  if ( crondata.wDay ) {
    console.log("crondata.wDay = ", crondata.wDay)
    if ( 'number' == typeof crondata.wDay ) {
      sum.push(LOC('on (day)'))
      sum.push(LOC(EnglishWeekday[crondata.wDay]))
    } else {

      const listJours = crondata.wDay.map(ij => {return LOC(EnglishWeekday[ij])})
      sum.push("on (days)")
      sum.push(prettyList(listJours))
    }
  }

  if (crondata.mDay || crondata.yMonth) sum.push(", ")

  if ( crondata.mDay && ['fr'].includes(LANG) ) {
    sum = this.le_jour_du_mois(crondata, sum)
  }

  if ( crondata.yMonth ) {
    if ( 'number' == typeof crondata.yMonth ){
      // Valeur simple
      const mois = MOIS[crondata.yMonth - 1]
      key = [4, 8, 10].includes(crondata.yMonth) ? "d’$1" : "de $1";
      sum.push(LOC("du mois") + ' ' + LOC(key, [mois]))
    } else {
      // Valeur several
      const listMois = crondata.yMonth.map(x => {return MOIS[x]})
      sum.push("des mois de")
      sum.push(prettyList(listMois))
    }
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
