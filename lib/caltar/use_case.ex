defmodule Caltar.UseCase do
  def execute!(module, params, options) do
    Box.UseCase.execute!(module, params, with_default_options(options))
  end

  def execute(module, params, options) do
    Box.UseCase.execute(module, params, with_default_options(options))
  end

  defp with_default_options(options) do
    Keyword.put(options, :run, &Caltar.Repo.transaction/2)
  end
end
