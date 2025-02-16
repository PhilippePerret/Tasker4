'use strict'; 
/**
 * Script pour la gestion de l'édition JS de la tâche
 * Ce fichier a été initié pour gérer les notes.
 */
function StopEvent(ev){
  ev.stopPropagation();
  ev.preventDefault();
  return false
}

class Task {
  static init(){
    // D'abord il faut empêcher de soumettre le formulaire en
    // jouer 'Enter' sur un champ de formulaire
    DGetAll('input[type="text"]').forEach(input => {
      input.addEventListener('keydown', this.stopEnterKey.bind(this))
    })
  }
  static stopEnterKey(ev){
    if (ev.key == 'Enter'){ return StopEvent(ev) }
  }
}

class Notes {
  static create(){
    const title = DGet('#new_note_title').value.trim()
    if ( title == "" ) {
      return alert("Il faut donner un titre à la note !")
    }
    const details = DGet('#new_note_details').value
    const taskSpecId = DGet('#new_note_task_spec_id')
    const dataNote = {
        title: title
      , details: details
      , task_spec_id: taskSpecId 
    }
    ServerTalk.dial({
      route: "/tools/create_note",
      data: {script_args: dataNote},
      callback: this.afterCreateNote.bind(this)
    })
  }
  static afterCreateNote(retour){
    if (retour.ok) {
      console.info("La note a été créée")
    } else {
      console.error("La note n'a pas pu être créée.")
    }
  }
}

window.Task = Task
window.Notes = Notes

Task.init()