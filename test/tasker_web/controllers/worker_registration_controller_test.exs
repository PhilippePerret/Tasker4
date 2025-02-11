defmodule TaskerWeb.WorkerRegistrationControllerTest do
  use TaskerWeb.ConnCase, async: true

  import Tasker.AccountsFixtures

  describe "GET /workers/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, ~p"/workers/register")
      response = html_response(conn, 200)
      assert response =~ "Register"
      assert response =~ ~p"/workers/log_in"
      assert response =~ ~p"/workers/register"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_worker(worker_fixture()) |> get(~p"/workers/register")

      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "POST /workers/register" do
    @tag :capture_log
    test "creates account and logs the worker in", %{conn: conn} do
      email = unique_worker_email()

      conn =
        post(conn, ~p"/workers/register", %{
          "worker" => valid_worker_attributes(email: email)
        })

      assert get_session(conn, :worker_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ ~p"/workers/settings"
      assert response =~ ~p"/workers/log_out"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, ~p"/workers/register", %{
          "worker" => %{"email" => "with spaces", "password" => "too short"}
        })

      response = html_response(conn, 200)
      assert response =~ "Register"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
    end
  end
end
