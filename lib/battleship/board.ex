alias Battleship.{Coordinate, Ship}

defmodule Battleship.Board do

  def new(), do: %{}

  def position_ship(board, key, %Ship{} = ship) do
    case overlaps_existing_ship?(board, key, ship) do
      true -> {:error, :overlaping_ship}
      false -> Map.put(board, key, ship)
    end
  end

  def all_ships_positioned?(board) do
    Enum.all?(Ship.types, &(Map.has_key?(board, &1)))
  end

  def guess(board, %Coordinate{} = coordinate) do
    board
    |> check_all_ships(coordinate)
    |> guess_response(board)
  end

  defp check_all_ships(board, coordinate) do
    Enum.find_value(board, :miss, fn {key, ship} ->
      case Ship.guess(ship, coordinate) do
        {:hit, ship} -> {key, ship}
        :miss        -> false
      end
    end)
  end

  defp guess_response({key, ship}, board) do
    board = %{board | key => ship}
    {:hit, destroy_chek(board, key), win_check(board), board}
  end

  defp guess_response(:miss, board), do:
    {:miss, :none, :no_win, board}

  defp destroy_chek(board, key) do
    case destroyed?(board, key) do
      true -> key
      false -> :none
    end
  end

  defp destroyed?(board, key) do
    board
    |> Map.fetch!(key)
    |> Ship.destroyed?()
  end

  defp win_check(board) do
    case all_destroyed?(board) do
      true -> :win
      false -> :no_win
    end
  end

  def all_destroyed?(board) do
    Enum.all?(board, fn {_key, ship} -> Ship.destroyed?(ship) end)
  end

  defp overlaps_existing_ship?(board, new_key, new_ship) do
    Enum.any?(board, fn {key, ship} ->
      key != new_key and Ship.overlaps?(ship, new_ship)
    end)
  end
end