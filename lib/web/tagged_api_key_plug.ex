defmodule FT.Web.TaggedApiKeyPlug do
  @moduledoc """
  Validates a header value against valid keys, and either denies request, or updates
  the `Plug.Conn` with authentication details in a `FT.Web.Authentication` struct.

  Keys can be configured with *roles* which will be passed through as `conn.private.authentication.roles`
  for the matching key, allowing e.g. keys to be associated with particular policies.

  ## Plug Options

  * `header`: request header to examine for api key, default `"x-api-key"`.
  * `metrics`: module implementing `FT.Web.ApiKeyMetrics` behaviour to use to report metrics, default disabled (`false`).
  * `keys`: source for api keys; see below.
  * `forbid` : whether to generate a `403 Forbidden` if no api key matches, or to pass through to next authentication method; default `true`.

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

  ## Keys

  Keys can be specified via the `keys` option as:
  * a `String` containing serialized keys.
  * the atom name of a module implementing the `FT.Web.KeyStorage` behaviour.
  * an *MFA* tuple which should return a `String` or a map of `key => [roles].

  NB keys specfied as an `KeyStorage` module or MFA are resolved at run-time.

  ### Interpretation

  If the keys resolves as the string:
  ```
  xxxxx<>roleA,yyyyy<>roleA<>roleB,zzzzz
  ```

  This would be interpreted as:
  * key `xxxx` has single role `roleA` assigned.
  * key `yyyy` has roles `roleA` and `roleB` assigned.
  * key `zzzz` assigns no roles.

  If an MFA returned a map for the same data it would be:
  ```
  %{
    "xxxx" => [:roleA],         # or %{roleA: true}
    "yyyy" => [:roleA, :roleB], # or %{roleA: true, roleB: true}
    "zzzz" => []
  }
  ```
  Note that roles can be specified as a list of `atom` or `String`,
  or as a `map` of `atom => true`.

  In either case, roles end up as `atom => true` entries in the `FT.Web.Authentication{}` struct.

  ## Plug.Conn Result

  Unsuccessful key validation will call `FT.Web.Errors.ForbiddenError.send/2`, resulting in
  a 403 response, and will halt the pipeline.

  Successful key validation sets `conn.private.authentication` with a `FT.Web.Authentication` struct:

  ```
  %FT.Web.Authentication{method: :api_key, roles: tags, private: %{key: key}}
  ```

  Where `key` is the valid api key, and `roles` is a map of `role => true`, where `role` is
  the `atom` form of the role name, providing a straight-forward way of pattern matching
  on roles, e.g. for key `xxxx` above, `private.authentication` would be:

  ```
  %FT.Web.Authentication{method: :api_key, roles: %{tagA: true}, private: %{key; "xxxx"}}
  ```

  ## Metrics

  API Key metrics are enabled by specifying an implementation of `FT.Web.ApiKeyMetrics` in
  the Plug's `metrics` option. `FT.Web.PrometheusApiKeyMetrics` provides an
  implementation for sending metrics to Prometheus.
  """

  import Plug.Conn

  require Logger

  alias FT.Web.Errors.ForbiddenError

  @type key_config :: {module, atom, list} | String.t() | atom

  @type roles :: FT.Web.Authentication.roles()

  @default_header "x-api-key"

  @behaviour Plug

  @impl true
  @spec init(header: String.t(), keys: key_config) :: %{
          header: String.t(),
          keys: key_config,
          forbid: boolean,
          metrics: module | false
        }
  def init(options) do
    header = Keyword.get(options, :header, @default_header)
    metrics = Keyword.get(options, :metrics, false)
    forbid = !!Keyword.get(options, :forbid, true)
    keys_config = Keyword.get(options, :keys)

    keys =
      case keys_config do
        {m, f, a} ->
          {m, f, a}

        "" <> keys ->
          keys

        m when is_atom(m) and not is_nil(m) ->
          (Code.ensure_loaded?(m) && Kernel.function_exported?(m, :lookup, 1)) ||
            raise ArgumentError, message: "Module must implement FT.Web.KeyStorage"

          m

        _ ->
          raise ArgumentError,
            message: "Plug requires :keys option, mod, {mod, fun, args} or String"
      end

    %{header: header, keys: keys, forbid: forbid, metrics: metrics}
  end

  @impl true
  def call(%Plug.Conn{private: %{authentication: _}} = conn, _), do: conn

  @impl true
  def call(conn, %{header: header, keys: keys_config, forbid: forbid, metrics: metrics}) do
    given_api_key = api_key_from_header(conn, header)

    if is_nil(given_api_key) do
      if(forbid, do: ForbiddenError.send(conn, "API key required."), else: conn)
    else
      case lookup(keys_config, given_api_key) do
        {:ok, roles} ->
          Logger.debug(fn ->
            "#{__MODULE__} Valid key #{given_api_key} has tags #{inspect(Map.keys(roles))}"
          end)

          # compatible
          # compatible
          conn
          |> assign(:api_key, given_api_key)
          |> assign(:auth_tags, roles)
          |> put_authentication(given_api_key, roles)
          |> record_metrics(given_api_key, metrics)

        false ->
          if(forbid, do: ForbiddenError.send(conn, "Invalid API key."), else: conn)
      end
    end
  end

  @spec lookup(keys_config :: key_config, key :: String.t()) :: {:ok, roles} | false
  defp lookup(m, key) when is_atom(m) do
    # FT.Web.KeyStorage impl
    m.lookup(key)
  end

  defp lookup("" <> keys, key) do
    keys = expand_keys(keys)

    case keys[key] do
      nil -> false
      tags when is_list(tags) -> {:ok, to_roles(tags)}
    end
  end

  defp lookup({m, f, a}, key) do
    keys = apply(m, f, a)
    keys = expand_keys(keys)

    case keys[key] do
      nil -> false
      tags when is_list(tags) -> {:ok, to_roles(tags)}
      tags when is_map(tags) -> {:ok, tags}
    end
  end

  defp record_metrics(conn, _key, false), do: conn

  defp record_metrics(conn, key, metrics) do
    metrics.record_usage(conn, key)
  end

  defp put_authentication(conn, key, roles) do
    FT.Web.Authentication.put_authentication(conn, authentication(key, roles))
  end

  @spec authentication(key :: String.t(), roles :: roles) :: FT.Web.Authentication.t()
  defp authentication(key, roles) when is_map(roles) do
    %FT.Web.Authentication{method: :api_key, roles: roles, private: %{key: key}}
  end

  @spec to_roles([String.t()]) :: roles
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

  # split key config string into a map of `key => [tag, ...]`
  defp expand_keys("" <> keys) do
    # [key, key<>x, key <>x<>y]
    #   [[key], [key, x], [key, x, y]
    # [{key, [tags]}, ...]
    keys
    |> String.splitter(",", trim: true)
    |> Stream.map(&String.split(&1, "<>", trim: true))
    |> Stream.map(fn [key | tags] -> {key, tags} end)
    |> Enum.into(%{})
  end

  # config module may supply fully expanded key => [tags] map.
  defp expand_keys(keys) when is_map(keys), do: keys
end
