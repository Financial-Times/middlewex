defmodule FT.Web.NiceLoggerPlug do
  @moduledoc """
  A plug for logging request information in a nice, Splunk compatible format:

      09:17:08.251 [info]  method=GET path="/foo/bar" query="x=100" remote_ip=10.0.0.1
      09:17:08.251 [info]  type=Sent status=200 duration=572

  To use it, just plug it into the desired module.

      plug FT.Web.NiceLoggerPlug, log: :debug

  ## Options

    * `:log` - The log level at which this plug should log its request info.
      Default is `:info`.
    * `:time_unit` - the unit of measured duration. Default `:milliseconds`.
  """

  require Logger
  alias Plug.Conn
  @behaviour Plug

  @impl true
  def init(opts) do
    {
      Keyword.get(opts, :log, :info),
      Keyword.get(opts, :time_unit, :milliseconds)
    }
  end

  @impl true
  def call(conn, {level, time_unit}) do
    Logger.log level, fn ->
      [
        "method=", conn.method,
        ~S( path="), conn.request_path,
        ~S(" query="), String.replace(conn.query_string, ~S("), ~S(\\")),
        ~S(" remote_ip=), format_ip(conn.remote_ip)
      ]
    end

    start = System.monotonic_time()

    Conn.register_before_send(conn, fn conn ->
      Logger.log level, fn ->
        stop = System.monotonic_time()
        diff = System.convert_time_unit(stop - start, :native, time_unit)

        [
          "type=", connection_type(conn),
          " status=", Integer.to_string(conn.status),
          " duration=", Integer.to_string(diff)
        ]
      end
      conn
    end)
  end

  defp connection_type(%{state: :set_chunked}), do: "Chunked"
  defp connection_type(_), do: "Sent"

  defp format_ip({_, _, _, _} = ip4), do: :inet.ntoa(ip4)
  defp format_ip({_, _, _, _, _, _, _, _} = ip6), do: :inet.ntoa(ip6)
  defp format_ip(_), do: "unknown"
end
