defmodule Middlewex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :middlewex,
      version: "0.5.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
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
      {:plug, "~> 1.11"},
      {:prometheus_ex, "~> 3.0.5", optional: true},
      {:poison, "~> 4.0", optional: true},
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:benchee, "~> 1.0", only: [:dev, :bench]}
    ]
  end

  def package do
    [
      maintainers: ["Ellis Pritchard"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/Financial-Times/middlewex"}
    ]
  end

  defp description do
    """
    Essential Middleware Plugs for FT Elixir web apps.
    """
  end

  def docs do
    [main: "readme", extras: ["README.md"]]
  end
end
