defmodule TaskerWeb.OneTaskCycleHTML do
  use TaskerWeb, :html

  # alias Tasker.Helper, as: H

  embed_templates "one_task_cycle_html/*"

  # Juste pour éviter l'erreur de formatage VSCode
  slot :inner_block, required: true
  def js_constants(assigns) do
    ~H"""
    <script type="text/javascript">
      <%= render_slot(@inner_block) %>
    </script>
    """
  end
end