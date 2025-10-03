'use strict';
import "./atwork/exclusive_task.js"
import "./atwork/alerts.js"

function DListen(o, e, m){o.addEventListener(e, m)}
function DListenClick(o, m){o.addEventListener('click', m)}

const NOW = new Date()

/**
 * Pour conserver les tâches mises de côté quand c'est le filtre
 * NB : On utilise la fonction resetAllTasks() pour remettre 
 * toutes les tâches
 */
window.TASKS_OUT = []

/**
 * 
 */
class ClassAtWork {

  /**
   * Fonction qui affiche la tâche courante.
   * 
   * La tâche courante est TOUJOURS la tâche en haut de pile.
   */
  showCurrentTask(){
    this.redefineRelativeIndexes()
    this.showTask(TASKS[0])
    sessionStorage.setItem('current-task-index', String(TASKS[0].absolute_index))
  }


  init(){
    if ( ! this.btnAfterNext /* On n'est pas sur la page de travail */ ) return ;
    // console.log(" -> <ClassAtWork>.init")
    // console.log("TASKS", TASKS)
    // console.log("PROJECTS", PROJECTS)

    /**
     * Pour des essais en direct, on peut modifier de force certaines
     * données de tâche. Ne pas oublier de retirer ça en mode pro-
     * duction
     */
    // this.__modifyTasksForTries()


    /**
     * Cas où la liste contient des tâches exclusives.
     * Maintenant, on commence par ça car on retire les tâches 
     * exclusives de la liste courante.
     * 
     * Rappel : une tâche exclusive, qui ne peut qu'être unique sur 
     * un temps, éclipse toutes les autres. C'est par exemple un coup
     * de fil ou un rendez-vous qui ne peut être supprimé.
     * Voir le détail du fonctionnement sur la fonction
     */
    TASKS = ExclusiveTask.retrieveExclusives()

    /**
     * Mode Zen
     */
    this.btnZen.classList.remove('invisible')
    if ( !sessionStorage.getItem('zen-state') ) {
      sessionStorage.setItem('zen-state', 'false')
    }
    this.zenState = (0, eval)(sessionStorage.getItem('zen-state'))
    this.setZenMode()

    this.observe()
    this.TASKS_COUNT = TASKS.length

    // On définit l'index absolu des tâches
    this.forEachTask((tk, index) => tk.absolute_index = index)

    // Préparation du "CBoxier" pour filtrer par projet
    this.prepareFiltreProjets()

    // Préparation du CBoxier pour filtrer par nature
    this.prepareFiltreNature()

    /**
     * Si un ordre de tâche a été enregistré, ce qui arrive par
     * exemple lorsque l'on part modifier une tâche et qu'on 
     * revient, alors il faut remettre cet ordre.
     */
    if ( sessionStorage.getItem('task-order') ) this.reorder_tasks() ;

    /**
     * Si une tâche était en cours avant le rechargement, on la
     * reprend
     */
    let indexCurTask;
    if ( (indexCurTask = sessionStorage.getItem('current-task-index')) ){
      indexCurTask = Number(indexCurTask)
      const lastIndex = TASKS.length - 1
      while ( TASKS[0].absolute_index != indexCurTask ){
        const first = TASKS.shift()
        TASKS.splice(lastIndex, 0, first)
      }
    }

    /**
     * Si un temps de départ était enregistré (pour une tâche en 
     * cours de travail), on le réactive.
     */
    let z ;
    if ( (z = sessionStorage.getItem('running-start-time')) ){
      this.running = true
      this.runningStartTime = Number(z)
      this.toggleStartStopButtons()
    }

    /**
     * On programme les alertes qui ont été remontées
     */
    Alerts.schedule()

    // On affiche la tâche courante
    this.showCurrentTask()

    // On affiche le nombre de tâche courante
    this.setTaskCount()
  }

  setTaskCount(){
    DGet('div#current-task-count').innerHTML = TASKS.length
  }

