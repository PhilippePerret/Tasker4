'use strict';
/**
 * TODO
 * ----
 *      - réduire les valeurs de several. Par exemple : [1,2,3] => 1-3
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
const FieldsPerCronUnit = {
  hour:   ['hMin']
, day:    ['hMin', 'dHour']
, week:   ['hMin', 'dHour', 'wDay']
, month:  ['hMin', 'dHour', 'wDay', 'mDay']
, year:   ['hMin', 'dHour', 'wDay', 'mDay', 'yMonth']
}

const CRON_PROPERTIES = ['uFreq', 'uFreqValue', 'hMin','dHour','wDay','mDay','yMonth'];

const EnglishWeekday = ['sunday', 'monday','tuesday','wednesday','thursday','friday','saturday'];
const EnglishMonth = ['january','february','march','april','may','june','july','august','september','october','november','december'];
const MOIS  = []
const WDAYS = []
const TABLE_WDAYS = {}

class Crontab {

  /**
   * Initialisation du formulaire de récurrence
   */
  static init(){
    EnglishMonth.forEach(m => {MOIS.push(LOC(m))})
    for (var j in EnglishWeekday){
      const loc_m = LOC(EnglishWeekday[j])
      Object.assign(TABLE_WDAYS, {[j]: loc_m})
      WDAYS.push(loc_m)
    }
    // console.info("TABLE_WDAYS", TABLE_WDAYS)
  }

  /**
   * Fonction appelée quand on clique sur la case à cocher principale
   * qui permet d'activer la récurrence ou au contraire de la reti-
   * rer
   */
  static onChange(cb){
    const isChecked = cb.checked
    this.crontab.toggleState()
  }

  /**
   * Méthode appelée au chargement du formulaire d'édition de la tâche, désignée pour régler le composant Crontab si nécessaire.
   * [N1] Attention, la bloc de récurrence n'existe pas à la création de la tâche, d'où le test du container.
  */
 static onLoad(){
   this.container /* [N1] */ && this.crontab.setState()
  }
  
  /** 
   * @return une instance {Crontab} qui est en fait l'instance courante
   */
  static get crontab(){return this._crontab || (this._crontab = new Crontab())}
  static get container(){return this._cont || (this._cont = DGet('div#crontab-container'))}



  // --- INSTANCE ---

  constructor(){
  this.obj = this.constructor.container;
  this.CronFields = {}
  this.data.prepared || this.prepare()
}


/**
 * Fonction appelée au chargement du formulaire pour régler l'état du composant récurrence
 * 
 * L'état est défini par la valeur du champ hidden principal qui 
 * contient le crontab (this.hiddenField). S'il est vide, c'est
 * qu'aucune récurrence n'est définie. Sinon, la récurrence est
 * active.
 * 
 * @param {String} state 'ON' ou 'OFF'
 */
setState(){
  const isActif = this.getState() == 'ON'
  if ( isActif ) {
    var cron = NullIfEmpty(this.hiddenField.value)
    this.setCronUI(cron)
    this.onChangeCrontabField(null)
  } else {
    // On doit vider le champ récurrence
    this.hiddenField.value = ""
  }
  this.activeCB.checked = isActif
  this.obj.classList[isActif ? 'remove' : 'add']("hidden")
}

getState(){
  var cron = NullIfEmpty(this.hiddenField.value)
  return cron ? 'ON' : 'OFF'
}

toggleState(){
  this.state = this.state == 'ON' ? 'OFF' : 'ON'
  const isActif = this.state == 'ON'
  if ( isActif ){
    // Pour rendre le crontab actif, il faut lui donner une valeur
    this.hiddenField.value = this.lastCrontab || "* * * * *"
  } else {
    // Avant de rendre le crontab inactif, on enregistre la valeur
    // actuelle du crontab, qui pourra être remise plus tard.
    this.lastCrontab = this.hiddenField.value
    this.hiddenField.value = ""
  }
  this.setState(this.state)
}

/**
 * Retourne le champ d'édition de la propriété (champ) voulu.
 * 
 * @usage
 *    const field = this.field(<key>)
 * 
 * @return le DOMElement de clé +key+. Par exemple 'select#cron-value-wDay'
 */
field(key){
  return this.CronFields[key] || (
    Object.assign(this.CronFields, {[key]: this.getField(key)})[key]
  )
}
getField(key){
  switch(key){
    case 'uFreq':
      return DGet('select#cron-frequency-unit')
    case 'uFreqValue':
      return DGet('input#cron-frequency-value')
    default:
      return DGet(`select#cron-value-${key}`)
  }
}

