defmodule FT.Web.PrometheusApiKeyMetrics do
  @moduledoc """
  Records metrics about API keys to [Prometheus](https://prometheus.io/),
  implementing the `FT.Web.ApiKeyMetrics` behaviour.

  > Ensure `setup/0` has been called before `record_usage/2` is called,
  e.g. call from your `Application` module.

  The recorded key is hashed using `:erlang.phash2/1` and the hash value added to the
  `Logger` metadata under `:api_key`. The same hash value is recorded in a
  `Prometheus.Metric.Counter` with `:method`, `:path` and `:keyhash` labels.

  > WARNING since the entire `path_info` is used as a `label`, this will potentially leak sensitive
  information into Prometheus, and/or cause a memory leak if the path contains many possible
  varients (e.g. contains a UUID); in which case, write your own module which removes sensitive
  or high-cardinality data before delegating to this module.
  """
  require Prometheus.Metric.Counter

  alias Prometheus.Metric.Counter

  @behaviour FT.Web.ApiKeyMetrics

  def setup() do
    Counter.declare(
      name: :api_key_usage,
      labels: [:method, :path, :keyhash],
      help: "API Key usage"
    )
  end

  @impl true
  def record_usage(%Plug.Conn{method: method, path_info: path_info} = conn, key) do
    key_hash = :erlang.phash2(key)
    Logger.metadata(api_key: key_hash)
    path = Enum.join(path_info, "/")
    Counter.inc(name: :api_key_usage, labels: [method, path, key_hash])
    conn
  end
end
