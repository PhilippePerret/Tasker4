defmodule Tasker.Factory do

  # alias Tasker.Repo
  alias Tasker.Accounts.Worker
  # import Ecto.Changeset

  @default_attrs %{
    worker: %{
      pseudo: "Un pseudo",
      email:  "son.email@chez.lui",
      password: "son mot de passe en clair",
     }
  }

  def changeset(:worker, attrs) do
    attrs = Map.merge(attributes(:worker), attrs)
    %Tasker.Accounts.Worker{}
    |> Worker.registration_changeset(attrs)
  end

  def attributes(table, attrs \\ %{}) do
    Map.merge(@default_attrs[table], attrs)
  end


end