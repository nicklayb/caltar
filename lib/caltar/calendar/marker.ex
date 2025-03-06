defmodule Caltar.Calendar.Marker do
  alias Caltar.Calendar.Marker

  defstruct [
    :id,
    :source,
    :icon,
    :date,
    :provider
  ]

  @type t :: %Marker{}
end
