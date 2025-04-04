defmodule TaskerWeb.OTCRequestTest do
  use Tasker.DataCase

  # import CommonTestMethods # is_around etc.

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

    @tag skip: "à implémenter"
    test "retourne les candidates dans le bon ordre" do
    end

    @tag skip: "à implémenter"
    test "retourne les candidates avec toutes leurs données" do
    end

    @tag skip: "à implémenter"
    test "ne retourne pas les tâches dépendantes" do
    end

    @tag skip: "à implémenter"
    test "ne retourne pas les tâches attribuées à un autre worker que le courant" do
    end

    @tag skip: "à implémenter"
    test "ne retourne pas les tâches trop loin (> une semaine)" do
    end
  end

end