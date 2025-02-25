defmodule TaskerWeb.WorkerAuthTest do
  use TaskerWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Tasker.Accounts
  alias TaskerWeb.WorkerAuth
  import Tasker.AccountsFixtures

  @remember_me_cookie "_tasker_web_worker_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, TaskerWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{worker: worker_fixture(), conn: conn}
  end

  describe "log_in_worker/3" do
    test "stores the worker token in the session", %{conn: conn, worker: worker} do
      conn = WorkerAuth.log_in_worker(conn, worker)
      assert token = get_session(conn, :worker_token)
      assert get_session(conn, :live_socket_id) == "workers_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_worker_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, worker: worker} do
      conn = conn |> put_session(:to_be_removed, "value") |> WorkerAuth.log_in_worker(worker)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, worker: worker} do
      conn = conn |> put_session(:worker_return_to, "/hello") |> WorkerAuth.log_in_worker(worker)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, worker: worker} do
      conn = conn |> fetch_cookies() |> WorkerAuth.log_in_worker(worker, %{"remember_me" => "true"})
      assert get_session(conn, :worker_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :worker_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_worker/1" do
    test "erases session and cookies", %{conn: conn, worker: worker} do
      worker_token = Accounts.generate_worker_session_token(worker)

      conn =
        conn
        |> put_session(:worker_token, worker_token)
        |> put_req_cookie(@remember_me_cookie, worker_token)
        |> fetch_cookies()
        |> WorkerAuth.log_out_worker()

      refute get_session(conn, :worker_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_worker_by_session_token(worker_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "workers_sessions:abcdef-token"
      TaskerWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> WorkerAuth.log_out_worker()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if worker is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> WorkerAuth.log_out_worker()
      refute get_session(conn, :worker_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_worker/2" do
    test "authenticates worker from session", %{conn: conn, worker: worker} do
      worker_token = Accounts.generate_worker_session_token(worker)
      conn = conn |> put_session(:worker_token, worker_token) |> WorkerAuth.fetch_current_worker([])
      assert conn.assigns.current_worker.id == worker.id
    end

    test "authenticates worker from cookies", %{conn: conn, worker: worker} do
      logged_in_conn =
        conn |> fetch_cookies() |> WorkerAuth.log_in_worker(worker, %{"remember_me" => "true"})

      worker_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> WorkerAuth.fetch_current_worker([])

      assert conn.assigns.current_worker.id == worker.id
      assert get_session(conn, :worker_token) == worker_token

      assert get_session(conn, :live_socket_id) ==
               "workers_sessions:#{Base.url_encode64(worker_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, worker: worker} do
      _ = Accounts.generate_worker_session_token(worker)
      conn = WorkerAuth.fetch_current_worker(conn, [])
      refute get_session(conn, :worker_token)
      refute conn.assigns.current_worker
    end
  end

  describe "on_mount :mount_current_worker" do
    test "assigns current_worker based on a valid worker_token", %{conn: conn, worker: worker} do
      worker_token = Accounts.generate_worker_session_token(worker)
      session = conn |> put_session(:worker_token, worker_token) |> get_session()

      {:cont, updated_socket} =
        WorkerAuth.on_mount(:mount_current_worker, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_worker.id == worker.id
    end

    test "assigns nil to current_worker assign if there isn't a valid worker_token", %{conn: conn} do
      worker_token = "invalid_token"
      session = conn |> put_session(:worker_token, worker_token) |> get_session()

      {:cont, updated_socket} =
        WorkerAuth.on_mount(:mount_current_worker, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_worker == nil
    end

    test "assigns nil to current_worker assign if there isn't a worker_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        WorkerAuth.on_mount(:mount_current_worker, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_worker == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_worker based on a valid worker_token", %{conn: conn, worker: worker} do
      worker_token = Accounts.generate_worker_session_token(worker)
      session = conn |> put_session(:worker_token, worker_token) |> get_session()

      {:cont, updated_socket} =
        WorkerAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_worker.id == worker.id
    end

    test "redirects to login page if there isn't a valid worker_token", %{conn: conn} do
      worker_token = "invalid_token"
      session = conn |> put_session(:worker_token, worker_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: TaskerWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = WorkerAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_worker == nil
    end

    test "redirects to login page if there isn't a worker_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: TaskerWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = WorkerAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_worker == nil
    end
  end

  describe "on_mount :redirect_if_worker_is_authenticated" do
    test "redirects if there is an authenticated  worker ", %{conn: conn, worker: worker} do
      worker_token = Accounts.generate_worker_session_token(worker)
      session = conn |> put_session(:worker_token, worker_token) |> get_session()

      assert {:halt, _updated_socket} =
               WorkerAuth.on_mount(
                 :redirect_if_worker_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated worker", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               WorkerAuth.on_mount(
                 :redirect_if_worker_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_worker_is_authenticated/2" do
    test "redirects if worker is authenticated", %{conn: conn, worker: worker} do
      conn = conn |> assign(:current_worker, worker) |> WorkerAuth.redirect_if_worker_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if worker is not authenticated", %{conn: conn} do
      conn = WorkerAuth.redirect_if_worker_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_worker/2" do
    test "redirects if worker is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> WorkerAuth.require_authenticated_worker([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/workers/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> WorkerAuth.require_authenticated_worker([])

      assert halted_conn.halted
      assert get_session(halted_conn, :worker_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> WorkerAuth.require_authenticated_worker([])

      assert halted_conn.halted
      assert get_session(halted_conn, :worker_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> WorkerAuth.require_authenticated_worker([])

      assert halted_conn.halted
      refute get_session(halted_conn, :worker_return_to)
    end

    test "does not redirect if worker is authenticated", %{conn: conn, worker: worker} do
      conn = conn |> assign(:current_worker, worker) |> WorkerAuth.require_authenticated_worker([])
      refute conn.halted
      refute conn.status
    end
  end
end
