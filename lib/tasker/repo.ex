defmodule Tasker.Repo do
  use Ecto.Repo,
    otp_app: :tasker,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Permet de soumettre une requête SQL pure et de récupérer le 
  résultat.

  ## Examples

    iex> Repo.submit_sql("SELECT * FROM natures;")
    %Map{}

  @param {String} sql   Requête SQL valide
  @param {List} params  Liste des paramètres ($N) pour la requête
  @param {Struct} structure Si spécifié, on renvoie les résultats
                  dans ce format (liste de structures)
                  Sinon, on retourne simplement une map avec les
                  colonnes en clé et les valeurs en valeur.
                  C'est le nom du module

  """
  def submit_sql(sql), do: submit_sql(sql, [])

  def submit_sql(sql, params, structure) do
    sql = safe_sql(sql)
    Enum.map(submit_sql(sql, params), &struct(structure, &1))
  end
  def submit_sql(sql, params) when is_list(params) do
    result = query!(sql, params)
    {colonnes, binary_keys} = result.columns
    |> Enum.reduce({[],[]}, fn key, accu ->
      key_atom = String.to_atom(key)
      {cols, bkeys} = accu
      cols = cols ++ [key_atom]
      bkeys = if key == "id" || String.ends_with?(key, "_id") do
        bkeys ++ [key_atom]
      else bkeys end
      {cols, bkeys}
    end) 
    
    Enum.map(result.rows, fn row -> 
      Enum.zip(colonnes, row)
      |> Enum.into(%{}) 
      |> (fn map ->
        binary_keys |> Enum.reduce(map, fn bkey, coll ->
          if is_binary(map[bkey]) do
            %{coll | bkey => Ecto.UUID.load!(map[bkey]) } 
          else coll end
        end)
      end).()
    end)
  end
  defp safe_sql(sql) do
    sql
    |> String.trim()
    |> (fn x -> String.ends_with?(x, ";") && x || "#{x};" end).()
  end

end
