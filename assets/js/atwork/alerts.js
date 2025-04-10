'use strict';
/**
 * Gestion des alertes dans le travail courant
 * 
 * NB: Pour la gestion des alertes dans le formulaire d'édition de la
 * tâche, voir task_edition/task_alerts.js
 * 
 * TODO
 *  - quand l'alerte a été donnée, il faut passer la suivante en
 *    prochaine alerte.
 */

const NOW = new Date()

class Alerts {

  static schedule(){
    if ( ALERTES.length == 0 ) return ;
    spy("Programmation des alertes", ALERTES)
    this.buildContainer()
    ALERTES.forEach(dAlert => {
      const alert = new Alert(dAlert)
      alert.schedule()
    })
  }

  static buildContainer(){
    this.obj = DGet('div#alerts')
    if ( ! this.obj ) {
      this.obj = DCreate('DIV', {id: 'alerts'})
      document.body.appendChild(this.obj)
    }
  }
}

class Alert {
  constructor(data){
    this.data = data
  }

  /**
   * Méthode principale pour programmer l'alerte
   * 
   * Programmer l'alerte consiste simplement à placer un
   * timeout sur la construction et l'affichage.
   * 
   * Note : Si le laps de temps est négatif (c'est-à-dire que 
   * l'alerte est dépassée), il faut afficher l'alerte tout de
   * suite. Sinon, on la programme.
   */
  schedule(){
    const laps = Number(this.atDate) - Number(NOW)
    if ( laps < 0 ) {
      this.show()
    } else if ( isNaN(laps) ) {
      console.error("Problème avec le laps qui n'est pas un nombre… NOW et atDate sont respectivement égaux à ", NOW, this.atDate)
    } else {
      this.timer = setTimeout(this.show.bind(this), laps)
    }
  }

  /**
   * Afficher l'alerte
   */
  show(){
    clearTimeout(this.timer)
    this.build()
  }

  // === Méthode d'évènements ===

  remove(){
    this.obj.remove()
  }
  edit(){
    AtWork.editTaskById(this.data.task_id)
  }
  /**
   * Pour mettre la tâche en tâche courante
   * Mais ici, un problème se pose : la tâche peut ne pas être 
   * chargée (si par exemple c'est une tâche lointaine). Dans ce
   * cas, il faut la charger et l'ajouter à la liste.
   */
  setCurrent(){
    const task = AtWork.getTask(this.data.task_id);
    if ( task ) {
      AtWork.setCurrentTask(task)
    } else {
      AtWork.fetchTaskAndSetCurrent(this.data.task_id)
    }
  }

  /**
   * Construction de l'alerte
   */
  build(){
    const o = DCreate('DIV', {class: "alert"})
    o.appendChild(DCreate('DIV', {class:'alert content', text: this.content}))
    const b = DCreate('DIV', {class:'right'})
    o.appendChild(b)
    // Bouton pour la fermer
    this.bntClose = DCreate('BUTTON', {class:'alert btn-close', text: LOC('Close (verb)')})
    b.appendChild(this.bntClose)
    // Bouton pour modifier la tâche
    this.btnEdit  = DCreate('BUTTON', {class:'alert btn-edit', text: LOC('Edit')})
    b.appendChild(this.btnEdit)
    // Bouton pour mettre la tâche en tâche courante
    this.btnSetCur = DCreate('BUTTON', {class:'alert btn-set-cur', text: LOC('Set current')})
    b.appendChild(this.btnSetCur)

    this.obj = o
    Alerts.obj.appendChild(o)
    this.observe()
  }

  observe(){
    // En cliquant sur le bouton pour la fermer, on la ferme
    this.listenButton(this.bntClose, 'remove')
    // En cliquant sur le bouton pour l'éditer, on l'éditer
    this.listenButton(this.btnEdit, 'edit')
    // En cliquant sur le bouton pour la mettre en tâche courante, on
    // la met en tâche courante
    this.listenButton(this.btnSetCur, 'setCurrent')
  }

  listenButton(btn, methode){
    btn.addEventListener('click', this[methode].bind(this))
  }

  get content(){
    const c = []
    c.push(LOC('The task'))
    c.push(`« ${this.data.title} »`)
    c.push(LOC("will start"))
    c.push(this.formatedStartDate)
    return c.join(" ")
  }
  get atDate(){
    return this._alertdate || (this._alertdate = new Date(this.firstAlert.at))
  }
  get firstAlert(){
    return this.data.alerts[0]
  }

  get formatedStartDate(){
    const startDate = new Date(this.data.start)
    const [date, heure] = startDate.toLocaleString().split(" ")
    return `${LOC('on (day)')} ${date} ${LOC('at')} ${heure}`
  }
}


window.Alerts = Alerts