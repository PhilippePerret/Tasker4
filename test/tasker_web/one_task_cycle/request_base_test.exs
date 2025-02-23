defmodule TaskerWeb.OTCRequestTest do
  use Tasker.DataCase

  alias Tasker.Repo

  alias Tasker.TacheFixtures, as: F
  alias Tasker.AccountsFixtures, as: WF

  alias Tasker.Accounts.{Worker}
  alias Tasker.Tache
  alias Tasker.Tache.{Task, TaskSpec, TaskTime, TaskNature}

  defp set_spec_time(tmap, prop, spec) do
    if !spec do
      tmap
    else
      thetime = 
      case spec do
        true          -> F.random_time()
        :future       -> F.random_time(:after)
        :now          -> F.now()
        :past         -> F.random_time(:before)
        :near_past    -> F.random_time(:before, NaiveDateTime.add(F.now(), - :rand.uniform(@day * 2), :minute), @day)
        :near_future  -> 
          F.random_time(:after, NaiveDateTime.add(F.now(), :rand.uniform(@day * 2), :minute), @day)
          |> IO.inspect(label: "\nFutur proche")
        :far_past     -> F.random_time(:before, NaiveDateTime.add(F.now(), - @week * 2, :minute), @day)
        :far_future   -> F.random_time(:after, NaiveDateTime.add(F.now(), @week * 2, :minute), @day)
        %NaiveDateTime{} -> spec
      end        
      %{tmap | task_time: %{tmap.task_time | prop => thetime}}
    end
  end


  describe "La requête SQL de relève" do
    def add_in_list(liste, properties) do
      new_element = F.create_task(properties)
      |> IO.inspect(label: "\nNOUVEL ÉLÉMENT")
      liste ++ [new_element]
    end

    # @tag skip: "à implémenter"
    test "retourne les bonnes candidates" do

      in_list   = []
      out_list  = []

      # IO.puts "DANS IN_LIST"
      in_list = add_in_list(in_list, %{headline: false, deadline: false})
      in_list = add_in_list(in_list, %{headline: :past, deadline: false})
      in_list = add_in_list(in_list, %{headline: :past, deadline: true})
      in_list = add_in_list(in_list, %{headline: :near_future, deadline: false})
      in_list = add_in_list(in_list, %{headline: :near_future, deadline: true})
      in_list = add_in_list(in_list, %{headline: false, deadline: :past})
      in_list = add_in_list(in_list, %{headline: false, deadline: :near_future})
      in_list = add_in_list(in_list, %{headline: false, deadline: :far_future})
      
      # IO.puts "DANS OUT_LIST"
      out_list = add_in_list(out_list, %{headline: :far_future, deadline: false})
      out_list = add_in_list(out_list, %{headline: :far_future, deadline: true})

      # Tâche avec dépendance before
      out_list = add_in_list(out_list, %{deps_before: true})

      # IO.inspect(candidates_request(), label: "REQUEST SQL")
      # IO.inspect(Repo.all(from t in Tasker.Tache.Task), label: "\nTâches réellement en base")

      current_worker = WF.worker_fixture()
      candidate_ids = Repo.submit_sql(candidates_request(), [Ecto.UUID.dump!(current_worker.id)], Tasker.Tache.Task)
      |> Enum.reduce(%{}, fn task, coll -> Map.put(coll, task.id, true) end)
      |> IO.inspect(label: "\nIDS TÂCHES RELEVÉES")

      # On regarde si ces candidates se trouvent bien dans les deux
      # listes (le contraire serait inquiétant)
      candidate_ids |> Enum.each(fn {tid, _rien} ->
        if Enum.reduce(in_list, false, fn task, accu -> 
          if task.id == tid, do: true, else: accu
        end) or Enum.reduce(out_list, false, fn task, accu -> 
          if task.id == tid, do: true, else: accu
        end) do
          IO.puts "FIND: #{tid}"
        else
          IO.puts "NOT FOUND! #{tid}"
        end
      end)

      # Toutes les tâches dans la in_list doivent avoir été relevées
      unfounds = in_list |> Enum.filter(fn t -> ! candidate_ids[t.id] end) |> Enum.map(fn t -> t.id end)
      assert(Enum.count(unfounds) == 0, "Les tâches suivantes (#{Enum.count(unfounds)}) auraient dû être relevées :\n- #{Enum.join(unfounds, "\n- ")}")
      # Aucune des tâches dans la out_list ne doit avoir été relevées
      badfounds = out_list |> Enum.filter(fn t -> candidate_ids[t.id] === true end) |> Enum.map(fn t -> t.id end)
      assert(Enum.count(badfounds) == 0, "Les tâches suivantes (#{Enum.count(unfounds)}) N'auraient PAS dû être relevées :\n- #{Enum.join(badfounds, "\n- ")}")

    end

    # Retourne la requête de relève telle que définie dans le contrôleur
    defp candidates_request do
      TaskerWeb.OneTaskCycleController.candidates_request()
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