defmodule Caltar.Http do
  defmacro __using__(options) do
    functions =
      for method <- ~w(get post put patch delete head)a do
        quote do
          def unquote(method)(url, options \\ []) do
            request([method: unquote(method), url: url], options)
          end
        end
      end

    request =
      quote do
        alias Caltar.Http.Error, as: HttpError
        alias Caltar.Http.Response, as: HttpResponse

        @handle_non_200 Keyword.get(unquote(options), :non_200, :error)

        def request(input_options, other_options \\ []) do
          input_options
          |> build_request(other_options)
          |> Req.request()
          |> Caltar.Http.map_response(non_200: @handle_non_200)
        end

        def run(input_options, other_options \\ []) do
          input_options
          |> build_request(other_options)
          |> Req.run()
          |> then(fn {request, response} -> {request, Caltar.Http.map_response(response)} end)
        end

        defp build_request(input, other_options) do
          input
          |> Req.new()
          |> Req.merge(other_options)
          |> Req.merge(options())
          |> Req.merge(local_config())
        end

        defp options, do: unquote(options)

        def local_config do
          :caltar
          |> Application.get_env(__MODULE__, [])
          |> Keyword.get(:http, [])
        end
      end

    [request | functions]
  end

  defguard is_success(status) when status in 200..299

  def map_response({:ok, %Req.Response{status: status} = response}, _options)
      when is_success(status) do
    {:ok, map_response(response)}
  end

  def map_response({:ok, %Req.Response{} = response}, options) do
    response = map_response(response)

    case Keyword.get(options, :non_200) do
      :ok -> {:ok, response}
      :error -> {:error, response}
    end
  end

  def map_response({:error, error}, _) do
    {:error, Caltar.Http.Error.new(error)}
  end

  def map_response(response), do: Caltar.Http.Response.new(response)
end
