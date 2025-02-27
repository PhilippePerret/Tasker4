defmodule TaskerWeb.OTCCalculsTest do
  @moduledoc """
  Ce module de test permet aussi de voir l'influence des poids sur
  le calcul du rank des tâches. Tous les calculs qui vont dans ce
  sens sont précédé de 📠 (il suffit d'appeler la méthode report/1
  pour écrire une ligne de rapport)
  """
  use Tasker.DataCase

  import TestHandies # par exemple equal_with_tolerance/3

  # import CommonTestMethods # is_around etc.
  # alias Tasker.Repo

  alias Tasker.TacheFixtures, as: F
  # alias Tasker.AccountsFixtures, as: WF

  # alias Tasker.Accounts.{Worker}
  # alias Tasker.Tache
  # alias Tasker.Tache.{Task, TaskSpec, TaskTime, TaskNature}

  alias Tasker.TaskRankCalculator, as: RCalc

  @weights RCalc.weights

  # Les durées en minutes
  @now    NaiveDateTime.utc_now()
  @hour   60
  @day    @hour * 24
  @week   @day * 7
  @month  @week * 4

  @eloignements [
    {"1 heure",   @hour},
    {"1 jour",    @day},
    {"1 semaine", @week},
    {"1 mois",    @month}
  ] 

  doctest Tasker.TaskRankCalculator

  defp report(value, line) do
    signe = value > 0 && "+" || "-"
    IO.puts String.pad_trailing("📠 #{line}", 60, ".") <> " #{signe} #{value}"
  end

  defp report_title(condition) do
    title = "Ajouté à rank.value par #{condition}"
    titlen = String.length(title)
    IO.puts "\n#{title}\n#{String.pad_leading("", titlen, "-")}"
  end

  defp time_from_now(minutes) do
    NaiveDateTime.add(@now, minutes, :minute)
  end


  describe "Calcul du poids (add_weight)" do

    test "en fonction de l'éloignement de l'headline" do
      # Les tâches, sans autre prérogatives, sont classées
      # par leur proximité

      task1 = F.create_task(headline: time_from_now(@day + 1000))
      task2 = F.create_task(headline: time_from_now(@day + 100000))
      task3 = F.create_task(headline: time_from_now(@day + 200))

      liste = [task1, task2, task3]
      new_liste = RCalc.sort(liste)
      # new_liste |> Enum.each(fn tk ->
      #   IO.puts "- T. #{tk.id} [rank=#{tk.rank.value}]"
      # end)
      assert( Enum.at(new_liste, 0).id == task3.id )
      assert( Enum.at(new_liste, 1).id == task1.id )
      assert( Enum.at(new_liste, 2).id == task2.id )

    end

    defp task_with_priority_and_remoteness(priority, remoteness) do
      ref_date = NaiveDateTime.add(@now, remoteness, :minute)
      F.create_task(%{:rank => true, :priority => priority, :headline => ref_date})
      |> RCalc.calc_remoteness()
      |> RCalc.add_weight(:priority)
    end
    test "en fonction de la priorité et de l'éloignement" do
      report_title("priorité et éloignement")
      (0..5)
      |> Enum.each(fn priority -> 
        @eloignements |> Enum.each(fn {msg, remoteness} ->
          tk = task_with_priority_and_remoteness(priority, remoteness)
          report(tk.rank.value, "Tâche à #{msg} avec priorité de #{priority}")
          assert equal_with_tolerance?(round(priority * @weights[:priority].weight * @weights[:priority].time_factor / remoteness), tk.rank.value, "5%")
        end)
      end)
    end

    defp task_with_urgence_and_remoteness(urgence, remoteness) do
      ref_date = NaiveDateTime.add(@now, remoteness, :minute)
      F.create_task(%{:rank => true, :urgence => urgence, :headline => ref_date})
      |> RCalc.calc_remoteness()
      |> RCalc.add_weight(:urgence)
    end
    test "en fonction de l'urgence et de l'éloignement" do
      report_title("urgence et éloignement")
      (0..5) |> Enum.each(fn urgence -> 
        @eloignements |> Enum.each(fn {msg, remoteness} ->
          tk = task_with_urgence_and_remoteness(urgence, remoteness)
          report(tk.rank.value, "Tâche à #{msg} avec urgence de #{urgence}")
          assert equal_with_tolerance?(round(urgence * @weights[:urgence].weight * @weights[:urgence].time_factor / remoteness), tk.rank.value, "5%")
        end)
      end)
    end

    defp task_expired_with_weight(expireness, prop) do
      ref_date = NaiveDateTime.add(@now, -expireness, :minute)
      F.create_task(%{:rank => true, prop => ref_date})
      |> RCalc.calc_remoteness()
      |> RCalc.add_weight(String.to_atom("#{prop}_expired"))
    end
    test "une date expirée par le deadline ajoute le bon poids" do
      expired_weight = RCalc.weights[:deadline_expired].weight
      IO.puts "" # pour le rapport
      @eloignements |> Enum.each(fn {msg, duree} -> 
        task = task_expired_with_weight(duree, :deadline)
        expect = expired_weight * duree
        report(expect, "Date expirée par deadline depuis #{msg}")
        actual = task.rank.value
        assert(expect == actual)

      end)
      
      
    end
    test "une date expirée par le headline ajoute le bon poids" do
      # Calcul du poids ajouté par une expiration :
      # Principes :
      #   - plus l'expiration est lointaine, plus elle doit être forte
      #   - donc il n'y a pas de time-pondération ici
      #   - le poids est un poids par minute
      # Le poids de l'expiration de la tâche
      expired_weight    = RCalc.weights[:headline_expired].weight
      report_title("tâche expirée")

      @eloignements |> Enum.each(fn {msg, duree} -> 
        task = task_expired_with_weight(duree, :headline)
        expect = round(expired_weight * duree / 4)  # 1.5
        report(expect, "Date expirée par headline depuis #{msg}")
        actual = task.rank.value
        assert(expect == actual)
      end)

    end

    defp task_du_jour(deadline) do
      F.create_task(%{:rank => true, :headline => @now, deadline: deadline})
      |> RCalc.calc_remoteness()
      |> RCalc.add_weight(:today_task)
    end
    test "une tâche d'aujourd'hui gagne un peu" do
      # Note : une tâche est considérée du jour quand son commencement
      # est aujourd'hui et que sa fin est nil ou d'aujourd'hui aussi
      report_title("tâche d'aujourd'hui")
      task = task_du_jour(nil)
      assert task.rank.value == 250
      report(250, "Tâche du jour sans deadline")
      task = task_du_jour(NaiveDateTime.add(@now, 1000))
      assert task.rank.value == 250
      report(250, "Tâche du jour et deadline aujourd'hui")
      task = task_du_jour(NaiveDateTime.add(@now, 1000000, :minute))
      assert task.rank.value == 0
      report(0, "Tâche du jour et deadline lointaine")
    end

    test "une tâche sans échéance mais depuis trop longtemps dans la liste" do
      # En fait, ça correspond à une tâche dont le started_at est très
      # lointain. Plus ce started_at est lointain, plus la tâche a de poids
      report_title("tâche démarrée, sans échéance")
      task = F.create_task(%{rank: true, started: :far_past})
      |> RCalc.calc_remoteness()
      |> RCalc.add_weight(:started_long_ago)
      assert task.rank.value > 0

      @eloignements |> Enum.each(fn {msg, duree} -> 
        date = time_from_now(- duree)
        task = F.create_task(%{rank: true, started: date})
        |> RCalc.calc_remoteness()
        |> RCalc.add_weight(:started_long_ago)
        # |> IO.inspect(label: "Tâche")
        
        rem = NaiveDateTime.diff(@now, task.task_time.started_at, :minute)
        # |> IO.inspect(label: "remote started")
        expect = @weights[:started_long_ago].weight * rem * @weights[:started_long_ago].time_factor
        # assert true
        titre = "Assertion avec @eloignement = #{duree}"
        debug_tasks([task], [], titre)
        assert equal_with_tolerance?(
          round(expect), 
          task.rank.value, 
          "5%"
         ) 
        report(expect, "Tâche (sans échéances) commencée depuis #{msg}")
      end)
    end

    test "une tâche presque finie ajoute du poids" do
      task = F.create_task(%{
        rank: true, 
        headline: time_from_now(- @day),
        started:  time_from_now((- @day) + @hour),
        duree: @day,
        exec_duree: @day - (@day * 5 / 100)
      })
      |> RCalc.calc_remoteness()
      |> RCalc.add_weight(:almost_finished)
      
      assert(task.rank.value == @weights[:almost_finished].weight)

      # Une tâche non touchée par cette condition
      task = F.create_task(%{
        rank: true, 
        started:  time_from_now((- @day) + @hour),
        headline: time_from_now(- @day),
        duree: @day,
        exec_duree: @day - (@day * 20 / 100)
      })
      |> RCalc.calc_remoteness()
      |> RCalc.add_weight(:almost_finished)
  
      assert(task.rank.value == 0)
    end

    defp tasks_for_sort_by_duration do
      [@hour, @day, @week] 
      |> Enum.map(fn duree ->
        F.create_task(%{rank: true, duree: duree})
      end)
    end

    test "pour une tâche courte si le worker les privilégie" do
      # C'est un calcul relatif en fonction des tâches relevées
      # Cf. l'explication dans task_rank_calculator
      options = [
        {:prefs, [
          {:sort_by_task_duration, :short},
          {:default_task_duration, 30}
          ]
        }
      ]
      task_list = tasks_for_sort_by_duration()

      # task_list
      # |> Enum.map(fn tk -> 
      #   [tk.rank.value, tk.task_time.expect_duration]
      # end)
      # |> IO.inspect(label: "Classement AVANT")

      task_list = RCalc.sort(task_list, options)

      # task_list
      # |> Enum.map(fn tk -> 
      #   [tk.rank.value, tk.task_time.expect_duration]
      # end)
      # |> IO.inspect(label: "Classement APRÈS")

      task1 = Enum.at(task_list, 0)
      assert( task1.task_time.expect_duration == @hour )
      assert (task1.rank.value == 2 * @weights[:per_duration].weight)
      task2 = Enum.at(task_list, 1)
      assert( task2.task_time.expect_duration == @day )
      assert (task2.rank.value == @weights[:per_duration].weight)
      task3 = Enum.at(task_list, 2)
      assert( task3.task_time.expect_duration == @week )
      assert (task3.rank.value == 0)
    end

    test "pour une tâche longue si le worker les privilégie" do
      # C'est un calcul relatif en fonction des tâches relevées
      # Cf. l'explication dans task_rank_calculator
      options = [
        {:prefs, [
          {:sort_by_task_duration, :long},
          {:default_task_duration, 30}
          ]
        }
      ]
      task_list = tasks_for_sort_by_duration()
      # |> IO.inspect(label: "Classement AVANT")
      
      task_list = RCalc.sort(task_list, options)
      # |> IO.inspect(label: "Classement APRÈS")

      task1 = Enum.at(task_list, 0)
      assert( task1.task_time.expect_duration == @week )
      assert (task1.rank.value == 2 * @weights[:per_duration].weight)
      task2 = Enum.at(task_list, 1)
      assert( task2.task_time.expect_duration == @day )
      assert (task2.rank.value == @weights[:per_duration].weight)
      task3 = Enum.at(task_list, 2)
      assert( task3.task_time.expect_duration == @hour )
      assert (task3.rank.value == 0)

    end

    # Retourne une liste de 4 tâches avec les natures réparties
    # de cette manière :
    #   – tâche 1 : natures ['writing', 'docu']
    #   - tâche 2 : natures ['writing', 'sports']
    #   - tâche 3 : natures ['report']
    #   - tâche 4 : natures ['sports', 'pedago', 'drama']
    # 
    # Fonctionnement suivant le réglage de :prioritize_same_nature
    # Quand TRUE (le worker privilégie les mêmes natures)
    #   => la tâche 4 doit monter après la tâche 2 donc l'ordre
    #       doit devenir : 1, 2, 4, 3
    # Quand FALSE (le worker privilégie les natures différentes)
    #   => la tâche 2 doit descendre d'une tâche
    #   => la tâche 4 doit monter tout en haut
    #   => l'ordre doit devenir : 4, 1, 3, 2
    # Quand NIL (aucune préférence)
    #   L'ordre doit rester le même
    # 
    # Note pour classer dans le bon order, il suffit de créer les
    # tâche avec un should_start_at progressif.
    defp tasks_for_sort_by_nature do
      [
        ["writing", "docu"],
        ["writing", "sport"],
        ["report"],
        ["sport", "pedago", "drama"]
      ] |> Enum.with_index()
      |> Enum.map(fn {natures, index} -> 
        F.create_task(%{rank: true, headline: time_from_now(2 * @day + index * 60), natures: natures})
      end)
    end

    test "pour les tâches de même nature quand le worker les priviligie " do
      # Ce choix n'affecte pas le poids de la tâche mais son index (son
      # classement dans la liste finale)
      options = [
        {:prefs, [
          {:sort_by_task_duration, nil},
          {:default_task_duration, 30},
          {:prioritize_same_nature, true}
          ]
        }
      ]
      task_list = tasks_for_sort_by_nature()
      # |> debug_tasks([:natures], "Avant tri")
      task0 = Enum.at(task_list, 0)
      task1 = Enum.at(task_list, 1)
      task2 = Enum.at(task_list, 2)
      task3 = Enum.at(task_list, 3)
      new_task_list = RCalc.sort(task_list, options)
      # |> debug_tasks([:natures], "Après classement")
      # Nouvel ordre
      assert(Enum.at(new_task_list, 0).id == task0.id)
      assert(Enum.at(new_task_list, 1).id == task1.id)
      assert(Enum.at(new_task_list, 2).id == task3.id)
      assert(Enum.at(new_task_list, 3).id == task2.id)
    end

    test "pour les tâches de même nature avec rejet par le worker" do
      # Ce choix n'affecte pas le poids de la tâche mais son index (son
      # classement dans la liste finale)
      options = [
        {:prefs, [
          {:sort_by_task_duration, nil},
          {:default_task_duration, 30},
          {:prioritize_same_nature, false}
          ]
        }
      ]
      task_list = tasks_for_sort_by_nature()
      # |> debug_tasks([:natures], "Avant tri")
      task0 = Enum.at(task_list, 0)
      task1 = Enum.at(task_list, 1)
      task2 = Enum.at(task_list, 2)
      task3 = Enum.at(task_list, 3)
      new_task_list = RCalc.sort(task_list, options)
      # |> debug_tasks([:natures], "Après classement")
      # Nouvel ordre
      assert(Enum.at(new_task_list, 0).id == task0.id)
      assert(Enum.at(new_task_list, 1).id == task2.id)
      assert(Enum.at(new_task_list, 2).id == task1.id)
      assert(Enum.at(new_task_list, 3).id == task3.id)

    end
    test "pour les tâches de même nature sans préférence" do
      # Sans préférences au niveau des natures, la liste garde
      # le même ordre
      options = [
        {:prefs, [
          {:sort_by_task_duration, nil},
          {:default_task_duration, 30},
          {:prioritize_same_nature, nil}
          ]
        }
      ]
      task_list = tasks_for_sort_by_nature()
      # |> debug_tasks([:natures], "Avant tri")
      task0 = Enum.at(task_list, 0)
      task1 = Enum.at(task_list, 1)
      task2 = Enum.at(task_list, 2)
      task3 = Enum.at(task_list, 3)
      new_task_list = RCalc.sort(task_list, options)
      # |> debug_tasks([:natures], "Après classement")
      # Nouvel ordre
      assert(Enum.at(new_task_list, 0).id == task0.id)
      assert(Enum.at(new_task_list, 1).id == task1.id)
      assert(Enum.at(new_task_list, 2).id == task2.id)
      assert(Enum.at(new_task_list, 3).id == task3.id)
    end

    test "Entre deux tâches, celle avec (le plus grand nombre de) dépendances est privilégiée" do
      task1 = F.create_task(%{deps_after: true})
      task2 = F.create_task(%{deps_after: false})
      task3 = F.create_task(%{deps_after: 2})

      task_list = [task2, task3, task1]
      # |> debug_tasks([:dependencies], "Avant classement")
      new_task_list = RCalc.sort(task_list)
      # |> debug_tasks([:dependencies], "Après classement")
      assert(Enum.at(new_task_list, 0).id == task3.id)
      assert(Enum.at(new_task_list, 1).id == task1.id)
      assert(Enum.at(new_task_list, 2).id == task2.id)

    end

  end #/descript add_weight

end