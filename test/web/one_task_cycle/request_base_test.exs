defmodule TaskerWeb.OTCRequestTest do
  use Tasker.DataCase

  import CommonTestMethods # is_around etc.

  alias Tasker.Repo

  alias Tasker.TacheFixtures, as: F
  alias Tasker.AccountsFixtures, as: WF

  alias TaskerWeb.OneTaskCycleController, as: OTC

  # alias Tasker.Accounts.{Worker}
  # alias Tasker.Tache
  # alias Tasker.Tache.{Task, TaskSpec, TaskTime, TaskNature}

  alias Tasker.TaskRankCalculator, as: RankCalc

  # Les durées en minutes
  @now    NaiveDateTime.utc_now()
  @bod    NaiveDateTime.beginning_of_day(@now) # beginning of day
  @hour   60
  @day    @hour * 24
  # @week   @day * 7
  # @month  @week * 4



  doctest Tasker.TaskRankCalculator


  describe "La requête SQL de relève" do

    def add_in_list(liste, properties, raison \\ nil) do
    # def add_in_list(liste, properties) do
      new_element = F.create_task(properties)
      # |> IO.inspect(label: "\nNOUVEL ÉLÉMENT")
      new_element = if raison do 
        Map.put(new_element, :raison, raison)
      else new_element end
      liste ++ [new_element]
    end

    test "retourne les bonnes candidates" do

      in_list   = []
      out_list  = []

      # IO.puts "DANS IN_LIST"
      # [IN] Tâche sans échéance du tout
      in_list = add_in_list(in_list, %{headline: false, deadline: false})
      # [IN] Tâche avec headline dans le passé et sans deadline
      in_list = add_in_list(in_list, %{headline: :past, deadline: false})
      # [IN] Tâche avec headline dans le passé et avec deadline
      in_list = add_in_list(in_list, %{headline: :past, deadline: true})
      # [IN] Tâche dans un futur proche (< 7 jours) et sans deadline
      in_list = add_in_list(in_list, %{headline: :near_future, deadline: false})
      # [IN] Tâche dans un futur proche (< 7 jours) et avec deadline
      in_list = add_in_list(in_list, %{headline: :near_future, deadline: true})
      # [IN] Tâche sans headline avec deadline dans le passé
      in_list = add_in_list(in_list, %{headline: false, deadline: :past})
      # [IN] Tâche sans headline mais avec deadline dans le proche futur
      in_list = add_in_list(in_list, %{headline: false, deadline: :near_future})
      # [IN] Tâche sans headline (donc qui peut commencer n'importe quand), mais avec une deadline dans le futur lointain
      in_list = add_in_list(in_list, %{headline: false, deadline: :far_future})
      
      # IO.puts "DANS OUT_LIST"
      # [OUT] Tâche loin dans le futur (sans deadline)
      out_list = add_in_list(out_list, %{headline: :far_future, deadline: false}, "Tâche loin dans le futur, sans deadline")
      # [OUT] Tâche loin dans le futur (avec deadline)
      out_list = add_in_list(out_list, %{headline: :far_future, deadline: true}, "Tâche loin dans le futur, avec deadline")
      # [OUT] Tâche avec dépendance before
      out_list = add_in_list(out_list, %{deps_before: true}, "Tâche dépendante d'une autre tâche non accomplie")
      # [OUT] Tâche attribuée à un autre worker
      out_list = add_in_list(out_list, %{worker: true}, "Tâche attribuée à un autre worker")
      # [OUT] Tâche exclusive dans le passé
      out_list = add_in_list(out_list, %{
        headline:  NaiveDateTime.add(@bod, 6, :hour), # pour aujourd'hui
        deadline:  NaiveDateTime.add(@bod, 7, :hour), # pour aujourd'hui
        priority: 5                 # exclusive
      }, "Une tâche exclusive terminée ne doit être retenue.")
      # [OUT] Tâche récurrente exclusive dans le passé
      out_list = add_in_list(out_list, %{
        recurrence: "0 4 * * *",   # tous les jours à 6:00
        headline:  NaiveDateTime.add(@bod, 4, :hour), # pour aujourd'hui
        deadline:  NaiveDateTime.add(@bod, 5, :hour), # pour aujourd'hui
        priority: 5                 # exclusive
        },
         "Une tâche récurrente, exclusive, dans le passé proche ne doit pas être affichée"
        )

      # IO.inspect(candidates_request(), label: "REQUEST SQL")
      # IO.inspect(Repo.all(from t in Tasker.Tache.Task), label: "\nTâches réellement en base")

      current_worker = WF.worker_fixture()

      # candidate_ids = Repo.submit_sql(candidates_request(), [Ecto.UUID.dump!(current_worker.id)], Tasker.Tache.Task)
      # |> Enum.reduce(%{}, fn task, coll -> Map.put(coll, task.id, true) end)
      # |> IO.inspect(label: "\nIDS TÂCHES RELEVÉES")

      candidate_ids = OTC.get_candidate_tasks(current_worker.id)
      |> Enum.reduce(%{}, fn task, coll -> Map.put(coll, task.id, true) end)

      # Toutes les tâches dans la in_list doivent avoir été relevées
      unfounds = in_list |> Enum.filter(fn t -> ! candidate_ids[t.id] end) |> Enum.map(fn t -> "#{t.id} (#{inspect t})" end)
      assert(Enum.count(unfounds) == 0, "Les tâches suivantes (#{Enum.count(unfounds)}) auraient dû être relevées :\n- #{Enum.join(unfounds, "\n- ")}")
      # Aucune des tâches dans la out_list ne doit avoir été relevées
      badfounds = out_list 
      |> Enum.filter(fn t -> 
        IO.inspect(t, label: "\nDans le filtre")
        candidate_ids[t.id] === true 
      end) 
      |> Enum.map(fn t -> "\n Tâche ##{t.id}\n Raison : #{Map.get(t, :raison, "non documentée")}\nDétail de la tâche : (#{inspect t})" 
      end)
      assert(Enum.count(badfounds) == 0, 
        # Le message d'erreur
        """
        Les tâches suivantes (#{Enum.count(badfounds)}) N'auraient PAS dû
        être relevées :\n- #{Enum.join(badfounds, "\n- ")}
        """)

    end

    # Retourne la requête de relève telle que définie dans le contrôleur
    defp candidates_request do
      OTC.candidates_request()
    end

  end #/describe "La requête SQL de relève"


  describe "la relève des alertes" do

    # @tag :skip
    test "retourne les alertes du jour" do

      current_worker = WF.worker_fixture()

      in_list   = []
      out_list  = []


      # debug_current_tasks("Tâche AVANT l'insertion")

      # === Tâches à alertes à remonter ===

      # Tâche avec alerte démarrant dans quelques heures
      in_one_hour = NaiveDateTime.add(@now, 4, :hour)
      alert_at    = NaiveDateTime.add(@now, 10, :minute)
      attrs = %{should_start_at: in_one_hour, deadline: false, alerts: [%{at: @now, unit: "1", quantity: nil}]}
      in_list = add_in_list(in_list, attrs)
      # Tâche très très lointaine mais qu'il faut alerter maintenant
      alert_near = NaiveDateTime.add(@now, 10, :minute)
      alerte_far = NaiveDateTime.add(@now, 10, :day)
      attrs = %{headline: :far_future, alerts: [%{at: alert_near, unit: "minute", quantity: nil}, %{at: alerte_far, unit: "minute", quantity: nil}]}
      in_list = add_in_list(in_list, attrs)

      # === Tâches à ne pas remonter (au niveau des alertes) ===

      # Tâche sans alerte
      in_one_hour = NaiveDateTime.add(@now, 4, :hour)
      out_list = add_in_list(out_list, %{headline: in_one_hour})

      # Tâche avec alerte trop lointaine
      attrs = %{headline: :far_future, alert_at: alerte_far, alerts: [%{at: alerte_far, unit: "minute", quantity: nil}]}
      out_list = add_in_list(out_list, attrs)

      # debug_current_tasks("Tâche APRÈS l'insertion")
      # raise "Pour voir"
      
      # - test -
      alerts_task_ids = 
      OTC.get_alerts(current_worker.id)
      |> Enum.reduce(%{}, fn data, coll ->
        Map.put(coll, Ecto.UUID.load!(data.task_id), true)
      end)
      # - vérification -
      not_founds = 
      in_list
      |> Enum.filter(fn task -> ! alerts_task_ids[task.id] === true end)
      if Enum.any?(not_founds) do
        IO.puts "= Tâches à alerte non remontées ="
        not_founds |> Enum.each(fn task -> IO.inspect(task) end)
      end
      assert(Enum.count(not_founds) == 0, "Des alertes requises n'ont pas été trouvées (#{Enum.count(not_founds)})")
      # - Les tâches à alerte qui ne doivent pas avoir été remontées -
      undesirables = 
      out_list
      |> Enum.filter(fn task -> alerts_task_ids[task.id] === true end)
      # On affiche les tâches qu'on n'aurait pas dû trouver
      if Enum.any?(undesirables) do
        IO.puts "= Tâches à alerte indésiables ="
        undesirables |> Enum.each(fn task -> IO.inspect(task) end)
      end
      assert(Enum.count(undesirables) == 0, "Des alertes non requises ont été trouvées (#{Enum.count(undesirables)})")
    end

  end

end