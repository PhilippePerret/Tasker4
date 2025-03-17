'use strict';

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
      return Flash.notice(LOC("No tasks found. Therefore, none can be selected."))
    }
    const rightList = this['tasks_' + type]
    const rightIds  = rightList.map(dtask => {return dtask.id})

    const contreType = type == 'prev' ? 'next' : 'prev'
    const contreList = this['tasks_' + contreType]
    const contreIds  = contreList.map(dtask => {return dtask.id})

    const div = DCreate('DIV', {id:'task_list_container', text: `<h4>${LOC("Select tasks")}</h4>`, style:'position:fixed;top:10em;left:10em;background-color:white;box-shadow:5px 5px 5px 5px #CCC;padding:2em;border:1px solid;border-radius:0.5em;'})
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
  /**
   * Fonction appelée quand on clique sur le bouton "OK" pour choisir 
   * les tâches avant ou après la tâche éditée.
   */
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
    const serverData = {relations: relData, task_id: TASK_ID}
    // console.info("Données pour le serveur : ", serverData)
    if ( this.checkDependencies(relData) ) {
      ServerTalk.dial({
          route:    "/tasksop/save_relations"
        , data:     serverData
        , callback: this.afterSavedDependencies.bind(this)
      })
    } else {
      Flash.error(LOC("Inconsistencies in dependencies. I cannot save them."))
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
            LOC("A task cannot be dependent on itself.")
          )
        }
      })
      for (var i = 0; i < deps_len - 1; ++i) {
        const [avant, apres] = deps[i]
        for (var ii = i+1; ii < deps_len; ++ii ) {
          const [autreAvant, autreApres] = deps[ii]
          if ( autreAvant == apres && autreApres == avant ) {
            throw new Error(LOC("Double dependency between task $1 and task $2.", [avant, apres]))
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


window.TaskDependencies = TaskDependencies;