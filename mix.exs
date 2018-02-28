defmodule Middlewex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :middlewex,
      version: "0.4.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      name: "Middlewex",
      source_url: "https://github.com/Financial-Times/middlewex",
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  # Run "mix docs" to generate documentation.
  defp deps do
    [
      {:plug, "~> 1.4"},
      {:prometheus_ex, "~> 1.1", optional: true},
      {:poison, "~> 3.1", optional: true},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:benchee, "~> 0.1", only: [:dev, :bench]}
    ]
  end

  def package do
    [
      maintainers: ["Ellis Pritchard"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/Financial-Times/middlewex"} ]
  end

  defp description do
    """
    Essential Middleware Plugs for FT Elixir web apps.
    """
  end

  def docs do
    [main: "readme",
     extras: ["README.md"]]
  end

end
