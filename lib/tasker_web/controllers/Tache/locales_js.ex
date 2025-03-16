defmodule TaskerWeb.LocalesJS do
  use TaskerWeb, :controller

  @doc """
  Cette fonction ne sert qu'à exposer les locales qui seront 
  utilisées en JavaScript. Elle n'est jamais appelée ou l'est
  seulement pour ne pas avoir de message de warning disant que
  la fonction est inutilisée.
  """
  def locales_js do
    
    # - common -
    gettext("Every_fem")
    gettext("every")
    gettext("Each")
    gettext("each")
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
    gettext("on (date)")

    # - tasker -
    dgettext("tasker", "Double dependency between task __BEFORE__ and task __AFTER__.")
    dgettext("tasker", "A task cannot be dependent on itself.")
    dgettext("tasker", "Inconsistencies in dependencies. I cannot save them.")
    dgettext("tasker", "A title must be given to the note!")
    dgettext("tasker", "Repeat this task")
    dgettext("tasker", "No task selected, I’m stopping here.")
    dgettext("tasker", "No tasks found. Therefore, none can be selected.")
    dgettext("tasker", "Select tasks")
    dgettext("tasker", "Select natures")
    gettext("Array or Table required")
    dgettext("tasker", "Click on the task to move it forward by one. Click “Hide List” to finish.")
    dgettext("tasker", "The script was executed successfully!")
    dgettext("tasker", "Filter per project")
    dgettext("tasker", "Filter per nature")
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
    dgettext("tasker","There are no tasks left. Should I restore the filtered tasks?")
   
    # - il y a - 
    dgettext("ilya", "monday")
    dgettext("ilya", "tuesday")
    dgettext("ilya", "wednesday")
    dgettext("ilya", "thursday")
    dgettext("ilya", "friday")
    dgettext("ilya", "saturday")
    dgettext("ilya", "sunday")

  end

end