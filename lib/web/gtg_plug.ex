defmodule FT.Web.GtgPlug do
  @moduledoc """
  Plug for to serve `/__gtg` end-point:

  ```
  plug FT.Web.GtgPlug
  ```

  The plug will only be executed when `conn.path_info` is `["__gtg"]`.

  The plug always responds with a `200` status code, and the `text/plain`
  body `OK`, as per the GTG standard, execution halts the Plug pipeline.
  """

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(options) do
    options
  end

  @impl true
  def call(conn = %Plug.Conn{path_info: ["__gtg"]}, _config) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "OK")
    |> halt() # NB depending on where this is placed, no logging
  end

  @impl true
  def call(conn, _config), do: conn

end
