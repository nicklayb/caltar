defmodule CaltarWeb.PubSub do
  import Phoenix.Component

  def subscribe(%Phoenix.LiveView.Socket{} = socket, topics_or_topic) do
    Caltar.PubSub.subscribe(topics_or_topic)
    update_topics(socket, topics_or_topic)
  end

  defp update_topics(%Phoenix.LiveView.Socket{} = socket, topics_or_topic) do
    topics =
      topics_or_topic
      |> List.wrap()
      |> MapSet.new()

    socket
    |> assign_new(:__topics__, fn -> MapSet.new() end)
    |> update(:__topics__, &MapSet.union(&1, topics))
  end
end
