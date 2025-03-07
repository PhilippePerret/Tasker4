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
  }

  onClickStart(ev){
    console.log("Je dois apprendre à démarrer la tâche.")
  }
  onClickStop(ev){
    console.log("Je dois apprendre à stopper la tâche.")
  }
  onPushToTheEnd(ev){
    console.log("Je dois apprendre à repousser la tâche à la fin.")
  }
  onPushAfterNext(ev){
    console.log("Je dois apprendre à repousser après la prochaine.")
  }
  onPushLater(ev){
    console.log("Je dois apprendre à repousser après (de façon aléatoire).")
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

  get btnSup(){return this._btnrem || (this._btnrem || DGet('button.btn-remove', this.obj))}
  get btnEdit(){return this._btnedit || (this._btnedit || DGet('button.btn-edit', this.obj))}
  get btnStart(){return this._btnstart || (this._btnstart || DGet('button.btn-start', this.obj))}
  get btnStop(){return this._btnstop || (this._btnstop || DGet('button.btn-stop', this.obj))}
  get btnLater(){return this._btnlater || (this._btnlater || DGet('button.btn-later', this.obj))}
  get btn2end(){return this._btn2end || (this._btn2end || DGet('button.btn-to-the-end', this.obj))}
  get btnAfterNext(){return this._btnaftnext || (this._btnaftnext || DGet('button.btn-after-next', this.obj))}
  get btnOutOfDay(){return this._btnoutday || (this._btnoutday || DGet('button.btn-out-day', this.obj))}

  get obj(){return this._obj || (this._obj || DGet('div#main-task-container'))}
}

window.AtWork = new ClassAtWork();

window.addEventListener("load", function() {
  AtWork.init()
});