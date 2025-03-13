'use strict';
/**
 * Module pour gérer l'horloge affichée
 */

class HorlogeClass {

  static s2h(s){
    let h = Math.round(s / 3600)
    s = s % 3600
    let m = Math.round(s / 60)
    if ( m < 10 ) m = `0${m}` ;
    s = s % 60
    if ( s < 10 ) s = `0${s}` ;
    return `${h}:${m}:${s}`
  }

  constructor(){

  }

  show(){this.obj.classList.remove('invisible')}
  hide(){this.obj.classList.add('invisible')}

  /**
   * Pour démarrer l'horloge
   * 
   * L'horloge peut être démarrée de deux façons : lorsqu'on commence
   * à travailler une tâche, ou lorsqu'on recharge la page alors 
   * qu'une tâche était en route. +z+ contient toujours le temps de
   * départ.
   * 
   * @param {Number} z Temps de départ en secondes
   */
  start(z){
    this.show();
    this.startTime = z || (new Date()).getTime()
    this.timer = setInterval(this.run.bind(this), 500)
  }
  stop(){
    clearInterval(this.timer)
    this.timer = null
    this.hide();
  }

  run(){
    const laps = (new Date()).getTime() - this.startTime
    this.obj.innerHTML = this.s2h(Math.round(laps / 1000))
  }
  s2h(s){return this.constructor.s2h(s)}

  get obj(){return this._obj || (this._obj = DGet('div#horloge'))}

}

window.Horloge = HorlogeClass
