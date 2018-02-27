defmodule DefUtil do
  @moduledoc """
  A utility to help debug macros by dumping a module's fully expanded source-code after compilation.

  Simply `use` this module:
  ```
      use DefUtil
  ```
  """

  @doc false
  defmacro __using__(_) do
    quote do
      @on_definition {DefUtil, :on_def}
    end
  end

  # credo:disable-for-this-file
  @doc false
  def on_def(_env, kind, name, args, guards, body) do
    IO.puts "Defining #{kind} named #{name} with args:"
    IO.inspect args
    IO.puts "and guards"
    IO.inspect guards
    IO.puts "and body"
    IO.puts Macro.to_string(body)
  end

end
