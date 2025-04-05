'use strict';
/**
 * Pour gérer les tâches exclusives dans le travail courant
 */
class ExclusiveTask {

  /**
   * 
   * @param {Object} task La table complète de la tâche
   * @param {ClassAtWork} taskDealer L'instance at-work courante
   */
  constructor(task, taskDealer) {
    this.task = task
    this.taskDealer = taskDealer
  }

  setup(){
    this.start = new Date(this.task.task_time.should_start_at)
    this.stop  = new Date(this.task.task_time.should_end_at)
    Object.assign(this.task, {start_at: this.start, end_at: this.stop})

    if ( this.start > now() ) {
      /**
       * Une tâche exclusive à déclencher plus tard
       */
      const diffMilliseconds = this.startDans('millisecond')
      // console.info("Tâche exclusive à déclencher dans %s secondes", parseInt(diffMilliseconds / 1000), tk)
      // Le timer de déclenchement de la tâche
      this.startTimer = setTimeout(this.lock.bind(this), diffMilliseconds)
      // Le timer d'annonce (discrète) de déclenchement
      this.poseAnnonceDebut()
    } else {
      /**
       * Une tâche exclusive déjà en cours
       */
      // console.info("Tâche exclusive à déclencher tout de suite", tk)
      this.lock()
    }
  }

  /**
   * Retourne le laps de temps avant le début de la tâche, dans
   * l'unité voulue.
   * 
   * @param {String} unity 'minute', 'hour', 'millisecond', 'second' (default)
   */
  startDans(unity){
    // La différence en millisecondes
    const diff = this.start.getTime() - now().getTime()
    switch(unity){
      case 'millisecond': return diff;
      case 'second': return diff / 1000;
      case 'minute': return diff / (1000 * 60);
      case 'hour':   return diff / (1000 * 3600);
      default: return diff / 1000;
    }
  }


  /**
   * Permet de verrouiller le travail sur la tâche exclusive.
   */
  lock(){
    const task = this.task
    const dealer = this.taskDealer
    this.stopStartTimer()
    // Si une tâche courante était en cours de travail, il faut
    // demander ce que l'on doit faire. Si le worker veut enregistrer
    // le temps, on simule le clic sur le bouton stop.
    if ( dealer.running ){
      if (confirm(LOC('Can I log the working time on the current task? (Otherwise, it will not be recorded'))){
        dealer.onClickStop(null)
      }
    }
    // On met la tâche exclusive en tâche courante
    dealer.currentTask = task
    dealer.showCurrentTask()
    // Pour bloquer l'interface, on met un div qui couvre tout
    this.UIMask = new UIMasker({
        counterback: task.end_at.getTime()
      , title: `${LOC('In progress:')} ${task.title}`
      , ontime: this.unlock.bind(this, true)
      , onclick: LOC('You have to wait for the end of the task.')
      , onforceStop: this.unlock.bind(this, false)
    })
    this.UIMask.activate()
  }

  /**
   * Permet de déverrouiller le travail sur la tâche exclusive.
   */
  unlock(regularEnd){
    const task    = this.task
    const dealer  = this.taskDealer
    this.stopStartTimer()

    let markDone = regularEnd || confirm(LOC('Should I mark the end of this exclusive task?'))
    if (markDone) {
      dealer.runOnCurrentTask('is_done', dealer.afterSetDone.bind(dealer))
    } else {
      // Pour le moment, on ne fait rien
    }
  }

  /**
   * Méthode qui gère les annonces qui doivent être faites du départ
   * d'une tâche exclusive.
   * Le fonctionnement est le suivant :
   * - si la tâche exclusive doit commencer dans plus d'une heure, un
   *    message discret est programmé pour s'afficher une heure avant.
   * -  ensuite, on l'annonce 30 minutes avant.
   * -  Si la tâche exclusive doit être lancée dans moins d'une demi-
   *    heure (et qu'elle n'a pas été annoncée), on met un message 
   *    indiquant son heure de départ.
   */
  poseAnnonceDebut(){
    const diffMinutes = this.startDans('minute')
    if ( diffMinutes > 60 ) {
      spy("Cette tâche doit commencer dans plus d'une heure", this)
      // Si l'annonce de l'heure n'a pas été programmée
      this.annonceTimer || this.annonce('heure')
    } else if ( diffMinutes > 30 ) {
      spy("Cette tâche doit commencer dans plus d'une demi-heure", this)
      this.annonceTimer || this.annonce('demi-heure')
    } else {
      this.annonceTimer || this.annonce('imminent')
    }
  }

  annonce(type){
    const [message, laps] = this.dataAnnonce(type)
    if ( laps === null ) {
      this.showAnnonce(message)
    } else {
      this.annonceTimer = setTimeout(this.showAnnonce.bind(this, message), laps)
    }
  }

  showAnnonce(message){
    const data = {
        content: message
      , position: 'bottom-left'
      , discretion: 6
    }
    const msg = new DiscreteMessage(data)
    msg.show()
  }

  dataAnnonce(type) {
    const diffMinutes = this.startDans('minute')
    let laps, message;
    switch(type){
      case 'heure':
        laps = (diffMinutes - 60) * 1000 * 60
        message = LOC('The exclusive task « $1 » will start in $2.', [this.task.title, LOC('an hour')]) 
        return [message, laps]
      case 'demi-heure':
        laps = (diffMinutes - 30) * 1000 * 60
        message = LOC('The exclusive task « $1 » will start in $2.', [this.task.title, LOC('a half-hour')]) 
        return [message, laps]
      case 'imminent':
        message = LOC('The exclusive task « $1 » will start in $2 minutes.', [this.task.title, `${Math.round(diffMinutes)}`]) 
        return [message, null]
    }
  }



  // ========== Méthodes privées =============

  stopStartTimer(){
    if ( this.startTimer ) {
      clearTimeout(this.startTimer);
      delete this.startTimer
    }
  }

}

window.ExclusiveTask = ExclusiveTask