prepare(){
  this.data.prepared = true
  CRON_PROPERTIES.forEach(key => {
    this.field(key).addEventListener('change', this.onChangeCrontabField.bind(this))
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
  this[built_prop] || this[fct_prop]() // build the cboxier
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
    yearMonths.push({key: i, label: MOIS[i], checked: false})
  }
  this.buildCBoxier('yMonth', yearMonths, {width:440, item_width: 140})
}

/**
 * Fonction utilisées par les fonctions onChoose_<type field> pour
 * déterminer la valeur final à donner à several_<type field> et 
 * traiter les cas particuliers, lorsque la liste est vide ou ne 
 * contient qu'un seul élément.
 */
onChooseSeveral(keyField, several){
  // console.info("several choisis pour %s", keyField, several)
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
      this.field(kfd).value = several[0]
      return null
    } else {
      // Cas normal où plusieurs éléments on été choisis
      return sev.map(x => {return parseInt(x)})
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
  FieldsPerCronUnit[uFreq].forEach( fieldId => {
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
  const cronData = this.getCronData()
  // console.info("[onChangeCrontagField] cronData = ", cronData)
  const crontab = this.generateCronExpression(cronData)
  this.hiddenField.value = crontab
  DGet('#cron-shower').innerHTML = crontab
  this.maskAllProperties()
  this.showRequiredProperties(this.field_uFreq.value /* "day", "week", etc. */)    
  this.showResumeHumain(cronData)
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

/**
 * Fonction qui collecte les valeurs du crontab
 * 
 * Elle les prend soit dans les valeurs multiples `several_<field key>', soit dans les
 * valeurs des menus dans l'interface.
 * 
 * @return {Table} une table contenant toutes les valeurs utiles pour 
 * construire le crontab
 */
getCronData(){
  const cronData = {uFreq: null, uFreqValue: null, hMin: null, dHour: null, wDay: null, mDay: null, yMonth: null}
  const dataReleve = {}
  CRON_PROPERTIES.forEach( kField => {
    let value_str     = this.field(kField).value, value
    let value_several = this[`several_${kField}`] // par exemple several_dHour
    // console.info("value_several de %s = ", kField, value_several)

    if ( value_several ) {
      value = value_several
    } else if ( value_str == '---' ) {
      value = null
    } else if ( value_str == 'all' ) {
      value = 'all'
    } else {
      value = value_str
    }
    dataReleve[kField] = value ;
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
  // console.log("finalizeCronFieldValue(%s, %s)", value, type)
  if ( value === null || value == 'all') return '*';
  else if ( 'number' == typeof value) return value;
  else if ( value == '---') return null
  else if ( 'object' == typeof value && value.length ) return value.join(",")
  else if ( 'string' == typeof value) return value
  else raise(`Valeur de ${type} inconnue : ${value} (type ${typeof value})`)
}

parseAndShowCronExpression(cron) {
  const [hMin, dHour, mDay, yMonth, wDay] = cron.split(" ");
  const table_frequences = {
      hMin:   {raw: hMin    , value: undefined, uFreq: 'hour'  ,  frequential: undefined}
    , dHour:  {raw: dHour   , value: undefined, uFreq: 'day'   ,  frequential: undefined}
    , wDay:   {raw: wDay    , value: undefined, uFreq: 'week' ,   frequential: false}
    , mDay:   {raw: mDay    , value: undefined, uFreq: 'month' ,  frequential: undefined}
    , yMonth: {raw: yMonth  , value: undefined, uFreq: 'year'  ,  frequential: undefined}
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
      row.value = rawValue.split(",").map(x => {return parseInt(x)})
    }

    // Définition des valeurs
    // console.info("row.value", row.value, typeof row.value)
    if ( 'string' == typeof row.value) {
      this.field(key).value = row.value
    } else {
      this[`several_${key}`] = row.value
      this[`cboxier_${key}_built`] || this[`buildCBoxier_${key}`]()
      const cboxier = this[`cboxier_${key}`]
      cboxier.checkOnly(row.value)
    }
    // Et les valeurs retournées
    resultats[key] = this.finalizeCronFieldValue(row.value, key)
  });
  // On renseigne les deux champs de fréquence
  ;['uFreq', 'uFreqValue'].forEach(key => this.field(key).value = resultats[key])

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
  for(var kfield in crondata){
    Object.assign(crondata, {[kfield]: parseIntIfNumberish(crondata[kfield])})
  }
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
  
  // --- Jour(s) de la semaine
  if ( crondata.wDay ) {
    // console.log("crondata.wDay = ", crondata.wDay)
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
    // console.info("crondata.yMonth", crondata.yMonth, typeof crondata.yMonth)
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

get field_uFreq(){return this._menuufreq || (this._menuufreq = DGet('select#cron-frequency-unit', this.obj) ) }
get field_uFreqValue(){return this._fieldufreqv || (this._fieldufreqv = DGet('input#cron-frequency-value', this.obj))}
get activeCB(){return this._cb || (this._cb = DGet('input#cb-recurrence'))}
get hiddenField(){return this._hiddenfield || (this._hiddenfield = DGet('input#task-recurrence'))}

get data(){
  return this.obj.dataset
}

} // /class Crontab

window.Crontab = Crontab

window.addEventListener('load', function(){
  Crontab.init()
})
