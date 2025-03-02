defmodule Caltar.Calendar.Marker do
  defstruct [
    :id,
    :source,
    :icon,
    :date,
    :provider
  ]

  alias Caltar.Calendar.Marker

  @type t :: %Marker{}
end
