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


  describe "Calcul du poids (add_weight)" do

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
        date = NaiveDateTime.add(@now, - duree, :minute)
        task = F.create_task(%{rank: true, started: date})
        |> RCalc.calc_remoteness()
        |> RCalc.add_weight(:started_long_ago)
        
        rem = NaiveDateTime.diff(@now, task.task_time.started_at, :minute)
        expect = @weights[:started_long_ago].weight * rem * @weights[:started_long_ago].time_factor
        assert equal_with_tolerance?(
          round(expect), 
          task.rank.value, 
          "5%"
         ) 
        report(expect, "Tâche (sans échéances) commencée depuis #{msg}")
      end)


    end

  end #/descript add_weight

end