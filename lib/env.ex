defmodule Env do
  require Config

  def int(key, options \\ []) do
    key
    |> get_env(options)
    |> mutate(&String.to_integer/1)
  end

  def uri(key, options \\ []) do
    key
    |> get_env(options)
    |> mutate(&URI.parse/1)
  end

  def bool(key, options \\ []) do
    key
    |> get_env(options)
    |> mutate(&to_bool/1)
  end

  def get(key, options \\ []) do
    key
    |> get_env(options)
    |> mutate(&Function.identity/1)
  end

  defp to_bool("true"), do: true
  defp to_bool("false"), do: false

  defp mutate({:hardcoded, value}, _function), do: value
  defp mutate(value, function), do: function.(value)

  defp get_env(key, options) do
    case value_spec(options) do
      :required -> System.fetch_env!(key)
      {:default, default} -> System.get_env(key, default)
      :optional -> System.get_env(key)
      {:hardcoded, value} -> {:hardcoded, value}
    end
  end

  defp value_spec(options) do
    current_env = current_env(options)

    case Keyword.fetch(options, current_env) do
      :error -> default_or_required(options)
      {:ok, value} -> {:hardcoded, value}
    end
  end

  defp default_or_required(options) do
    case {Keyword.get(options, :required), Keyword.get(options, :default)} do
      {true, nil} ->
        :required

      {nil, value} when is_binary(value) ->
        {:default, value}

      {nil, nil} ->
        :optional

      {nil, non_string_value} ->
        raise """
        Expected a string default value to be converted if needed, got: #{inspect(non_string_value)}
        """

      {required, default} ->
        raise """
        Expected either `required: true` or `default: "string"`, got: required: #{inspect(required)} and default: #{inspect(default)}
        """
    end
  end

  defp current_env(options) do
    Config.config_env()
  rescue
    RuntimeError ->
      app = Keyword.get(options, :app, :caltar)
      Application.fetch_env!(app, :environment)
  end
end
