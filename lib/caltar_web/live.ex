defmodule CaltarWeb.Live do
  alias Phoenix.LiveView.AsyncResult

  def update_async_result(socket, key, function) do
    Phoenix.Component.update(socket, key, &%AsyncResult{&1 | result: function.(&1.result)})
  end

  def execute_use_case(_socket, use_case, params, options \\ []) do
    Caltar.UseCase.execute(use_case, params, options)
  end
end
