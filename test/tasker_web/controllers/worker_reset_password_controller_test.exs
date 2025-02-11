defmodule TaskerWeb.WorkerResetPasswordControllerTest do
  use TaskerWeb.ConnCase, async: true

  alias Tasker.Accounts
  alias Tasker.Repo
  import Tasker.AccountsFixtures

  setup do
    %{worker: worker_fixture()}
  end

  describe "GET /workers/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, ~p"/workers/reset_password")
      response = html_response(conn, 200)
      assert response =~ "Forgot your password?"
    end
  end

  describe "POST /workers/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, worker: worker} do
      conn =
        post(conn, ~p"/workers/reset_password", %{
          "worker" => %{"email" => worker.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.WorkerToken, worker_id: worker.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/workers/reset_password", %{
          "worker" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.WorkerToken) == []
    end
  end

  describe "GET /workers/reset_password/:token" do
    setup %{worker: worker} do
      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_reset_password_instructions(worker, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, ~p"/workers/reset_password/#{token}")
      assert html_response(conn, 200) =~ "Reset password"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, ~p"/workers/reset_password/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /workers/reset_password/:token" do
    setup %{worker: worker} do
      token =
        extract_worker_token(fn url ->
          Accounts.deliver_worker_reset_password_instructions(worker, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, worker: worker, token: token} do
      conn =
        put(conn, ~p"/workers/reset_password/#{token}", %{
          "worker" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == ~p"/workers/log_in"
      refute get_session(conn, :worker_token)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Password reset successfully"

      assert Accounts.get_worker_by_email_and_password(worker.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, ~p"/workers/reset_password/#{token}", %{
          "worker" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert html_response(conn, 200) =~ "something went wrong"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, ~p"/workers/reset_password/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Reset password link is invalid or it has expired"
    end
  end
end
