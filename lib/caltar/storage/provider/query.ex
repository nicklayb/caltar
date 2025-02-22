defmodule Caltar.Storage.Provider.Query do
  alias Caltar.Storage.Provider
  require Ecto.Query

  def from(base_query \\ Provider.from()) do
    base_query
  end

  def by_id(query \\ from(), id) do
    Ecto.Query.where(query, [provider: provider], provider.id == ^id)
  end
end
