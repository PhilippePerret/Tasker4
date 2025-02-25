defmodule TaskerWeb.WorkerConfirmationControllerTest do
  use TaskerWeb.ConnCase, async: true

  alias Tasker.Accounts
  alias Tasker.Repo
  import Tasker.AccountsFixtures

  setup do
    %{worker: worker_fixture()}
  end

  describe "GET /workers/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, ~p"/workers/confirm")
      response = html_response(conn, 200)
      assert response =~ "Resend confirmation instructions"
    end
  end

  describe "POST /workers/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, worker: worker} do
      conn =
        post(conn, ~p"/workers/confirm", %{
          "worker" => %{"email" => worker.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.WorkerToken, worker_id: worker.id).context == "confirm"
    end

    test "does not send confirmation token if Worker is confirmed", %{conn: conn, worker: worker} do
      Repo.update!(Accounts.Worker.confirm_changeset(worker))

      conn =
        post(conn, ~p"/workers/confirm", %{
          "worker" => %{"email" => worker.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Accounts.WorkerToken, worker_id: worker.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/workers/confirm", %{
          "worker" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.WorkerToken) == []
    end
  end

  describe "GET /workers/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      token_path = ~p"/workers/confirm/some-token"
      conn = get(conn, token_path)
      response = html_response(conn, 200)
      assert response =~ "Confirm account"

      assert response =~ "action=\"#{token_path}\""
    end
  end

  describe "POST /workers/confirm/:token" do
    test "confirms the given token once", %{conn: conn, worker: worker} do
      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_confirmation_instructions(worker, url)
        end)

      conn = post(conn, ~p"/workers/confirm/#{token}")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Worker confirmed successfully"

      assert Accounts.get_worker!(worker.id).confirmed_at
      refute get_session(conn, :worker_token)
      assert Repo.all(Accounts.WorkerToken) == []

      # When not logged in
      conn = post(conn, ~p"/workers/confirm/#{token}")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Worker confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_worker(worker)
        |> post(~p"/workers/confirm/#{token}")

      assert redirected_to(conn) == ~p"/"
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, worker: worker} do
      conn = post(conn, ~p"/workers/confirm/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Worker confirmation link is invalid or it has expired"

      refute Accounts.get_worker!(worker.id).confirmed_at
    end
  end
end
