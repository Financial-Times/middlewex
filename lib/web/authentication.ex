defmodule FT.Web.Authentication do
  @moduledoc """
  Defines type of authentication data to be stored in `Plug.Conn` `private.authentication` field.
  """

  @type roles :: %{optional(atom) => true}

  @type authentication :: %{:method => atom, :roles => roles, optional(atom) => any}
end
