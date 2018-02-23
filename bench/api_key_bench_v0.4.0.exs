keys = "DC0D6FF0548DB4F9B0A3ACD94918BF15DA0CBECC<>admin<>explorer,E4D528F9A5311E9CC33DB75467FCF71D951C9AA3<>admin<>explorer<>acceptance-tests,598905869F6C9CD53B8A4E97A99158A99C72F416<>explorer,7D189DE0C23EE5C681D639F3A7549E8B92073A00,6F6822EFCDCCDD8C2FA5710427BD99D545F6C8FA<>explorer,0C2B0038172978FCD338F336F3D56B92CB8DD67B<>admin<>explorer,A791365B1A1B9EC62B1863029B4C976153E99991<>explorer,02BD28467AB97C62138FD5C14EEA09DD3944F857<>explorer,98DD345319618DE0227CAFE7F3B885BE9C8B2EBA<>explorer,0095AF05002A7474E0EE24965EB02031D5C7A44D<>explorer,BFA16FAF8A52D3BBD185527771A3E2EA4ECF0314<>explorer,97A0BE8A473FF0ACB331317F713C60E981F4A744<>user<>acceptance-tests-non-explorer,861FA028FFB7723AB26FE00AC9F68C14EA4A4ADF<>bonsai-tiger,A45D16592C9B2178DF26632B6956CD72A4A757B9<>gift-article-svc,8D87FBB6DE17705D59BFC78FB1C2C61BAAF353BB,B14FBC243C24D85A946CB4DDFA2E741836E2141B<>explorer<>next-profile,4F9B4A03C7AD21C26E1C13E77EC9E4C4CB587167,1F31A9875494913807F9DFB6D2A19E43C8079FE7<>explorer<>data-team"

conn =
  Plug.Test.conn("GET", "/")
  |> Plug.Conn.put_req_header("x-api-key", "6F6822EFCDCCDD8C2FA5710427BD99D545F6C8FA")

expected_auth = %FT.Web.Authentication{method: :api_key, private: %{key: "6F6822EFCDCCDD8C2FA5710427BD99D545F6C8FA"}, roles: %{explorer: true}}

string_parsing_config = FT.Web.TaggedApiKeyPlug.init(keys: keys)
string_parsing = fn ->
  conn = FT.Web.TaggedApiKeyPlug.call(conn, string_parsing_config)
  # NB introduces 1.6.0 compiler bug when followed by :erlang.phash2(expected_auth.private.key)
  # ** (CompileError) elixir_compiler_1: function '-__FILE__/1-fun-0-'/2+10:
  # Internal consistency check failed - please report this bug.
  # Instruction: {get_map_elements,{f,19},{x,0},{list,[{atom,private},{x,1}]}}
  # Error:       {bad_type,{needed,map},{actual,term}}:

  #   (stdlib) lists.erl:1338: :lists.foreach/2
  ^expected_auth = FT.Web.Authentication.authentication(conn)
  # :erlang.phash2(expected_auth.private.key)
end

FT.Web.ETSKeyStorage.setup(keys)
ets_storage_config = FT.Web.TaggedApiKeyPlug.init(keys: FT.Web.ETSKeyStorage)
ets_storage = fn ->
  conn = FT.Web.TaggedApiKeyPlug.call(conn, ets_storage_config)
  ^expected_auth = FT.Web.Authentication.authentication(conn)
  # :erlang.phash2(expected_auth.private.key)
end

Benchee.run(%{
  "string_parsing" => string_parsing,
  "ets_storage" => ets_storage
},
time: 20)