  resetAllTasks(){
    TASKS_OUT.forEach(tk => TASKS.push(tk))
    TASKS_OUT = []
  }

  /**
   * @return True is la tâche d'identifiant +taskId+ n'est pas en session courante
   */
  notInSession(taskId){
    for (var task of TASKS){
      if ( task.id == taskId) return false; // => en session
    }
    return true; // => pas en session
  }

  /**
   * @return la tâche en session courante, si elle existe
   */
  getTask(taskId){
    for (var task of TASKS){ if ( task.id == taskId) return task }
  }

  prepareFiltreProjets(){
    const values = Object.values(PROJECTS).map(p => {
      return {key: p.id, label: p.title, checked: true}
    })
    const data = {
        values: values
      , title: LOC('Filter per project')
      , onOk: this.onFiltrePerProjets.bind(this)
      , onCancel: this.onFiltrePerProjets.bind(this)
      , container: DGet('div#container-filter-per-project')
    }
    const options = {
        okName: LOC('Filter')
      , return_checked_keys: true
    }
    this.projectFilter = new CBoxier(data, options)
  }

  prepareFiltreNature(){
    const values = Object.values(NATURES).map(p => {
      return {key: p.id, label: p.name, checked: false}
    })
    const data = {
        values: values
      , title: LOC('Filter per nature')
      , onOk: this.onFiltrePerNatures.bind(this)
      , onCancel: this.onFiltrePerNatures.bind(this)
      , container: DGet('div#container-filter-per-nature')
    }
    const options = {
        okName: LOC('Filter')
      , return_checked_keys: true
      , width: 680
    }
    this.natureFilter = new CBoxier(data, options)
  }

  /**
   * Filtrage de la liste des tâches
   * 
   * Ce filtrage, pour le moment, peut se faire suivant le projet ou
   * suivant la nature.
   */
  applyFiltersOnTasks(){
    const tasks_out = [] // pour le remettre si aucune ne reste
    this.redefineRelativeIndexes()
    
    // On travaille sur une liste inversée pour ne pas modifier les
    // indexes des tâches
    const reversed_tasks = TASKS.reverse().map(tk => {return tk})

    reversed_tasks.forEach(tk => {
      const projectOk = (!this.projectsIn) || this.taskIsInProject(tk, this.projectsIn)
      const natureOk  = (!this.naturesIn)  || this.taskHasNatures(tk, this.naturesIn)

      if ( !(projectOk && natureOk) ) {
        tasks_out.push(TASKS.splice(tk.relative_index, 1)[0])
      }
    })

    if ( TASKS.length == 0 ) {
      if ( confirm(LOC('There are no tasks left. Should I restore the filtered tasks?')) ) { 
        tasks_out.forEach(tk => TASKS.push(tk))
      } else {
        // Il faut toujours garder au moins une tâche
        Flash.notice(LOC('I’m keeping one nonetheless.'))
        TASKS.push(tasks_out.shift())
      }
    }
    // On garde les tâches filtrées
    TASKS_OUT = tasks_out
    this.redefineRelativeIndexes()
    this.showCurrentTask()
  }

  /**
   * @return True quant la tâche +task+ contient au moins une des 
   * natures de la liste +natures+
   */
  taskHasNatures(task, natures){
    console.info("task", task)
    if ( !task.natures || !task.natures.length) return false ;
    for ( var nat of task.natures ){
      if ( natures.includes(nat) ) return true
    }
    return false
  }
  /**
   * @return True si la tâche +task+ appartient à un projet de 
   * +projects+
   * @param {Object} task Table des données de la tâche
   * @param {Object} projects Liste des identifiants de projet. Table
   *                 avec en clé l'identifiant du projet et en valeur
   *                 True
   */
  taskIsInProject(task, projects){
    return this.projectsIn[task.project_id] === true
  }

