defmodule TaskerWeb.WorkerSessionControllerTest do
  use TaskerWeb.ConnCase, async: true

  import Tasker.AccountsFixtures

  setup do
    %{worker: worker_fixture()}
  end

  describe "GET /workers/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, ~p"/workers/log_in")
      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ ~p"/workers/register"
      assert response =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn, worker: worker} do
      conn = conn |> log_in_worker(worker) |> get(~p"/workers/log_in")
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "POST /workers/log_in" do
    test "logs the worker in", %{conn: conn, worker: worker} do
      conn =
        post(conn, ~p"/workers/log_in", %{
          "worker" => %{"email" => worker.email, "password" => valid_worker_password()}
        })

      assert get_session(conn, :worker_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ worker.email
      assert response =~ ~p"/workers/settings"
      assert response =~ ~p"/workers/log_out"
    end

    test "logs the worker in with remember me", %{conn: conn, worker: worker} do
      conn =
        post(conn, ~p"/workers/log_in", %{
          "worker" => %{
            "email" => worker.email,
            "password" => valid_worker_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_tasker_web_worker_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the worker in with return to", %{conn: conn, worker: worker} do
      conn =
        conn
        |> init_test_session(worker_return_to: "/foo/bar")
        |> post(~p"/workers/log_in", %{
          "worker" => %{
            "email" => worker.email,
            "password" => valid_worker_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "emits error message with invalid credentials", %{conn: conn, worker: worker} do
      conn =
        post(conn, ~p"/workers/log_in", %{
          "worker" => %{"email" => worker.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /workers/log_out" do
    test "logs the worker out", %{conn: conn, worker: worker} do
      conn = conn |> log_in_worker(worker) |> delete(~p"/workers/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :worker_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

  end
end
