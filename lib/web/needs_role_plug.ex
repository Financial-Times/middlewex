defmodule FT.Web.NeedsRolePlug do
  @moduledoc """
  Checks for a role in a request's `priv.authentication` (e.g. as set by the plug `FT.Web.TaggedApiKeyPlug`).

  Ensures the roles passed through contain the specified role (an atom).

  ## Phoenix Example
  In your Phoenix Router:
  ```
  pipeline :needs_api_key_and_explorer_role do
    plug FT.Web.TaggedApiKeyPlug, keys: "xyzzy<>user,yzyyz<>explorer"
    plug FT.Web.NeedsRolePlug, role: :explorer
  end

  scope "/" do
      pipe_through :needs_api_key_and_explorer_role

      ...routes which are available only to requesters with the `:explorer` role...
  end
  ```

  ## Plug Options

  * `role`: an atom represetation of the name of the role, e.g. `:explorer`.

  """

  require Logger

  alias FT.Web.Errors.ForbiddenError

  @behaviour Plug

  @type roles :: FT.Web.Authentication.roles()

  @impl true
  @spec init(role: atom) :: %{role: atom}
  def init(options) do
    role = Keyword.get(options, :role) || raise ArgumentError, "Needs role"
    role = if(is_atom(role), do: role, else: raise(ArgumentError, "Role must be atom"))
    %{role: role}
  end

  @impl true
  @spec call(conn :: Plug.Conn.t(), config :: %{role: atom}) :: Plug.Conn.t()
  def call(%{private: %{authentication: %{roles: roles}}} = conn, %{role: role}) do
    Logger.debug(fn -> "#{__MODULE__} Looking for role: #{role} in tags: #{inspect(roles)}" end)

    if roles[role] do
      conn
    else
      message = "Forbidden: Missing role #{role} for path #{conn.request_path}"
      Logger.info(message)

      ForbiddenError.send(conn, message)
    end
  end

  @impl true
  def call(conn, _config) do
    message = "Forbidden: Unauthenticated at path #{conn.request_path}"
    Logger.info(message)

    ForbiddenError.send(conn, message)
  end
end
