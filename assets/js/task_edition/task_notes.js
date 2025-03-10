'use strict';


class Notes {
  static create(){
    const title = DGet('#new_note_title').value.trim()
    if ( title == "" ) {
      return alert(LANG["tasker_A title must be given to the note!"])
      // 
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

window.Notes = Notes
