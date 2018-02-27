defmodule AuthIntegrationTest do
  use ExUnit.Case

  defmodule Pipeline do
    use Plug.Router
    import Plug.Conn
    import FT.Web.Authentication
    alias FT.Web.Authentication

    plug FT.Web.TaggedApiKeyPlug, keys: "xxxx", forbid: false
    plug :other_auth
    plug FT.Web.NeedsAuthenticationPlug

    get "/paid" do
      send_resp(conn, 200, "PAID")
    end

    match _, do: send_resp(conn, 404, "Route not found")

    plug :match
    plug :dispatch

    def other_auth(conn, _opts) do
      conn = Plug.Conn.fetch_cookies(conn)
      if !authenticated?(conn) && conn.req_cookies["auth"] do
        put_authentication(conn, %Authentication{method: :cookie, roles: %{}})
      else
        conn
      end
    end
  end

  test "any auth" do
    pipe_init = Pipeline.init([])

    conn = Plug.Test.conn("GET", "/paid")
    conn = Pipeline.call(conn, pipe_init)
    assert conn.status == 403
    refute FT.Web.Authentication.authentication(conn)

    conn = Plug.Test.conn("GET", "/paid")
    conn = Plug.Conn.put_req_header(conn, "x-api-key", "xxxx")
    conn = Pipeline.call(conn, pipe_init)
    assert conn.status == 200
    assert FT.Web.Authentication.authentication(conn).method == :api_key

    conn = Plug.Test.conn("GET", "/paid")
    conn = Plug.Conn.put_req_header(conn, "cookie", "auth=1")
    conn = Pipeline.call(conn, pipe_init)
    assert conn.status == 200
    assert FT.Web.Authentication.authentication(conn).method == :cookie

    # NB authentication is always enforced, even for non-matching URLs
    conn = Plug.Test.conn("GET", "/unknown")
    conn = Pipeline.call(conn, pipe_init)
    assert conn.status == 403
  end

  test "first method of auth is prime [*]" do
    # [*] so long as enforced by implementing module!
    pipe_init = Pipeline.init([])

    conn = Plug.Test.conn("GET", "/paid")
    conn = Plug.Conn.put_req_header(conn, "cookie", "auth=1")
    conn = Plug.Conn.put_req_header(conn, "x-api-key", "xxxx")
    conn = Pipeline.call(conn, pipe_init)
    assert conn.status == 200
    assert FT.Web.Authentication.authentication(conn).method == :api_key
  end
end