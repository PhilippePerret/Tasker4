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
    this.TASKS_COUNT = TASKS.length
    // On définit l'index absolu des tâches
    this.forEachTask((tk, index) => tk.absolute_index = index)
    this.showCurrentTask()
  }


  /**
   * Fonction qui affiche la tâche courante.
   * 
   * La tâche courante est TOUJOURS la tâche en haut de pile.
   */
  showCurrentTask(){
    this.redefineRelativeIndexes()
    this.showTask(TASKS[0])
  }

  /**
   * Fonction qui affiche la tâche fournie en argument.
   * 
   * @param {Object} task Les données de la tâche à afficher
   * 
   */
  showTask(task){
    this.setField('title', task.title)
    this.setField('details', task.details)
    this.setField('absolute_index', task.absolute_index + 1)
    this.setField('relative_index', task.relative_index + 1)
    
  }
  setField(fName, fValue){
    this.field(fName).innerHTML = fValue || `[${fName} non défini]`
  }
  field(fName){
    return DGet(`#current-task-${fName}`)
  }



  observe(){
    DListenClick(this.btnStart      , this.onClickStart.bind(this))
    DListenClick(this.btnStop       , this.onClickStop.bind(this))
    DListenClick(this.btn2end       , this.onPushToTheEnd.bind(this))
    DListenClick(this.btnAfterNext  , this.onPushAfterNext.bind(this))
    DListenClick(this.btnLater      , this.onPushLater.bind(this))
    DListenClick(this.btnOutOfDay   , this.onOutOfDay.bind(this))
    DListenClick(this.btnSup        , this.onRemove.bind(this))
    DListenClick(this.btnEdit       , this.onEdit.bind(this))
    DListenClick(this.btnProjet     , this.onProjet(this))
    DListenClick(this.btnResetOrder , this.onResetOrder(this))
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
    console.log("Je dois apprendre à sortir du jour la tâche.")
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
  onResetOrder(ev){
    Flash.notice("Je dois apprendre à remettre l'ordre inital")
    TASKS.sort(function(a,b){return a.absolute_index < b.absolute_index ? 1 : -1})
    this.showCurrentTask()
  }
  /**
   * Pour redéfinir l'index relatif
   * 
   * Noter que cet index ne sert que pour le débuggage, entendu qu'on 
   * ne voit toujours que la première tâche, donc la tâche "1" 
   * d'index zéro.
   */
  redefineRelativeIndexes(){
    this.forEachTask((tk, i) => tk.relative_index = Number(i))
  }

  forEachTask(method){
    for(var i = 0, len = TASKS.length; i < len; ++i){
      method(TASKS[i], Number(i))
    }
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
  get btnResetOrder(){return this._btnresetorder || (this._btnresetorder || DGet('button.btn-reset-order', this.obj))}

  get obj(){return this._obj || (this._obj || DGet('div#main-task-container'))}
}

window.AtWork = new ClassAtWork();

window.addEventListener("load", function() {
  AtWork.init()
});