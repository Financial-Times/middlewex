defmodule FT.Web.Authentication do
  @moduledoc """
  Defines type of authentication data to be stored in `Plug.Conn` `private.authentication` field.
  """

  defstruct [
    method: nil,
    roles: %{},
    private: nil
  ]

  @type roles :: %{optional(atom) => true}

  @type t :: %__MODULE__{
    method: atom,
    roles: roles,
    private: any
  }

  @type authentication :: t

  @doc "retrieve `%Authentication{}` from `Plug.Conn`, or return `nil`"
  @spec authentication(conn :: Plug.Conn.t) :: t
  def authentication(%Plug.Conn{private: %{authentication: %__MODULE__{} = auth}}), do: auth
  def authentication(%Plug.Conn{}), do: nil

  @doc "store `%Authentication{}` in the `Plug.Conn`"
  @spec put_authentication(conn :: Plug.Conn.t, auth :: t) :: Plug.Conn.t
  def put_authentication(%Plug.Conn{} = conn, %__MODULE__{} = auth) do
    Plug.Conn.put_private(conn, :authentication, auth)
  end

end
