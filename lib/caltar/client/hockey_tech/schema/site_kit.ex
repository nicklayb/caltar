defmodule Caltar.Client.HockeyTech.Schema.SiteKit do
  alias Caltar.Client.HockeyTech.Schema.SiteKit

  defstruct [:parameters, :body]

  def decoder do
    SiteKit
    |> Starchoice.Decoder.new()
    |> Starchoice.Decoder.put_field(:parameters, source: "Parameters")
  end

  def decoder(source, inner_decoder) do
    Starchoice.Decoder.put_field(decoder(), :body, source: source, with: inner_decoder)
  end
end
