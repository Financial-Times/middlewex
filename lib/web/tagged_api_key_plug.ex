defmodule FT.Web.TaggedApiKeyPlug do

  @moduledoc """
  Validates a header value against a list of valid keys, and either denies request, or updates
  the `Plug.Conn` with authentication details.

  Keys can be configured with *tags* which will be passed through as `conn.private.authentication.roles`
  for the matching key, allowing e.g. keys to be associated with particular policies.

  ## Plug Options

  * `header`: request header to examine for api key, default `"x-api-key"`.
  * `metrics`: module implementing `FT.Web.ApiKeyMetrics` behaviour to use to report metrics, default disabled (`false`).
  * `keys`: a String, or an MFA tuple (`{module,function,[argument, ...]}`) to call with `Kernel.apply/3`, which should
  return a `String` or a map of `key => [tags]`.

  NB keys specfied as an MFA are resolved at run-time.

  ## Phoenix Example
  In your Phoenix Router:
  ```
  pipeline :needs_api_key do
      plug FT.Web.TaggedApiKeyPlug, keys: {Application, :get_env, [:my_app, :api_keys]}
  end

  scope "/" do
      pipe_through :needs_api_key

      ...routes...
  end
  ```

  ## Key Interpretation

  If the keys resolve as the String:
  ```
  xxxxx<>tagA,yyyyy<>tagA<>tagB,zzzzz
  ```

  This would be interpreted as:
  * `xxxx` has single tag `tagA`
  * `yyyy` has tags `tagA` and `tagB`
  * `zzzz` has no tags

  If an MFA returned a map for the same data it would be:
  ```
  %{
    "xxxx" => [:tagA],
    "yyyy" => [:tagA, :tagB],
    "zzzz" => []
  }
  ```
  (Note that tags can be specified as atoms or Strings in either case).

  ## Plug.Conn Result

  Unsuccessful key validation will call `FT.Web.Errors.ForbiddenError.send/2`, resulting in
  a 403 response, and will halt the pipeline.

  Successful key validation sets `conn.private.authentication` with a map:

  ```
  %{method: :api_key, key: key, roles: tags}
  ```

  Where `key` is the valid api key, and `roles` is a map of `role => true`, where `role` is
  the `atom` form of associated tags (converted via `String.to_atom/1` if necessary), providing a
  straight-forward way of pattern matching roles, e.g. for key `xxxx` above, `private.authentication`
  would be:

  ```
  %{method: :api_key, key: "xxxx", roles: %{tagA: true}}
  ```

  ## Metrics

  API Key metrics are enabled by specifying an implementation of `FT.Web.ApiKeyMetrics` in
  the Plug's `metrics` option. `FT.Web.PrometheusApiKeyMetrics` provides an
  implementation for sending metrics to Prometheus.
  """

  import Plug.Conn

  require Logger

  alias FT.Web.Errors.ForbiddenError

  @type key_config :: {module, atom, list} | String.t

  @type roles ::  FT.Web.Authentication.roles
  @type authentication :: %{method: :api_key, key: String.t, roles: roles}

  @default_header "x-api-key"

  @behaviour Plug

  @impl true
  @spec init([header: String.t, keys: key_config]) :: %{header: String.t, keys: key_config, metrics: module | false}
  def init(options) do
      header = Keyword.get(options, :header, @default_header)
      metrics = Keyword.get(options, :metrics, false)
      keys_config = Keyword.get(options, :keys)
      keys = case keys_config do
        {m, f, a} -> {m, f, a}
        "" <> keys -> keys
        _ -> raise ArgumentError, message: "Plug requires keys: configuraton, {mod, fun, args} or String"
      end

      %{header: header, keys: keys, metrics: metrics}
  end

  @impl true
  def call(%Plug.Conn{private: %{authentication: _}} = conn, _), do: conn

  @impl true
  def call(conn, %{header: header, keys: keys_config, metrics: metrics}) do

      given_api_key = api_key_from_header(conn, header)

      if is_nil(given_api_key) do
        ForbiddenError.send(conn, "API key required.")
      else
        keys_config
        |> fetch_keys()
        |> expand_keys()
        |> case do
          %{^given_api_key => tags} ->
            Logger.debug(fn -> "#{__MODULE__} Valid key #{given_api_key} has tags #{inspect tags}" end)

            roles =  to_roles(tags)

            conn
            |> assign(:api_key, given_api_key) # compatible
            |> assign(:auth_tags, roles) # compatible
            |> put_authentication(given_api_key, roles)
            |> record_metrics(given_api_key, metrics)
          _ ->
            ForbiddenError.send(conn, "Invalid API key.")
        end
      end
  end

  defp record_metrics(conn, _key, false), do: conn

  defp record_metrics(conn, key, metrics) do
    metrics.record_usage(conn, key)
  end

  defp put_authentication(conn, key, roles) do
    put_private(conn, :authentication, authentication(key, roles))
  end

  @spec authentication(key :: String.t, roles :: roles) :: authentication
  defp authentication(key, roles) do
    %{method: :api_key, key: key, roles: roles}
  end

  @spec to_roles([String.t]) :: roles
  defp to_roles(tags) when is_list(tags) do
    Enum.into(tags, %{}, fn
      tag when is_atom(tag) -> {tag, true}
      tag -> {String.to_atom(tag), true}
    end)
  end

  # retrieve value of key header
  defp api_key_from_header(%Plug.Conn{req_headers: req_headers}, accepted_header) do
      found_header = Enum.find(req_headers, fn {name, _} -> name == accepted_header end)

      case found_header do
          {_name, value} -> value
          _ -> nil
      end
  end

  defp fetch_keys({m, f, a}) do
    apply(m, f, a)
  end
  defp fetch_keys("" <> keys) do
    keys
  end

  # split key config string into a map of `key => [tag, ...]`
  defp expand_keys("" <> keys) do
    keys
    |> String.splitter(",", trim: true) # [key, key<>x, key <>x<>y]
    |> Stream.map(&(String.split(&1, "<>", trim: true))) #  [[key], [key, x], [key, x, y]
    |> Stream.map(fn [key | tags] -> {key, tags} end) # [{key, [tags]}, ...]
    |> Enum.into(%{})
  end

  # config module may supply fully expanded key => [tags] map.
  defp expand_keys(keys) when is_map(keys), do: keys

end
