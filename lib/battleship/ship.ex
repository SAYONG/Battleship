defmodule Battleship.Ship do
    alias Battleship.{Coordinate, Ship}
    
    @enforce_keys [:coordinates, :hit_coordinates]
    defstruct [:coordinates, :hit_coordinates]

    def new(type, %Coordinate{} = upper_left) do
        with [_|_] = offsets <- offsets(type),
          %MapSet{} = coordinates <- add_coordinates(offsets, upper_left)
        do
          {:ok, %Ship{coordinates: coordinates, hit_coordinates: MapSet.new()}}
        else
          error -> error
        end
    end

    def add_coordinates(offsets, upper_left) do
      Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
        add_coordinate(acc, upper_left, offset)
      end)
    end

    def overlaps?(existing_ship, new_ship), do:
      not MapSet.disjoint?(existing_ship.coordinates, new_ship.coordinates)

    def guess(ship, coordinate) do
      case MapSet.member?(ship.coordinates, coordinate) do
        true ->
          hit_coordinates = MapSet.put(ship.hit_coordinates, coordinate)
          {:hit, %{ship | hit_coordinates: hit_coordinates}}
        false -> :miss
      end
    end

    def types(), do:
      [:square, :atoll, :dot, :l_shape, :s_shape]

    def destroyed?(ship), do:
      MapSet.equal?(ship.coordinates, ship.hit_coordinates)

    defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
      case Coordinate.new(row + row_offset, col + col_offset) do
        {:ok, coordinate} ->
          {:cont, MapSet.put(coordinates, coordinate)}
        {:error, :invalid_coordinate} ->
          {:halt, {:error, :invalid_coordinate}}
      end
    end

    defp offsets(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]

    defp offsets(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]

    defp offsets(:dot), do: [{0, 0}]

    defp offsets(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]

    defp offsets(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {0, 1}]

    defp offsets(_), do: {:error, :invalid_ship_shape}
end

