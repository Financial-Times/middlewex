defmodule FT.Web.Errors do
  @moduledoc """
  Convenient definitions for HTTP Errors.
  """

  defmodule ForbiddenError do
    @moduledoc """
    Access Forbidden.

    NB if you `raise` this error, due to current Plug/Cowboy interaction, it
    has the side-effect of closing the client's socket on the server end, without
    sending `Connection: closed`, which plays badly with connection pooling.
    It's better to use the `send/2` function instead of raising for this reason.
    """

    import Plug.Conn

    defexception message: "Forbidden", plug_status: 403, conn: nil

    @doc "send a 403 response, rather than raising an exception"
    def send(conn, message \\ "Forbidden") do
      conn
      |> send_resp(403, message)
      |> halt()
    end
  end
end
