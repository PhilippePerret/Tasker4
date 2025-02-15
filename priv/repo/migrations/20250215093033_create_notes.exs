defmodule Tasker.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :details, :text
      add :author_id, references(:workers, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:notes, [:author_id])

    create table(:notes_tasks, primary_key: false) do
      add :note_id, :binary_id
      add :task_id, :binary_id
      add :read_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:notes_tasks, [:task_id])

  end
end
