defmodule FT.Web.NeedsRoleTest do
  @moduledoc false

  use ExUnit.Case
  use Plug.Test

  require Logger


  describe "configuration with single role to check" do
    @tag :configuration
    test "configuration with single role" do
      config = FT.Web.NeedsRolePlug.init([role: :leading_lady])
      assert config == %{role: :leading_lady}
    end
  end


  describe "role checking" do
    @tag :role
    test "tag list that does not include required role sets response status to 403" do
      required_role = :intrepid_explorer
      auth_tags = %{admin: true, foo: true}

      conn = call(required_role, auth_tags)
      assert(conn.status == 403)
    end

    @tag :role
    test "tag list that does include required role returns connection with status unchanged" do
      required_role = :intrepid_explorer
      auth_tags = %{admin: true, intrepid_explorer: true}

      conn = call(required_role, auth_tags)
      assert( conn.status == :nil )
    end

    @tag :role
    test "unauthenticated or non-role-based auth is forbidden" do
      config = FT.Web.NeedsRolePlug.init([role: :foo])
      conn =
        conn(:get, "/foo", "bar=10")
        |> FT.Web.NeedsRolePlug.call(config)

      assert conn.status == 403
    end
  end

  defp call(required_role, auth_tags) do
    config = FT.Web.NeedsRolePlug.init([role: required_role])
    conn = conn(:get, "/foo", "bar=10")
      |> put_private(:authentication, %{roles: auth_tags})

    FT.Web.NeedsRolePlug.call(conn, config)
  end

end
