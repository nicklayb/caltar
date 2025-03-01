defmodule Caltar.Http.Error do
  alias Caltar.Http.Error

  defstruct [:error]

  def new(error) do
    %Error{error: error}
  end
end
