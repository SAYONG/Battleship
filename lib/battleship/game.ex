defmodule Battleship.Game do
  use GenServer

  alias Battleship.{Board, Guesses, Rules}

  def start_link(name) when is_binary(name), do:
    GenServer.start_link(__MODULE__, name, [])

  def init(name) do
    player1 = %{name: name, borard: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, borard: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: Rules.new()}}
  end

  def add_player(game, name), do:
    GenServer.call(game, {:add_player, name})

  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player)
      do
        state
          |> update_player2_name(name)
          |> update_rules(rules)
          |> reply_success(:ok)
      else
        :error -> {:reply, :error, state}
    end
  end

  defp update_player2_name(state, name), do:
    put_in(state.player2.name, name)

  defp update_rules(state, rules), do:
    %{state | rules: rules}

  defp reply_success(state, reply), do: {:reply, reply, state}
end