defmodule TaskerWeb.TaskSpecControllerTest do
  use TaskerWeb.ConnCase

  import Tasker.TacheFixtures

  @create_attrs %{details: "some details"}
  @update_attrs %{details: "some updated details"}
  @invalid_attrs %{details: nil}

  describe "index" do
    test "lists all task_specs", %{conn: conn} do
      conn = get(conn, ~p"/task_specs")
      assert html_response(conn, 200) =~ "Listing Task specs"
    end
  end

  describe "new task_spec" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/task_specs/new")
      assert html_response(conn, 200) =~ "New Task spec"
    end
  end

  describe "create task_spec" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/task_specs", task_spec: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/task_specs/#{id}"

      conn = get(conn, ~p"/task_specs/#{id}")
      assert html_response(conn, 200) =~ "Task spec #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/task_specs", task_spec: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Task spec"
    end
  end

  describe "edit task_spec" do
    setup [:create_task_spec]

    test "renders form for editing chosen task_spec", %{conn: conn, task_spec: task_spec} do
      conn = get(conn, ~p"/task_specs/#{task_spec}/edit")
      assert html_response(conn, 200) =~ "Edit Task spec"
    end
  end

  describe "update task_spec" do
    setup [:create_task_spec]

    test "redirects when data is valid", %{conn: conn, task_spec: task_spec} do
      conn = put(conn, ~p"/task_specs/#{task_spec}", task_spec: @update_attrs)
      assert redirected_to(conn) == ~p"/task_specs/#{task_spec}"

      conn = get(conn, ~p"/task_specs/#{task_spec}")
      assert html_response(conn, 200) =~ "some updated details"
    end

    test "renders errors when data is invalid", %{conn: conn, task_spec: task_spec} do
      conn = put(conn, ~p"/task_specs/#{task_spec}", task_spec: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Task spec"
    end
  end

  describe "delete task_spec" do
    setup [:create_task_spec]

    test "deletes chosen task_spec", %{conn: conn, task_spec: task_spec} do
      conn = delete(conn, ~p"/task_specs/#{task_spec}")
      assert redirected_to(conn) == ~p"/task_specs"

      assert_error_sent 404, fn ->
        get(conn, ~p"/task_specs/#{task_spec}")
      end
    end
  end

  defp create_task_spec(_) do
    task_spec = task_spec_fixture()
    %{task_spec: task_spec}
  end
end
