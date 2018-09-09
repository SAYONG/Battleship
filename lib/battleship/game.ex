defmodule Battleship.Game do
  use GenServer

  alias Battleship.{Board, Guesses, Rules, Coordinate, Ship}

  def start_link(name) when is_binary(name), do:
    GenServer.start_link(__MODULE__, name, [])

  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: Rules.new()}}
  end

  def add_player(game, name), do:
    GenServer.call(game, {:add_player, name})

  def position_ship(game, player, key, row, col), do:
    GenServer.call(game, {:position_ship, player, key, row, col})

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

  def handle_call({:position_ship, player, key, row, col}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:position_ships, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, ship} <- Ship.new(key, coordinate),
         %{} = board <- Board.position_ship(board, key, ship)
      do
        state
          |> update_board(player, board)
          |> update_rules(rules)
          |> reply_success(:ok)
      else
        :error -> {:reply, :error, state}
        {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state}
        {:error, :invalid_ship_shape} -> {:reply, {:error, :invalid_ship_shape}, state}
      end
  end

  defp player_board(state, player), do: Map.get(state, player).board

  defp update_player2_name(state, name), do:
    put_in(state.player2.name, name)

  defp update_board(state, player, board), do:
    Map.update!(state, player, fn player -> %{player | board: board} end)

  defp update_rules(state, rules), do:
    %{state | rules: rules}

  defp reply_success(state, reply), do: {:reply, reply, state}
end