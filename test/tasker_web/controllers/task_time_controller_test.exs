defmodule TaskerWeb.TaskTimeControllerTest do
  use TaskerWeb.ConnCase

  import Tasker.TacheFixtures

  @create_attrs %{priority: 42, started_at: ~N[2025-02-12 16:25:00], should_start_at: ~N[2025-02-12 16:25:00], should_end_at: ~N[2025-02-12 16:25:00], ended_at: ~N[2025-02-12 16:25:00], given_up_at: ~N[2025-02-12 16:25:00], urgence: 42, recurrence: "some recurrence", expect_duration: 42, execution_time: 42}
  @update_attrs %{priority: 43, started_at: ~N[2025-02-13 16:25:00], should_start_at: ~N[2025-02-13 16:25:00], should_end_at: ~N[2025-02-13 16:25:00], ended_at: ~N[2025-02-13 16:25:00], given_up_at: ~N[2025-02-13 16:25:00], urgence: 43, recurrence: "some updated recurrence", expect_duration: 43, execution_time: 43}
  @invalid_attrs %{priority: nil, started_at: nil, should_start_at: nil, should_end_at: nil, ended_at: nil, given_up_at: nil, urgence: nil, recurrence: nil, expect_duration: nil, execution_time: nil}

  describe "index" do
    test "lists all task_times", %{conn: conn} do
      conn = get(conn, ~p"/task_times")
      assert html_response(conn, 200) =~ "Listing Task times"
    end
  end

  describe "new task_time" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/task_times/new")
      assert html_response(conn, 200) =~ "New Task time"
    end
  end

  describe "create task_time" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/task_times", task_time: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/task_times/#{id}"

      conn = get(conn, ~p"/task_times/#{id}")
      assert html_response(conn, 200) =~ "Task time #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/task_times", task_time: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Task time"
    end
  end

  describe "edit task_time" do
    setup [:create_task_time]

    test "renders form for editing chosen task_time", %{conn: conn, task_time: task_time} do
      conn = get(conn, ~p"/task_times/#{task_time}/edit")
      assert html_response(conn, 200) =~ "Edit Task time"
    end
  end

  describe "update task_time" do
    setup [:create_task_time]

    test "redirects when data is valid", %{conn: conn, task_time: task_time} do
      conn = put(conn, ~p"/task_times/#{task_time}", task_time: @update_attrs)
      assert redirected_to(conn) == ~p"/task_times/#{task_time}"

      conn = get(conn, ~p"/task_times/#{task_time}")
      assert html_response(conn, 200) =~ "some updated recurrence"
    end

    test "renders errors when data is invalid", %{conn: conn, task_time: task_time} do
      conn = put(conn, ~p"/task_times/#{task_time}", task_time: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Task time"
    end
  end

  describe "delete task_time" do
    setup [:create_task_time]

    test "deletes chosen task_time", %{conn: conn, task_time: task_time} do
      conn = delete(conn, ~p"/task_times/#{task_time}")
      assert redirected_to(conn) == ~p"/task_times"

      assert_error_sent 404, fn ->
        get(conn, ~p"/task_times/#{task_time}")
      end
    end
  end

  defp create_task_time(_) do
    task_time = task_time_fixture()
    %{task_time: task_time}
  end
end
