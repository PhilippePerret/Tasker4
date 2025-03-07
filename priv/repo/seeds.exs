# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Tasker.Repo.insert!(%Tasker.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


# Ce fichier contient les données de production qu'il faut toujours remettre

# --- DONNÉES NATURES DE TÂCHE ---
#
# NOTE :  Ce seed fait plus que d'alimenter la table avec les données
#         de départ. Il crée aussi un fichier 'xlocales_natures.ex'
#         qui définit les locales pour gettext 
#         (dans lib/tasker/tache/).
natures_locales_file = Path.absname(Path.join(["lib","tasker","tache","xlocales_natures.ex"]))
# Pour refaire toute la table, ex-commenter le code suivant (4 
# lignes). Sinon, seuls les nouveaux noms seront ajoutés
natures_table_names = Tasker.Repo.all(Tasker.Tache.TaskNature)
|> Enum.reduce(%{}, fn nature, accu ->
  Map.put(accu, nature.id, true)
end)

new_natures =
[
  ["Purchases", "purchases"],
  ["Film Analysis", "ana_film"],
  ["Music Analysis", "ana_mus"],
  ["Accounting", "compta"],
  ["Personal Finances", "compta_perso"],
  ["Design", "design"],
  ["Dramaturgy", "drama"],
  ["Documentation", "docu"],
  ["Pedagogy", "pedago"],
  ["Exercise (Pedagogy)", "pedago_exo"],
  ["Programming", "prog"],
  ["Programming Test", "prog_test"],
  ["Report", "report"],
  ["Writing", "writing"],
  ["Information", "infos"],
  ["Research", "research"],
  ["Sports", "sport"],

  ["Z-Z-Z-sans-virgule", "rien"]
]|> Enum.map(fn [nat_name, nat_id] ->
  if nat_name != "Z-Z-Z-sans-virgule" && !natures_table_names[nat_id] do
    Tasker.Repo.insert!(struct(Tasker.Tache.TaskNature, %{id: nat_id, name: nat_name}))
    nat_name
  else
    false
  end
end)
|> Enum.filter(fn el -> el != false end)

old_natures = natures_table_names |> Enum.map(fn {key, name} -> name end)
all_natures = new_natures ++ old_natures

IO.puts "Nouvelles natures (#{Enum.count(new_natures)}/#{Enum.count(all_natures)}) : #{Enum.join(new_natures, ", ")}"


# On fabrique le fichier des locales
File.exists?(natures_locales_file) && File.rm(natures_locales_file)
natures_gettext = all_natures
|> Enum.map(fn nat_name -> ~s|  dgettext("natures", "#{nat_name}")| end)
|> Enum.join("\n")
code = """
# Fichier composé automatiquement par seeds.exs
defmodule Tasker.NatureLocales do
  use Gettext, backend: TaskerWeb.Gettext

  #{natures_gettext}
end
"""
File.write!(natures_locales_file, code)