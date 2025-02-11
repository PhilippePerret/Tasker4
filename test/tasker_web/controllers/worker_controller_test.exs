defmodule TaskerWeb.WorkerControllerTest do
  use TaskerWeb.ConnCase

  import Tasker.AccountsFixtures

  @create_attrs %{password: "some password", pseudo: "some pseudo", email: "some email"}
  @update_attrs %{password: "some updated password", pseudo: "some updated pseudo", email: "some updated email"}
  @invalid_attrs %{password: nil, pseudo: nil, email: nil}

  describe "index" do
    test "lists all workers", %{conn: conn} do
      conn = get(conn, ~p"/workers")
      assert html_response(conn, 200) =~ "Listing Workers"
    end
  end

  describe "new worker" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/workers/new")
      assert html_response(conn, 200) =~ "New Worker"
    end
  end

  describe "create worker" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/workers", worker: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/workers/#{id}"

      conn = get(conn, ~p"/workers/#{id}")
      assert html_response(conn, 200) =~ "Worker #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/workers", worker: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Worker"
    end
  end

  describe "edit worker" do
    setup [:create_worker]

    test "renders form for editing chosen worker", %{conn: conn, worker: worker} do
      conn = get(conn, ~p"/workers/#{worker}/edit")
      assert html_response(conn, 200) =~ "Edit Worker"
    end
  end

  describe "update worker" do
    setup [:create_worker]

    test "redirects when data is valid", %{conn: conn, worker: worker} do
      conn = put(conn, ~p"/workers/#{worker}", worker: @update_attrs)
      assert redirected_to(conn) == ~p"/workers/#{worker}"

      conn = get(conn, ~p"/workers/#{worker}")
      assert html_response(conn, 200) =~ "Email"
    end

    test "renders errors when data is invalid", %{conn: conn, worker: worker} do
      conn = put(conn, ~p"/workers/#{worker}", worker: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Worker"
    end
  end

  describe "delete worker" do
    setup [:create_worker]

    test "deletes chosen worker", %{conn: conn, worker: worker} do
      conn = delete(conn, ~p"/workers/#{worker}")
      assert redirected_to(conn) == ~p"/workers"

      assert_error_sent 404, fn ->
        get(conn, ~p"/workers/#{worker}")
      end
    end
  end

  defp create_worker(_) do
    worker = worker_fixture()
    %{worker: worker}
  end
end