  /**
   * Application du filtre par projet
   * 
   */
  onFiltrePerProjets(projectsIn){
    if ( undefined === projectsIn ) {
      // Annulation
      this.invertButtonFilterState(this.btnFilterbyProject)
    } else {
      this.projectsIn = projectsIn
      this.applyFiltersOnTasks()
    }
  }
  
  onFiltrePerNatures(naturesIn){
    if ( undefined === naturesIn ) {
      // Annulation
      this.invertButtonFilterState(this.btnFilterbyNature)
    } else {
      this.naturesIn = naturesIn
      this.applyFiltersOnTasks()
    }
  }

  __modifyTasksForTries(){
    
    // Pour ne rien tenter (mode normal)
    return
    
    /**
     * On va modifier la troisième tâche pour qu'elle devienne
     * exclusive (elle doit donc passer en tête)
     */
    const task = TASKS[2]
    if ( !task ) {
      Flash.error("Il n'y a pas assez de tâche pour en faire une exclusive (il en faut au moins 3, recharger le seeds).")
      return false
    }
    Object.assign(task, {
      title: "Essai de tâche exclusive forcée"
    })
    Object.assign(task.task_spec, {
        priority: 5
      , should_start_at: new Date(Date.now() + 5 * 1000) // commencera 5 secondes plus tard
      , should_end_at: new Date(Date.now() + 10 * 1000) // finira 5 seconds plus tard
    })
  }

  /**
   * Pour remettre TASKS dans l'ordre où il a été enregistré dans
   * task-order
   */
  reorder_tasks(){
    const orderedTaskIds = sessionStorage.getItem('task-order').split(',')
    // console.info("Ordre tâches récupéré", orderedTaskIds)
    const task_table = {}
    TASKS.forEach(tk => Object.assign(task_table, {[tk.id]: tk}))
    TASKS = [];
    orderedTaskIds.forEach(tk_id => {
      TASKS.push(task_table[tk_id])
      delete task_table[tk_id]
    })
    // On met enfin les tâches qui ont pu être ajoutées entre temps
    for (var tkid in task_table) { TASKS.push(task_table[tkid]) }
    // console.info("TASKS après reclassement", TASKS)
    sessionStorage.removeItem('task-order')
  }
  /**
   * Fonction qui consigne l'ordre actuel des tâches dans l'item de
   * session task-order pour le remettre en revenant sur la page.
   */
  register_task_order(){
    const order = TASKS.map(tk => {return tk.id}).join(',')
    console.info("Ordre tâches consigné", order)
    sessionStorage.setItem('task-order', order)
  }

  /**
   * @return {Object} La tâche courante (données)
   */
  get currentTask(){return TASKS[0]}
  set currentTask(tk){
    TASKS.splice(tk.relative_index, 1)
    TASKS.unshift(tk)
  }
  /**
   * Pour définir de force la tâche courante et l'afficher
   * 
   * Note : ne pas utiliser this.currentTask = ... qui ne recalcule
   * pas les indexes et n'affiche pas la tâche courante.
   */
  setCurrentTask(task){
    this.currentTask = task
    this.showCurrentTask()
  }

  /**
   * Permet d'injecter une tâche dans les tâches de session. Si
   * options.asCurrent est true, on la met en tâche courante
   */
  injectTask(task, options){
    TASKS.push(task)
    spy("Nouvelle liste de tâches", TASKS)
    if (options && options.asCurrent){
      this.setCurrentTask(task)
    }
  }

  /**
   * Méthode inaugurée pour les alertes qui permet de remonter une 
   * tâche depuis le serveur (BdD), de l'injecter dans les tâches
   * actuelle et de la mettre en tâche courante.
   * 
   * @param {String} taskId Identifiant de la tâche à remonter
   */
  fetchTaskAndSetCurrent(taskId){
    if ( 'string' == typeof taskId ) {
      ServerTalk.dial({
          route:    'tasksop/fetch'
        , data:     {task_id: taskId}
        , callback: this.afterFetchTask.bind(this)
      })
    }
  }
  afterFetchTask(retour){
    console.log("-> afterFetchTask", retour)
    if ( retour.ok ) {
      this.injectTask(retour.task, {asCurrent: true})
    } else {
      Flash.error(retour.error)
    }
  }

