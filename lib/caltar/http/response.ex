defmodule Caltar.Http.Response do
  alias Caltar.Http.Response, as: HttpResponse
  defstruct [:status, :headers, :body]

  def new(%Req.Response{} = response) do
    %HttpResponse{
      status: response.status,
      headers: response.headers,
      body: response.body
    }
  end
end
