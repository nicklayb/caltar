defmodule Caltar.BaseCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Caltar.Factory
    end
  end
end
