defmodule Ash.Flags do
  @moduledoc """
  Feature flagging support for Ash internals.

  These are macros so that they can be used at compile time to switch code
  paths.
  """

  @flags [
    read_uses_flow?: false
  ]

  @flag_config Application.compile_env(:ash, :flags, [])

  @flag_values Enum.reduce(@flags, %{}, fn {key, default}, values ->
                 Map.put(values, key, Keyword.get(@flag_config, key, default))
               end)

  @noop {:__block__, [], []}

  @doc "Should read actions use the new flow-based executor?"
  @spec read_uses_flow? :: Macro.t()
  defmacro read_uses_flow? do
    quote do
      unquote(Map.get(@flag_values, :read_uses_flow?))
    end
  end

  @doc """
  Ensure that the feature flag is set to the expected value, otherwise an
  exception will be thrown at run time.
  """
  @spec assert!(atom, any) :: Macro.t()
  defmacro assert!(flag, expected) when :erlang.map_get(flag, @flag_values) == expected, do: @noop

  defmacro assert!(flag, expected) when :erlang.map_get(flag, @flag_values) != expected do
    actual = Map.get(@flag_values, flag)

    heading =
      "Expected value of the `#{inspect(flag)}` feature flag to be `#{inspect(expected)}`, however it is `#{inspect(actual)}`."

    quote do
      raise Ash.Error.Framework.FlagAssertionFailed.exception(
              flag: unquote(flag),
              heading: unquote(heading)
            )
    end
  end

  @doc """
  Ensure that the feature flag is set to the expected value, otherwise an
  exception will be thrown at run time.
  """
  @spec refute!(atom, any) :: Macro.t()
  defmacro refute!(flag, expected) when :erlang.map_get(flag, @flag_values) != expected, do: @noop

  defmacro refute!(flag, expected) when :erlang.map_get(flag, @flag_values) == expected do
    heading =
      "Expected value of the `#{inspect(flag)}` feature flag not to be `#{inspect(expected)}`."

    quote do
      raise Ash.Error.Framework.FlagAssertionFailed.exception(
              flag: unquote(flag),
              heading: unquote(heading)
            )
    end
  end
end
