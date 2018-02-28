defmodule FT.Web.ApiKeyMetrics do
  @moduledoc """
  Defines behaviour for API key usage recording.
  """
  @callback record_usage(conn :: Plug.Conn.t(), api_key :: String.t()) :: Plug.Conn.t()
end
