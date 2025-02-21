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
]|> Enum.filter(fn [task_name, task_id] ->
  if task_name != "Z-Z-Z-sans-virgule" && !natures_table_names[task_id] do
    Tasker.Repo.insert!(struct(Tasker.Tache.TaskNature, %{id: task_id, name: task_name}))
    task_name
  else
    false
  end
end)

IO.puts "Nouvelles natures (#{Enum.count(new_natures)}) : #{Enum.join(new_natures, ", ")}"