defmodule Tasker.RecurrenteTaskTests do
  # use ExUnit.Case, async: false
  use TaskerWeb.ConnCase

  alias Tasker.Tache
  alias Tasker.TacheFixtures, as: F

  describe "Une tâche récurrente" do

    test "marquée faite passe à sa récurrence suivante" do
      now = NaiveDateTime.utc_now()
      dansuneheure = NaiveDateTime.add(now, 3, :hour)

      task = F.create_task(%{
        recurrence: "0 #{dansuneheure.hour} * * *", # tous les jours à x heures
        duree: 120
      })

      # On force le rafraichissement qui devrait définir la prochaine
      # occurrence.
      Tache.refresh_bdd_data(force: true)
      new_task = Tache.get_task!(task.id)

      # --- Pré-vérifications ---
      # La prochaine date doit avoir été mise à aujourd'hui
      assert(new_task.task_time.should_start_at.day == NaiveDateTime.utc_now().day)

      # --- Test ---
      # On simule le marquage de la tâche comme effectuée
      TaskerWeb.TasksOpController.exec_op("is_done", %{"task_id" => task.id})

      # --- Post-Vérification ---
      # La prochaine date doit avoir été mise à demain
      new_task = Tache.get_task!(task.id)
      demain = NaiveDateTime.add(NaiveDateTime.utc_now(), 1, :day)
      assert(new_task.task_time.should_start_at.day == demain.day)

    end

  end #/describe "Une tâche récurrente"

end