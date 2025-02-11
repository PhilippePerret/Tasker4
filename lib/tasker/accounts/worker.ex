defmodule Tasker.Worker do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "workers" do
    field :password, :string
    field :pseudo, :string
    field :email, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(worker, attrs) do
    worker
    |> cast(attrs, [:pseudo, :email, :password])
    |> validate_required([:pseudo, :email, :password])
    |> update_change(:password, &Bcrypt.hash_pwd_salt/1)
  end
end
