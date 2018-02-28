defmodule FT.Web.ETSKeyStorage do
  @moduledoc """
  A key storage module that stores keys in an ETS table.

  Call `setup/1` with keys before `lookup/1` is called, e.g in your `Application.start/2`
  method or other permanent supervised process.
  """

  @behaviour FT.Web.KeyStorage

  @doc "store keys from delimited string format."
  def setup("" <> keys) do
    table_ref = :ets.new(__MODULE__, [:named_table, :protected, {:read_concurrency, true}])
    keys = expand_keys(keys)
    Enum.each(keys, fn key_roles -> :ets.insert(table_ref, key_roles) end)
  end

  @spec lookup(key :: String.t) :: {:ok, FT.Web.KeyStorage.roles} | false
  @impl FT.Web.KeyStorage
  def lookup(key) do
    case :ets.lookup(__MODULE__, key) do
      [{_key, roles}] -> {:ok, roles}
      [] -> false
    end
  end

  # split key config string into a map of `"key" => %{:role => true, ...}`
  defp expand_keys("" <> keys) do
    keys # "key1,key2<>x,key3<>x<>y"
    |> String.splitter(",", trim: true) # ["key1", "key2<>x", "key3<>x<>y"]
    |> Stream.map(&(String.split(&1, "<>", trim: true))) #  [["key1"], ["key2", "x"], ["key3", "x", "y"]
    |> Stream.map(fn [key | roles] -> {key, roles} end) # [{"key1", []}, {"key2", ["x"]}, ...]
    |> Stream.map(fn {key, roles} -> {key, to_roles_map(roles)} end) # [{"key1", %{}}, {"key2", %{x: true}}, ...]
    |> Enum.into(%{})
  end

  defp to_roles_map(roles) when is_list(roles) do
    Enum.into(roles, %{}, fn
      tag when is_atom(tag) -> {tag, true}
      tag -> {String.to_atom(tag), true}
    end)
  end

end