  removeCurrentTask(){
    if ( this.running ) {
      sessionStorage.removeItem('running-start-time')
      this.running = false
    }
    TASKS.shift()
    this.showCurrentTask()
  }

  /**
   * Pour jouer l'opération +operation+ sur la tâche courante puis
   * appeler la fonction +callback+ avec, éventuellement les données
   * +extraData+ ajoutées.
   * 
   * Cette opération doit être définie par une fonction elixir :
   *    exec_op("+operation+", %{"task_id" => task_id} = _params)
   * dans le fichier tasks_op_controller.ex
   * 
   * @param {String} operation L'opération à jouer sur la tâche
   * @param {Function} callback La fonction de retour
   * @param {Object|Undefined} extraData les données supplémentaires
   */
  runOnCurrentTask(operation, callback, extraData){
    const data = Object.assign(extraData||{}, {task_id: this.currentTask.id})
    ServerTalk.dial({
        route: `/tasksop/${operation}`
      , data: data
      , callback: callback
    })
  }

  /**
   * Fonction qui affiche la tâche fournie en argument.
   * 
   * @param {Object} task Les données de la tâche à afficher
   * 
   */
  showTask(task){
    this.setField('title', task.title)
    this.setField('details', task.task_spec.details || "")
    this.setField('absolute_index', task.absolute_index + 1)
    this.setField('relative_index', task.relative_index + 1)
    this.setField('tags', this.buildTags(task))
    this.setField('scripts', this.buildScriptsTools(task))
    this.setField('notes', this.buildNotes(task))
    this.setAndShowField('bandeau', this.bandeauFor(task))
  }
  setAndShowField(fName, fValue){
    if ( fValue ) {
      this.showField(fName)
      this.setField(fName, fValue)
    } else this.maskField(fName)
  }
  setField(fName, fValue){
    if ( 'string' == typeof fValue || 'number' == typeof fValue) {
      this.field(fName).innerHTML = fValue || "" //`[${fName} non défini]`
    } else if (fValue && fValue.length) {
      this.field(fName).innerHTML = ""
      fValue.forEach(o => this.field(fName).appendChild(o))
    } else {
      console.error("Impossible de régler la valeur du champ '%s' à ", fName, fValue)
    }
  }
  showField(fName){this.field(fName).classList.remove('hidden')}
  maskField(fName){this.field(fName).classList.add('hidden')}
  field(fName){
    return DGet(`#current-task-${fName}`)
  }

  /**
   * Définit le bandeau de travers sur la tâche
   */
  bandeauFor(task){
    if ( task.task_time.imperative_end) {
      const fin = new Date(task.task_time.should_end_at)
      let mns = fin.getMinutes()
      if ( mns < 10 ) mns = `0${mns}`
      return `Fin impérative à ${fin.getHours()}:${mns}`
    }
  }

  buildTags(task){
    let tags = "";
    if ( task.tags && task.tags.length ) {
      tags = task.tags.map(tag => {
        const o = DCreate('SPAN', {class: 'mini-tool', text: tag})
        return o
      })
    }
    return tags
  }
  buildScriptsTools(task){
    let scripts = "";
    if ( task.scripts && task.scripts.length ){
      scripts = task.scripts.map(script => {
        const o = DCreate('SPAN', {class:'mini-tool', text: `🪛 ${script.title}`})
        DListenClick(o, this.onRunScript.bind(this, script))
        return o
      })
    }
    return scripts
  }
  onRunScript(script, ev){
    this.runOnCurrentTask('run_script', this.afterRunScript.bind(this), {script: script})
  }
  afterRunScript(retour){
    if (retour.ok) {
      console.log("Retour de script", retour)
      Flash.success(LOC('The script was executed successfully!'))
    } else {
      Flash.error(retour.error)
    }
  }

