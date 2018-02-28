defmodule NiceLoggerPlugTest do
  use ExUnit.Case
  use Plug.Test

  import ExUnit.CaptureLog

  setup_all do
    Logger.configure(level: :info)
    Logger.configure_backend(:console, colors: [enabled: false])
  end

  test "logs request" do
    log =
      capture_log([level: :info], fn ->
        conn = Plug.Test.conn(:get, "/foo/bar?x=100")
        conn = %{conn | remote_ip: {10, 0, 0, 1}}
        conn = put_req_header(conn, "user-agent", ~S(ua "agent"))
        _conn2 = FT.Web.NiceLoggerPlug.call(conn, {:info, :milliseconds})
      end)

    IO.puts(log)
    parts = String.split(String.trim(log))
    assert ~S(method=GET) in parts
    assert ~S(path="/foo/bar") in parts
    assert ~S(query="x=100") in parts
    assert ~S(remote_ip=10.0.0.1) in parts
    assert String.contains?(log, ~S(user_agent="ua \"agent\""))
  end

  test "logs response" do
    conn = Plug.Test.conn(:get, "/foo/bar?x=100")
    conn = %{conn | remote_ip: {10, 0, 0, 1}}
    conn2 = FT.Web.NiceLoggerPlug.call(conn, {:info, :milliseconds})

    log =
      capture_log([level: :info], fn ->
        send_resp(conn2, 401, "Denied")
      end)

    parts = String.split(String.trim(log))
    assert ~S(method=GET) in parts
    assert ~S(path="/foo/bar") in parts
    assert ~S(query="x=100") in parts
    assert ~S(remote_ip=10.0.0.1) in parts
    assert ~S(type=Sent) in parts
    assert ~S(status=401) in parts

    duration = Enum.find(parts, fn x -> String.starts_with?(x, "duration=") end)
    assert Regex.match?(~r/duration=\d+/, duration)
  end

  test "logs request with no query params" do
    log =
      capture_log([level: :info], fn ->
        conn = Plug.Test.conn(:get, "/foo/bar")
        _conn2 = FT.Web.NiceLoggerPlug.call(conn, {:info, :milliseconds})
      end)

    parts = String.split(String.trim(log))
    assert ~S(path="/foo/bar") in parts
    assert ~S(query="") in parts
  end
end
