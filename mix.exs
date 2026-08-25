defmodule SkyLoyalty.MixProject do
  use Mix.Project

  def project do
    [
      app: :sky_loyalty,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: SkyLoyalty.CLI],
      deps: []
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto]]
  end
end
