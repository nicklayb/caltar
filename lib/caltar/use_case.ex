defmodule Caltar.UseCase do
  @type use_case :: module()
  @type params :: any()
  @type options :: Keyword.t()

  @spec execute!(use_case(), params(), options()) :: any()
  def execute!(module, params, options \\ []) do
    Box.UseCase.execute!(module, params, with_default_options(options))
  end

  @spec execute(use_case(), params(), options()) :: any()
  def execute(module, params, options \\ []) do
    Box.UseCase.execute(module, params, with_default_options(options))
  end

  defp with_default_options(options) do
    Keyword.put(options, :run, &Caltar.Repo.transaction/2)
  end
end
