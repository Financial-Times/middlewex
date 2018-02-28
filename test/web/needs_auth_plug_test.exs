defmodule NeedAuthPlugTest do
  use ExUnit.Case

  alias FT.Web.Authentication

  test "403 on no authentication" do
    config = FT.Web.NeedsAuthenticationPlug.init([])
    conn = Plug.Test.conn("GET", "/")
    conn = FT.Web.NeedsAuthenticationPlug.call(conn, config)

    assert conn.status == 403
    assert conn.halted
    assert conn.state == :sent
  end

  test "pass-thru when valid authentication with any method" do
    config = FT.Web.NeedsAuthenticationPlug.init([])
    conn = Plug.Test.conn("GET", "/")
    conn = Authentication.put_authentication(conn, %Authentication{method: :api_key})
    conn = FT.Web.NeedsAuthenticationPlug.call(conn, config)

    refute conn.halted
    refute conn.state == :sent
  end

  test "pass-thru when valid authentication matches specific method" do
    config = FT.Web.NeedsAuthenticationPlug.init(method: :api_key)
    conn = Plug.Test.conn("GET", "/")
    conn = Authentication.put_authentication(conn, %Authentication{method: :api_key})
    conn = FT.Web.NeedsAuthenticationPlug.call(conn, config)

    refute conn.halted
    refute conn.state == :sent
  end

  test "denied when valid authentication not matching specific method" do
    config = FT.Web.NeedsAuthenticationPlug.init(method: :api_key)
    conn = Plug.Test.conn("GET", "/")
    conn = Authentication.put_authentication(conn, %Authentication{method: :sso})
    conn = FT.Web.NeedsAuthenticationPlug.call(conn, config)

    assert conn.status == 403
    assert conn.halted
    assert conn.state == :sent
  end
end
