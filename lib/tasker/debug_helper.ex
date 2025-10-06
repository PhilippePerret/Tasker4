defmodule Tasker.DebugHelper do
  def logme(message) do
    File.write("/Users/philippeperret/xlogs/debug_onceuponatask.log", "#{message}\n", [:append])
  end
end