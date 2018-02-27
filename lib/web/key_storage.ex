defmodule FT.Web.KeyStorage do
  @moduledoc "Defines behaviour for a key storage module."

  @type roles :: FT.Web.Authentication.roles

  @callback lookup(key :: String.t) :: {:ok, roles :: roles} | false
end
