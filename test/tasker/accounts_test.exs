defmodule Tasker.AccountsTest do
  use Tasker.DataCase

  alias Tasker.Accounts

  describe "workers" do
    alias Tasker.Accounts.Worker

    import Tasker.AccountsFixtures

    @invalid_attrs %{password: nil, pseudo: nil, email: nil}

    test "list_workers/0 returns all workers" do
      worker = worker_fixture()
      assert Accounts.list_workers() == [worker]
    end

    test "get_worker!/1 returns the worker with given id" do
      worker = worker_fixture()
      assert Accounts.get_worker!(worker.id) == worker
    end

    test "create_worker/1 with valid data creates a worker" do
      uniq_email = "worker#{System.unique_integer()}@example.com"
      valid_attrs = %{password: "some password", pseudo: "some pseudo", email: uniq_email}

      assert {:ok, %Worker{} = worker} = Accounts.create_worker(valid_attrs)
      # assert worker.password == "some password"
      assert Bcrypt.verify_pass("some password", worker.hashed_password)
      assert worker.pseudo == "some pseudo"
      assert worker.email == uniq_email
    end

    test "create_worker/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_worker(@invalid_attrs)
    end

    test "update_worker/2 with valid data updates the worker" do
      worker = worker_fixture()
      uniq_email = "worker#{System.unique_integer()}@example.com"
      update_attrs = %{password: "some updated password", pseudo: "some updated pseudo", email: uniq_email}

      assert {:ok, %Worker{} = worker} = Accounts.update_worker(worker, update_attrs)
      # assert worker.password == "some updated password"
      assert Bcrypt.verify_pass("some updated password", worker.hashed_password)
      assert worker.pseudo == "some updated pseudo"
      assert worker.email == uniq_email
    end

    test "update_worker/2 with invalid data returns error changeset" do
      worker = worker_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_worker(worker, @invalid_attrs)
      assert worker == Accounts.get_worker!(worker.id)
    end

    test "delete_worker/1 deletes the worker" do
      worker = worker_fixture()
      assert {:ok, %Worker{}} = Accounts.delete_worker(worker)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_worker!(worker.id) end
    end

    test "change_worker/1 returns a worker changeset" do
      worker = worker_fixture()
      # assert %Ecto.Changeset{} = Accounts.change_worker(worker)()
      assert %Ecto.Changeset{} = Accounts.change_worker_registration(worker)
    end
  end

  import Tasker.AccountsFixtures
  alias Tasker.Accounts.{Worker, WorkerToken}

  describe "get_worker_by_email/1" do
    test "does not return the worker if the email does not exist" do
      refute Accounts.get_worker_by_email("unknown@example.com")
    end

    test "returns the worker if the email exists" do
      %{id: id} = worker = worker_fixture()
      assert %Worker{id: ^id} = Accounts.get_worker_by_email(worker.email)
    end
  end

  describe "get_worker_by_email_and_password/2" do
    test "does not return the worker if the email does not exist" do
      refute Accounts.get_worker_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the worker if the password is not valid" do
      worker = worker_fixture()
      refute Accounts.get_worker_by_email_and_password(worker.email, "invalid")
    end

    test "returns the worker if the email and password are valid" do
      %{id: id} = worker = worker_fixture()

      assert %Worker{id: ^id} =
               Accounts.get_worker_by_email_and_password(worker.email, valid_worker_password())
    end
  end

  describe "get_worker!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_worker!("11111111-1111-1111-1111-111111111111")
      end
    end

    test "returns the worker with the given id" do
      %{id: id} = worker = worker_fixture()
      assert %Worker{id: ^id} = Accounts.get_worker!(worker.id)
    end
  end

  describe "create_worker/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.create_worker(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.create_worker(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.create_worker(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = worker_fixture()
      {:error, changeset} = Accounts.create_worker(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.create_worker(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers workers with a hashed password" do
      email = unique_worker_email()
      {:ok, worker} = Accounts.create_worker(valid_worker_attributes(email: email))
      assert worker.email == email
      assert is_binary(worker.hashed_password)
      assert is_nil(worker.confirmed_at)
      assert is_nil(worker.password)
    end
  end

  describe "change_worker_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_worker_registration(%Worker{})
      assert changeset.required == [:pseudo, :password, :email]
    end

    test "allows fields to be set" do
      email = unique_worker_email()
      password = valid_worker_password()

      changeset =
        Accounts.change_worker_registration(
          %Worker{},
          valid_worker_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_worker_email/2" do
    test "returns a worker changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_worker_email(%Worker{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_worker_email/3" do
    setup do
      %{worker: worker_fixture()}
    end

    test "requires email to change", %{worker: worker} do
      {:error, changeset} = Accounts.apply_worker_email(worker, valid_worker_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{worker: worker} do
      {:error, changeset} =
        Accounts.apply_worker_email(worker, valid_worker_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{worker: worker} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_worker_email(worker, valid_worker_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{worker: worker} do
      %{email: email} = worker_fixture()
      password = valid_worker_password()

      {:error, changeset} = Accounts.apply_worker_email(worker, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{worker: worker} do
      {:error, changeset} =
        Accounts.apply_worker_email(worker, "invalid", %{email: unique_worker_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{worker: worker} do
      email = unique_worker_email()
      {:ok, worker} = Accounts.apply_worker_email(worker, valid_worker_password(), %{email: email})
      assert worker.email == email
      assert Accounts.get_worker!(worker.id).email != email
    end
  end

  describe "deliver_worker_update_email_instructions/3" do
    setup do
      %{worker: worker_fixture()}
    end

    test "sends token through notification", %{worker: worker} do
      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_update_email_instructions(worker, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert worker_token = Repo.get_by(WorkerToken, token: :crypto.hash(:sha256, token))
      assert worker_token.worker_id == worker.id
      assert worker_token.sent_to == worker.email
      assert worker_token.context == "change:current@example.com"
    end
  end

  describe "update_worker_email/2" do
    setup do
      worker = worker_fixture()
      email = unique_worker_email()

      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_update_email_instructions(%{worker | email: email}, worker.email, url)
        end)

      %{worker: worker, token: token, email: email}
    end

    test "updates the email with a valid token", %{worker: worker, token: token, email: email} do
      assert Accounts.update_worker_email(worker, token) == :ok
      changed_worker = Repo.get!(Worker, worker.id)
      assert changed_worker.email != worker.email
      assert changed_worker.email == email
      assert changed_worker.confirmed_at
      assert changed_worker.confirmed_at != worker.confirmed_at
      refute Repo.get_by(WorkerToken, worker_id: worker.id)
    end

    test "does not update email with invalid token", %{worker: worker} do
      assert Accounts.update_worker_email(worker, "oops") == :error
      assert Repo.get!(Worker, worker.id).email == worker.email
      assert Repo.get_by(WorkerToken, worker_id: worker.id)
    end

    test "does not update email if worker email changed", %{worker: worker, token: token} do
      assert Accounts.update_worker_email(%{worker | email: "current@example.com"}, token) == :error
      assert Repo.get!(Worker, worker.id).email == worker.email
      assert Repo.get_by(WorkerToken, worker_id: worker.id)
    end

    test "does not update email if token expired", %{worker: worker, token: token} do
      {1, nil} = Repo.update_all(WorkerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_worker_email(worker, token) == :error
      assert Repo.get!(Worker, worker.id).email == worker.email
      assert Repo.get_by(WorkerToken, worker_id: worker.id)
    end
  end

  describe "change_worker_password/2" do
    test "returns a worker changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_worker_password(%Worker{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_worker_password(%Worker{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_worker_password/3" do
    setup do
      %{worker: worker_fixture()}
    end

    test "validates password", %{worker: worker} do
      {:error, changeset} =
        Accounts.update_worker_password(worker, valid_worker_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{worker: worker} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_worker_password(worker, valid_worker_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{worker: worker} do
      {:error, changeset} =
        Accounts.update_worker_password(worker, "invalid", %{password: valid_worker_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{worker: worker} do
      {:ok, worker} =
        Accounts.update_worker_password(worker, valid_worker_password(), %{
          password: "new valid password"
        })

      assert is_nil(worker.password)
      assert Accounts.get_worker_by_email_and_password(worker.email, "new valid password")
    end

    test "deletes all tokens for the given worker", %{worker: worker} do
      _ = Accounts.generate_worker_session_token(worker)

      {:ok, _} =
        Accounts.update_worker_password(worker, valid_worker_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(WorkerToken, worker_id: worker.id)
    end
  end

  describe "generate_worker_session_token/1" do
    setup do
      %{worker: worker_fixture()}
    end

    test "generates a token", %{worker: worker} do
      token = Accounts.generate_worker_session_token(worker)
      assert worker_token = Repo.get_by(WorkerToken, token: token)
      assert worker_token.context == "session"

      # Creating the same token for another worker should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%WorkerToken{
          token: worker_token.token,
          worker_id: worker_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_worker_by_session_token/1" do
    setup do
      worker = worker_fixture()
      token = Accounts.generate_worker_session_token(worker)
      %{worker: worker, token: token}
    end

    test "returns worker by token", %{worker: worker, token: token} do
      assert session_worker = Accounts.get_worker_by_session_token(token)
      assert session_worker.id == worker.id
    end

    test "does not return worker for invalid token" do
      refute Accounts.get_worker_by_session_token("oops")
    end

    test "does not return worker for expired token", %{token: token} do
      {1, nil} = Repo.update_all(WorkerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_worker_by_session_token(token)
    end
  end

  describe "delete_worker_session_token/1" do
    test "deletes the token" do
      worker = worker_fixture()
      token = Accounts.generate_worker_session_token(worker)
      assert Accounts.delete_worker_session_token(token) == :ok
      refute Accounts.get_worker_by_session_token(token)
    end
  end

  describe "deliver_worker_confirmation_instructions/2" do
    setup do
      %{worker: worker_fixture()}
    end

    test "sends token through notification", %{worker: worker} do
      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_confirmation_instructions(worker, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert worker_token = Repo.get_by(WorkerToken, token: :crypto.hash(:sha256, token))
      assert worker_token.worker_id == worker.id
      assert worker_token.sent_to == worker.email
      assert worker_token.context == "confirm"
    end
  end

  describe "confirm_worker/1" do
    setup do
      worker = worker_fixture()

      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_confirmation_instructions(worker, url)
        end)

      %{worker: worker, token: token}
    end

    test "confirms the email with a valid token", %{worker: worker, token: token} do
      assert {:ok, confirmed_worker} = Accounts.confirm_worker(token)
      assert confirmed_worker.confirmed_at
      assert confirmed_worker.confirmed_at != worker.confirmed_at
      assert Repo.get!(Worker, worker.id).confirmed_at
      refute Repo.get_by(WorkerToken, worker_id: worker.id)
    end

    test "does not confirm with invalid token", %{worker: worker} do
      assert Accounts.confirm_worker("oops") == :error
      refute Repo.get!(Worker, worker.id).confirmed_at
      assert Repo.get_by(WorkerToken, worker_id: worker.id)
    end

    test "does not confirm email if token expired", %{worker: worker, token: token} do
      {1, nil} = Repo.update_all(WorkerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_worker(token) == :error
      refute Repo.get!(Worker, worker.id).confirmed_at
      assert Repo.get_by(WorkerToken, worker_id: worker.id)
    end
  end

  describe "deliver_worker_reset_password_instructions/2" do
    setup do
      %{worker: worker_fixture()}
    end

    test "sends token through notification", %{worker: worker} do
      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_reset_password_instructions(worker, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert worker_token = Repo.get_by(WorkerToken, token: :crypto.hash(:sha256, token))
      assert worker_token.worker_id == worker.id
      assert worker_token.sent_to == worker.email
      assert worker_token.context == "reset_password"
    end
  end

  describe "get_worker_by_reset_password_token/1" do
    setup do
      worker = worker_fixture()

      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_reset_password_instructions(worker, url)
        end)

      %{worker: worker, token: token}
    end

    test "returns the worker with valid token", %{worker: %{id: id}, token: token} do
      assert %Worker{id: ^id} = Accounts.get_worker_by_reset_password_token(token)
      assert Repo.get_by(WorkerToken, worker_id: id)
    end

    test "does not return the worker with invalid token", %{worker: worker} do
      refute Accounts.get_worker_by_reset_password_token("oops")
      assert Repo.get_by(WorkerToken, worker_id: worker.id)
    end

    test "does not return the worker if token expired", %{worker: worker, token: token} do
      {1, nil} = Repo.update_all(WorkerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_worker_by_reset_password_token(token)
      assert Repo.get_by(WorkerToken, worker_id: worker.id)
    end
  end

  describe "reset_worker_password/2" do
    setup do
      %{worker: worker_fixture()}
    end

    test "validates password", %{worker: worker} do
      {:error, changeset} =
        Accounts.reset_worker_password(worker, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{worker: worker} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_worker_password(worker, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{worker: worker} do
      {:ok, updated_worker} = Accounts.reset_worker_password(worker, %{password: "new valid password"})
      assert is_nil(updated_worker.password)
      assert Accounts.get_worker_by_email_and_password(worker.email, "new valid password")
    end

    test "deletes all tokens for the given worker", %{worker: worker} do
      _ = Accounts.generate_worker_session_token(worker)
      {:ok, _} = Accounts.reset_worker_password(worker, %{password: "new valid password"})
      refute Repo.get_by(WorkerToken, worker_id: worker.id)
    end
  end

  describe "inspect/2 for the Worker module" do
    test "does not include password" do
      refute inspect(%Worker{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "le pseudo" do

    test "doit être unique" do
      # %Worker{pseudo: "Phil", email: "emaildephil@chez.lui"} |> Repo.insert!()
      attrs = valid_worker_attributes(%{pseudo: "Phil"})
      Worker.registration_changeset(%Worker{}, attrs)
      |> Repo.insert!()
      # Test avec un autre
      changeset = Worker.registration_changeset(%Worker{}, %{pseudo: "Phil"})
      assert {:error, _} = Repo.insert(changeset) # S'assure que l'insert échoue
    end

  end #/describe "le pseudo"
end
