defmodule Battleship.Rules do
  alias __MODULE__

   defstruct state: :initialized,
             player1: :ships_not_set,
             player2: :ships_not_set

   def new(), do: %Rules{}

   def check(%Rules{state: :initialized} = rules, :add_player), do:
    {:ok, %Rules{rules | state: :players_set}}

  def check(%Rules{state: :players_set} = rules,
  {:position_ships, player}) do
    case Map.fetch!(rules, player) do
      :ships_set -> :error
      :ships_not_set -> {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set} = rules,
  {:set_ships, player}) do
    rules = Map.put(rules, player, :ships_set)
    case both_player_ships_set?(rules) do
      true -> {:ok, %Rules{rules | state: player1_turn}}
      false -> {:ok, rules}
    end
  end

  def check(_state, _action), do: :error

  defp both_player_ships_set?(rules) do
    rules.player1 == :ships_set && rules.player2 == :ships_set
  end
end