  buildNotes(task){
    // console.info("tâche pour notes", task)
    let notes = "";
    if ( task.notes && task.notes.length ){
      notes = task.notes.map(dnote => {
        const o = DCreate('DIV', {class: 'note'})
        o.appendChild(DCreate('DIV', {class: 'title', text: dnote.title}))
        const details = `${dnote.details} <span class="author">${dnote.author}</span><span class="date">, ${LOC('on (date)')}${dnote.date}</span>` 
        o.appendChild(DCreate('DIV', {class: 'details', text: details}))

        return o
      })
    }
    return notes
  }



  observe(){
    DListenClick(this.btnStart      , this.onClickStart.bind(this))
    DListenClick(this.btnStop       , this.onClickStop.bind(this))
    DListenClick(this.btnDone       , this.onClickDone.bind(this))
    DListenClick(this.btnEdit       , this.onEditCurrentTask.bind(this))
    DListenClick(this.btn2end       , this.onPushToTheEnd.bind(this))
    DListenClick(this.btnAfterNext  , this.onPushAfterNext.bind(this))
    DListenClick(this.btnLater      , this.onPushLater.bind(this))
    DListenClick(this.btnOutOfDay   , this.onOutOfDay.bind(this))
    DListenClick(this.btnSup        , this.onRemove.bind(this))
    DListenClick(this.btnProjet     , this.onProjet.bind(this))
    DListenClick(this.btnResetOrder , this.onResetOrder.bind(this))
    DListenClick(this.btnSortList   , this.onSortList.bind(this))
    DListenClick(this.btnChooseTask , this.onChooseInTaskList.bind(this))
    DListenClick(this.btnZen        , this.onToggleZenMode.bind(this))
    DListenClick(this.btnRandom     , this.onRandomTask.bind(this))
    DListenClick(this.btnFilterbyProject, this.onFilterByProject.bind(this))
    DListenClick(this.btnFilterbyNature, this.onFilterByNature.bind(this))

  }
  get boutonsZenMode(){return [this.btnResetOrder, this.btnProjet, this.btnEdit, 
    this.btnOutOfDay, this.btnLater, this.btnAfterNext, this.btn2end
  ]}

  onFilterByNature(ev){
    const newStateActif = this.invertButtonFilterState(this.btnFilterbyNature)
    if ( newStateActif ) {
      this.natureFilter.show()
    } else {
      // Désactiver le filtre par nature
      delete this.naturesIn
      this.resetAllTask()
      this.applyFiltersOnTasks()
    }
    return stopEvent(ev)
  }
  onFilterByProject(ev){
    const newStateActif = this.invertButtonFilterState(this.btnFilterbyProject)
    if ( newStateActif ) {
      this.projectFilter.show()
    } else {
      // Désactiver le filtre par projet
      delete this.projectsIn
      this.resetAllTasks()
      this.applyFiltersOnTasks()
    }
    return stopEvent(ev)
  }

  invertButtonFilterState(btn){
    let newState;
    if ( btn.dataset.state == 'actif' ) {
      newState = ''
    } else {
      newState = 'actif'
    }
    btn.dataset.state = newState
    return newState == 'actif'
  }


  onToggleZenMode(ev){
    this.zenState = !this.zenState
    sessionStorage.setItem('zen-state', this.zenState ? 'true' : 'false')
    this.setZenMode()
  }
  setZenMode(){
    // console.info("Zen mode (nouvel état)", this.zenState)
    const method = this.zenState ? 'add' : 'remove' ;
    this.boutonsZenMode.forEach(btn => btn.classList[method]('invisible'))
    this.btnZen.classList[this.zenState?'add':'remove']('on')
  }

