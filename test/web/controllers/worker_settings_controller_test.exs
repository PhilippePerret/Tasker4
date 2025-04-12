defmodule TaskerWeb.WorkerIdentityControllerTest do
  use TaskerWeb.ConnCase, async: true

  alias Tasker.Accounts
  import Tasker.AccountsFixtures

  setup :register_and_log_in_worker

  describe "GET /workers/identity" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~p"/workers/identity")
      response = html_response(conn, 200)
      assert response =~ "Settings"
    end

    test "redirects if worker is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/workers/identity")
      assert redirected_to(conn) == ~p"/workers/log_in"
    end
  end

  describe "PUT /workers/identity (change password form)" do
    test "updates the worker password and resets tokens", %{conn: conn, worker: worker} do
      new_password_conn =
        put(conn, ~p"/workers/identity", %{
          "action" => "update_password",
          "current_password" => valid_worker_password(),
          "worker" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == ~p"/workers/identity"

      assert get_session(new_password_conn, :worker_token) != get_session(conn, :worker_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_worker_by_email_and_password(worker.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, ~p"/workers/identity", %{
          "action" => "update_password",
          "current_password" => "invalid",
          "worker" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "Settings"
      assert response =~ "should be at least 12 character(s)"
      # assert response =~ "doivent faire au moins 12 caractère(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :worker_token) == get_session(conn, :worker_token)
    end
  end

  describe "PUT /workers/identity (change email form)" do
    @tag :capture_log
    test "updates the worker email", %{conn: conn, worker: worker} do
      conn =
        put(conn, ~p"/workers/identity", %{
          "action" => "update_email",
          "current_password" => valid_worker_password(),
          "worker" => %{"email" => unique_worker_email()}
        })

      assert redirected_to(conn) == ~p"/workers/identity"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "A link to confirm your email"

      assert Accounts.get_worker_by_email(worker.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, ~p"/workers/identity", %{
          "action" => "update_email",
          "current_password" => "invalid",
          "worker" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Settings"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /workers/identity/confirm_email/:token" do
    setup %{worker: worker} do
      email = unique_worker_email()

      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_update_email_instructions(%{worker | email: email}, worker.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the worker email once", %{conn: conn, worker: worker, token: token, email: email} do
      conn = get(conn, ~p"/workers/identity/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/workers/identity"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Email changed successfully"

      refute Accounts.get_worker_by_email(worker.email)
      assert Accounts.get_worker_by_email(email)

      conn = get(conn, ~p"/workers/identity/confirm_email/#{token}")

      assert redirected_to(conn) == ~p"/workers/identity"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, worker: worker} do
      conn = get(conn, ~p"/workers/identity/confirm_email/oops")
      assert redirected_to(conn) == ~p"/workers/identity"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"

      assert Accounts.get_worker_by_email(worker.email)
    end

    test "redirects if worker is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, ~p"/workers/identity/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/workers/log_in"
    end
  end
end
