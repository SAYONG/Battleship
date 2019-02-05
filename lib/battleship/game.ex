defmodule Battleship.Game do
  @tiemout 5 * 60 * 1000

  use GenServer

  alias Battleship.{Board, Guesses, Rules, Coordinate, Ship}

  @players [:player1, :player2]

  def start_link(name) when is_binary(name), do:
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))

  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: Rules.new()}, @tiemout}
  end

  def add_player(game, name), do:
    GenServer.call(game, {:add_player, name})

  def position_ship(game, player, key, row, col), do:
    GenServer.call(game, {:position_ship, player, key, row, col})

  def set_ships(game, player) when player in @players, do:
    GenServer.call(game, {:set_ships, player})

  def guess_coordinate(game, player, row, col), do:
    GenServer.call(game, {:guess_coordinate, player, row, col})

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player)
      do
        state
          |> update_player2_name(name)
          |> update_rules(rules)
          |> reply_success(:ok)
      else
        :error -> reply_error(:error, state)
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
        :error -> reply_error(:error, state)
        {:error, :invalid_coordinate} -> reply_error({:error, :invalid_coordinate}, state)
        {:error, :invalid_ship_shape} -> reply_error({:error, :invalid_ship_shape}, state)
      end
  end

  def handle_call({:set_ships, player}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:set_ships, player}),
        true <- Board.all_ships_positioned?(board)
      do
        state
          |> update_rules(rules)
          |> reply_success({:ok, board})
      else
        :error -> reply_error(:error, state)
        false -> reply_error({:error, :not_all_ships_positioned}, state)
      end
  end

  def handle_call({:guess_coordinate, player, row, col}, _from, state) do
    opponent_player = opponent(player)
    opponent_board = player_board(state, opponent_player)
    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
        {:ok, coordinate} <- Coordinate.new(row, col),
        {hit_or_miss, destroyed_ship, win_status, opponent_board} <- Board.guess(opponent_board, coordinate),
        {:ok, rules} = Rules.check(rules ,{:win_check, win_status})
      do
        state
          |> update_board(opponent_player, opponent_board)
          |> update_guesses(player, hit_or_miss, coordinate)
          |> update_rules(rules)
          |> reply_success({hit_or_miss, destroyed_ship, win_status})
      else
        :error -> reply_error(:error, state)
        {:error, :invalid_coordinate} -> reply_error({:error, :invalid_coordinate}, state)
      end
  end

  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  defp player_board(state, player), do: Map.get(state, player).board

  defp update_player2_name(state, name), do:
    put_in(state.player2.name, name)

  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1

  defp update_board(state, player, board), do:
    Map.update!(state, player, fn player -> %{player | board: board} end)
  
  defp update_guesses(state, player, hit_or_miss, coordinate), do:
    update_in(state[player].guesses, fn guesses -> Guesses.add(guesses, hit_or_miss, coordinate) end)

  defp update_rules(state, rules), do:
    %{state | rules: rules}

  defp reply_success(state, reply), do: {:reply, reply, state, @tiemout}
  defp reply_error(state, reply), do: {:reply, reply, state, @tiemout}
end