defmodule Tasker.TWorker do

  @default_attributes %{
    pseudo: "Un pseudo",
    email:  "son.email@chez.lui",
    password: "son mot de passe en clair",
    enc_password: nil
  }

  def get_params(attrs) do
    Map.merge(@default_attributes, attrs)
  end

end