defmodule Caltar do
  def schema(options) do
    quote do
      use Ecto.Schema
      require Ecto.Query

      @type t :: %__MODULE__{}

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id

      defp __options__, do: unquote(options)

      if unquote(Keyword.get(options, :persisted, true)) do
        def from(base_query \\ __MODULE__) do
          Ecto.Query.from(base_query, as: ^__named_binding__())
        end

        defp __named_binding__, do: Keyword.fetch!(__options__(), :name)
      end
    end
  end

  defmacro __using__(type) do
    case type do
      {type, options} ->
        apply(__MODULE__, type, [options])

      type ->
        apply(__MODULE__, type, [])
    end
  end
end
