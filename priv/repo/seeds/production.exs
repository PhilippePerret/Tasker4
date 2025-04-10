# Pour insérer ces données courantes en production : 
# 
#     MIX_ENV=prod mix run priv/repo/seeds/production.exs

# phil = Tasker.Repo.insert!(struct(Tasker.Account.Worker), %{

# })

alias Tasker.Repo
alias Tasker.Tache.{Task, TaskTime, TaskSpec}
alias Tasker.Projet.Project

# --- Tout initialiser ---
Tasker.Repo.delete_all(Project)
Tasker.Repo.delete_all(Task)
Tasker.Repo.delete_all(TaskTime)
Tasker.Repo.delete_all(TaskSpec)

# === PROJETS ===


# Projet vie privée
vie_privee = %Project{
  title: "Vie privée"
}
vie_privee = Repo.insert!(vie_privee)
|> IO.inspect(label: "Projet Vie Privée")

# Projet autoentreprise
autoentreprise = %Project{
  title: "Autoentreprise",
  folder: "/Users/philippeperret/ICARE_EDITIONS"
}
autoentreprise = Repo.insert!(autoentreprise)

# Projet Analyse Musicale
analyse_musicale = %Project{
  title: "Analyse Musicale",
  folder: nil
}

# ===== TÂCHES ===
# Anniversaire d'Élie
birthday_elie = %Task{
  title:      "Anniversaire d'ÉLIE",
  project_id: vie_privee.id
}
Repo.insert!(%TaskTime{
  task_id: birthday_elie.id,
  recurrence: "0 10 23 9 *",
  alert_at:   ~N[2025-09-23 09:50:00],
  alerts:     [%{at: nil, unit: "1", quatity: 10}]
})
Repo.insert!(%TaskSpec{
  task_id:  birthday_elie.id,
  priority: 5
})

# Anniversaire de Marion
birthday_marion = %Task{
  title:      "Anniversaire MARION",
  project_id: vie_privee.id
}
Repo.insert!(%TaskTime{
  task_id: birthday_marion.id,
  should_start_at: ~N[2025-12-23 10:00:00],
  recurrence: "0 10 23 12 *",
  alert_at:   ~N[2025-12-22 10:00:00],
  alerts:     [%{at: nil, unit: 24 * 3600, quatity: 1}]
})

# Séance hebdomadaire d'analyse de Bernard
analyse_bernard = Repo.insert!(%Task{
  title: "Analyse musicale Bernard",
  project_id: analyse_musicale.id
})
Repo.insert!(%TaskSpec{
  task_id:  analyse_bernard.id,
  priority: 5
  })
Repo.insert!(%TaskTime{
  task_id:  analyse_bernard.id,
  should_start_at:  ~N[2025-04-16 12:00:00],
  should_end_at:    ~N[2025-04-16 13:00:00],
  alert_at:         ~N[2025-04-16 11:00:00],
  alerts: [
    %{at: ~N[2025-04-16 11:00:00], unit: "1", quantity: 60},
    %{at: ~N[2025-04-16 11:30:00], unit: "1", quantity: 30}
  ]
})

# Facture mensuelle de Bernard
facture_benard = Repo.insert!(%Task{
  title: "Facture Bernard Waterlot",
  project_id: analyse_musicale.id
})
Repo.insert!(%TaskSpec{
  task_id: facture_benard.id,
  details: """
  * Ajouter une nouvelle vente avec > iced add > Une vente
  * Puis produire la facture avec > iced facture
  """
})
Repo.insert!(%TaskTime{
  task_id: facture_benard.id,
  should_start_at:  ~N[2025-04-10 11:00:00],
  should_end_at:    ~N[2025-04-15 11:00:00],
  recurrence:       "0 11 10 * *",
  alert_at:         ~N[2025-04-10 10:50:00],
  alerts:           [%{at: ~N[2025-04-10 10:50:00], unit: 1, quantity: 10}]
})


# Déclaration mensuelle autoentreprise
declaration = Repo.insert!(%Task{
  title:      "Déclaration mensuelle URSSAF",
  project_id: autoentreprise.id
})
Repo.insert!(%TaskSpec{
  task_id:  declaration.id,
  details:  "Utiliser l'outils > iced proc > La micro-entreprise > Rapport mensuel pour les impôts",
  priority: 4
})
Repo.insert!(%TaskTime{
  task_id:          declaration.id,
  should_start_at:  ~N[2025-04-10 10:00:00],
  should_end_at:    ~N[2025-04-15 10:00:00],
  imperative_end:   true,
  alert_at:         ~N[2025-04-10 09:50:00],
  alerts:           [%{at: ~N[2025-04-10 09:50:00], unit: "1", quantity: 10}],
  recurrence:       "0 10 10 * *"
})


# Séance hebdomadaire du Clip
clip = Repo.insert!(%Task{
  title:      "Séance hebdo CLIP",
  project_id: vie_privee.id
})
Repo.insert!(%TaskSpec{
  task_id:  clip.id,
  priority: 5,
  details:  "Au centre pénitentiaire de Mont-de-Marsan"
})
Repo.insert!(%TaskTime{
  task_id:          clip.id,
  recurrence:       "15 13 * * 4",
  should_start_at:  ~N[2025-04-10 13:15:00],
  should_end_at:    ~N[2025-04-10 16:15:00]
})