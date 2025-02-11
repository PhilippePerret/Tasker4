defmodule Tasker.Factory do

  alias Tasker.{Repo, Worker}
  import Ecto.Changeset

  @default_attrs %{
    worker: %{
      pseudo: "Un pseudo",
      email:  "son.email@chez.lui",
      password: "son mot de passe en clair",
     }
  }

  def changeset(:worker, attrs) do
    attrs = Map.merge(attributes(:worker), attrs)
    %Tasker.Worker{}
    |> Worker.changeset(attrs)
  end

  def attributes(table, attrs \\ %{}) do
    Map.merge(@default_attrs[table], attrs)
  end


end