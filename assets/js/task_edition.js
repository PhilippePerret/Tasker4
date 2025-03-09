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

    this.menuNatures && this.initNaturesValues()
    
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
    // Maintenant on ne fait plus rien puisque les valeurs sont 
    // consignées en direct
    return true
  }
  static stopEnterKey(ev){
    if (ev.key == 'Enter'){ return StopEvent(ev) }
  }

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

class Notes {
  static create(){
    const title = DGet('#new_note_title').value.trim()
    if ( title == "" ) {
      return alert(LANG["tasker_A title must be given to the note!"])
      // 
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


// ========= DÉPENDANCES ============


class TaskDependencies {

  constructor(){

  }
  init(){
    if ( ! this.btnPrevTasks ) return ;

  
    this.loadData()
    this.dispatchData()
    this.observe()

  }

  get tasks_after(){return this.data.tasks_after}
  get tasks_next(){return this.tasks_after}
  get tasks_before(){return this.data.tasks_before}
  get tasks_prev(){return this.tasks_before}

  observe(){
    // Surveiller les boutons pour choisir les tâches avant et après
    this.btnPrevTasks.addEventListener('click', this.onWantToChooseTasks.bind(this, 'prev'))
    this.btnNextTasks.addEventListener('click', this.onWantToChooseTasks.bind(this, 'next'))
  }
  loadData(){
    this.data = JSON.parse(this.fieldData.value)
    // console.info("Data dépendances", this.data)
  }

  dispatchData(){
    DGet('div#previous-task-list').innerHTML  = this.taskHumanList(this.tasks_before)
    DGet('div#next-task-list').innerHTML      = this.taskHumanList(this.tasks_after)
  }

  saveData(){

  }


  /**
   * Fonction appelée quand on clique sur les boutons pour choisir
   * les tâches précédentes et suivante.
   * Elle appelle la liste des tâches suivantes ou précédente (si des
   * dates sont déjà définies), et les affiche pour pouvoir en 
   * choisir.
   * 
   * @param {String} type 'prev' ou 'next'
   * @param {Event} ev  Evènement clic de souris
   */
  onWantToChooseTasks(type, ev){
    // On prend les dates de la tâche
    let dateRef ;
    const start_at    = DGet('input#start-at').value
    const end_at      = DGet('input#end-at').value
    const project_id  = DGet('select#project_id').value
    let task_id       = TASK_ID;
    task_id = task_id == "" ? null : task_id ;
    switch(type){
      case 'prev':
        dateRef = start_at || end_at
        break;
      case 'next': 
        dateRef = end_at || start_at
        break;
    }
    // Ajout des secondes si nécessaire
    if (dateRef != "") dateRef += ":00" ;
    // On demande la relève des tâches
    ServerTalk.dial({
        route: "/tools/get_task_list"
      , data: {script_args: {
            date_ref: dateRef
          , position: type
          , project_id: project_id
          , task_id:    task_id
          }
        }
      , callback: this.onReturnTaskList.bind(this)
    })
  }
  /**
   * Fonction appelée par le serveur (ServerTalk…) quand on remonte
   * avec une liste de tâche à afficher.
   */
  onReturnTaskList(data){
    if ( data.ok ) {
      // console.info("Retour de la liste des tâches avec", data)
      const tasks = data.tasks
      const cols = tasks.shift()
      const task_list = []
      // console.log("-> avant boucle")
      for ( var dtask of tasks ) {
        // console.log("Dans boucle", dtask)
        const task = {}
        for ( var icol in cols ) {
          task[cols[icol]] = dtask[icol]
        }
        const itask = new Task(task)
        task_list.push(itask)
      }
      const type = data.args.position
      // Fonction à appeler après le choix des tâches
      const callback = (ty => {
        switch(ty){
          case 'prev': return this.onChoosePreviousTasks.bind(this);
          case 'next': return this.onChooseNextTasks.bind(this)
        }
      })(type)

      this.showListAndChoose(task_list, type, callback)

    } else {
      Flash.error(data.error)
      console.error(data)
    }
  }

  showListAndChoose(taskList, type, callback){
    if ( taskList.length ==  0) {
      return Flash.notice(LANG["tasker_No tasks found. Therefore, none can be selected."])
    }
    const rightList = this['tasks_' + type]
    const rightIds  = rightList.map(dtask => {return dtask.id})

    const contreType = type == 'prev' ? 'next' : 'prev'
    const contreList = this['tasks_' + contreType]
    const contreIds  = contreList.map(dtask => {return dtask.id})

    const div = DCreate('DIV', {id:'task_list_container', text: `<h4>${LANG["tasker_Select tasks"]}</h4>`, style:'position:fixed;top:10em;left:10em;background-color:white;box-shadow:5px 5px 5px 5px #CCC;padding:2em;border:1px solid;border-radius:0.5em;'})
    const list = DCreate('DIV', {id:'task_list'})
    div.appendChild(list)
    // Boucle sur toutes les tâches, mais :
    // -  on ne permet la sélection qu'avec des tâches qui ne sont 
    //    pas liées dans le sens opposé
    // -  on coche les liaisons existantes
    for (const task of taskList ) {

      const taskId = task.id
      const taskIsEnable  = !contreIds.includes(taskId)
      const taskIsCheched = rightIds.includes(taskId)

      const cb_id = `cb-task-${task.id}`
      const tdiv = DCreate('DIV', {class:'task', style:"margin-top:0.5em;"})
      if ( taskIsEnable ) {
        const cb = DCreate('INPUT', {type:'checkbox', class:"cb-task", id: cb_id})
        cb.checked = taskIsCheched
        cb.dataset.uuid = task.id
        tdiv.appendChild(cb)
      } else {
        tdiv.appendChild(DCreate('SPAN', {text: '– ', class: 'disabled'}))
      }

      const label = DCreate('LABEL', {class:'task-title ' + (taskIsEnable?'enabled':'disabled'), for: cb_id, text: task.title})
      label.setAttribute('for', cb_id)
      if ( !taskIsEnable) label.setAttribute('disabled', true)
      // TODO : mettre les détails dans un div caché à faire apparaitre avec un
      // petit bouton "i" (ne le faire que si la tâche définit des détails)
      tdiv.appendChild(label)
      list.appendChild(tdiv)
    }
    const btns = DCreate('DIV',{class:'buttons'})
    div.appendChild(btns)
    const btn = DCreate('BUTTON', {text: "OK"})
    btn.addEventListener('click', this.getTaskListAndCallback.bind(this, callback))
    btns.appendChild(btn)
    document.body.appendChild(div)
  }
  getTaskListAndCallback(callback, ev){
    const taskList = []
    // TODO Récupérer la liste des tâches
    DGetAll('input[type="checkbox"].cb-task', DGet('div#task_list')).forEach(cb => {
      if ( cb.checked ) taskList.push(cb.dataset.uuid)
    })
    // On enregistre toujours la liste, même si elle est vide
    callback(taskList)

    // Détruire la boite
    DGet('div#task_list_container').remove()
  }
  onChoosePreviousTasks(taskList){
    const savedData = taskList.map(task_id => {return [task_id, TASK_ID]})
    this.saveDependencies('prev', savedData)
  }
  onChooseNextTasks(taskList){
    const savedData = taskList.map(task_id => {return [TASK_ID, task_id]})
    this.saveDependencies('next', savedData)
  }
  /**
   * Enregistre dans la table les dépendances avec la tâche courante
   * (et remonte la liste actualisée pour afficher la liste complète)
   * 
   * @param {String} nature   Soit 'prev', soit 'next'. Nature des 
   *        données transmises en sachant qu'il faudra les compléter
   *        avec les données de l'autre sens pour envoyer des données
   *        complètes au serveur (rapel : on enregistre toujours
   *        toutes les données relations)
   * @param {Array} relData Liste des relations. Ce sont des tables
   *                        qui définissent :previous et :next
   */
  saveDependencies(nature, relData){
    const contreNature = nature == 'prev' ? 'next' : 'prev';
    const contreTasks = this.getDependenciesOfNature(contreNature, 'map2save');
    relData.push(...contreTasks)
    if ( this.checkDependencies(relData) ) {
      ServerTalk.dial({
          route: "/tasksop/save_relations"
        , data: {relations: relData, task_id: TASK_ID}
        , callback: this.afterSavedDependencies.bind(this)
      })
    } else {
      Flash.error(LANG["tasker_Inconsistencies in dependencies. I cannot save them."])
    }
  }
  afterSavedDependencies(rData){
    if ( rData.ok ) {
      // TODO Procéder à l'affichage
      // console.info("Retour sauvegarde dépendances avec", rData)
      // Actualiser la liste des relations de la tâche courante
      this.data = rData.dependencies
      this.dispatchData()
    } else {
      Flash.error(rData.error)
      rData.full_error && console.error(rData.full_error)
    }
  }

  /**
   * Fonction qui s'assure que les dépendances à enregistrer sont 
   * correctes à tout niveau : 
   * - une tâche ne peut être dépendante d'elle-même
   * - une tache après une autre ne peux pas être avant cette autre.
   */
  checkDependencies(deps){
    const deps_len = deps.length
    if ( deps_len == 0 ) return true;
    try {
      // Une tâche ne peut être en dépendance d'elle-même
      deps.forEach(paire => {
        const [avant, apres] = paire
        if (avant == apres) {
          throw new Error(
            LANG["tasker_A task cannot be dependent on itself."]
          )
        }
      })
      for (var i = 0; i < deps_len - 1; ++i) {
        const [avant, apres] = deps[i]
        for (var ii = i+1; ii < deps_len; ++ii ) {
          const [autreAvant, autreApres] = deps[ii]
          if ( autreAvant == apres && autreApres == avant ) {
            throw new Error(LANG["tasker_Double dependency between task __BEFORE__ and task __AFTER__."].replace("__BEFORE__", avant).replace("__AFTER__", apres))
          }
        }
      }
      return true
    } catch(err) {
      // console.error(err)
      Flash.error(err.message)
      return false
    }
  }

  /**
   * Retourne les tâches dépendantes de la +nature+ voulue
   * 
   * @param nature {String} 'prev' ou 'next'
   */
  getDependenciesOfNature(nature, as){
    const tasks = this[nature == 'next' ? 'tasks_after' : 'tasks_before']
    switch(as){
      case 'map2save':
        return tasks.map(dtask => { 
          if ( nature == 'next' ) {
            return [TASK_ID, dtask.id]
          } else {
            return [dtask.id, TASK_ID] 
          }
        })
        break
      default:
        return tasks;
    }
  }

  taskHumanList(taskList){
    return taskList.map(tdata => {
      return '<span class="rel-task small">' + tdata.title + '</span>'
    }).join(', ')
  }

  get fieldData(){return this._fielddata || (this._fielddata = DGet('input#data-dependencies'))}
  get btnPrevTasks(){return DGet('button#btn-choose-previous-tasks')}
  get btnNextTasks(){return DGet('button#btn-choose-next-tasks')}
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
    this.activeCB = this.obj.previousSibling
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
      var cron = this.hiddenField.value
      cron = cron == "" ? undefined : cron
      // Si la valeur est définie, on régle l'interface
      if ( cron ) this.setCronUI(cron)
    }
    this.activeCB.checked = isActif
    this.obj.classList[isActif ? 'remove' : 'add']("hidden")
    this.onChangeRepeatField(null)
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
        hMin:   {raw: hMin    , value: undefined, uFreq: 'minute' , frequential: undefined}
      , dHour:  {raw: dHour   , value: undefined, uFreq: 'hour'   , frequential: undefined}
      , mDay:   {raw: mDay    , value: undefined, uFreq: 'day'    , frequential: undefined}
      , yMonth: {raw: yMonth  , value: undefined, uFreq: 'month'  , frequential: undefined}
      , wDay:   {raw: wDay    , value: undefined, uFreq: null     , frequential: false}
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
   * Affiche le résumé humain de la récurrence.
   */
  showResumeHumain(crondata){
    let sum = []
    sum.push(LANG.Summary + LANG["[SPACE]"] + ":") 
    sum.push(LANG["tasker_Repeat this task"])
    sum.push(LANG['every' + (['day','month'].includes(crondata.uFreq) ? '' : '_fem')] )
    sum.push(crondata.uFreqValue > 1 ? String(crondata.uFreqValue) : "")
    sum.push(LANG['ilya_'+crondata.uFreq] + "s")
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
      console.info("crondata.dHour", crondata.dHour)
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