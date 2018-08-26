alias Battleship.{Ship}

defmodule Battleship.Board do
  alias __MODULE__

  def new(), do: %{}

  def position_ship(board, key, %Ship{} = ship) do
    case ship.overlaps_existing_ship?(board, key, ship) do
      true -> {:error, :overlaping_ship}
      false -> Map.put(board, key, ship)
    end
  end

  def all_ship_positioned?(board) do
    Enum.all?(Ship.types, %(Map.has_key?(board, &1)))
  end

  defp overlaps_existing_ship?(board, new_key, new_ship) do
    Enum.any?(board, fn(key, ship) -> 
      key != new_key and Ship.overlaps?(ship, new_ship)
    end)
  end
end