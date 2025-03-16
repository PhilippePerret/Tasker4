defmodule Tasker.TaskScript do
  @moduledoc """
  Module pour gérer les scripts.

  NB : ils sont tous définis, au niveau des données dans le
  module JavaScript scripts_data.js

  """

  @doc """
  Fonction publique principale recevant l'appel pour jouer le script
  donné en argument.

  @return %{ok: false/true, error: l'erreur/nil}

  @public
  """

  use TaskerWeb, :controller

  alias Tasker.Tache.{Task}
  alias Tasker.Projet.Project


  def run(%Task{} = task, data_script) do
    run_script(data_script["type"], task, data_script["argument"])
  end

  def run_script("worker-script", _task, argument) do
    params = String.split(argument, " ")
    {cmd, params} = List.pop_at(params, 0)
    # En fonction de l'extension du fichier (si c'est un fichier) il 
    # faut invoquer le langage
    [cmd, params ]= case Path.extname(cmd) do
      ""    -> cmd
      "rb"  -> ["ruby",     [cmd] ++ params]
      "ex"  -> ["elixir",   [cmd] ++ params]
      "exs" -> ["elixir",   [cmd] ++ params]
      "py"  -> ["python3",  [cmd] ++ params]
      _ -> cmd
    end
    case System.cmd(cmd, params) do
      {stdout, 0} -> %{ok: true, return: stdout}
      {stdout, exit_code} -> %{ok: false, error: "ERR CODE #{exit_code} (#{stdout})"}
    end
  end

  def run_script("open-folder", task, foopath) do
    case define_full_path(task, foopath) do
      {:error, err} -> %{ok: false, error: "#{err} #{dgettext("tasker", "Can’t open folder.")}"}
      {:ok, fullpath} -> 
        case System.cmd("open", ["-a Finder", fullpath]) do
          {stdout, 0} -> %{ok: true, return: stdout}
          {stdout, _} -> %{ok: false, error: stdout}
        end
    end
  end

  def run_script("open-file", task, foopath) do
    run_script("open-folder", task, foopath)
  end

  def run_script("new-main-version", task, foopath) do
    change_version(foopath, task, 0)
  end
  def run_script("new-minor-version", task, foopath) do
    change_version(foopath, task, 1)
  end
  def run_script("new-patch-version", task, foopath) do
    change_version(foopath, task, 2)
  end

  @reg_version ~r/^(?<debut>.+)(?<main>[0-9]+)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)(?<fin>.+)$/
  defp change_version(foopath, task, index_number) do
    case define_full_path(task, foopath) do
      {:error, err} -> %{ok: false, error: "#{err} #{dgettext("tasker", "Can’t change version.")}"}
      {:ok, src} -> 
        src_name    = Path.basename(src)
        src_folder  = Path.dirname(src)
        mapd = Regex.named_captures(@reg_version, src_name)
        case mapd do
        nil -> %{ok: false, error: dgettext("tasker", "Note a versioned file")}
        _ -> 
          main  = index_number == 0 && (String.to_integer(mapd["main"]) + 1) || mapd["main"]
          minor = index_number == 1 && (String.to_integer(mapd["minor"]) + 1) || mapd["minor"]
          patch = index_number == 2 && (String.to_integer(mapd["patch"]) + 1) || mapd["patch"]
          dest_name = ~s(#{mapd["debut"]}#{main}.#{minor}.#{patch}#{mapd["fin"]})
          dest = Path.join([src_folder, dest_name])
          archive_folder  = Path.join([src_folder, "xbackups"])
          File.exists?(archive_folder) || File.mkdir_p!(archive_folder)
          backup = Path.join([archive_folder, src_name])
          File.copy!(src, backup)
          File.rename!(src, dest)
          %{ok: true, versionUp: %{src: src, new_version: dest, backup: backup}}
        end
    end
  end



  defp define_full_path(task, foopath) do
    is_absolute = String.starts_with?(foopath, "/")
    _is_relative = !is_absolute

    fullpath = if is_absolute, do: foopath, else: path_in_project(task, foopath)

    cond do
      fullpath && File.exists?(fullpath) -> {:ok, fullpath}
      is_nil(task.project.folder) -> {:error, dgettext("tasker", "Project folder not defined.")}
      !File.exists?(task.project.folder) -> {:error, dgettext("tasker", "Project folder not found.")}
      !File.exists?(fullpath) ->
        if is_absolute do
          {:error, dgettext("tasker", "The path element '%{fullpath}' could not be found.", fullpath: fullpath)}
        else 
          {:error, dgettext("tasker", "Unable to find the path element '%{fullpath}' in the project.", fullpath: fullpath)}
        end
    end
  end

  defp path_in_project(%Task{} = task, foopath) do
    path_in_project(task.project, foopath)
  end
  defp path_in_project(%Project{} = project, foopath) do
    if is_nil(project.folder) do
      nil
    else
      Path.absname(Path.join([project.folder, foopath]))
    end
  end

end