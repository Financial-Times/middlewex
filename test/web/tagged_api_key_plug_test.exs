defmodule FT.Web.TaggedApiKeyTest do
  @moduledoc false

  use ExUnit.Case
  use Plug.Test

  alias FT.Web.TaggedApiKeyPlug

  def get_val(val), do: val

  describe "configuration" do
    @tag :configuration
    test "configuration defaults" do
      config = TaggedApiKeyPlug.init(keys: "api-key")

      %{header: "x-api-key", metrics: false} = config
    end

    @tag :configuration
    test "configuration with custom header" do
      config = TaggedApiKeyPlug.init(header: "my-header", keys: "api-key")

      %{header: "my-header"} = config
    end

    @tag :configuration
    test "configuration with custom metrics" do
      config = TaggedApiKeyPlug.init(keys: "api-key", metrics: Foo)

      %{metrics: Foo} = config
    end

    @tag :configuration
    test "configuration with metrics disabled" do
      config = TaggedApiKeyPlug.init(keys: "api-key", metrics: false)

      %{metrics: false} = config
    end

    @tag :configuration
    test "configuration with tuple" do
      mfa = {__MODULE__, :get_val, ["xyzzy"]}
      config = TaggedApiKeyPlug.init(keys: mfa)

      %{keys: ^mfa} = config
    end

    @tag :configuration
    test "configuration with string" do
      key = "yyzzx"
      config = TaggedApiKeyPlug.init(keys: key)

      %{keys: ^key} = config
    end

    @tag :configuration
    test "configuration with keystorage module" do
      defmodule DummyKS do
        @behaviour FT.Web.KeyStorage
        def lookup(_), do: {:ok, %{}}
      end

      config = TaggedApiKeyPlug.init(keys: DummyKS)

      %{keys: DummyKS} = config
    end

    @tag :configuration
    test "configuration with non-keystorage module raises ArgumentError" do
      assert_raise ArgumentError, fn -> TaggedApiKeyPlug.init(keys: __MODULE__) end
    end

    @tag :configuration
    test "missing keys configuration raises ArgumentError" do
      assert_raise ArgumentError, fn -> TaggedApiKeyPlug.init(header: "my-header") end
    end
  end

  describe "key validation" do
    @tag :api_key
    test "valid api key" do
      conn = call([keys: "XYZZY"], "XYZZY")

      assert conn.assigns.api_key == "XYZZY"
      assert FT.Web.Authentication.authentication(conn)

      assert FT.Web.Authentication.authentication(conn) == %FT.Web.Authentication{
               method: :api_key,
               private: %{key: "XYZZY"},
               roles: %{}
             }
    end

    @tag :api_key
    test "valid api key with tag" do
      conn = call([keys: "XYZZY<>my_tag"], "XYZZY")

      assert conn.assigns.api_key == "XYZZY"
      assert conn.assigns.auth_tags == %{my_tag: true}
      assert FT.Web.Authentication.authentication(conn)

      assert FT.Web.Authentication.authentication(conn) == %FT.Web.Authentication{
               method: :api_key,
               private: %{key: "XYZZY"},
               roles: %{my_tag: true}
             }
    end

    @tag :api_key
    test "valid api key with tags" do
      conn = call([keys: "XYZZY<>my_tag<>another"], "XYZZY")

      assert conn.assigns.api_key == "XYZZY"
      assert conn.assigns.auth_tags == %{my_tag: true, another: true}
      assert FT.Web.Authentication.authentication(conn)

      assert FT.Web.Authentication.authentication(conn) == %FT.Web.Authentication{
               method: :api_key,
               private: %{key: "XYZZY"},
               roles: %{my_tag: true, another: true}
             }
    end

    @tag :api_key
    test "valid api key, multiple comma-sparated keys" do
      ["XYZZY", "YYZZX"]
      |> Enum.map(fn key ->
        conn = call([keys: "SECRET,XYZZY,YYZZX"], key)
        refute conn.status == 403, "Unexpected denial for key #{key}"
        assert conn.assigns.api_key == key
        assert FT.Web.Authentication.authentication(conn)

        assert FT.Web.Authentication.authentication(conn) == %FT.Web.Authentication{
                 method: :api_key,
                 private: %{key: key},
                 roles: %{}
               }
      end)
    end

    @tag :api_key
    test "invalid api key" do
      conn = call([keys: "WRONGKEY"], "XYZZY")

      refute FT.Web.Authentication.authentication(conn)
      assert conn.status == 403
      assert conn.halted
    end

    @tag :api_key
    test "no api key" do
      conn =
        conn(:get, "/foo", "bar=10")
        |> TaggedApiKeyPlug.call(%{
          header: "x-header",
          keys: "XYZZY",
          forbid: true,
          metrics: false
        })

      refute FT.Web.Authentication.authentication(conn)
      assert conn.status == 403
      assert conn.halted
    end

    @tag :api_key
    test "keys specified by MFA" do
      Application.put_env(:my_app, :api_key, "XYZZY")

      config = [keys: {Application, :get_env, [:my_app, :api_key]}]

      conn = call(config, "XYZZY")
      assert conn.assigns.api_key == "XYZZY"
      assert FT.Web.Authentication.authentication(conn)

      conn = call(config, "ZXYYX")
      assert conn.status == 403
      assert conn.halted
    end

    @tag :api_key
    test "keys specified by key_storage" do
      FT.Web.ETSKeyStorage.setup("XYZZY<>a<>b")

      config = [keys: FT.Web.ETSKeyStorage]

      conn = call(config, "XYZZY")
      assert conn.assigns.api_key == "XYZZY"

      assert FT.Web.Authentication.authentication(conn) ==
               %FT.Web.Authentication{
                 method: :api_key,
                 roles: %{a: true, b: true},
                 private: %{key: "XYZZY"}
               }

      conn = call(config, "ZXYYX")
      assert FT.Web.Authentication.authentication(conn) == nil
      assert conn.status == 403
      assert conn.halted
    end

    @tag :api_key
    test "forbid: false" do
      conn = call([forbid: false, keys: "XYZZY"], "XYZZY")

      assert conn.assigns.api_key == "XYZZY"
      assert FT.Web.Authentication.authentication(conn)

      assert FT.Web.Authentication.authentication(conn) == %FT.Web.Authentication{
               method: :api_key,
               private: %{key: "XYZZY"},
               roles: %{}
             }

      conn = call([forbid: false, keys: "XYZZY"], "ZARK!")

      refute FT.Web.Authentication.authentication(conn)
      refute conn.halted
    end
  end

  defmodule TestMetrics do
    @behaviour FT.Web.ApiKeyMetrics

    @impl true
    def record_usage(conn, api_key) do
      send(self(), {:metrics, api_key})
      conn
    end
  end

  describe "metrics" do
    @tag :metrics
    test "recorded for valid api key" do
      config = TaggedApiKeyPlug.init(keys: "XYZZY", metrics: TestMetrics)

      conn =
        conn(:get, "/")
        |> put_req_header("x-api-key", "XYZZY")
        |> TaggedApiKeyPlug.call(config)

      assert conn.private.authentication
      assert_received {:metrics, "XYZZY"}
    end

    @tag :metrics
    test "not recorded for for invalid api key" do
      config = TaggedApiKeyPlug.init(keys: "XYZZY", metrics: TestMetrics)

      conn =
        conn(:get, "/")
        |> put_req_header("x-api-key", "ZYXXY")
        |> TaggedApiKeyPlug.call(config)

      assert conn.status == 403
      assert conn.halted

      refute_received {:metrics, _}
    end
  end

  defp call(config, key, header \\ "x-api-key") do
    config =
      config
      |> Keyword.put_new(:header, header)
      |> Keyword.put_new(:metrics, false)
      |> TaggedApiKeyPlug.init()

    conn(:get, "/foo", "bar=10")
    |> put_req_header(header, key)
    |> TaggedApiKeyPlug.call(config)
  end
end
