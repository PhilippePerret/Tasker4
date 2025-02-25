defmodule TaskerWeb.OTCCalculsTest do
  @moduledoc """
  Ce module de test permet aussi de voir l'influence des poids sur
  le calcul du rank des tâches. Tous les calculs qui vont dans ce
  sens sont précédé de 📠 (il suffit d'appeler la méthode report/1
  pour écrire une ligne de rapport)
  """
  use Tasker.DataCase

  # import CommonTestMethods # is_around etc.
  # alias Tasker.Repo

  alias Tasker.TacheFixtures, as: F
  # alias Tasker.AccountsFixtures, as: WF

  # alias Tasker.Accounts.{Worker}
  # alias Tasker.Tache
  # alias Tasker.Tache.{Task, TaskSpec, TaskTime, TaskNature}

  alias Tasker.TaskRankCalculator, as: RCalc

  # Les durées en minutes
  @now    NaiveDateTime.utc_now()
  @hour   60
  @day    @hour * 24
  @week   @day * 7
  @month  @week * 4

  doctest Tasker.TaskRankCalculator

  defp report(value, line) do
    signe = value > 0 && "+" || "-"
    IO.puts String.pad_trailing("📠 #{line}", 50, ".") <> " #{signe} #{value}"
  end

  describe "Calcul du poids (add_weight)" do

    defp task_expired_with_weight(expireness, prop) do
      ref_date = NaiveDateTime.add(@now, -expireness, :minute)
      F.create_task(%{:rank => true, prop => ref_date})
      |> RCalc.calc_remoteness()
      |> RCalc.add_weight(String.to_atom("#{prop}_expired"))
    end

    test "une date expirée par le deadline ajoute le bon poids" do
      expired_weight = RCalc.weights[:deadline_expired].weight
      IO.puts "" # pour le rapport
      [
        {"1 heure",   @hour},
        {"1 jour",    @day},
        {"1 semaine", @week},
        {"1 mois",    @month}
      ] |> Enum.each(fn {msg, duree} -> 
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
      IO.puts "" # pour le rapport

      [
        {"1 heure", @hour},
        {"1 jour",  @day},
        {"1 semaine", @week},
        {"1 mois", @month}
      ]
      |> Enum.each(fn {msg, duree} -> 
        task = task_expired_with_weight(duree, :headline)
        expect = expired_weight * duree / 4  # 1.5
        report(expect, "Date expirée par headline depuis #{msg}")
        actual = task.rank.value
        assert(expect == actual)
      end)

    end

    
  end

end