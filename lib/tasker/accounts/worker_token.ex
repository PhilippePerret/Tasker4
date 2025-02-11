defmodule Tasker.Accounts.WorkerToken do
  use Ecto.Schema
  import Ecto.Query
  alias Tasker.Accounts.WorkerToken

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the email may take over the account.
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @change_email_validity_in_days 7
  @session_validity_in_days 60

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "workers_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :worker, Tasker.Accounts.Worker

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual worker
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_session_token(worker) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %WorkerToken{token: token, context: "session", worker_id: worker.id}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the worker found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  def verify_session_token_query(token) do
    query =
      from token in by_token_and_context_query(token, "session"),
        join: worker in assoc(token, :worker),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: worker

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the worker's email.

  The non-hashed token is sent to the worker email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  """
  def build_email_token(worker, context) do
    build_hashed_token(worker, context, worker.email)
  end

  defp build_hashed_token(worker, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %WorkerToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       worker_id: worker.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the worker found by the token, if any.

  The given token is valid if it matches its hashed counterpart in the
  database and the user email has not changed. This function also checks
  if the token is being used within a certain period, depending on the
  context. The default contexts supported by this function are either
  "confirm", for account confirmation emails, and "reset_password",
  for resetting the password. For verifying requests to change the email,
  see `verify_change_email_token_query/2`.
  """
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in by_token_and_context_query(hashed_token, context),
            join: worker in assoc(token, :worker),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == worker.email,
            select: worker

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the worker found by the token, if any.

  This is used to validate requests to change the worker
  email. It is different from `verify_email_token_query/2` precisely because
  `verify_email_token_query/2` validates the email has not changed, which is
  the starting point by this function.

  The given token is valid if it matches its hashed counterpart in the
  database and if it has not expired (after @change_email_validity_in_days).
  The context must always start with "change:".
  """
  def verify_change_email_token_query(token, "change:" <> _ = context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in by_token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def by_token_and_context_query(token, context) do
    from WorkerToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given worker for the given contexts.
  """
  def by_worker_and_contexts_query(worker, :all) do
    from t in WorkerToken, where: t.worker_id == ^worker.id
  end

  def by_worker_and_contexts_query(worker, [_ | _] = contexts) do
    from t in WorkerToken, where: t.worker_id == ^worker.id and t.context in ^contexts
  end
end
