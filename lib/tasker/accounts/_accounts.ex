defmodule Tasker.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Tasker.Repo

  alias Tasker.Accounts.{Worker, WorkerSettings}

  @doc """
  Returns the list of workers.

  ## Examples

      iex> list_workers()
      [%Worker{}, ...]

  """
  def list_workers do
    Repo.all(Worker)
  end

  @doc """
  Gets a single worker.

  Raises `Ecto.NoResultsError` if the Worker does not exist.

  ## Examples

      iex> get_worker!(123)
      %Worker{}

      iex> get_worker!(456)
      ** (Ecto.NoResultsError)

  """
  def get_worker!(id), do: Repo.get!(Worker, id)

  def get_worker_settings(worker_id) do
    Repo.one!(from ws in WorkerSettings, where: ws.worker_id == ^worker_id)
  end

  @doc """
  Creates a worker.

  ## Examples

      iex> create_worker(%{field: value})
      {:ok, %Worker{}}

      iex> create_worker(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_worker(attrs \\ %{}) do
    %Worker{}
    |> Worker.registration_changeset(attrs)
    |> Repo.insert()
    |> create_worker_settings()
  end

  defp create_worker_settings(res) do
    case res do
    {:ok, worker} ->
      Repo.insert!(
        struct(WorkerSettings, 
          Map.put(default_worker_settings(), :worker_id, worker.id)
        )
      )
      res
    {:error, _} -> res
    end
  end

  @doc """
  Préférences par défaut
  """
  def default_worker_settings do
    %{
      display_prefs: %{
        theme: :standard
      },
      interaction_prefs: %{
        notification: true,
        can_be_joined: true
      },
      task_prefs: %{
        max_tasks_count: 100,
        filter_on_duree: false, # false|:long|:short|:medium
        same_nature: :enable_same_nature, # :never_same_nature|:avoid_same_nature
        custom_natures: [] # liste des natures personnelles
      },
      project_prefs: %{

      },
      divers_prefs: %{
        work_start_at: 9,
        work_noon_at: 12,
        work_end_at:  17,
        near_future:  7, # nombre de jours
      }

    }
  end

  @doc """
  Updates a worker.

  ## Examples

      iex> update_worker(worker, %{field: new_value})
      {:ok, %Worker{}}

      iex> update_worker(worker, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_worker(%Worker{} = worker, attrs) do
    worker
    |> Worker.registration_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a worker.

  ## Examples

      iex> delete_worker(worker)
      {:ok, %Worker{}}

      iex> delete_worker(worker)
      {:error, %Ecto.Changeset{}}

  """
  def delete_worker(%Worker{} = worker) do
    Repo.delete(worker)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking worker changes.

  ## Examples

      iex> change_worker(worker)
      %Ecto.Changeset{data: %Worker{}}

  """
  def change_worker(%Worker{} = worker, attrs \\ %{}) do
    Worker.registration_changeset(worker, attrs)
  end

  alias Tasker.Accounts.{Worker, WorkerToken, WorkerNotifier}

  ## Database getters

  @doc """
  Gets a worker by email.

  ## Examples

      iex> get_worker_by_email("foo@example.com")
      %Worker{}

      iex> get_worker_by_email("unknown@example.com")
      nil

  """
  def get_worker_by_email(email) when is_binary(email) do
    Repo.get_by(Worker, email: email)
  end

  @doc """
  Gets a worker by email and password.

  ## Examples

      iex> get_worker_by_email_and_password("foo@example.com", "correct_password")
      %Worker{}

      iex> get_worker_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_worker_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    worker = Repo.get_by(Worker, email: email)
    if Worker.valid_password?(worker, password), do: worker
  end

  ## Worker registration

  @doc """
  Registers a worker.

  ## Examples

      iex> register_worker(%{field: value})
      {:ok, %Worker{}}

      iex> register_worker(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_worker(attrs) do
    %Worker{}
    |> Worker.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking worker changes.

  ## Examples

      iex> change_worker_registration(worker)
      %Ecto.Changeset{data: %Worker{}}

  """
  def change_worker_registration(%Worker{} = worker, attrs \\ %{}) do
    Worker.registration_changeset(worker, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the worker email.

  ## Examples

      iex> change_worker_email(worker)
      %Ecto.Changeset{data: %Worker{}}

  """
  def change_worker_email(worker, attrs \\ %{}) do
    Worker.email_changeset(worker, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_worker_email(worker, "valid password", %{email: ...})
      {:ok, %Worker{}}

      iex> apply_worker_email(worker, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_worker_email(worker, password, attrs) do
    worker
    |> Worker.email_changeset(attrs)
    |> Worker.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the worker email using the given token.

  If the token matches, the worker email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_worker_email(worker, token) do
    context = "change:#{worker.email}"

    with {:ok, query} <- WorkerToken.verify_change_email_token_query(token, context),
         %WorkerToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(worker_email_multi(worker, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp worker_email_multi(worker, email, context) do
    changeset =
      worker
      |> Worker.email_changeset(%{email: email})
      |> Worker.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:worker, changeset)
    |> Ecto.Multi.delete_all(:tokens, WorkerToken.by_worker_and_contexts_query(worker, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given worker.

  ## Examples

      iex> deliver_worker_update_email_instructions(worker, current_email, &url(~p"/workers/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_worker_update_email_instructions(%Worker{} = worker, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, worker_token} = WorkerToken.build_email_token(worker, "change:#{current_email}")

    Repo.insert!(worker_token)
    WorkerNotifier.deliver_update_email_instructions(worker, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the worker password.

  ## Examples

      iex> change_worker_password(worker)
      %Ecto.Changeset{data: %Worker{}}

  """
  def change_worker_password(worker, attrs \\ %{}) do
    Worker.password_changeset(worker, attrs, hash_password: false)
  end

  @doc """
  Updates the worker password.

  ## Examples

      iex> update_worker_password(worker, "valid password", %{password: ...})
      {:ok, %Worker{}}

      iex> update_worker_password(worker, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_worker_password(worker, password, attrs) do
    changeset =
      worker
      |> Worker.password_changeset(attrs)
      |> Worker.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:worker, changeset)
    |> Ecto.Multi.delete_all(:tokens, WorkerToken.by_worker_and_contexts_query(worker, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{worker: worker}} -> {:ok, worker}
      {:error, :worker, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_worker_session_token(worker) do
    {token, worker_token} = WorkerToken.build_session_token(worker)
    Repo.insert!(worker_token)
    token
  end

  @doc """
  Gets the worker with the given signed token.
  """
  def get_worker_by_session_token(token) do
    {:ok, query} = WorkerToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_worker_session_token(token) do
    Repo.delete_all(WorkerToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given worker.

  ## Examples

      iex> deliver_worker_confirmation_instructions(worker, &url(~p"/workers/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_worker_confirmation_instructions(confirmed_worker, &url(~p"/workers/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_worker_confirmation_instructions(%Worker{} = worker, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if worker.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, worker_token} = WorkerToken.build_email_token(worker, "confirm")
      Repo.insert!(worker_token)
      WorkerNotifier.deliver_confirmation_instructions(worker, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a worker by the given token.

  If the token matches, the worker account is marked as confirmed
  and the token is deleted.
  """
  def confirm_worker(token) do
    with {:ok, query} <- WorkerToken.verify_email_token_query(token, "confirm"),
         %Worker{} = worker <- Repo.one(query),
         {:ok, %{worker: worker}} <- Repo.transaction(confirm_worker_multi(worker)) do
      {:ok, worker}
    else
      _ -> :error
    end
  end

  defp confirm_worker_multi(worker) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:worker, Worker.confirm_changeset(worker))
    |> Ecto.Multi.delete_all(:tokens, WorkerToken.by_worker_and_contexts_query(worker, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given worker.

  ## Examples

      iex> deliver_worker_reset_password_instructions(worker, &url(~p"/workers/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_worker_reset_password_instructions(%Worker{} = worker, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, worker_token} = WorkerToken.build_email_token(worker, "reset_password")
    Repo.insert!(worker_token)
    WorkerNotifier.deliver_reset_password_instructions(worker, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the worker by reset password token.

  ## Examples

      iex> get_worker_by_reset_password_token("validtoken")
      %Worker{}

      iex> get_worker_by_reset_password_token("invalidtoken")
      nil

  """
  def get_worker_by_reset_password_token(token) do
    with {:ok, query} <- WorkerToken.verify_email_token_query(token, "reset_password"),
         %Worker{} = worker <- Repo.one(query) do
      worker
    else
      _ -> nil
    end
  end

  @doc """
  Resets the worker password.

  ## Examples

      iex> reset_worker_password(worker, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Worker{}}

      iex> reset_worker_password(worker, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_worker_password(worker, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:worker, Worker.password_changeset(worker, attrs))
    |> Ecto.Multi.delete_all(:tokens, WorkerToken.by_worker_and_contexts_query(worker, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{worker: worker}} -> {:ok, worker}
      {:error, :worker, changeset, _} -> {:error, changeset}
    end
  end
end
