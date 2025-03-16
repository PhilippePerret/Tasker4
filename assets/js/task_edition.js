'use strict';
import "./task_edition/task_script.js"
import "./task_edition/task_dependencies.js"
import "./task_edition/task_notes.js"
import "./task_edition/repeat.js"

class Task {
  static init(){
    // D'abord il faut empêcher de soumettre le formulaire en
    // tapant 'Enter' dans un champ de formulaire
    DGetAll('input[type="text"]').forEach(input => {
      input.addEventListener('keydown', this.stopEnterKey.bind(this))
    })

    // Est-on avec l'éditeur complet ?
    const isFullEditor = this.fieldDureeUnit && this.menuPriority
    
    if ( isFullEditor ) {
      
      // Surveiller le menu de la durée attendue : quand on choisit 
      // "---" on doit masquer le champ du nombre et inversement
      this.fieldDureeUnit.addEventListener('change', this.onChangeDureeUnit.bind(this))

      // Surveiller le menu priority (le choix "exclusive" doit
      // entrainer une vérification)
      // Observation du menu priorité
      this.menuPriority.addEventListener('change', this.onChangePriority.bind(this))

      // Préparation du menu des natures
      this.prepareNaturesChooser()
    }

    // On crée une instance pour gérer les dépendances
    this.taskDeps = new TaskDependencies()
    this.taskDeps.init()

    // Préparation du bloc des scripts de tâche
    TaskScript.init()

    // Préparation du bloc des notes
    Blocnotes.init()
    
  } // init

  static get TaskSpecId(){
    return this._taskspecid || (this._taskspecid = DGet('input#task_spec_id', this.obj).value)
  }

  static get fieldDureeUnit(){return DGet('select#task_time_exp_duree_unit')}
  static get fieldDureeValue(){return DGet('input#task_time_exp_duree_value')}
  static get obj(){return this._obj || (this._obj = DGet('form#task-form'))}  
  
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
    if (ev.key == 'Enter'){ return stopEvent(ev) }
  }

  // ======== NATURES ==========
  /**
   * Fonction appelée à l'initialisation du formulaire, lorsque la
   * tâche contient la donnée "natures", qui prépare le formulaire
   * au niveau des natures. C'est-à-dire qui : 
   *  - relève la valeur dans le champ caché
   *  - règle l'affichage de la liste des natures correspondantes (en
   *    utilisant CBoxier)
   */
  static prepareNaturesChooser(){
    let natureIds = NullIfEmpty(this.fieldNatures.value)
    if ( natureIds ) {
      natureIds = natureIds.split(",")
    } else {
      natureIds = []
    }
    const values = {}
    const data = {
        id: "nature-chooser"
      , title: LOC('Task natures')
      , onOk: this.onChooseNatures.bind(this)
      , values: NATURES
      , container: DGet("div#natures-select-container")
    }
    const options = {
        okName: LOC('Choose these natures')
      , checkeds: natureIds
      , return_checked_keys: true
    }
    this.natureChooser = new CBoxier(data, options)
    // console.info("natureIds", natureIds)
    this.displayTaskNatureList(natureIds)
  }

  static onChooseNatures(natureIds){
    this.fieldNatures.value = natureIds.join(",")
    this.displayTaskNatureList(natureIds)
  }

  // Pour ouvrir la fenêtre du choix des natures
  static toggleMenuNatures(){
    this.natureChooser.show()
  }

  // Pour afficher la liste des natures
  static displayTaskNatureList(natureIds){
    let content;
    if (natureIds.length) {
      content = natureIds.map(key => {return NATURES[key]}).join(", ")
    } else {
      content = "[" + LOC('Choose task natures') + "]"
    }
    DGet('div#natures-list').innerHTML = content
  }


  // ======= PRIORITÉ ========

  static onChangePriority(ev){
    const prior = this.menuPriority.value;
    if ( prior != "5" ) return ;
    const startat = NullIfEmpty(this.fieldStartAt.value)
    const endat   = NullIfEmpty(this.fieldEndAt.value)
    try {
      if ( !startat || !endat ) {
        throw LOCALES['set_start_stop_for_exclusive']
      }
    } catch (err) {
      this.menuPriority.selectedIndex = 0
      if (startat) this.fieldEndAt.focus();
      else this.fieldStartAt.focus();
      Flash.error(err)
    }
  }


  static get fieldStartAt(){return DGet('input#start-at')}
  static get fieldEndAt(){return DGet('input#end-at')}
  static get menuPriority(){return DGet('select#task-priority')}
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