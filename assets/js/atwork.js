'use strict';
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
    this.__modifyTasksForTries()

    /**
     * Mode Zen
     */
    this.btnZen.classList.remove('invisible')
    if ( !sessionStorage.getItem('zen-state') ) {
      sessionStorage.setItem('zen-state', 'false')
    }
    this.zenState = eval(sessionStorage.getItem('zen-state'))
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
     * Si un temps de départ était enregistré, on le réactive
     */
    let z ;
    if ( (z = sessionStorage.getItem('running-start-time')) ){
      this.running = true
      this.runningStartTime = Number(z)
      this.toggleStartStopButtons()
    }

    /**
     * Cas où la liste contient une tâche exclusive.
     * Rappel : une tâche exclusive, qui ne peut qu'être unique sur 
     * un temps, éclipse toutes les autres. C'est par exemple un coup
     * de fil ou un rendez-vous qui ne peut être supprimé.
     * Voir le détail du fonctionnement sur la fonction
     */
    this.checkExclusiveTask()

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
   * Étude du cas d'une TÂCHE EXCLUSIVE
   * 
   * Les cas possibles :
   *    1)  Pas de tâche exclusive 
   *        => ne rien faire
   *    2)  Une tâche exclusive déjà commencée 
   *        => la remettre
   *    3)  Une tâche exclusive qui commence juste maintenant
   *        => la mettre
   *    4)  Une tâche exclusive qui commence dans peu de temps
   *        => la programmer
   * 
   * Note : il peut y avoir plusieurs tâches exclusives dans une 
   * session de travail, surtout si elle est longue.
   */
  checkExclusiveTask(){
    const exclusiveTasks = TASKS.filter(tk => {return tk.task_spec.priority == 5})
    // console.info("exclusiveTasks", exclusiveTasks)
    if ( exclusiveTasks.length == 0 ) return ; // cas 1
    exclusiveTasks.forEach(tk => {
      const start = new Date(tk.task_time.should_start_at)
      const stop  = new Date(tk.task_time.should_end_at)
      Object.assign(tk, {start_at: start, end_at: stop})
      if ( start > NOW ) {
        /**
         * Une tâche exclusive à déclencher plus tard
         */
        const diffMilliseconds = start.getTime() - NOW.getTime()
        // console.info("Tâche exclusive à déclencher dans %s secondes", parseInt(diffMilliseconds / 1000), tk)
        var timer = setTimeout(this.lockExclusiveTask.bind(this, tk), diffMilliseconds)
        Object.assign(tk, {exclusive_timer: timer})
      } else {
        /**
         * Une tâche exclusive déjà en cours
         */
        // console.info("Tâche exclusive à déclencher tout de suite", tk)
        this.lockExclusiveTask(tk)
      }
    })
  }

  lockExclusiveTask(task){
    if ( task.exclusive_timer ) {
      clearTimeout(task.exclusive_timer);
      delete task.exclusive_timer
    }
    // Si une tâche courante était en cours de travail, il faut
    // demander ce que l'on doit faire. Si le worker veut enregistrer
    // le temps, on simule le clic sur le bouton stop.
    if ( this.running ){
      if (confirm(LOC('Can I log the working time on the current task? (Otherwise, it will not be recorded'))){
        this.onClickStop(null)
      }
    }
    // On met la tâche exclusive en tâche courante
    this.currentTask = task
    this.showCurrentTask()
    // Pour bloquer l'interface, on met un div qui couvre tout
    this.UIMask = new UIMasker({
        counterback: task.end_at.getTime()
      , title: `${LOC('In progress:')} ${task.title}`
      , ontime: this.unlockExclusiveTask.bind(this, task, true)
      , onclick: LOC('You have to wait for the end of the task.')
      , onforceStop: this.unlockExclusiveTask.bind(this, task, false)
    })
    this.UIMask.activate()
  }
  unlockExclusiveTask(task, regularEnd){
    if ( task.exclusive_timer ) {
      clearTimeout(task.exclusive_timer);
      delete task.exclusive_timer
    }
    let markDone = regularEnd || confirm(LOC('Should I mark the end of this exclusive task?'))
    if (markDone) {
      this.runOnCurrentTask('is_done', this.afterSetDone.bind(this))
    } else {
      // Pour le moment, on ne fait rien
    }
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
  setCurrentTask(task){this.currentTask = task}


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
  field(fName){
    return DGet(`#current-task-${fName}`)
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
    DListenClick(this.btnEdit       , this.onEdit.bind(this))
    DListenClick(this.btn2end       , this.onPushToTheEnd.bind(this))
    DListenClick(this.btnAfterNext  , this.onPushAfterNext.bind(this))
    DListenClick(this.btnLater      , this.onPushLater.bind(this))
    DListenClick(this.btnOutOfDay   , this.onOutOfDay.bind(this))
    DListenClick(this.btnSup        , this.onRemove.bind(this))
    DListenClick(this.btnProjet     , this.onProjet.bind(this))
    DListenClick(this.btnResetOrder , this.onResetOrder.bind(this))
    DListenClick(this.btnShowList   , this.onShowList.bind(this))
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

  onClickStart(ev){
    this.runningStartTime = Number(new Date())
    sessionStorage.setItem('running-start-time', String(this.runningStartTime))
    this.running = true
    this.toggleStartStopButtons()
  }
  onClickStop(ev){
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
    const loc = window.location
    const url = `${loc.protocol}//${loc.host}/tasks/${this.currentTask.id}/edit`
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
    this.showCurrentTask()
  }

  /** 
   * Quand on clique sur le bouton pour voir la liste des tâches
   * 
   * Note : je voudrais un affichage où on peut les voir comme des
   * cartes les unes derrière les autres.
   */
  onShowList(ev){
    if ( ev /* la toute première fois */) {
      if ( this.taskListOpen ) {
        this.taskListOpen = false
        this.btnShowList.innerHTML = LOC('Sort')
        this.showCurrentTask()
        return this.removeTaskList()
      } else {
        this.btnShowList.innerHTML = LOC('End of sorting')
      }
      Flash.notice(LOC('Click on the task to move it forward by one. Click “Hide List” to finish.'))
    }
    var top = 100, left = 200
    const tks = TASKS.map(tk => {return tk})
    tks.reverse().forEach(tk => {
      top += 80
      left += 40
      const d = DCreate('DIV', {class: 'details', text: tk.task_spec.details})
      const t = DCreate('DIV', {class: 'title', text: tk.title})
      const o = DCreate('DIV', {class: 'task-as-list', style:`top:${top}px;left:${left}px;`})
      o.appendChild(t)
      o.appendChild(d)
      o.dataset.task_id = tk.id
      DListenClick(o, this.onClickTaskInList.bind(this, tk)) 
      document.body.appendChild(o)
    })
    this.taskListOpen = true
    return ev && stopEvent(ev)
  }

  onClickTaskInList(tk, ev){
    // console.info("J'ai cliqué la tâche (que je dois passer devant", tk, tk.id)
    if ( tk.relative_index == 0 ) return
    TASKS.splice(tk.relative_index, 1)
    TASKS.splice(tk.relative_index - 1, 0, tk)
    this.removeTaskList()
    this.redefineRelativeIndexes()
    this.onShowList(null)
    return stopEvent(ev)
  }
  removeTaskList(){
    DGetAll('div.task-as-list').forEach(o => o.remove())
  }


  toggleStartStopButtons(){
    this.btnStart.classList[this.running?'add':'remove']('hidden')
    this.btnStop.classList[this.running?'remove':'add']('hidden')
    if ( this.running ) {
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
  get btnShowList(){return this._btnshowlist || (this._btnshowlist = DGet('button.btn-show-list', this.obj))}
  get btnFilterbyProject(){return this._btnfpp || (this._btnfpp = DGet('button.btn-filter-per-project', this.obj))}
  get btnFilterbyNature(){return this._btnfpn || (this._btnfpn = DGet('button.btn-filter-per-nature', this.obj))}
  get horloge(){return this._horloge || (this._horloge = new Horloge())}
  get obj(){return this._obj || (this._obj || DGet('div#main-task-container'))}
}

window.AtWork = new ClassAtWork();

window.addEventListener("load", function() {AtWork.init()});
