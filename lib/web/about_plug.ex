defmodule FT.Web.AboutPlug do
  @moduledoc """
  Plug to serve `/__about` endpoint from config.

  This Plug implements the [About endpoint proposal](https://github.com/Financial-Times/middlewex/About-runbook+standard.pdf)
  (Betts 2016).

  Looks for configuration under the `:about` key of the configured `otp_app`:

  ```
  config :my_app, :about,
    system_code: "system-code",
    app_version: "1.1.2", # use sem-ver
    name: "name", # default: system_code
    description: "description", # default: name
    purpose: "purpose", # default: description
    service_tier: :gold # default: :bronze
    contacts: [
      %{name: "...", email: "...", slack: "#...", rel: :owner, domain: :technical},
    ],
    links: [
      %{url: "...", category: :repo, description: "..."},
    ]

  ```

  then in your router/pipeline:

  ```
  plug FT.Web.AboutPlug, otp_app: :my_app
  ```

  The plug will only be executed when `conn.path_info` is `["__about"]`, returning
  a `200` status code and a JSON body; execution halts the plug pipeline.
  """

  import Plug.Conn

  @behaviour Plug

  @app_version Mix.Project.config()[:version]

  @doc """
  Plug init function: requires `opt_app` option, which should specify source app of `:about` config.

  NB `init/1` is called at COMPILE time when used in a Phoenix Router, so config cannot use
  run-time resolved values.
  """
  @impl true
  @spec init(otp_app: atom) :: %{optional(atom) => String.t() | atom | integer | list}
  def init(opts) do
    otp_app = opts[:otp_app] || arg_error!("otp_app argument is required")

    config =
      Application.get_env(otp_app, :about) ||
        arg_error!(":about key required in #{otp_app} configuration")

    about(config)
  end

  @doc false
  @impl true
  def call(%Plug.Conn{path_info: ["__about"]} = conn, about) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode_to_iodata!(%{about | _hostname: hostname()}))
    |> halt()
  end

  @impl true
  def call(conn, _about), do: conn

  @doc "Generate about schema from configuration"
  def about(config) do
    config[:system_code] || arg_error!(":system_code configuration is required")

    name = config[:name] || config[:system_code]
    description = config[:description] || name
    purpose = config[:purpose] || description

    %{
      schemaVersion: 1,
      systemCode: config[:system_code],
      name: name,
      description: description,
      purpose: purpose,
      appVersion: to_string(Version.parse!(config[:app_version] || @app_version)),
      serviceTier: config[:service_tier] || :bronze,
      contacts: config[:contacts] || [],
      links: config[:links] || [],
      # resolved dynamically, see hostname/0
      _hostname: nil
    }
  end

  defp hostname do
    {:ok, hostname} = :inet.gethostname()
    List.to_string(hostname)
  end

  defp arg_error!(msg), do: raise(ArgumentError, msg)
end
