defmodule FT.Web.ApiKeyMetrics do
  @moduledoc """
  Defines behaviour for API key usage recording.
  """
  @callback record_usage(Plug.Conn.t, String.t) :: Plug.Conn.t
end