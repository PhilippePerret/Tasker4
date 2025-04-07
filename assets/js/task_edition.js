'use strict';
import "./task_edition/task_script.js"
import "./task_edition/task_dependencies.js"
import "./task_edition/task_notes.js"
import "./task_edition/task_alerts.js"
import "./task_edition/crontab.js"

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

      // Préparation du bloc des alertes
      AlertsBlock.init()

      // Préparation du bloc des natures
      this.prepareNaturesChooser()
      
      // On crée une instance pour gérer les dépendances
      this.taskDeps = new TaskDependencies()
      this.taskDeps.init()
      
      // Préparation du bloc des scripts de tâche
      TaskScript.init()
      
      // Préparation du bloc des notes
      Blocnotes.init()
      
      // Surveillance de la CB "Imperative End" et réglage de son état
      this.cbImperativeEnd.addEventListener('click', this.onChooseImperativeEnd.bind(this, this.cbImperativeEnd))
      this.setImperativeEndState()
      
      // Surveillance du champ de date de fin (qui doit changer l'état
      // de la cb "Fin impérative")
      this.fieldEndAt.addEventListener('change', this.onChangeEndAt.bind(this))
        
      // Surveillance du champ de date de début (qui doit permettre 
      // de définir une alerte)
      this.fieldStartAt.addEventListener('change', this.onChangeStartAt.bind(this))
      
    } // fin si full editor
  } // init

  /**
   * Méthode d'évènement appelée quand on change la date de début de
   * tâche
   */
  static onChangeStartAt(ev){
    AlertsBlock.onChangeStartAt(this.getStartAt())
    return stopEvent(ev)
  }
  /**
   * Méthode d'event appelée quand on change la date de fin de tâche
   */
  static onChangeEndAt(ev){
    this.setImperativeEndState()
    return stopEvent(ev)
  }

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
      AlertsBlock.getData()
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
    const natureCount = natureIds.length
    const content = (_ => {
      return natureCount
        ? natureIds.map(key => {return NATURES[key]}).join(", ")
        : ""
    })()
    const btnName = '[' + (_ => {
      return natureCount ? LOC('Edit') : LOC('Choose task natures')
    })() + ']'

    DGet('div#natures-list').innerHTML = content
    DGet('span#natures-list-button').innerHTML = btnName
  }


  // ======= PRIORITÉ ========

  static onChangePriority(ev){
    const prior = this.menuPriority.value;
    if ( prior != "5" ) {
      this.expliPriority.innerHTML = ""
      return
    }
    const startat = this.getStartAt()
    const endat   = this.getEndAt()
    try {
      this.expliPriority.innerHTML = LOC('Exclusive task explication')
      if ( !startat || !endat ) {
        this.menuPriority.selectedIndex = 0
        const errMsg = LOC('A exclusive requires headline and deadline')
        const errField = startat ? this.fieldEndAt : this.fieldStartAt ;
        raise(errMsg, errField)
      }
    } catch (err) {}
  }

  /**
   * Règle l'état de la case à cocher "Fin impérative".
   * Elle ne doit être accessible que lorsqu'une date de fin est 
   * définie.
  */
 static setImperativeEndState() {
   this.cbImperativeEnd.disabled =
   this.labelImperativeEnd.classList[this.getEndAt()?'remove':'add']('invisible')
  }
  
  static onChooseImperativeEnd(cb, ev){
    try {
      
      if ( cb.checked && !this.fieldEndAt.value ) {
        cb.checked = false
        stopEvent(ev)
        raise("A hard deadline obviously requires an end date.", this.fieldEndAt)
      }
      this.expliTimes.innerHTML = cb.checked ? LOC('Hard deadline Explication') : "" ;
    } catch(err) {
      // L'erreur est déjà affichée
    }
  }
  
  static getStartAt(){return NullIfEmpty(this.fieldStartAt.value)}
  static getEndAt(){return NullIfEmpty(this.fieldEndAt.value)}
  
  static get fieldStartAt(){return DGet('input#start-at')}
  static get fieldEndAt(){return DGet('input#end-at')}
  static get menuPriority(){return DGet('select#task-priority')}
  static get expliPriority(){return DGet('div#description-task-priority')}
  static get fieldNatures(){return DGet('input#natures-value')}
  static get blocNatures(){return DGet('div#natures-select-container')}
  static get menuNatures(){return DGet('select#task-natures-select')}
  static get cbImperativeEnd(){return DGet('input#cb-imperative-end')}
  static get labelImperativeEnd(){return this.cbImperativeEnd.parentNode}
  static get expliTimes(){return DGet('div#description-times')}


  // ============ INSTANCE TASK ================

  constructor(data){
    this.data = data
  }
  get title(){return this.data.title}
  get id(){return this.data.id}

} // class Task

window.Task = Task

window.addEventListener('load', function(){
  Task.init()
  Crontab.onLoad()
  AlertsBlock.onLoad()
})

Crontab.ctest = function(){
  if (!this.activited ) {
    this.activited = true
    return active_lib_testor(Crontab)
  }
  /* === DÉBUT DES TESTS === */
  const r = Crontab.crontab;
  const hf = r.hiddenField;

  t("--- Tests de la gestion du CRON ---");

  hf.value = "5 * * * *"
  r.setState()

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