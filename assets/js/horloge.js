'use strict';
/**
 * Module pour gérer l'horloge affichée
 * 
 * 
 * L'horloge travaille suivant deux modes :
 * 
 * -  MODE HORLOGE. C'est le mode normal, avec le temps qui défile
 *    en indiquant le temps consacré à la tâche.
 * 
 * -  MODE COUNTDOWN (compte à rebours), quand une durée de travail
 *    ou une échéance a été fixée avant la fin de la tâche, dans le
 *    champ interactif idoine. Dans ce mode, c'est un compte à 
 *    rebours qui est affiché.
 */

class HorlogeClass {

  static s2h(s){
    let h = Math.floor(s / 3600)
    s = s % 3600
    let m = Math.floor(s / 60)
    if ( m < 10 ) m = `0${m}` ;
    s = s % 60
    if ( s < 10 ) s = `0${s}` ;
    return `${h}:${m}:${s}`
  }

  static h2s(horl) {
    let s, m, h;
    [s, m, h] = horl.split(':').reverse();
    return (s || 0) + (m || 0) * 60 + (h || 0) * 3600;
  }

  constructor(owner){
    this.owner = owner;
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
    this.mode = this.getWorkTimeMode();
    this.show();
    this.startTime = z || (new Date()).getTime()
    if (this.mode === 'countdown') { this.endTime = this.calcEndTime(this.startTime);}
    this.timer = setInterval(this.run.bind(this), 500)
  }
  getWorkTimeMode(){
    return this.uptoField.value ? 'countdown' : 'horloge';
  }
  stop(){
    clearInterval(this.timer)
    this.timer = null
    this.hide();
  }

  run(){
    let laps;
    const curTime = (new Date()).getTime();
    if (this.mode === 'horloge') {
      laps = curTime  - this.startTime;
    } else {
      laps = this.endTime - curTime;
      if ( laps < 0 ) {
        // Il faut avertir que le temps est terminé
        console.log("Le temps de travail est terminé, il faut passer au travail suivant.")
        Flash.notice(LOC('You have reached your work time limit'));
        this.stop();
        this.owner.onClickStop();
      } else if ( laps < 10 * 60 * 1000 && !this.alert10minutes ) {
        // Il faut avertir que le temps va terminer dans 10 minutes
        console.log("Ce travail doit terminer dans 10 minutes.");
        Flash.notice(LOC('Less than 10 minutes of work remaining on this task.'))
        this.alert10minutes = true;
     }
    }
    this.obj.innerHTML = this.s2h(Math.round(laps / 1000))
  }
  s2h(s){return this.constructor.s2h(s)}

  get obj(){return this._obj || (this._obj = DGet('div#horloge'))}

  /**
   * Calcule le temps de fin en mode compte à rebours
   * 
   * @param {Number} fromTime Temps de départ en nombre de secondes
   */
  calcEndTime(fromTime){
    const modeUpto = this.menuUptoType.value; // 'by-duree', 'by-upto'
    const valuUpto = this.constructor.h2s(this.uptoField.value);
    switch(modeUpto){
      case 'by-duree': 
        return fromTime + valuUpto;
        break;
      case 'by-upto':
        const date = new Date();
        let h, m;
        [h, m] = this.uptoField.value.split(':');
        date.setHours(Number(h), Number(m), 0, 0);
        return date;
    } 
  }
  get uptoField(){
    return this._uptofield || (this._uptofield = DGet('input#upto-value'))
  }
  get menuUptoType(){
    return this._menuupto || (this._menuupto = DGet('select#upto-type'))
  }
}

window.Horloge = HorlogeClass
