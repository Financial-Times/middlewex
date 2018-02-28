defmodule FT.Web.FastlyClientIPPlug do
  @moduledoc """
  Plug which replaces the `Plug.Conn.remote_ip` field with the value
  of the `Fastly-Client-IP` header sent by the Fastly CDN.

  ```
  iex> Plug.Test.conn("GET", "/") |>
  ...> Plug.Conn.put_req_header("fastly-client-ip", "1.2.3.4") |>
  ...> FT.Web.FastlyClientIPPlug.call([]) |>
  ...> Map.get(:remote_ip)
  {1, 2, 3, 4}
  ```

  Note that `Plug.Conn.peer` will still contain the original peer IP address (and remote port),
  if you need  it.

  If the `Fastly-Client-IP` header is not present, or is not a valid IPv4 or IPv6 address,
  `remote_ip` is left as-is.

  ## Usage

  Just add the plug to your endpoint/router, most usefully  before anything that might
  want use the true client ip, like `FT.Web.NiceLoggerPlug`:
  ```
  plug FT.Web.FastlyClientIPPlug
  ```

  """

  @behaviour Plug

  @impl true
  def init(opts) do
    opts
  end

  @impl true
  def call(conn, _opts) do
    %{conn | remote_ip: fastly_client_ip(conn.req_headers, conn.remote_ip)}
  end

  def fastly_client_ip(headers, default) do
    with {_header, value} <- List.keyfind(headers, "fastly-client-ip", 0),
         {:ok, ip_tuple} <- :inet.parse_address(String.to_charlist(value)) do
      ip_tuple
    else
      _error ->
        default
    end
  end
end
