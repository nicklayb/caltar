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
        alias Caltar.Http.Response, as: HttpResponse
        alias Caltar.Http.Error, as: HttpError

        def request(input_options, other_options \\ []) do
          input_options
          |> Req.new()
          |> Req.merge(other_options)
          |> Req.merge(options())
          |> Req.merge(local_config())
          |> Req.request()
          |> Caltar.Http.map_response()
        end

        defp options, do: unquote(options)

        defp local_config do
          :caltar
          |> Application.get_env(__MODULE__, [])
          |> Keyword.get(:http, [])
        end
      end

    [request | functions]
  end

  def map_response({:ok, response}) do
    {:ok, Caltar.Http.Response.new(response)}
  end

  def map_error({:error, error}) do
    {:error, Caltar.Http.Error.new(error)}
  end
end