  /**
   * Fonction appelée quand on clique sur le bouton "Démarre" pour
   * lancer la tâche. Elle met en route le chronomètre et regarde
   * s'il y a une durée de travail définie.
   */
  onClickStart(ev){
    this.runningStartTime = Number(new Date())
    sessionStorage.setItem('running-start-time', String(this.runningStartTime))
    this.running = true
    this.toggleStartStopButtons()
  }
  onClickStop(ev /* undefined quand appelé directement */){
    if ( !this.runningStartTime) {
      // Page rechargée en cours de travail
      this.runningStartTime = Number(sessionStorage.getItem('running-start-time'))
    }
    this.runningStopTime = Number(new Date())
    this.running = false
    this.toggleStartStopButtons()

    const laps = {start: this.runningStartTime, stop: this.runningStopTime}
    this.runOnCurrentTask(
        'save_working_time'
      , this.afterSaveLaps.bind(this)
      , {laps: laps}
    )
  }
  onClickDone(ev){
    if (!this.runningStartTime){
      /**
       * La tâche a été démarrée, et on utilise le bouton "Effectuée" 
       * pour en marquer la fin, sans passer par le bouton "Stop".
       * Il faut donc faire comme s'il avait arrêté la tâche quand 
       * même
       */
      this.onClickStop(ev)
    }
    this.runOnCurrentTask('is_done', this.afterSetDone.bind(this))
  }
  afterSetDone(retour){
    if (retour.ok) {
      this.removeCurrentTask()
    } else { 
      console.error(retour)
      Flash.error(retour.error) 
    }
  }
  afterSaveLaps(retour){
    if ( retour.ok ){
      sessionStorage.removeItem('running-start-time')
      if ( this.currentTask.id != retour.task_id ){
        Flash.error(LOC('Strange… the current task has changed. I cant’t update its execution time.'))
      } else {
        this.currentTask.task_time.execution_time = retour.execution_time
      }
      Flash.notice(LOC('Working time recorded'))
    } else {
      Flash.error(retour.error)
    }
  }

  // Pour choisir une tâche au hasard
  onRandomTask(ev){
    let randIndex = 1 + parseInt(Math.random() * (TASKS.length - 1))
    const task = TASKS.splice(randIndex, 1)[0]
    TASKS.unshift(task)
    this.showCurrentTask()
  }

  onPushToTheEnd(ev){
    const first = TASKS.shift()
    TASKS.push(first)
    this.showCurrentTask()
  }
  onPushAfterNext(ev){
    const first = TASKS.shift()
    TASKS.splice(1, 0, first)
    this.showCurrentTask()
  }
  onPushLater(ev){
    const pos = Math.round(Math.random() * (this.TASKS_COUNT - 1) + 1)
    const first = TASKS.shift()
    TASKS.splice(pos, 0, first)
    Flash.notice(LOC('The task has been placed in position $1.', [String(pos + 1)]))
    this.showCurrentTask()
  }
  onOutOfDay(ev){
    this.removeCurrentTask()
    Flash.notice(LOC('Reloading the page will be enought to restore it.'))
  }
  onRemove(ev){
    if ( !confirm(LOC('Do you really want to permanently delete this task?')) ) return ;
    this.runOnCurrentTask('remove', this.afterRemove.bind(this))
  }
  afterRemove(retour){
    if (retour.ok) {
      this.removeCurrentTask()
    } else {
      console.error(retour)
      Flash.error(retour.error)
    }
  }
  /**
   * Édition de la tâche
   * Avant d'y aller, on enregistre l'état actuel de la liste pour 
   * pouvoir le remettre au retour.
   */
  onEdit(ev){
    this.register_task_order()
    sessionStorage.setItem('back', `/work|${LOC('Back to work')}`)
  }
  onEditCurrentTask(ev){
    this.editTaskById(this.currentTask.id)
    return stopEvent(ev)
  }
  editTaskById(taskId){
    this.onEdit()
    const loc = window.location
    const url = `${loc.protocol}//${loc.host}/tasks/${taskId}/edit`
    window.location = url
  }
  onProjet(ev){
    this.register_task_order()
    sessionStorage.setItem('back', `/work|${LOC('Back to work')}`)
    const loc = window.location
    const url = `${loc.protocol}//${loc.host}/projects/${this.currentTask.project_id}/edit`
    window.location = url
  }
  onResetOrder(ev){
    TASKS.sort(function(a,b){return a.absolute_index > b.absolute_index ? 1 : -1})
    Flash.notice(LOC('Initial order restored'))
    this.showCurrentTask()
  }

