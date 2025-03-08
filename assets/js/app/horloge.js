'use strict';
/**
 * Module pour gérer l'horloge affichée
 */

class HorlogeClass {

  constructor(){}

  show(){this.obj.classList.remove('invisible')}
  hide(){this.obj.classList.add('invisible')}

  start(){
    this.show();
    this.startTime = (new Date()).getTime()
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
  s2h(s){
    let h = Math.round(s / 3600)
    s = s % 3600
    let m = Math.round(s / 60)
    if ( m < 10 ) m = `0${m}` ;
    s = s % 60
    if ( s < 10 ) s = `0${s}` ;
    return `${h}:${m}:${s}`
  }

  get obj(){return this._obj || (this._obj = DGet('div#horloge'))}

}
window.Horloge = new HorlogeClass()