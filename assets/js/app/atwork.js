'use strict';
function DListen(o, e, m){o.addEventListener(e, m)}
function DListenClick(o, m){o.addEventListener('click', m)}
/**
 * 
 */
class ClassAtWork {
  init(){
    this.observe()
    console.log("TASKS", TASKS)
    console.log("PROJECTS", PROJECTS)
    this.showCurrentTask()
    this.TASKS_COUNT = TASKS.length
  }


  /**
   * Fonction qui affiche la tâche courante.
   * 
   * La tâche courante est TOUJOURS la tâche en haut de pile.
   */
  showCurrentTask(){
    this.showTask(TASKS[0])
  }

  /**
   * Fonction qui affiche la tâche fournie en argument.
   * 
   * @param {Object} task Les données de la tâche à afficher
   * 
   */
  showTask(task){
    DGet('div#current-task-title').innerHTML = task.title
  }



  observe(){
    DListenClick(this.btnStart     , this.onClickStart.bind(this))
    DListenClick(this.btnStop      , this.onClickStop.bind(this))
    DListenClick(this.btn2end      , this.onPushToTheEnd.bind(this))
    DListenClick(this.btnAfterNext , this.onPushAfterNext.bind(this))
    DListenClick(this.btnLater     , this.onPushLater.bind(this))
    DListenClick(this.btnOutOfDay  , this.onOutOfDay.bind(this))
    DListenClick(this.btnSup       , this.onRemove.bind(this))
    DListenClick(this.btnEdit      , this.onEdit.bind(this))
    DListenClick(this.btnProjet    , this.onProjet(this))
  }

  onClickStart(ev){
    console.log("Je dois apprendre à démarrer la tâche.")
  }
  onClickStop(ev){
    console.log("Je dois apprendre à stopper la tâche.")
  }
  onPushToTheEnd(ev){
    const first = TASKS.shift()
    TASKS.push(first)
    this.showCurrentTask()
  }
  onPushAfterNext(ev){
    const first = TASKS.shift()
    console.log("Première tâche", first, TASKS)
    TASKS.splice(1, 0, first)
    this.showCurrentTask()
  }
  onPushLater(ev){
    const pos = Math.round(Math.random() * (this.TASKS_COUNT - 1) + 1)
    const first = TASKS.shift()
    TASKS.splice(pos, 0, first)
    Flash.notice(`La tâche a été placée en position ${pos + 1}.`)
    this.showCurrentTask()
  }
  onOutOfDay(ev){
    console.log("Je dois apprendre à sortir la tâche du jour.")
  }
  onRemove(ev){
    console.log("Je dois apprendre à détruire la tâche.")
  }
  onEdit(ev){
    console.log("Je dois apprendre à éditer la tâche.")
  }
  onProjet(ev){
    Flash.notice("Je dois apprendre à afficher le projet.")
  }

  get btnSup(){return this._btnrem || (this._btnrem || DGet('button.btn-remove', this.obj))}
  get btnEdit(){return this._btnedit || (this._btnedit || DGet('button.btn-edit', this.obj))}
  get btnStart(){return this._btnstart || (this._btnstart || DGet('button.btn-start', this.obj))}
  get btnStop(){return this._btnstop || (this._btnstop || DGet('button.btn-stop', this.obj))}
  get btnLater(){return this._btnlater || (this._btnlater || DGet('button.btn-later', this.obj))}
  get btn2end(){return this._btn2end || (this._btn2end || DGet('button.btn-to-the-end', this.obj))}
  get btnAfterNext(){return this._btnaftnext || (this._btnaftnext || DGet('button.btn-after-next', this.obj))}
  get btnOutOfDay(){return this._btnoutday || (this._btnoutday || DGet('button.btn-out-day', this.obj))}
  get btnProjet(){return this._btnprojet || (this._btnprojet || DGet('button.btn-projet', this.obj))}

  get obj(){return this._obj || (this._obj || DGet('div#main-task-container'))}
}

window.AtWork = new ClassAtWork();

window.addEventListener("load", function() {
  AtWork.init()
});