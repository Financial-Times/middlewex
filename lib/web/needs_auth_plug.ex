defmodule FT.Web.NeedsAuthenticationPlug do
  @moduledoc """
  Requires a valid `FT.Web.Authentication` to be set in the `Plug.Conn`,
  or else sends a `403 Forbidden` status and halts the pipeline.

  This is mostly for use where multiple authentication methods are possible,
  and any one is sufficient to satisfy authentication, so you don't want the
  first one to fail the request if not satisfied, e.g.

  ```
  plug FT.Web.TaggedApiKeyPlug, keys: FT.Web.ETSKeyStorage, forbid: false # NB forbid=false
  plug FT.Web.S3OPlug
  plug FT.Web.NeedsAuthenticationPlug
  ```

  In Phoenix pipelines, slightly more flexible use can be had by
  separating the authentication into pipelines, and using 'NeedsAuthenticationPlug'
  to enforce authentication beyond a certain point, e.g.

  ```
  pipeline :try_api_key_auth do
    plug FT.Web.TaggedApiKeyPlug, keys: FT.Web.ETSKeyStorage, forbid: false
  end
  pipeline :try_s3o_auth do
    plug FT.Web.S3OPlug # from middlewex_s3o
  end
  pipeline :enforce_auth do
    plug FT.Web.NeedAuthenticationPlug
  end
  pipeline :needs_explorer_role do
    plug FT.Web.NeedsRolePlug, role: :explorer
  end

  scope "/" do
    # try api-key auth for whole scope
    pipe_through [:try_api_key_auth]

    forward "/api", Absinthe.Plug,
      # only keys with explorer role
      pipe_through [:enforce_auth, :needs_explorer_role]
      schema: Graphql.Schema

    scope "/graphiql" do
      # this route may additionally use S3O auth
      pipe_through [:try_s3o_auth, :enforce_auth, :needs_explorer_role]
      forward "/", Absinthe.Plug.GraphiQL,
        schema: Graphql.Schema
    end
  end
  ```
  """

  @behaviour Plug

  alias FT.Web.Authentication

  @doc "Takes option `method` to require match of authentication method."
  @impl Plug
  def init(opts) do
    %{
      method: opts[:method]
    }
  end

  @doc false
  @impl Plug
  def call(%Plug.Conn{private: %{authentication: %Authentication{method: method}}} = conn, %{method: method}) do
    conn
  end
  def call(%Plug.Conn{private: %{authentication: %Authentication{}}} = conn, %{method: nil}) do
    conn
  end
  def call(%Plug.Conn{} = conn, %{method: nil}) do
    FT.Web.Errors.ForbiddenError.send(conn, "Need authentication.")
  end
  def call(%Plug.Conn{} = conn, %{method: method}) do
    FT.Web.Errors.ForbiddenError.send(conn, "Need authentication by #{method}.")
  end

end
