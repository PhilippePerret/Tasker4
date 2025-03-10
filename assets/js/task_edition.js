'use strict';
import "./task_edition/task_script.js"
import "./task_edition/task_dependencies.js"
import "./task_edition/task_notes.js"
import "./task_edition/repeat.js"

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
    // tapant 'Enter' dans un champ de formulaire
    DGetAll('input[type="text"]').forEach(input => {
      input.addEventListener('keydown', this.stopEnterKey.bind(this))
    })
    // Surveiller le menu de la durée attendue : quand on choisit 
    // "---" on doit masquer le champ du nombre et inversement
    if ( this.fieldDureeUnit ) {
      this.fieldDureeUnit.addEventListener('change', this.onChangeDureeUnit.bind(this))
    }

    // On crée une instance pour gérer les dépendances
    this.taskDeps = new TaskDependencies()
    this.taskDeps.init()

    // Préparation du menu des natures
    this.menuNatures && this.initNaturesValues()

    // Préparation du bloc des scripts de tâche
    TaskScript.init()
    
  } // init

  static get fieldDureeUnit(){return DGet('select#task_time_exp_duree_unit')}
  static get fieldDureeValue(){return DGet('input#task_time_exp_duree_value')}
  
  
  static onChangeDureeUnit(ev) {
    const unit = this.fieldDureeUnit.value
    this.fieldDureeValue.style.visibility = unit == '---' ? 'hidden' : 'visible';
    this.fieldDureeValue.value =  unit == '---' ? '' : '1' ;
  }

  /**
   * Fonction appelée quand on clique sur un des boutons pour enregistrer la tâche
   * On peut faire quelques opération et vérifications.
   * 
   * @return true en cas de succès, pour pouvoir soumettre le formulaire.
   */
  static beforeSave(ev){
    // console.info("Ce que je dois faire avant de sauver.")
    try {
      TaskScript.getData()
    } catch (err) {
      console.error(err)
    }
    // return confirm("Dois-je enregistrer ?");
    return true
  }
  static stopEnterKey(ev){
    if (ev.key == 'Enter'){ return StopEvent(ev) }
  }

  // ======== NATURES ==========
  /**
   * Fonction appelée à l'initialisation du formulaire, lorsque la
   * tâche contient la donnée "natures", qui prépare le formulaire
   * au niveau des natures. C'est-à-dire qui : 
   *  - relève la valeur dans le champ caché
   *  - règle l'affichage de la liste des natures correspondantes
   *  - règle le select des natures.
   */
  static initNaturesValues(){
    let natureIds = NullIfEmpty(this.fieldNatures.value)
    if ( natureIds ) {
      natureIds = natureIds.split(",")
    } else {
      natureIds = []
    }
    // console.info("natureIds", natureIds)
    this.setNaturesToMenu(natureIds)
    this.displayTaskNatureList(this.getNaturesFromMenu())
  }
  static onCloseMenuNatures(){
    this.onChangeNatures()
    this.toggleMenuNatures()
  }
  static onChangeNatures(){
    const natures = this.getNaturesFromMenu()
    this.fieldNatures.value = Object.keys(natures).join(",")
    this.displayTaskNatureList(natures)
  }
  static toggleMenuNatures(){
    const blocNature = this.blocNatures
    const isOpened = blocNature.dataset.state == 'opened'
    blocNature.classList[isOpened?'add':'remove']('hidden')
    blocNature.dataset.state = isOpened ? 'closed' : 'opened'
  }
  static displayTaskNatureList(natures){
    natures = Object.values(natures || this.getNaturesFromMenu())
    // console.info("natures", natures)
    let msg;
    if ( natures.length ) {
      msg = Object.values(natures).join(", ") +
            '<span class="explication"> ' + LANG["(click to edit)"] + '</span>.'
    } else {
      msg = LANG["tasker_Select natures"]
    }
    DGet('div#natures-list').innerHTML = msg
  }
  static setNaturesToMenu(natureIds){
    natureIds.forEach(nat_id => {
      this.menuNatures.querySelector(`option[value="${nat_id}"]`).selected = true
    })
  }
  static getNaturesFromMenu(){
    const natures = {}
    Array.from(this.menuNatures.selectedOptions).forEach(option => {
      Object.assign(natures, {[option.value]: option.text})
    })
    return natures
  }
  static get fieldNatures(){return DGet('input#natures-value')}
  static get blocNatures(){return DGet('div#natures-select-container')}
  static get menuNatures(){return DGet('select#task-natures-select')}


  // ============ INSTANCE TASK ================

  constructor(data){
    this.data = data
  }
  get title(){return this.data.title}
  get id(){return this.data.id}

} // class Task

window.Task = Task

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