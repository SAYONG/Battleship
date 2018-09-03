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
end