  /**
   * Méthode appelée quand on clique sur le bouton pour CHOISIR une
   * tâche dans la liste.
   */
  onChooseInTaskList(ev){
    if ( this.taskListOpen ) {
      // Normalement, ne peut pas arriver puisque le bouton "Choisir
      // une tâche" a été rendu invisible.
    } else {
      this.showTasksAsList(this.onChooseTask.bind(this))
      UI.hide(this.btnChooseTask)
    }
    return stopEvent(ev)
  }
  /**
   * Méthode associée à la précédente appelée lorsque l'on clique une
   * tâche dans la liste pour la choisir (elle va devenir la tâche
   * courante)
   */
  onChooseTask(task, ev){
    this.removeTasksAsList()
    UI.reveal(this.btnChooseTask)
    this.setCurrentTask(task)
    return stopEvent(ev)
  }

  /** 
   * Quand on clique sur le bouton pour TRIER la liste des tâches
   * 
   * Note : c'est un affichage où on peut les voir comme des
   * cartes les unes derrière les autres.
   */
  onSortList(ev){
    if ( ev /* la toute première fois */) {
      if ( this.taskListOpen ) {
        this.btnSortList.innerHTML = LOC('Sort')
        UI.unsetMainButton(this.btnSortList)
        this.showCurrentTask()
        return this.removeTasksAsList()
      } else {
        this.btnSortList.innerHTML = LOC('End of sorting')
        UI.setMainButton(this.btnSortList)
      }
      Flash.notice(LOC('Click on the task to move it forward by one. Click “Hide List” to finish.'))
    }
    this.showTasksAsList(this.onMoveForwardTaskBehind.bind(this))
    return ev && stopEvent(ev)
  }

  /**
   * Méthode d'évènement qui avance une tâche derrière devant la 
   * tâche placée avant elle, lorsque la liste de tâches est 
   * affichée par la méthode précédente.
   * Elle est invoquée lorsque la tâche est cliquée dans la liste.
   */
  onMoveForwardTaskBehind(tk, ev){
    // console.info("J'ai cliqué la tâche (que je dois passer devant", tk, tk.id)
    if ( tk.relative_index == 0 ) return
    TASKS.splice(tk.relative_index, 1)
    TASKS.splice(tk.relative_index - 1, 0, tk)
    this.removeTasksAsList()
    this.redefineRelativeIndexes()
    this.onSortList(null)
    return stopEvent(ev)
  }

  /**
   * Affiche la liste des tâches comme une liste de cartes les unes
   * derrière les autres
   * 
   * @param {Function} onClickMethod La méthode qui sera appelée quand on clique sur la tâche
   */
  showTasksAsList(onClickMethod){
    var top = 100, left = 200
    const tks = TASKS.map(tk => {return tk})
    tks.reverse().forEach(tk => {
      top += 60
      left += 20
      const d = DCreate('DIV', {class: 'details', text: tk.task_spec.details, style:'font-size:11pt;'})
      const t = DCreate('DIV', {class: 'title', text: tk.title, style:'font-size:13pt;'})
      const o = DCreate('DIV', {class: 'task-as-list', style:`top:${top}px;left:${left}px;cursor:pointer;`})
      o.appendChild(t)
      o.appendChild(d)
      o.dataset.task_id = tk.id
      DListenClick(o, ev => onClickMethod(tk, ev)) 
      document.body.appendChild(o)
    })
    this.taskListOpen = true
  }
  /**
   * Détruit la liste des tâches précédente
   */
  removeTasksAsList(){
    this.taskListOpen = false
    DGetAll('div.task-as-list').forEach(o => o.remove())
  }



