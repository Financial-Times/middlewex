defmodule FT.Web.NiceLoggerPlug do
  @moduledoc """
  A plug for logging request information in a nice, Splunk compatible format:

      09:17:08.251 [info]  method=GET path="/foo/bar" query="x=100" remote_ip=10.0.0.1
      09:17:08.251 [info]  type=Sent status=200 duration=572 method=GET path="/foo/bar" query="x=100" remote_ip=10.0.0.1

  Note that the request details are repeated in the log line, allowing searches for duration to be
  filtered by path.

  To use it, just plug it into the desired module.

      plug FT.Web.NiceLoggerPlug, log: :debug

  ## Options

    * `:log` - The log level at which this plug should log its request info.
      Default is `:info`.
    * `:time_unit` - the unit of measured duration. Default is `:microseconds`.
  """

  require Logger
  alias Plug.Conn
  @behaviour Plug

  @impl true
  def init(opts) do
    {
      Keyword.get(opts, :log, :info),
      Keyword.get(opts, :time_unit, :microseconds)
    }
  end

  @impl true
  def call(conn, {level, time_unit}) do
    common_request_props = request_props(conn)

    Logger.log level, common_request_props

    start = System.monotonic_time()

    Conn.register_before_send(conn, fn conn ->
      Logger.log level, fn ->
        stop = System.monotonic_time()
        diff = System.convert_time_unit(stop - start, :native, time_unit)

        [
          "type=", connection_type(conn),
          " status=", Integer.to_string(conn.status),
          " duration=", Integer.to_string(diff),
          32
          | common_request_props
        ]
      end
      conn
    end)
  end

  defp request_props(conn) do
    [
      "method=", conn.method,
      ~S( path="), conn.request_path,
      ~S(" query="), String.replace(conn.query_string, ~S("), ~S(\\")),
      ~S(" remote_ip=), format_ip(conn.remote_ip)
    ]
  end

  defp connection_type(%{state: :set_chunked}), do: "Chunked"
  defp connection_type(_), do: "Sent"

  defp format_ip({_, _, _, _} = ip4), do: :inet.ntoa(ip4)
  defp format_ip({_, _, _, _, _, _, _, _} = ip6), do: :inet.ntoa(ip6)
  defp format_ip(_), do: "unknown"
end
