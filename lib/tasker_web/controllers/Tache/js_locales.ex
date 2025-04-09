defmodule TaskerWeb.LocalesJS do
  use TaskerWeb, :controller

  # use Gettext, backend: TaskerWeb.Gettext

  @doc """
  Cette fonction ne sert qu'à exposer les locales qui seront 
  utilisées en JavaScript. Elle n'est jamais appelée ou l'est
  seulement pour ne pas avoir de message de warning disant que
  la fonction est inutilisée.

  Si des locales sont ajoutées : 

      1) > mix gettext.extract
      2) > mix gettext.merge priv/gettext
      3) Définir les textes
      4) > mix run lib/mix/tasks/generate_locales_js.ex
      5) Détruire le stockage de LOCALES dans le navigateur
         pour que la liste soit actualisée.


  """
  def locales_js do
    
    # - common -
    gettext("Close")
    gettext("Close (verb)")
    gettext("Every_fem")
    gettext("every")
    gettext("Each")
    gettext("each")
    gettext("Edit")
    gettext("every_fem")
    gettext("Summary")
    gettext("(click to edit)")
    gettext("Filter")
    gettext("OK")
    gettext("Cancel")
    gettext("Select All")
    gettext("Deselect All")
    gettext("Sort")
    gettext("End of sorting")
    gettext("Show list")
    gettext("Hide list")
    gettext("Array or Table required")
    gettext(", and")

    # - tasker -
    dgettext("tasker", "The task")
    dgettext("tasker", "Choose task")
    dgettext("tasker", "Set current")
    dgettext("tasker", "Choose task natures")
    dgettext("tasker", "Double dependency between task $1 and task $2.")
    dgettext("tasker", "A task cannot be dependent on itself.")
    dgettext("tasker", "Inconsistencies in dependencies. I cannot save them.")
    dgettext("tasker", "A title must be given to the note!")
    dgettext("tasker", "Repeat this task")
    dgettext("tasker", "No task selected, I’m stopping here.")
    dgettext("tasker", "No tasks found. Therefore, none can be selected.")
    dgettext("tasker", "Select tasks")
    dgettext("tasker", "Select natures")
    dgettext("tasker", "Filter per nature")
    dgettext("tasker", "Task natures")
    dgettext("tasker", "Choose these natures")
    dgettext("tasker", "Click on the task to move it forward by one. Click “Hide List” to finish.")
    dgettext("tasker", "The script was executed successfully!")
    dgettext("tasker", "Filter per project")
    dgettext("tasker", "Back to work")
    dgettext("tasker", "End of the exclusive task in…")
    dgettext("tasker", "Should I mark the end of this exclusive task?")
    dgettext("tasker", "In progress:")
    dgettext("tasker", "Can I log the working time on the current task? (Otherwise, it will not be recorded)")
    dgettext("tasker", "You have to wait for the end of the task.")
    dgettext("tasker", "Strange… the current task has changed. I cant’t update its execution time.")
    dgettext("tasker", "Working time recorded")
    dgettext("tasker", "The task has been placed in position $1.")
    dgettext("tasker", "Reloading the page will be enought to restore it.")
    dgettext("tasker", "Do you really want to permanently delete this task?")
    dgettext("tasker", "I’m keeping one nonetheless.")
    dgettext("tasker", "There are no tasks left. Should I restore the filtered tasks?")
    dgettext("tasker", "Exclusive task explication")
    dgettext("tasker", "A exclusive requires headline and deadline")
    dgettext("tasker", "A hard deadline obviously requires an end date.")
    dgettext("tasker", "The exclusive task « $1 » will start in $2.")
    dgettext("tasker", "The exclusive task « $1 » will start in $2 minutes.")
    dgettext("tasker", "Initial order restored")
    dgettext("tasker", "To set an alert, you need to define the task’s start time.")
    dgettext("tasker", "The alert cannot be set after the task has started, come on…")
    dgettext("tasker", "The last alert must be defined!")
    dgettext("tasker", "will start")
    # - il y a - 
    dgettext("ilya", "january")
    dgettext("ilya", "february")
    dgettext("ilya", "march")
    dgettext("ilya", "april")
    dgettext("ilya", "may")
    dgettext("ilya", "june")
    dgettext("ilya", "july")
    dgettext("ilya", "august")
    dgettext("ilya", "september")
    dgettext("ilya", "october")
    dgettext("ilya", "november")
    dgettext("ilya", "december")
    dgettext("ilya", "monday")
    dgettext("ilya", "tuesday")
    dgettext("ilya", "wednesday")
    dgettext("ilya", "thursday")
    dgettext("ilya", "friday")
    dgettext("ilya", "saturday")
    dgettext("ilya", "sunday")
    dgettext("ilya", "at")
    dgettext("ilya", "(at the top of the hour)") # "(en début d’heure)"
    dgettext("ilya", "at the $1<sup>th</sup> minute") # "à la $1<sup>e</sup> minute"
    dgettext("ilya", "on (day)")
    dgettext("ilya", "on (date)")
    dgettext("ilya", "on (days)")
    dgettext("ilya", "du mois")
    dgettext("ilya", "d’$1")
    dgettext("ilya", "de $1")
    dgettext("ilya", "the first")
    dgettext("ilya", "the $1") # pour le 12 (jour)
    dgettext("ilya", "des mois de")
    dgettext("ilya", "an hour")
    dgettext("ilya", "a half-hour")


  end

end