  /**
   * Méthode appelée quand on démarre ou arrête une tâche
   */
  toggleStartStopButtons(){
    this.btnStart.classList[this.running?'add':'remove']('hidden')
    this.btnStop.classList[this.running?'remove':'add']('hidden')
    if ( this.running ) {
      // TODO Ici, on pourrait imaginer deux fonctionnement de l'horloge : 
      // 1) par temps écoulé depuis le départ
      // 2) par compte à rebours (quand on veut travailler pendant un
      //    certain temps ou jusqu'à une heure donnée)
      this.horloge.start(this.runningStartTime)
    } else {
      this.horloge.stop()
    }
  }

  /**
   * Pour redéfinir l'index relatif
   * 
   * Noter que cet index ne sert que pour le débuggage, entendu qu'on 
   * ne voit toujours que la première tâche, donc la tâche "1" 
   * d'index zéro.
   */
  redefineRelativeIndexes(){
    this.forEachTask((tk, i) => {
      // console.log("update index de ", tk)
      tk.relative_index = Number(i)
    })
  }

  /**
   * Boucle la méthode +method+ sur chaque tâche à faire.
   * 
   * Noter que la fonction +method+ peut utiliser en second argument
   * l'index relatif de la tâche dans la liste.
   */
  forEachTask(method){
    for(var i = 0, len = TASKS.length; i < len; ++i){
      method(TASKS[i], Number(i))
    }
  }

  get btnZen(){return this._btnzen || (this._btnzen || DGet('button.btn-zen', this.obj))}
  get btnSup(){return this._btnrem || (this._btnrem || DGet('button.btn-remove', this.obj))}
  get btnEdit(){return this._btnedit || (this._btnedit || DGet('button.btn-edit', this.obj))}
  get btnStart(){return this._btnstart || (this._btnstart || DGet('button.btn-start', this.obj))}
  get btnStop(){return this._btnstop || (this._btnstop || DGet('button.btn-stop', this.obj))}
  get btnDone(){return this._btndone || (this._btndone || DGet('button.btn-done', this.obj))}
  get btnLater(){return this._btnlater || (this._btnlater || DGet('button.btn-later', this.obj))}
  get btn2end(){return this._btn2end || (this._btn2end || DGet('button.btn-to-the-end', this.obj))}
  get btnAfterNext(){return this._btnaftnext || (this._btnaftnext || DGet('button.btn-after-next', this.obj))}
  get btnOutOfDay(){return this._btnoutday || (this._btnoutday || DGet('button.btn-out-day', this.obj))}
  get btnProjet(){return this._btnprojet || (this._btnprojet || DGet('button.btn-projet', this.obj))}
  get btnRandom(){return this._btnrand || (this._btnrand || DGet('button.btn-random', this.obj))}
  get btnResetOrder(){return this._btnresetorder || (this._btnresetorder || DGet('button.btn-reset-order', this.obj))}
  get btnSortList(){return this._btnshowlist || (this._btnshowlist = DGet('button.btn-show-list', this.obj))}
  get btnChooseTask(){return this._btnchoosetk || (this._btnchoosetk = DGet('button.btn-choose-task', this.obj))}
  get btnFilterbyProject(){return this._btnfpp || (this._btnfpp = DGet('button.btn-filter-per-project', this.obj))}
  get btnFilterbyNature(){return this._btnfpn || (this._btnfpn = DGet('button.btn-filter-per-nature', this.obj))}
  get horloge(){return this._horloge || (this._horloge = new Horloge(this))}
  get obj(){return this._obj || (this._obj || DGet('div#main-task-container'))}
}

window.AtWork = new ClassAtWork();

window.addEventListener("load", function() {AtWork.init()});
