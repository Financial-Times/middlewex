defmodule FastlyClientIPPlugTest do
  use ExUnit.Case, async: true

  doctest FT.Web.FastlyClientIPPlug

  test "missing fastly header has no effect" do

    conn = Plug.Test.conn("GET", "/")
    |> Map.put(:remote_ip, {127, 0, 0, 2})
    |> FT.Web.FastlyClientIPPlug.call([])

    assert conn.remote_ip == {127, 0, 0, 2}
  end

  test "bad fastly header is ignored" do
    conn = Plug.Test.conn("GET", "/")
    |> Map.put(:remote_ip, {127, 0, 0, 2})
    |> Plug.Conn.put_req_header("fastly-client-ip", "Robots")
    |> FT.Web.FastlyClientIPPlug.call([])

    assert conn.remote_ip == {127, 0, 0, 2}
  end

end
